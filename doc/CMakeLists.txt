include(${PROJECT_SOURCE_DIR}/cmake/UseLATEX.cmake)

add_latex_document(manual.tex BIBFILES references.bib DEFAULT_PDF)

add_custom_command(
    OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/manual.pdf
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/manual.pdf
    COMMAND ${CMAKE_COMMAND} -E copy
    ARGS ${CMAKE_CURRENT_BINARY_DIR}/manual.pdf ${CMAKE_CURRENT_SOURCE_DIR}/manual.pdf
)

add_custom_target(doc DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/manual.pdf)

install(
    FILES manual.pdf
    DESTINATION share/doc/flann
)

