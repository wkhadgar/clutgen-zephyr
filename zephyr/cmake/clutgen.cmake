# Copyright (c) 2026, Paulo Santos (pauloxrms@gmail.com).
# SPDX-License-Identifier: Apache-2.0

# Usage in app CMakeLists.txt:
#   clutgen_add_luts(
#       [NAME <output_filename>]   # Optional. Default: "lookup_tables"
#       [TARGET <cmake_target>]    # Optional. Default: "app"
#       TOMLS
#           path/to/sensors/temperature.toml
#           path/to/sensors/pressure.toml
#           ...
#   )
function(clutgen_add_luts)
  cmake_parse_arguments(CLUTGEN "" "NAME;TARGET" "TOMLS" ${ARGN})

  if(NOT CLUTGEN_NAME)
    set(CLUTGEN_NAME "lookup_tables")
  endif()

  if(NOT CLUTGEN_TARGET)
    set(CLUTGEN_TARGET "app")
  endif()

  if(NOT CLUTGEN_TOMLS)
    message(FATAL_ERROR "clutgen_add_luts: no TOMLS provided")
  endif()

  set(CLUTGEN_SCRIPT_DIR ${CMAKE_CURRENT_FUNCTION_LIST_DIR})
  set(CLUTGEN_OUTPUT_DIR ${CMAKE_BINARY_DIR}/clutgenerated)

  file(MAKE_DIRECTORY ${CLUTGEN_OUTPUT_DIR})

  # Note: only TOML changes trigger reconfiguration.
  # If you update a CSV, touch the corresponding TOML or re-run 'west build -p'.
  foreach(toml IN LISTS CLUTGEN_TOMLS)
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${toml})
  endforeach()

  execute_process(
    COMMAND
        ${PYTHON_EXECUTABLE}
        ${CLUTGEN_SCRIPT_DIR}/clutgen_cmd.py
        --output-dir ${CLUTGEN_OUTPUT_DIR}
        --name ${CLUTGEN_NAME}
        ${CLUTGEN_TOMLS}
    RESULT_VARIABLE clutgen_result
    COMMAND_ECHO STDOUT
  )

  if(NOT clutgen_result EQUAL 0)
    message(FATAL_ERROR "CLUTGen generation failed with ${clutgen_result}")
  endif()

  if(NOT EXISTS ${CLUTGEN_OUTPUT_DIR}/${CLUTGEN_NAME}.c)
    message(FATAL_ERROR "CLUTGen could not generate ${CLUTGEN_NAME}.")
  endif()

  target_include_directories(${CLUTGEN_TARGET} PRIVATE ${CLUTGEN_OUTPUT_DIR})
  target_sources(${CLUTGEN_TARGET}
    PRIVATE ${CLUTGEN_OUTPUT_DIR}/${CLUTGEN_NAME}.c
  )

  add_custom_target(clutgen_plot
    COMMAND
        ${PYTHON_EXECUTABLE}
        ${CLUTGEN_SCRIPT_DIR}/clutgen_cmd.py
        --preview
        ${CLUTGEN_TOMLS}
    VERBATIM
  )

  message(STATUS "CLUTGen output: ${CLUTGEN_OUTPUT_DIR}")
  message(STATUS
    "run 'west build -t clutgen_plot' to explore interpolation methods"
  )
endfunction()
