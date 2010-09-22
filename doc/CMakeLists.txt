set(TARGET manual)
set(REFERENCES references)
find_package(LATEX)

if (EXISTS ${PDFLATEX_COMPILER} AND EXISTS ${BIBTEX_COMPILER})

    add_custom_command(
        OUTPUT    ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}.aux
        DEPENDS   ${CMAKE_CURRENT_SOURCE_DIR}/${TARGET}.tex
        COMMAND   ${PDFLATEX_COMPILER}
        ARGS      -interaction=batchmode ${CMAKE_CURRENT_SOURCE_DIR}/${TARGET}
        COMMENT   "Latex (first pass)"
        VERBATIM
    )
    
    add_custom_command(
        OUTPUT    ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}.bbl
        DEPENDS   ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}.aux
                  ${CMAKE_CURRENT_SOURCE_DIR}/${REFERENCES}.bib
        COMMAND   ${BIBTEX_COMPILER}
        ARGS      -terse ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT   "Bibtex"
    )

    add_custom_command(
        OUTPUT    ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}.pdf
        DEPENDS   ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}.bbl
        COMMAND   ${PDFLATEX_COMPILER}
        ARGS      -interaction=batchmode ${CMAKE_CURRENT_SOURCE_DIR}/${TARGET}
        COMMENT   "Latex (second pass)"
    )

    add_custom_command(
        OUTPUT    ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}.log
        DEPENDS   ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}.bbl
                  ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}.pdf
        COMMAND   ${PDFLATEX_COMPILER}
        ARGS      -interaction=batchmode ${CMAKE_CURRENT_SOURCE_DIR}/${TARGET} 
        COMMENT   "Latex (third pass)"
    )
    # Eventually trigger the whole process

    add_custom_command(
        OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/${TARGET}.pdf
        DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}.pdf
                ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}.log
        COMMAND ${CMAKE_COMMAND} -E copy
        ARGS ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}.pdf ${CMAKE_CURRENT_SOURCE_DIR}/${TARGET}.pdf
    )

    add_custom_target(doc
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${TARGET}.pdf
    )

    install (
        FILES ${CMAKE_CURRENT_SOURCE_DIR}/${TARGET}.pdf
        DESTINATION doc
    )
endif()
