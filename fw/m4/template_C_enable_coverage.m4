AC_DEFUN([FW_TEMPLATE_C_ENABLE_COVERAGE],
[
  AC_ARG_ENABLE(coverage,
                [  --enable-coverage       turn on -fprofile-arcs -ftest-coverage ],
                [case "${enableval}" in
                  yes) FW_ENABLE_COVERAGE=1 ;;
                  no) FW_ENABLE_COVERAGE=0 ;;
                  *) AC_MSG_ERROR([bad value ${enableval} for --enable-coverage]) ;;
                esac],
                [FW_ENABLE_COVERAGE=2])

  AC_SUBST([FW_ENABLE_COVERAGE])

  AC_CONFIG_FILES([tests/test-wrapper.sh],
                  [chmod +x tests/test-wrapper.sh])

  if test "x[$]FW_ENABLE_COVERAGE" = "x1"
    then
      CFLAGS="`echo \"[$]CFLAGS\" | perl -pe 's/-O\d+//g;'` -fprofile-arcs -ftest-coverage"
    fi
])
