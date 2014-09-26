AC_DEFUN([FW_TEMPLATE_C_ENABLE_HARDCORE],
[
  AC_ARG_ENABLE(hardcore,
                [  --disable-hardcore      turn off -Wall -Werror and other compiler warnings],
                [case "${enableval}" in
                  yes) FW_ENABLE_HARDCORE=1 ;;
                  no) FW_ENABLE_HARDCORE=0 ;;
                  *) AC_MSG_ERROR([bad value ${enableval} for --disable-coverage]) ;;
                esac],
                [FW_ENABLE_HARDCORE=1])

  AC_SUBST([FW_ENABLE_HARDCORE])

  if test "x[$]FW_ENABLE_HARDCORE" = "x1"
    then
      CPPFLAGS="$CPPFLAGS -W -Wall -Werror -Wpointer-arith -Wcast-align -Wwrite-strings -Wmissing-prototypes"
    fi
])
