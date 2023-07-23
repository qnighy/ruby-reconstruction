# frozen_string_literal: true

RUBY_ARCHIVES = [
  "ruby-0.49.tar.gz",
  "ruby-0.50.tar.gz",
  "ruby-0.51-0.52.diff.gz",
  "ruby-0.51.tar.gz",
  "ruby-0.54.tar.gz",
  "ruby-0.55-0.56.diff.gz",
  "ruby-0.55.tar.gz",
  "ruby-0.60.tar.gz",
  "ruby-0.62.tar.gz",
  "ruby-0.62.tar.gz.broken",
  "ruby-0.63.tar.gz",
  "ruby-0.63.tar.gz.broken",
  "ruby-0.64.tar.gz",
  "ruby-0.65-0.66.diff.gz",
  "ruby-0.65.tar.gz",
  "ruby-0.66-0.67.diff.gz",
  "ruby-0.67-0.68.diff.gz",
  "ruby-0.69.tar.gz",
  "ruby-0.70-patch",
  "ruby-0.71-0.72.diff.gz",
  "ruby-0.71.tar.gz",
  "ruby-0.73-950413.tar.gz",
  "ruby-0.73.tar.gz",
  "ruby-0.76.tar.gz",
  "ruby-0.95.tar.gz",
  "ruby-0.99.4-961224.tar.gz",
  "ruby-1.0-961225.tar.gz",
  "ruby-1.0-971002.tar.gz",
  "ruby-1.0-971003.tar.gz",
  "ruby-1.0-971015.tar.gz",
  "ruby-1.0-971021.tar.gz",
  "ruby-1.0-971118.tar.gz",
  "ruby-1.0-971125.tar.gz",
  "ruby-1.0-971204.tar.gz",
  "ruby-1.0-971209.tar.gz",
  "ruby-1.0-971225.tar.gz",
]

ARCHIVED_VERSIONS = [
  "0.49",
  "0.50",
  "0.51",
  "0.54",
  "0.55",
  "0.60",
  "0.62",
  "0.63",
  "0.64",
  "0.65",
  "0.69",
  "0.71",
  "0.73-950413",
  "0.73",
  "0.76",
  "0.95",
  "1.0-961225",
  "1.0-971002",
  "1.0-971003",
  "1.0-971015",
  "1.0-971021",
  "1.0-971118",
  "1.0-971125",
  "1.0-971204",
  "1.0-971209",
  "1.0-971225",
]

BUILD_ARTIFACTS = [
  "Makefile",
  "config.status",
  /\.o$/,
]

directory "archives"

RUBY_ARCHIVES.each do |archive|
  file "archives/#{archive}" => "archives" do
    sh "curl --proto '=https' --tlsv1.2 -sSf -o archives/#{archive} https://cache.ruby-lang.org/pub/ruby/1.0/#{archive}"
  end
end

def checkout(version)
  if ARCHIVED_VERSIONS.include?(version)
    rm_rf "ruby"
    mkdir_p "ruby"
    sh "tar -xzf archives/ruby-#{version}.tar.gz -C ruby --strip-components 1"
  else
    raise "TODO: non-archived checkout"
  end
end

ARCHIVED_VERSIONS.each do |version|
  namespace :checkout do
    desc "Checkout Ruby #{version}"
    task version => "archives/ruby-#{version}.tar.gz" do
      checkout(version)
    end
  end
end

