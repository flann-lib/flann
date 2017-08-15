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


if (PROJECT_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    set(ARG_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../..")
else()
    set(ARG_INCLUDE_DIR "${PROJECT_SOURCE_DIR}")
endif()
get_filename_component(ARG_INCLUDE_DIR ${ARG_INCLUDE_DIR} REALPATH)


set(FLANN_LIB_PATH ${ARG_INCLUDE_DIR}/lib)
get_filename_component(FLANN_LIB_PATH ${FLANN_LIB_PATH} REALPATH)


get_filename_component(MEX_CMD ${MEX_CMD} REALPATH)
if(EXISTS ${MEX_CMD})
    get_filename_component(MEX_PATH ${MEX_CMD} PATH)
else()
    unset(MEX_CMD)
endif()

get_filename_component(MEXEXT_CMD ${MEXEXT_CMD} REALPATH)
if(DEFINED MEX_CMD)
    if(NOT EXISTS ${MEXEXT_CMD})
        set(MEXEXT_CMD ${MEX_PATH}/mexext)
    endif()
    if(EXISTS ${MEXEXT_CMD})
        get_filename_component(MEXEXT_PATH ${MEXEXT_CMD} PATH)
    else()
        unset(MEXEXT_CMD)
    endif()
else()
    unset(MEXEXT_CMD)
endif()

if(DEFINED MEX_CMD AND DEFINED MEXEXT_CMD)
    if (MEX_PATH STREQUAL MEXEXT_PATH)
        EXECUTE_PROCESS(COMMAND ${MEXEXT_CMD} OUTPUT_VARIABLE MEX_EXTENSION OUTPUT_STRIP_TRAILING_WHITESPACE)
        SET(MEX_FILE ${CMAKE_CURRENT_BINARY_DIR}/${MEX_NAME}.${MEX_EXTENSION})

		
        if (WIN32)
            if (MSVC_IDE)
                set(MEX_BUILD_FLAGS "COMPFLAGS=\"$COMPFLAGS ${OpenMP_CXX_FLAGS}\" LINKFLAGS=\"$LINKFLAGS ${OpenMP_CXX_FLAGS} ${OpenMP_EXE_LINKER_FLAGS}\"")
            else()
                set(MEX_BUILD_FLAGS "COMPFLAGS=\"$$COMPFLAGS ${OpenMP_CXX_FLAGS}\" LINKFLAGS=\"$$LINKFLAGS ${OpenMP_CXX_FLAGS} ${OpenMP_EXE_LINKER_FLAGS}\"")
            endif()
        else()
            set(MEX_BUILD_FLAGS "CXXFLAGS='$$CXXFLAGS ${OpenMP_CXX_FLAGS} -Wall -std=c++11'  CXXOPTIMFLAGS='-O3 -DNDEBUG' LDFLAGS='$$LDFLAGS ${OpenMP_CXX_FLAGS} ${OpenMP_EXE_LINKER_FLAGS} --verbose'")
        endif()
        separate_arguments(MEX_BUILD_FLAGS)   
        ADD_CUSTOM_COMMAND(
            OUTPUT ${MEX_FILE}
            COMMAND ${MEX_CMD}
            ARGS ${CMAKE_CURRENT_SOURCE_DIR}/${MEX_NAME}.cpp -I${ARG_INCLUDE_DIR}/src/cpp -L${FLANN_LIB_PATH} -lflann_s ${MEX_BUILD_FLAGS} -lgomp
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

