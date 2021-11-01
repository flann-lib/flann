set(PKG_DESC "Fast Library for Approximate Nearest Neighbors")

# Compute `PKG_EXTERNAL_DEPS` string from `PKGCONFIG_EXTERNAL_DEPS_LIST`.
# Once the project has `cmake_minimum_required(VERSION 2.6)`, this
# can be replaced by `list(JOIN ...)`.
set(PKG_EXTERNAL_DEPS "")
foreach(_dep ${PKGCONFIG_EXTERNAL_DEPS_LIST})
    string(APPEND PKG_EXTERNAL_DEPS " ${_dep}")
endforeach()

set(pkg_conf_file ${CMAKE_CURRENT_BINARY_DIR}/flann.pc)
configure_file(flann.pc.in ${pkg_conf_file} @ONLY)
install(FILES ${pkg_conf_file}
    DESTINATION ${FLANN_LIB_INSTALL_DIR}/pkgconfig/ COMPONENT pkgconfig)

