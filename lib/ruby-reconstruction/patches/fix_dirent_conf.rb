# frozen_string_literal: true

require_relative "../patcher"

module RubyReconstruction
  class Patcher
    register def fix_dirent_conf!
      conf_src = binread("configure.in")
      # HAVE_DIRENT_H would be correctly generated
      return if conf_src.match?(/AC_HAVE_HEADERS\([^)]*?dirent.h\)/)

      rewrite_file("gnuglob.c") do |src|
        src.gsub("#if defined (HAVE_DIRENT_H)", "#if defined (DIRENT)")
      end
    end
  end
end
