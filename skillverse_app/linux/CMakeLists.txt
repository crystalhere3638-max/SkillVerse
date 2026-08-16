cmake_minimum_required(VERSION 3.10)
project(runner LANGUAGES CXX)

set(BINARY_NAME "skillverse_app")
set(APPLICATION_ID "com.skillverse.app")

cmake_policy(SET CMP0063 NEW)

set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

get_filename_component(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter"
  REALPATH)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE "Debug" CACHE
    STRING "Flutter build mode" FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
    "Debug" "Profile" "Release")
endif()

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_14)
  target_compile_options(${TARGET} PRIVATE -Wall -Werror)
  target_compile_options(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:-O3>")
  target_compile_definitions(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:NDEBUG>")
endfunction()

set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")

add_subdirectory(${FLUTTER_MANAGED_DIR})

add_subdirectory("runner")

apply_standard_settings(${BINARY_NAME})
apply_standard_settings(flutter_wrapper_app)
apply_standard_settings(flutter_wrapper_plugin)
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)

set_target_properties(${BINARY_NAME} PROPERTIES
  BUILD_WITH_INSTALL_RPATH TRUE
  INSTALL_RPATH_USE_LINK_PATH TRUE
)

add_dependencies(${BINARY_NAME} flutter_assemble)

set(BUILD_BUNDLE_DIR "${PROJECT_BINARY_DIR}/bundle")

set(INSTALL_BUNDLE_DATA_DIR "${BUILD_BUNDLE_DIR}/data")
set(INSTALL_BUNDLE_LIB_DIR "${BUILD_BUNDLE_DIR}/lib")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${BUILD_BUNDLE_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

foreach(bundled_library ${PLUGIN_BUNDLED_LIBRARIES})
  install(FILES "${bundled_library}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endforeach(bundled_library)

set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

install(CODE "
  foreach(bundled_library \${PLUGIN_BUNDLED_LIBRARIES})
    file(INSTALL DESTINATION \"${INSTALL_BUNDLE_LIB_DIR}\"
      TYPE SHARED_LIBRARY FOLLOW_SYMLINK_CHAIN
      FILES \"\${bundled_library}\")
  endforeach(bundled_library)
  " COMPONENT Runtime)
