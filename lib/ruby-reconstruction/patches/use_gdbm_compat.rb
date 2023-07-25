# frozen_string_literal: true

require_relative "../patcher"

module RubyReconstruction
  class Patcher
    register def use_gdbm_compat!
      rewrite_file("configure") do |src|
        src.gsub("-ldbm", "-lgdbm_compat")
      end
      rewrite_file("configure.in") do |src|
        src.gsub("-ldbm", "-lgdbm_compat")
      end
    end
  end
end
