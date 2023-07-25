# frozen_string_literal: true

require_relative "../patcher"

module RubyReconstruction
  class Patcher
    # https://github.com/akr/all-ruby/blob/d3ab19975b540c1c808f2b29d06775876e7a93cd/Rakefile#L415-L474
    register def convert_varargs_to_stdarg!
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
  end
end
