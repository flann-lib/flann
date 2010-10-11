
add_executable(flann_example_c flann_example.c)
target_link_libraries(flann_example_c flann)
set_target_properties(flann_example_c PROPERTIES COMPILE_FLAGS -std=c99)

add_custom_target(examples ALL DEPENDS flann_example_c)
install (TARGETS flann_example_c DESTINATION bin )

if (HDF5_FOUND)
    add_executable(flann_example_cpp flann_example.cpp)
    target_link_libraries(flann_example_cpp flann_cpp ${HDF5_LIBRARIES})
    if (HDF5_IS_PARALLEL)
        target_link_libraries(flann_example_cpp ${MPI_LIBRARIES})
    endif()

    add_dependencies(examples flann_example_cpp)
    install (TARGETS flann_example_cpp DESTINATION bin)


    if (USE_MPI)
        add_executable(flann_example_mpi flann_example_mpi.cpp)
        target_link_libraries(flann_example_mpi flann_cpp ${HDF5_LIBRARIES} ${MPI_LIBRARIES})

        add_dependencies(examples flann_example_mpi)
        install (TARGETS flann_example_mpi DESTINATION bin)
    endif()
else()
    message("hdf5 library not found, not compiling flann_example.cpp")
endif()




