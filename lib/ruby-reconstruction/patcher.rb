# frozen_string_literal: true

require "tmpdir"
require "fileutils"

module RubyReconstruction
  class Patcher
    BUILD_ARTIFACTS = [
      "Makefile",
      "ext/Makefile",
      "ext/extmk.rb",
      "config.cache",
      "config.h",
      "config.log",
      "config.status",
      "ruby",
      /\.o$/,
    ].freeze

    def self.sync_patched(src, dest)
      FileUtils.mkdir_p dest

      Dir.mktmpdir do |tmpdir|
        tmp_dest = "#{tmpdir}/ruby"
        make_patched(src, tmp_dest)
        sync(tmp_dest, dest)
      end
    end

    def self.sync(src, dest)
      ours = Dir.glob("**/*", base: src).select { |path|
        BUILD_ARTIFACTS.none? { |artifact| artifact === path }
      }
      theirs = Dir.glob("**/*", base: dest).select { |path|
        BUILD_ARTIFACTS.none? { |artifact| artifact === path }
      }
      ours.each do |path|
        if File.directory?("#{src}/#{path}")
          $stderr.puts "mkdir #{path}" unless File.exist?("#{dest}/#{path}")
          FileUtils.mkdir_p "#{dest}/#{path}"
        else
          if !File.exist?("#{dest}/#{path}") || File.binread("#{src}/#{path}") != File.binread("#{dest}/#{path}")
            $stderr.puts "update #{path}"
            FileUtils.cp "#{src}/#{path}", "#{dest}/#{path}"
          end
        end
      end
      (theirs - ours).each do |path|
        $stderr.puts "rm#{File.directory?("#{dest}/#{path}") ? "dir" : ""} #{path}"
        FileUtils.rm_rf "#{dest}/#{path}"
      end
    end

    def self.make_patched(src, dest)
      FileUtils.rm_rf(dest)
      FileUtils.cp_r(src, dest)
      patch!(dest)
    end

    def self.patch!(dir)
      new(dir).patch!
    end

    attr_reader :dir

    def initialize(dir)
      @dir = dir
    end

    def patch!
      convert_varargs_to_stdarg!
      add_error_prototype!
      fix_stdio_pending!
      fix_struct_va_end!
      include_time_header!
      deduplicate_vars!
      fix_errno_decl!
      use_gdbm_compat!
      fix_dbmcc!
      fix_ldshared!
      use_crypt!
      fix_dirent_conf!
      fix_alloca_prototype!
      fix_re_match_2!
      fix_renamed_cons!
      fix_missing_ext_makefile!
      fix_pow_detection!
      fix_sys_nerr!
    end

    # https://github.com/akr/all-ruby/blob/d3ab19975b540c1c808f2b29d06775876e7a93cd/Rakefile#L415-L474
    def convert_varargs_to_stdarg!
      funcs = {}
      Dir.glob("#{dir}/*.c").each {|fn|
        src = File.binread(fn)
        next if /^\#include <stdarg\.h>\n/ =~ src
        next if /^\#include <varargs\.h>\n/ !~ src
        # File.write("#{fn}.org", src)
        src.gsub!(/^#include <varargs.h>\n/, <<-End.gsub(/^\s*/, ''))
          #ifdef __STDC__
          #include <stdarg.h>
          #define va_init_list(a,b) va_start(a,b)
          #else
          #include <varargs.h>
          #define va_init_list(a,b) va_start(a)
          #endif
        End
        src.gsub!(/^([A-Za-z][A-Za-z0-9_]*)\((.*), va_alist\)\n(( .*;\n)*)( +va_dcl\n)(\{.*\n(.*\n)*?\})/) {

          func = $1
          fargs = $2
          decls = $3
          body = $6
          decl_hash = {}
          decls.each_line {|line|
            line.gsub!(/^ +|;\n/, '')
            n = line.scan(/[a-z_][a-z_0-9]*/)[-1]
            decl_hash[n] = line
          }
          fargs.gsub!(/[a-z_][a-z_0-9]*/) {
            n = $&
            decl_hash[n] || "int #{n}"
          }
          stdarg_decl = "#{func}(#{fargs}, ...)"
          funcs[func] = stdarg_decl
          lastarg = stdarg_decl.scan(/[a-z_][a-z_0-9]*/)[-1]
          body.gsub!(/va_start\(([a-z]+)\)/) { "va_init_list(#{$1}, #{lastarg})" }
          stdarg_decl + "\n" + body
        }
        if fn == "#{dir}/error.c"
          src.gsub!(/^extern void TypeError\(\);/, '/* extern void TypeError(); */')
          src.gsub!(/^ *void ArgError\(\);/, '/* void ArgError(); */')
          src.gsub!(/va_start\(args\);/, 'va_start(args, fmt);')
        end
        src.gsub!(/^\#ifdef __GNUC__\nstatic volatile voidfn/, "\#if 0\nstatic volatile voidfn")
        # File.write("#{fn}+", src)
        File.write(fn, src)
      }
      %w[intern.h ruby.h].each {|header|
        fn = "#{dir}/#{header}"
        next unless File.file? fn
        h = File.read(fn)
        # File.write("#{fn}.org", h)
        funcs.each {|func, stdarg_decl|
          h.gsub!(/ #{func}\(\);/) { " #{stdarg_decl};" }
        }
        h.gsub!(/^\#ifdef __GNUC__\ntypedef void voidfn/, "\#if 0\ntypedef void voidfn")
        h.gsub!(/^\#ifdef __GNUC__\nvolatile voidfn/, "\#if 0\nvolatile voidfn")
        File.write(fn, h)
      }
    end

    def add_error_prototype!
      rewrite_file("error.c") do |src|
        error_pos = src.index("\nvoid\nError(char *fmt, ...)") || src.index("\nError(char *fmt, ...)")
        yyerror_pos = src.index("\nvoid\nyyerror(msg)") || src.index("\nint\nyyerror(msg)") || src.index("\nyyerror(msg)")

        return src unless error_pos && yyerror_pos
        return src if error_pos < yyerror_pos

        src2 = +src
        src2[yyerror_pos, 0] = "\nvoid Error(char *fmt, ...);\n"
        src2
      end
    end

    def fix_stdio_pending!
      rewrite_file("io.c") do |src|
        if src.include?("ifdef _STDIO_USES_IOSTREAM")
          src
            .gsub("ifdef _STDIO_USES_IOSTREAM", "if 1")
            .gsub("ifdef _IO_fpos_t", "if 1")
            .gsub("ifdef _other_gbase", "if 1")
        else
          src
            .gsub(/->_gptr/, "->_IO_read_ptr")
            .gsub(/->_egptr/, "->_IO_read_end")
        end
      end
    end

    def fix_struct_va_end!
      rewrite_file("struct.c") do |src|
        src
          .gsub("va_end(vargs)", "va_end(args)")
      end
    end

    def include_time_header!
      rewrite_file("time.c") do |src|
        return src if src.include?("#include <time.h>")

        pos = %r{#include <sys/time.h>\n}.match(src).end(0)
        src2 = +src
        src2[pos, 0] = "#include <time.h>\n"
        src2
      end
    end

    def deduplicate_vars!
      rewrite_file("range.c") do |src|
        src
          .gsub("\nVALUE M_Comparable;", "\nextern VALUE M_Comparable;")
          .gsub("\nVALUE mComparable;", "\nextern VALUE mComparable;")
      end
      rewrite_file("object.c") do |src|
        src
          .gsub("\nVALUE cFixnum;", "\nextern VALUE cFixnum;")
      end
      rewrite_file("env.h") do |src|
        src
          .gsub(/^(struct SCOPE \{[^}]*\} \*the_scope;)/, "extern \\1")
      end
    end

    def fix_errno_decl!
      rewrite_file("error.c") do |src|
        return if src.include?("#include \"errno.h\";") || src.include?("#include <errno.h>;")

        "#include <errno.h>;\n" + src
      end
    end

    def use_gdbm_compat!
      rewrite_file("configure") do |src|
        src.gsub("-ldbm", "-lgdbm_compat")
      end
      rewrite_file("configure.in") do |src|
        src.gsub("-ldbm", "-lgdbm_compat")
      end
    end

    def fix_dbmcc!
      rewrite_file("Makefile.in") do |src|
        src.gsub("DBMCC = cc", "DBMCC = @CC@")
      end
    end

    def fix_ldshared!
      rewrite_file("ext/extmk.rb.in") do |src|
        src.gsub("LDSHARED = @LDSHARED@", "LDSHARED = @CC@ -shared")
      end
    end

    def use_crypt!
      rewrite_file("configure.in") do |src|
        next src if src.include?("-lcrypt") || src.include?("AC_CHECK_LIB(crypt")
        last_have_library = src.scan(%r{AC_HAVE_LIBRARY\(.*\)\n}).last
        src.sub(last_have_library, last_have_library + "AC_CHECK_LIB(crypt, [LIBS=\"$LIBS -lcrypt\"])\n")
      end
      rewrite_file("configure") do |src|
        next src if src.include?("-lcrypt")
        last_libs_line_pos = src.rindex("LIBS=\"\$LIBS ")
        last_libs_section_pos = src.index(/^fi$/, last_libs_line_pos) + 3

        src2 = +src
        src2[last_libs_section_pos, 0] = <<~End

          LIBS_save="${LIBS}"
          LIBS="${LIBS} -lcrypt"
          have_lib=""
          echo checking for -lcrypt
          cat > conftest.c <<EOF
          #include "confdefs.h"

          int main() { exit(0); }
          int t() { main(); }
          EOF
          if eval $compile; then
            rm -rf conftest*
            have_lib="1"

          fi
          rm -f conftest*
          LIBS="${LIBS_save}"
          if test -n "${have_lib}"; then
              :; LIBS="$LIBS -lcrypt"
          else
              :;
          fi
        End
        src2
      end
    end

    def fix_dirent_conf!
      conf_src = binread("configure.in")
      # HAVE_DIRENT_H would be correctly generated
      return if conf_src.match?(/AC_HAVE_HEADERS\([^)]*?dirent.h\)/)

      rewrite_file("gnuglob.c") do |src|
        src.gsub("#if defined (HAVE_DIRENT_H)", "#if defined (DIRENT)")
      end
    end

    def fix_alloca_prototype!
      rewrite_file("glob.c") do |src|
        src.gsub("char *alloca ();", "#include <alloca.h>")
      end
      rewrite_file("gnuglob.c") do |src|
        src.gsub("char *alloca ();", "#include <alloca.h>")
      end
    end

    def fix_re_match_2!
      rewrite_file("regex.c") do |src|
        src.gsub(/re_match_2 \((.*?), size\)/, "re_match_2 (\\1)")
      end
    end

    def fix_renamed_cons!
      if exist?("assoc.c") && !exist?("cons.c")
        rewrite_file("Makefile.in") do |src|
          src.gsub("cons.o", "assoc.o").gsub("cons.c", "assoc.c")
        end
      end
    end

    def fix_missing_ext_makefile!
      if binread("configure").include?("ext/Makefile") && !exist?("ext/Makefile.in")
        mkdir_p("ext")
        binwrite("ext/Makefile.in", "all:\n")
      end
    end

    def fix_pow_detection!
      rewrite_file("configure") do |src|
        src.gsub("pow()", "pow(1.0, 1.0)")
      end
    end

    def fix_sys_nerr!
      rewrite_file("error.c") do |src|
        src.gsub("\nextern int sys_nerr;", "\n#define sys_nerr 256")
      end
    end

    def rewrite_file(rel_path)
      return unless exist?(rel_path)

      src = -binread(rel_path)
      src2 = yield(src)
      binwrite(rel_path, src2) if src != src2
    end

    def exist?(rel_path)
      File.exist?("#{dir}/#{rel_path}")
    end

    def binread(rel_path)
      File.binread("#{dir}/#{rel_path}")
    end

    def binwrite(rel_path, src)
      File.binwrite("#{dir}/#{rel_path}", src)
    end

    def mkdir_p(rel_path)
      FileUtils.mkdir_p("#{dir}/#{rel_path}")
    end
  end
end
