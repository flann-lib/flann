
if (HDF5)
    add_executable(flann_example_cpp flann_example.cpp)
    target_link_libraries(flann_example_cpp flann_cpp hdf5)
else()
    message("hdf5 library not found, not compiling flann_example.cpp")
endif()

add_executable(flann_example_c flann_example.c)
target_link_libraries(flann_example_c flann)
set_target_properties(flann_example_c PROPERTIES COMPILE_FLAGS -std=c99)


if (HDF5)
    add_custom_target(examples ALL DEPENDS flann_example_c flann_example_cpp)
    install (
        TARGETS flann_example_c flann_example_cpp
        DESTINATION bin
    )
else()
    add_custom_target(examples ALL DEPENDS flann_example_c)
    install (
        TARGETS flann_example_c
        DESTINATION bin
    )
endif()
