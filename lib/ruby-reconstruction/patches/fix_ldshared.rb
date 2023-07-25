# frozen_string_literal: true

require_relative "../patcher"

module RubyReconstruction
  class Patcher
    register def fix_ldshared!
      rewrite_file("ext/extmk.rb.in") do |src|
        src.gsub("LDSHARED = @LDSHARED@", "LDSHARED = @CC@ -shared")
      end
    end
  end
end
