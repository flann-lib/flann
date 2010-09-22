#IF(WIN32)
#    SET(MEXEXT_CMD cmd /C mexext)
#ELSE(WIN32)
#    SET(MEXEXT_CMD mexext)
#ENDIF(WIN32)

find_program(MEX_CMD mex)
find_program(MEXEXT_CMD mexext)

if(MEX_CMD AND MEXEXT_CMD)

    get_filename_component(MEX_REAL_CMD ${MEX_CMD} REALPATH)
    get_filename_component(MEX_PATH ${MEX_REAL_CMD} PATH)

    get_filename_component(MEXEXT_REAL_CMD ${MEXEXT_CMD} REALPATH)
    get_filename_component(MEXEXT_PATH ${MEXEXT_REAL_CMD} PATH)

    if (MEX_PATH STREQUAL MEXEXT_PATH)
        message("Found MATLAB at: " ${MEX_PATH})

        SET(MEX_NAME nearest_neighbors)
        EXECUTE_PROCESS(COMMAND ${MEXEXT_REAL_CMD} OUTPUT_VARIABLE MEX_EXTENSION OUTPUT_STRIP_TRAILING_WHITESPACE)
        SET(MEX_FILE ${CMAKE_CURRENT_BINARY_DIR}/${MEX_NAME}.${MEX_EXTENSION})

        IF(WIN32)
            SET(LIB_DEP flann.dll)
        ELSEIF(APPLE)
            SET(LIB_DEP libflann.dylib)
        ELSE()
            SET(LIB_DEP libflann.so)
        ENDIF()

        ADD_CUSTOM_COMMAND(
            OUTPUT ${MEX_FILE}
            COMMAND ${MEX_REAL_CMD}
            ARGS ${CMAKE_CURRENT_SOURCE_DIR}/${MEX_NAME}.cpp -I${PROJECT_SOURCE_DIR}/src/cpp  -L${LIBRARY_OUTPUT_PATH} -lflann_s
            DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${MEX_NAME}.cpp ${LIBRARY_OUTPUT_PATH}/${LIB_DEP}
            COMMENT "Building MEX extension ${MEX_FILE}"
        )

        ADD_CUSTOM_TARGET(mex_${MEX_NAME} ALL DEPENDS ${MEX_FILE})

        FILE(GLOB MATLAB_SOURCES *.m)

        INSTALL (
            FILES ${MEX_FILE} ${MATLAB_SOURCES}
            DESTINATION matlab
        )
    else()
        message("The 'mex' and 'mexext' programs have been found in different locations. It's likely that one of them is not part of the MATLAB instalation. Make sure that the 'bin' directory from the MATLAB instalation is in PATH")
    endif()
else()
    message("Cannot find MATLAB instalation. Make sure that the 'bin' directory from the MATLAB instalation is in PATH")
endif()
