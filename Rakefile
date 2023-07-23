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
    # TODO: do some transformation
    convert_varargs_to_stdarg("#{tmpdir}/ruby")

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
