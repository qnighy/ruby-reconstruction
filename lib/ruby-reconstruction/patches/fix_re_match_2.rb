# frozen_string_literal: true

require_relative "../patcher"

module RubyReconstruction
  class Patcher
    register def fix_re_match_2!
      rewrite_file("regex.c") do |src|
        src.gsub(/re_match_2 \((.*?), size\)/, "re_match_2 (\\1)")
      end
    end
  end
end
