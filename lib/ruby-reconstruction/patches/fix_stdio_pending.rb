# frozen_string_literal: true

require_relative "../patcher"

module RubyReconstruction
  class Patcher
    register def fix_stdio_pending!
      rewrite_file("io.c") do |src|
        if src.include?("ifdef _STDIO_USES_IOSTREAM")
          src
            .gsub("ifdef _STDIO_USES_IOSTREAM", "if 1")
            .gsub("ifdef _IO_fpos_t", "if 1")
            .gsub("ifdef _other_gbase", "if 1")
        else
          src
            .gsub(/->_gptr/, "->_IO_read_ptr")
            .gsub(/->_egptr/, "->_IO_read_end")
        end
      end
    end
  end
end
