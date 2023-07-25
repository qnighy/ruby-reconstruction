# frozen_string_literal: true

require_relative "../patcher"

module RubyReconstruction
  class Patcher
    register def fix_alloca_prototype!
      rewrite_file("glob.c") do |src|
        src.gsub("char *alloca ();", "#include <alloca.h>")
      end
      rewrite_file("gnuglob.c") do |src|
        src.gsub("char *alloca ();", "#include <alloca.h>")
      end
    end
  end
end
