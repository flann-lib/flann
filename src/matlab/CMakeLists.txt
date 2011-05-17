#IF(WIN32)
#    SET(MEXEXT_CMD cmd /C mexext)
#ELSE(WIN32)
#    SET(MEXEXT_CMD mexext)
#ENDIF(WIN32)

SET(MEX_NAME nearest_neighbors)

if(WIN32)
    find_program(MEX_CMD mex.bat)
    find_program(MEXEXT_CMD mexext.bat)
else()
    find_program(MEX_CMD mex)
    find_program(MEXEXT_CMD mexext)
endif()

find_program(OCT_CMD mkoctfile)

if(MEX_CMD AND MEXEXT_CMD)

    get_filename_component(MEX_REAL_CMD ${MEX_CMD} ABSOLUTE)
    get_filename_component(MEX_PATH ${MEX_REAL_CMD} PATH)

    get_filename_component(MEXEXT_REAL_CMD ${MEXEXT_CMD} ABSOLUTE)
    get_filename_component(MEXEXT_PATH ${MEXEXT_REAL_CMD} PATH)

    if (MEX_PATH STREQUAL MEXEXT_PATH)
        message(STATUS "Found MATLAB at: " ${MEX_PATH})

        EXECUTE_PROCESS(COMMAND ${MEXEXT_REAL_CMD} OUTPUT_VARIABLE MEX_EXTENSION OUTPUT_STRIP_TRAILING_WHITESPACE)
        SET(MEX_FILE ${CMAKE_CURRENT_BINARY_DIR}/${MEX_NAME}.${MEX_EXTENSION})

        ADD_CUSTOM_COMMAND(
            OUTPUT ${MEX_FILE}
            COMMAND ${MEX_REAL_CMD}
            ARGS ${CMAKE_CURRENT_SOURCE_DIR}/${MEX_NAME}.cpp -I${PROJECT_SOURCE_DIR}/src/cpp -L${LIBRARY_OUTPUT_PATH} -lflann_s
            DEPENDS flann_s ${CMAKE_CURRENT_SOURCE_DIR}/${MEX_NAME}.cpp
            COMMENT "Building MEX extension ${MEX_FILE}"
        )

        ADD_CUSTOM_TARGET(mex_${MEX_NAME} ALL DEPENDS ${MEX_FILE})

        FILE(GLOB MATLAB_SOURCES *.m)

        INSTALL (
            FILES ${MEX_FILE} ${MATLAB_SOURCES}
            DESTINATION share/flann/matlab
        )
    else()
        message(SEND_ERROR "The 'mex' and 'mexext' programs have been found in different locations. It's likely that one of them is not part of the MATLAB instalation. Make sure that the 'bin' directory from the MATLAB instalation is in PATH")
    endif()
elseif(OCT_CMD)
  SET(MEX_FILE ${CMAKE_CURRENT_BINARY_DIR}/${MEX_NAME}.mex)
  ADD_CUSTOM_COMMAND(
    OUTPUT ${MEX_FILE}
    COMMAND ${OCT_CMD}
    ARGS ${CMAKE_CURRENT_SOURCE_DIR}/${MEX_NAME}.cpp -I${PROJECT_SOURCE_DIR}/src/cpp -L${LIBRARY_OUTPUT_PATH} -DFLANN_STATIC -lflann_s --mex
    DEPENDS flann_s ${CMAKE_CURRENT_SOURCE_DIR}/${MEX_NAME}.cpp
    COMMENT "Building MEX extension ${MEX_FILE}"
    )

  ADD_CUSTOM_TARGET(mex_${MEX_NAME} ALL DEPENDS ${MEX_FILE})

  FILE(GLOB MATLAB_SOURCES *.m)

  INSTALL (
    FILES ${MEX_FILE} ${MATLAB_SOURCES}
    DESTINATION share/flann/octave
    )
else()
    message(SEND_ERROR "Cannot find MATLAB or Octave instalation. Make sure that the 'bin' directory from the MATLAB instalation or that mkoctfile is in PATH")
endif()

