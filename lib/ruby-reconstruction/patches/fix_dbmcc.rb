# frozen_string_literal: true

require_relative "../patcher"

module RubyReconstruction
  class Patcher
    register def fix_dbmcc!
      rewrite_file("Makefile.in") do |src|
        src.gsub("DBMCC = cc", "DBMCC = @CC@")
      end
    end
  end
end
