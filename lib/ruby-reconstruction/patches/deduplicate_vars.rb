# frozen_string_literal: true

require_relative "../patcher"

module RubyReconstruction
  class Patcher
    register def deduplicate_vars!
      rewrite_file("range.c") do |src|
        src
          .gsub("\nVALUE M_Comparable;", "\nextern VALUE M_Comparable;")
          .gsub("\nVALUE mComparable;", "\nextern VALUE mComparable;")
      end
      rewrite_file("object.c") do |src|
        src
          .gsub("\nVALUE cFixnum;", "\nextern VALUE cFixnum;")
      end
      rewrite_file("env.h") do |src|
        src
          .gsub(/^(struct SCOPE \{[^}]*\} \*the_scope;)/, "extern \\1")
      end
    end
  end
end
