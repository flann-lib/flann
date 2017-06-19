cmake_minimum_required(VERSION 3.7)

SET(MEX_NAME nearest_neighbors)

if(WIN32)
    find_program(MEX_CMD mex.bat)
    find_program(MEXEXT_CMD mexext.bat)
else()
    find_program(MEX_CMD mex)
    find_program(MEXEXT_CMD mexext)
endif()

find_program(OCT_CMD mkoctfile)

if (TARGET flann_s)
    get_property(FLANN_LIB_LOCATION TARGET flann_s PROPERTY LOCATION)
endif()
get_filename_component(FLANN_LIB_PATH ${FLANN_LIB_LOCATION} REALPATH) 
if (NOT IS_DIRECTORY FLANN_LIB_PATH)
    set(FLANN_LIB_LOCATION ${FLANN_LIB_PATH})
    get_filename_component(FLANN_LIB_PATH ${FLANN_LIB_LOCATION} PATH)
endif()

if (PROJECT_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    set(ARG_INCLUDE_DIR0 "${CMAKE_CURRENT_SOURCE_DIR}/../..")
else()
    set(ARG_INCLUDE_DIR0 "${PROJECT_SOURCE_DIR}")
endif()
get_filename_component(ARG_INCLUDE_DIR ${ARG_INCLUDE_DIR0} REALPATH)

if(MEX_CMD AND MEXEXT_CMD)

    get_filename_component(MEX_REAL_CMD ${MEX_CMD} REALPATH)
    get_filename_component(MEX_PATH ${MEX_REAL_CMD} PATH)

    get_filename_component(MEXEXT_REAL_CMD ${MEXEXT_CMD} REALPATH)
    get_filename_component(MEXEXT_PATH ${MEXEXT_REAL_CMD} PATH)

    if (MEX_PATH STREQUAL MEXEXT_PATH)
        message(STATUS "Found MATLAB at: ${MEX_PATH}")

        EXECUTE_PROCESS(COMMAND ${MEXEXT_REAL_CMD} OUTPUT_VARIABLE MEX_EXTENSION OUTPUT_STRIP_TRAILING_WHITESPACE)
        SET(MEX_FILE ${CMAKE_CURRENT_BINARY_DIR}/${MEX_NAME}.${MEX_EXTENSION})

		
        if (WIN32)
			if (MSVC_IDE)
				set(MEX_BUILD_FLAGS "COMPFLAGS=\"$COMPFLAGS ${OpenMP_CXX_FLAGS}\" LINKFLAGS=\"$LINKFLAGS ${OpenMP_CXX_FLAGS} ${OpenMP_EXE_LINKER_FLAGS}\"")
			else()
				set(MEX_BUILD_FLAGS "COMPFLAGS=\"$$COMPFLAGS ${OpenMP_CXX_FLAGS}\" LINKFLAGS=\"$$LINKFLAGS ${OpenMP_CXX_FLAGS} ${OpenMP_EXE_LINKER_FLAGS}\"")
			endif()
        else()
            set(MEX_BUILD_FLAGS "CFLAGS='$$CFLAGS ${OpenMP_CXX_FLAGS}' LDFLAGS='$$LDFLAGS ${OpenMP_CXX_FLAGS} ${OpenMP_EXE_LINKER_FLAGS}'")
        endif()
        separate_arguments(MEX_BUILD_FLAGS)   
        ADD_CUSTOM_COMMAND(
            OUTPUT ${MEX_FILE}
            COMMAND ${MEX_REAL_CMD}
            ARGS ${CMAKE_CURRENT_SOURCE_DIR}/${MEX_NAME}.cpp -I${ARG_INCLUDE_DIR}/src/cpp -L${FLANN_LIB_PATH} -lflann_s ${MEX_BUILD_FLAGS} -lgomp
            DEPENDS ${FLANN_LIB_PATH}/libflann_s.a ${CMAKE_CURRENT_SOURCE_DIR}/${MEX_NAME}.cpp
            COMMENT "Building MEX extension ${MEX_FILE}"
        )

        ADD_CUSTOM_TARGET(mex_${MEX_NAME} ALL DEPENDS ${MEX_FILE})

        FILE(GLOB MATLAB_SOURCES *.m)

        INSTALL (
            FILES ${MEX_FILE} ${MATLAB_SOURCES}
            DESTINATION share/flann/matlab
        )
    else()
        message(WARNING "The 'mex' and 'mexext' programs have been found in different locations. It's likely that one of them is not part of the MATLAB instalation. Make sure that the 'bin' directory from the MATLAB instalation is in PATH")
        set(BUILD_MATLAB_BINDINGS OFF) 
    endif()
elseif(OCT_CMD)
    SET(MEX_FILE ${CMAKE_CURRENT_BINARY_DIR}/${MEX_NAME}.mex)
    ADD_CUSTOM_COMMAND(
        OUTPUT ${MEX_FILE}
        COMMAND ${OCT_CMD}
        ARGS ${CMAKE_CURRENT_SOURCE_DIR}/${MEX_NAME}.cpp -I${ARG_INCLUDE_DIR}/src/cpp -L${FLANN_LIB_PATH} -DFLANN_STATIC -lflann_s -lgomp --mex
        DEPENDS ${FLANN_LIB_PATH}/libflann_s.a ${CMAKE_CURRENT_SOURCE_DIR}/${MEX_NAME}.cpp
        COMMENT "Building MEX extension ${MEX_FILE}"
    )

    ADD_CUSTOM_TARGET(mex_${MEX_NAME} ALL DEPENDS ${MEX_FILE})

    FILE(GLOB MATLAB_SOURCES *.m)

    INSTALL (
        FILES ${MEX_FILE} ${MATLAB_SOURCES}
        DESTINATION share/flann/octave
    )
else()
    message(WARNING "Cannot find MATLAB or Octave instalation. Make sure that the 'bin' directory from the MATLAB instalation or that mkoctfile is in PATH")
    set(BUILD_MATLAB_BINDINGS OFF) 
endif()