task "sync" do
  require "tmpdir"

  mkdir_p "build/ruby"

  Dir.mktmpdir do |tmpdir|
    cp_r "ruby", tmpdir

    convert_varargs_to_stdarg("#{tmpdir}/ruby")
    add_error_prototype("#{tmpdir}/ruby")
    rename_undocumented_file_member("#{tmpdir}/ruby")
    fix_struct_va_end("#{tmpdir}/ruby")
    include_time_header("#{tmpdir}/ruby")
    deduplicate_vars("#{tmpdir}/ruby")
    fix_errno_decl("#{tmpdir}/ruby")
    use_gdbm_compat("#{tmpdir}/ruby")
    use_crypt("#{tmpdir}/ruby")

    ours = Dir.glob("**/*", base: "#{tmpdir}/ruby").select { |path|
      BUILD_ARTIFACTS.none? { |artifact| artifact === path }
    }
    theirs = Dir.glob("**/*", base: "build/ruby").select { |path|
      BUILD_ARTIFACTS.none? { |artifact| artifact === path }
    }
    ours.each do |path|
      if File.directory?("#{tmpdir}/ruby/#{path}")
        mkdir_p "build/ruby/#{path}" unless File.exist?("build/ruby/#{path}")
      else
        cp "#{tmpdir}/ruby/#{path}", "build/ruby/#{path}" if !File.exist?("build/ruby/#{path}") || File.binread("#{tmpdir}/ruby/#{path}") != File.binread("build/ruby/#{path}")
      end
    end
    (theirs - ours).each do |path|
      # rm_rf "build/ruby/#{path}"
      $stderr.puts "TODO: remove #{path}"
    end
  end
end

task "configure" => "sync" do
  Dir.chdir("build/ruby") do
    sh "CC='gcc -m32 -g -O0' setarch i386 ./configure --prefix=#{Dir.pwd}/build/ruby"
  end
end

task "build" => "sync" do
  Dir.chdir("build/ruby") do
    sh "CC='gcc -m32 -g -O0' setarch i386 make"
  end
end

# https://github.com/akr/all-ruby/blob/d3ab19975b540c1c808f2b29d06775876e7a93cd/Rakefile#L415-L474
def convert_varargs_to_stdarg(dir)
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

def add_error_prototype(path)
  rewrite_file("#{path}/error.c") do |src|
    error_pos = src.index("\nvoid\nError(char *fmt, ...)") || src.index("\nError(char *fmt, ...)")
    yyerror_pos = src.index("\nvoid\nyyerror(msg)") || src.index("\nint\nyyerror(msg)") || src.index("\nyyerror(msg)")

    return src unless error_pos && yyerror_pos
    return src if error_pos < yyerror_pos

    src2 = +src
    src2[yyerror_pos, 0] = "\nvoid Error(char *fmt, ...);\n"
    src2
  end
end

def rename_undocumented_file_member(path)
  rewrite_file("#{path}/io.c") do |src|
    src
      .gsub(/->_gptr/, "->_IO_read_ptr")
      .gsub(/->_egptr/, "->_IO_read_end")
  end
end

def fix_struct_va_end(path)
  rewrite_file("#{path}/struct.c") do |src|
    src
      .gsub("va_end(vargs)", "va_end(args)")
  end
end

def include_time_header(path)
  rewrite_file("#{path}/time.c") do |src|
    return src if src.include?("#include <time.h>")

    pos = %r{#include <sys/time.h>\n}.match(src).end(0)
    src2 = +src
    src2[pos, 0] = "#include <time.h>\n"
    src2
  end
end

def deduplicate_vars(path)
  rewrite_file("#{path}/range.c") do |src|
    src
      .gsub("\nVALUE M_Comparable;", "\nextern VALUE M_Comparable;")
  end
end

def fix_errno_decl(path)
  rewrite_file("#{path}/error.c") do |src|
    return if src.include?("#include \"errno.h\";") || src.include?("#include <errno.h>;")

    "#include <errno.h>;\n" + src
  end
end

def use_gdbm_compat(path)
  rewrite_file("#{path}/configure") do |src|
    src.gsub("-ldbm", "-lgdbm_compat")
  end
  rewrite_file("#{path}/configure.in") do |src|
    src.gsub("-ldbm", "-lgdbm_compat")
  end
end

def use_crypt(path)
  rewrite_file("#{path}/configure.in") do |src|
    next src if src.include?("-lcrypt")
    last_have_library = src.scan(%r{AC_HAVE_LIBRARY\(.*\)\n}).last
    src.sub(last_have_library, last_have_library + "AC_CHECK_LIB(crypt, [LIBS=\"$LIBS -lcrypt\"])\n")
  end
  rewrite_file("#{path}/configure") do |src|
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

def rewrite_file(path)
  src = -File.binread(path)
  src2 = yield(src)
  File.binwrite(path, src2) if src != src2
end
