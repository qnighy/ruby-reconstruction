# frozen_string_literal: true

require_relative "../patcher"

module RubyReconstruction
  class Patcher
    register def fix_errno_decl!
      rewrite_file("error.c") do |src|
        return if src.include?("#include \"errno.h\";") || src.include?("#include <errno.h>;")

        "#include <errno.h>;\n" + src
      end
    end
  end
end
