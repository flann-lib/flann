# CmakeLists.txt in Test dir
# Make sure the compiler can find include files from our Hello library.
# Add binary called "helloWorld" that is built from the source file "test.cc".
# The extension is automatically found.

#ADD_EXECUTABLE(test_autotune test_autotune.cc)

ADD_EXECUTABLE(flann_test flann_test.cc)
TARGET_LINK_LIBRARIES(flann_test flann)

INSTALL (
    TARGETS flann_test
    RUNTIME DESTINATION bin
)