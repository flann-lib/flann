find_package(LATEX)
 
if (EXISTS ${PDFLATEX_COMPILER} AND EXISTS ${BIBTEX_COMPILER})
    include(${PROJECT_SOURCE_DIR}/cmake/UseLATEX.cmake)

    add_latex_document(manual.tex BIBFILES references.bib IMAGE_DIRS images DEFAULT_PDF)

    add_custom_command(OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/manual.pdf
        COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_BINARY_DIR}/manual.pdf ${CMAKE_CURRENT_SOURCE_DIR}/manual.pdf
        DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/manual.pdf
    )
    add_custom_target(doc DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/manual.pdf)
endif()

install(
    FILES manual.pdf
    DESTINATION share/doc/flann
    OPTIONAL
)
