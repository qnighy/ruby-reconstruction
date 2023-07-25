# frozen_string_literal: true

require_relative "../patcher"

module RubyReconstruction
  class Patcher
    register def include_time_header!
      rewrite_file("time.c") do |src|
        return src if src.include?("#include <time.h>")

        pos = %r{#include <sys/time.h>\n}.match(src).end(0)
        src2 = +src
        src2[pos, 0] = "#include <time.h>\n"
        src2
      end
    end
  end
end
