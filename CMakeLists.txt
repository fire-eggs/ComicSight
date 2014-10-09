cmake_minimum_required(VERSION 2.8)
project(comicsight)

set(CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}"
                      "${PROJECT_SOURCE_DIR}/cmake"
                      "${PROJECT_SOURCE_DIR}/cmake/modules"
                      "${PROJECT_SOURCE_DIR}/res/win")

include(TargetArch)
target_architecture(SYSTEM_ARCHITECTURE SYSTEM_ENDIAN)


include(ConfigureCompilerFlags)

include(ConfigureLibraryPath)

include(ConfigureLibraries)


include(BuildImages)

include(BuildVersionInformation)

include(BuildApplication)


include(BuildPackaging)

include(ConfigureInstallation)

include(ConfigurePackaging)
