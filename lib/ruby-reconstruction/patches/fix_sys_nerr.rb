# frozen_string_literal: true

require_relative "../patcher"

module RubyReconstruction
  class Patcher
    register def fix_sys_nerr!
      rewrite_file("error.c") do |src|
        src.gsub("\nextern int sys_nerr;", "\n#define sys_nerr 256")
      end
    end
  end
end
