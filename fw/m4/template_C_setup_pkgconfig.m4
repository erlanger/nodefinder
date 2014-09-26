AC_DEFUN([FW_TEMPLATE_C_SETUP_PKGCONFIG],
[
  AC_REQUIRE([FW_CHECK_BUILD_ENVIRONMENT])
  AC_REQUIRE([FW_DETECT_NATIVE_PACKAGE])

  AC_MSG_CHECKING([for pkg-config based build dependencies])

  if test "$FW_NATIVE_PACKAGE_TYPE" != none
    then
      arch=`fw-exec "package/$FW_NATIVE_PACKAGE_TYPE/get-arch"          \
                     --build yes                                        \
                     --template "$FW_TEMPLATE"`

      test $? = 0 || exit 1

      FW_PKGCONFIG_REQUIRES=`                                           \
        fw-exec "package/check-for-pkgconfig-packages"                  \
                "$arch"                                                 \
                "$FW_PACKAGE_BUILD_DEPENDS"                             \
                "$FW_NATIVE_PACKAGE_TYPE"`

      test $? = 0 || exit 1

      if test -z "$FW_PKGCONFIG_REQUIRES"
        then
          AC_MSG_RESULT([(empty)])
          FW_PKGCONFIG_PREREQS_CFLAGS=""
          FW_PKGCONFIG_PREREQS_LIBS=""
        else
          AC_MSG_RESULT([$FW_PKGCONFIG_REQUIRES])
          PKG_CHECK_MODULES([FW_PKGCONFIG_PREREQS],
                            [$FW_PKGCONFIG_REQUIRES],
                            ,
                            [AC_MSG_ERROR([pkg-config of '$FW_PKGCONFIG_REQUIRES' failed: $FW_PKGCONFIG_PREREQS_PKG_ERRORS])])
        fi
    else
        FW_PKGCONFIG_REQUIRES=""
        AC_MSG_RESULT([skipped (unknown native package type)])
        AC_MSG_WARN([compilation may fail due to bad CFLAGS and LIBS])

        FW_PKGCONFIG_PREREQS_CFLAGS=""
        FW_PKGCONFIG_PREREQS_LIBS=""
    fi

  FW_SUBST_PROTECT([FW_PKGCONFIG_CFLAGS])
  FW_SUBST_PROTECT([FW_PKGCONFIG_CFLAGS_EXTRA])
  FW_SUBST_PROTECT([FW_PKGCONFIG_LIBS])
  FW_SUBST_PROTECT([FW_PKGCONFIG_LIBS_EXTRA])
  FW_SUBST_PROTECT([FW_PKGCONFIG_REQUIRES])
  FW_SUBST_PROTECT([FW_PKGCONFIG_REQUIRES_EXTRA])

  FW_SUBST_PROTECT([FW_PKGCONFIG_PREREQS_CFLAGS])
  FW_SUBST_PROTECT([FW_PKGCONFIG_PREREQS_LIBS])

  FW_SUBST_PROTECT([FW_PKGCONFIG_EXTRA])

  AC_CONFIG_FILES([pkgconfig-template.pc])
])
