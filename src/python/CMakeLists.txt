configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/setup.py.tpl 
    ${CMAKE_CURRENT_SOURCE_DIR}/setup.py
)

INSTALL (
    FILES setup.py
    DESTINATION share/flann/python
)

INSTALL (
    DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/pyflann
    DESTINATION share/flann/python
    PATTERN *.cpp EXCLUDE
    PATTERN *.so EXCLUDE
    PATTERN *.a EXCLUDE
    PATTERN *.dat EXCLUDE
    PATTERN *.txt EXCLUDE
    PATTERN *.tpl EXCLUDE
    PATTERN *~ EXCLUDE
    PATTERN _tests EXCLUDE
)
