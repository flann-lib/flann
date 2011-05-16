configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/setup.py.tpl 
    ${CMAKE_CURRENT_SOURCE_DIR}/setup.py
)

if (NOT DEFINED PYTHON_INSTALL_PREFIX)
    set(PYTHON_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX})
endif()

install(CODE "execute_process(
    COMMAND ${PYTHON_EXECUTABLE} setup.py install --prefix ${PROJECT_BINARY_DIR}/python_install --install-layout deb
    WORKING_DIRECTORY \"${CMAKE_CURRENT_SOURCE_DIR}\")")

install (
    DIRECTORY ${PROJECT_BINARY_DIR}/python_install/
    DESTINATION ${CMAKE_INSTALL_PREFIX} 
)
