configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/setup.py.tpl 
    ${CMAKE_CURRENT_SOURCE_DIR}/setup.py
)

if (PYTHON_INSTALL_PREFIX)
    install(CODE "execute_process(
        COMMAND ${PYTHON_EXECUTABLE} setup.py install --prefix ${PYTHON_INSTALL_PREFIX}
        WORKING_DIRECTORY \"${CMAKE_CURRENT_SOURCE_DIR}\")")
else()
    install(CODE "execute_process(COMMAND ${PYTHON_EXECUTABLE} setup.py install
       WORKING_DIRECTORY \"${CMAKE_CURRENT_SOURCE_DIR}\")")
endif()

