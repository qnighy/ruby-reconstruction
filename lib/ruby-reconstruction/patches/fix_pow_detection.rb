# frozen_string_literal: true

require_relative "../patcher"

module RubyReconstruction
  class Patcher
    register def fix_pow_detection!
      rewrite_file("configure") do |src|
        src.gsub("pow()", "pow(1.0, 1.0)")
      end
    end
  end
end
