find_package(LATEX)
 
if (EXISTS ${PDFLATEX_COMPILER} AND EXISTS ${BIBTEX_COMPILER})
    include(${PROJECT_SOURCE_DIR}/cmake/UseLATEX.cmake)

    add_latex_document(manual.tex BIBFILES references.bib IMAGE_DIRS images DEFAULT_PDF)

    add_custom_target(doc)
    add_dependencies(doc pdf)
    
    add_custom_command( TARGET doc
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
        ARGS ${CMAKE_CURRENT_BINARY_DIR}/manual.pdf ${CMAKE_CURRENT_SOURCE_DIR}/manual.pdf
    )
endif()

install(
    FILES manual.pdf
    DESTINATION share/doc/flann
)
