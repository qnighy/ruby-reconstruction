# frozen_string_literal: true

require_relative "../patcher"

module RubyReconstruction
  class Patcher
    register def add_error_prototype!
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
  end
end
