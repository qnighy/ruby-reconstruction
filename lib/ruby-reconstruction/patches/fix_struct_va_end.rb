# frozen_string_literal: true

require_relative "../patcher"

module RubyReconstruction
  class Patcher
    register def fix_struct_va_end!
      rewrite_file("struct.c") do |src|
        src
          .gsub("va_end(vargs)", "va_end(args)")
      end
    end
  end
end
