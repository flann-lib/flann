configure_file( setup.py.tpl setup.py )

install( DIRECTORY pyflann DESTINATION share/flann/python )
install( FILES ${CMAKE_CURRENT_BINARY_DIR}/setup.py DESTINATION share/flann/python )


function (symlink_file source dest)
  if(EXISTS ${dest} AND NOT IS_SYMLINK ${dest})
    # If our target it not a symlink, then remove it so we can replace it
    file(REMOVE ${dest})
  endif()

  message(STATUS "Symlink \"${source}\" -> \"${dest}\"")
  # Need to ensure the directory exists before we create a symlink there
  get_filename_component(dest_dir ${dest} DIRECTORY)
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E make_directory ${dest_dir}
    )
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E create_symlink ${source} ${dest}
    )
endfunction ()


option(FLANN_SYMLINK_PYTHON ON "Ensures that the build directory can be used as a development environment")
if (FLANN_SYMLINK_PYTHON)
  file(GLOB_RECURSE PY_SOURCES RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" *.py)
  foreach(name ${PY_SOURCES})
    symlink_file("${CMAKE_CURRENT_SOURCE_DIR}/${name}" "${CMAKE_CURRENT_BINARY_DIR}/${name}")
  endforeach()
endif()


# python installation
if (PYTHON_EXECUTABLE)
    install(CODE "execute_process(
        COMMAND ${PYTHON_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/setup.py install
        WORKING_DIRECTORY \"${CMAKE_CURRENT_SOURCE_DIR}\")")
endif()
