# frozen_string_literal: true

require_relative "../patcher"

module RubyReconstruction
  class Patcher
    register def fix_renamed_cons!
      if exist?("assoc.c") && !exist?("cons.c")
        rewrite_file("Makefile.in") do |src|
          src.gsub("cons.o", "assoc.o").gsub("cons.c", "assoc.c")
        end
      end
    end
  end
end
