# frozen_string_literal: true

require_relative "../patcher"

module RubyReconstruction
  class Patcher
    register def use_crypt!
      rewrite_file("configure.in") do |src|
        next src if src.include?("-lcrypt") || src.include?("AC_CHECK_LIB(crypt")
        last_have_library = src.scan(%r{AC_HAVE_LIBRARY\(.*\)\n}).last
        src.sub(last_have_library, last_have_library + "AC_CHECK_LIB(crypt, [LIBS=\"$LIBS -lcrypt\"])\n")
      end
      rewrite_file("configure") do |src|
        next src if src.include?("-lcrypt")
        last_libs_line_pos = src.rindex("LIBS=\"\$LIBS ")
        last_libs_section_pos = src.index(/^fi$/, last_libs_line_pos) + 3

        src2 = +src
        src2[last_libs_section_pos, 0] = <<~End

          LIBS_save="${LIBS}"
          LIBS="${LIBS} -lcrypt"
          have_lib=""
          echo checking for -lcrypt
          cat > conftest.c <<EOF
          #include "confdefs.h"

          int main() { exit(0); }
          int t() { main(); }
          EOF
          if eval $compile; then
            rm -rf conftest*
            have_lib="1"

          fi
          rm -f conftest*
          LIBS="${LIBS_save}"
          if test -n "${have_lib}"; then
              :; LIBS="$LIBS -lcrypt"
          else
              :;
          fi
        End
        src2
      end
    end
  end
end
