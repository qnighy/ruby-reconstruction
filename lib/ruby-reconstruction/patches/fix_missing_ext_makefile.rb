# frozen_string_literal: true

require_relative "../patcher"

module RubyReconstruction
  class Patcher
    register def fix_missing_ext_makefile!
      if binread("configure").include?("ext/Makefile") && !exist?("ext/Makefile.in")
        mkdir_p("ext")
        binwrite("ext/Makefile.in", "all:\n")
      end
    end
  end
end
