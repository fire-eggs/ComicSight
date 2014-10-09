get_filename_component(_BUILD_IMAGES_CMAKE_FILE ${CMAKE_CURRENT_LIST_FILE} ABSOLUTE)

# create PNG from SVG
if(_BUILD_IMAGES_SVG_FILE AND _BUILD_IMAGES_PNG_FILE AND _BUILD_IMAGES_SIZE AND
   ImageMagick_identify_EXECUTABLE AND ImageMagick_convert_EXECUTABLE)

    if(Inkscape_EXECUTABLE)
        execute_process(COMMAND "${Inkscape_EXECUTABLE}"
              -z -e "${_BUILD_IMAGES_PNG_FILE}" -w "${_BUILD_IMAGES_SIZE}" "${_BUILD_IMAGES_SVG_FILE}"
            OUTPUT_VARIABLE WIDTH
            ERROR_VARIABLE ERROR
            OUTPUT_STRIP_TRAILING_WHITESPACE)

        if(NOT EXISTS "${_BUILD_IMAGES_PNG_FILE}")
            message(FATAL_ERROR "${ERROR}")
        endif(NOT EXISTS "${_BUILD_IMAGES_PNG_FILE}")
    else(Inkscape_EXECUTABLE)
        execute_process(COMMAND "${ImageMagick_identify_EXECUTABLE}"
              -format "%w" "${_BUILD_IMAGES_SVG_FILE}"
            OUTPUT_VARIABLE WIDTH
            ERROR_VARIABLE ERROR
            OUTPUT_STRIP_TRAILING_WHITESPACE)

        if(ERROR)
            message(FATAL_ERROR "${ERROR}")
        endif(ERROR)

        math(EXPR DENSITY "72 * ${_BUILD_IMAGES_SIZE} / ${WIDTH}")

        execute_process(COMMAND "${ImageMagick_convert_EXECUTABLE}"
              -background none
              -density "${DENSITY}"
              -resize "${_BUILD_IMAGES_SIZE}"
              "${_BUILD_IMAGES_SVG_FILE}" "${_BUILD_IMAGES_PNG_FILE}"
            ERROR_VARIABLE ERROR
            OUTPUT_STRIP_TRAILING_WHITESPACE)

        if(ERROR)
            message(FATAL_ERROR "${ERROR}")
        endif(ERROR)
    endif(Inkscape_EXECUTABLE)

    if(pngquant_EXECUTABLE)
        execute_process(COMMAND "${pngquant_EXECUTABLE}"
            --ext .png --speed 1 --force 256 "${_BUILD_IMAGES_PNG_FILE}")
    endif(pngquant_EXECUTABLE)

    if(PNGOUT_EXECUTABLE)
        execute_process(
            COMMAND "${PNGOUT_EXECUTABLE}" "${_BUILD_IMAGES_PNG_FILE}"
            OUTPUT_QUIET)
    else(PNGOUT_EXECUTABLE)
        if(OptiPNG_EXECUTABLE)
            execute_process(
                COMMAND "${OptiPNG_EXECUTABLE}" -o7 "${_BUILD_IMAGES_PNG_FILE}"
                OUTPUT_QUIET)
        endif(OptiPNG_EXECUTABLE)
    endif(PNGOUT_EXECUTABLE)

    return()
endif(_BUILD_IMAGES_SVG_FILE AND _BUILD_IMAGES_PNG_FILE AND _BUILD_IMAGES_SIZE AND
      ImageMagick_identify_EXECUTABLE AND ImageMagick_convert_EXECUTABLE)


# create XPM from PNG
if(_BUILD_IMAGES_PNG_FILE AND _BUILD_IMAGES_XPM_FILE AND _BUILD_IMAGES_IMAGE_NAME AND
   ImageMagick_convert_EXECUTABLE)

    execute_process(COMMAND "${ImageMagick_convert_EXECUTABLE}"
          "${_BUILD_IMAGES_PNG_FILE}" "xpm:-"
        OUTPUT_VARIABLE XPM_IMAGE
        ERROR_VARIABLE ERROR
        OUTPUT_STRIP_TRAILING_WHITESPACE)

    if(ERROR)
        message(FATAL_ERROR "${ERROR}")
    endif(ERROR)

    string(REGEX REPLACE "static char [^\\[]*\\[\\] = {"
                         "static const char *${_BUILD_IMAGES_IMAGE_NAME}[] = {"
                         XPM_IMAGE "${XPM_IMAGE}")
    file(WRITE "${_BUILD_IMAGES_XPM_FILE}" "${XPM_IMAGE}")

    return()
endif(_BUILD_IMAGES_PNG_FILE AND _BUILD_IMAGES_XPM_FILE AND _BUILD_IMAGES_IMAGE_NAME AND
      ImageMagick_convert_EXECUTABLE)


# create PNG from SVG
macro(add_svg2png_command SvgFile PngFile Size)
    add_custom_command(
        OUTPUT "${PngFile}"
        COMMAND "${CMAKE_COMMAND}"
          "-D_BUILD_IMAGES_SVG_FILE=${SvgFile}"
          "-D_BUILD_IMAGES_PNG_FILE=${PngFile}"
          "-D_BUILD_IMAGES_SIZE=${Size}"
          "-DImageMagick_identify_EXECUTABLE=${ImageMagick_identify_EXECUTABLE}"
          "-DImageMagick_convert_EXECUTABLE=${ImageMagick_convert_EXECUTABLE}"
          "-DInkscape_EXECUTABLE=${Inkscape_EXECUTABLE}"
          "-Dpngquant_EXECUTABLE=${pngquant_EXECUTABLE}"
          "-DPNGOUT_EXECUTABLE=${PNGOUT_EXECUTABLE}"
          "-DOptiPNG_EXECUTABLE=${OptiPNG_EXECUTABLE}"
          -P "${_BUILD_IMAGES_CMAKE_FILE}"
        DEPENDS "${SvgFile}"
        VERBATIM)
endmacro(add_svg2png_command SvgFile PngFile Size)


# create XPM from PNG
macro(add_png2xpm_command PngFile XpmFile ImageName)
    add_custom_command(
        OUTPUT "${XpmFile}"
        COMMAND "${CMAKE_COMMAND}"
          "-D_BUILD_IMAGES_PNG_FILE=${PngFile}"
          "-D_BUILD_IMAGES_XPM_FILE=${XpmFile}"
          "-D_BUILD_IMAGES_IMAGE_NAME=${ImageName}"
          "-DImageMagick_convert_EXECUTABLE=${ImageMagick_convert_EXECUTABLE}"
          -P "${_BUILD_IMAGES_CMAKE_FILE}"
        DEPENDS "${PngFile}"
        VERBATIM)
endmacro(add_png2xpm_command PngFile XpmFile ImageName)


# find graphics tools
find_package(ImageMagick REQUIRED COMPONENTS convert identify)
if(ImageMagick_VERSION_STRING VERSION_EQUAL 6.8 OR
   ImageMagick_VERSION_STRING VERSION_GREATER 6.8)
    # safe reduction for PNG-encoded ICO (256 pixels)
    # since the created PNG images also have only 256 colors
    set(ICO_PNG_COLOR_REDUCTION -colors 256)
else(ImageMagick_VERSION_STRING VERSION_EQUAL 6.8 OR
     ImageMagick_VERSION_STRING VERSION_GREATER 6.8)
    set(ICO_PNG_COLOR_REDUCTION)
endif(ImageMagick_VERSION_STRING VERSION_EQUAL 6.8 OR
      ImageMagick_VERSION_STRING VERSION_GREATER 6.8)

find_package(Inkscape)
if(NOT Inkscape_FOUND)
    message(WARNING "Warning: Inkscape not found. "
                    "Using ImageMagick convert instead to rasterize SVG to PNG. "
                    "The conversion result may not yield the same quality "
                    "as compared to using Inkscape. "
                    "On some architectures this may even lead to defect "
                    "conversion outcomes resulting in wrong colored images.")
endif(NOT Inkscape_FOUND)

find_package(pngquant)
if(NOT pngquant_FOUND)
    message(WARNING "Warning: pngquant not found. PNG images will not be quantized.")
endif(NOT pngquant_FOUND)

find_package(PNGOUT)
if(NOT PNGOUT_FOUND)
    find_package(OptiPNG)
    if(OptiPNG_FOUND)
        message(WARNING "Warning: PNGOUT not found. Using OptiPNG instead.")
    else(OptiPNG_FOUND)
        message(WARNING "Warning: PNGOUT not found and OptiPNG not found. "
                        "PNG images will not be optimized.")
    endif(OptiPNG_FOUND)
endif(NOT PNGOUT_FOUND)

if(APPLE)
    find_package(iconutil)
    if(NOT iconutil_FOUND)
        message(WARNING "Warning: iconutil not found. Application icon will not be created.")
    endif(NOT iconutil_FOUND)
endif(APPLE)


# add images target
set(REQUIRED_IMAGE_FILES)

if(WIN32)
    list(APPEND REQUIRED_IMAGE_FILES comicsight.ico wininstaller.bmp wininstallerheader.bmp)
endif(WIN32)

if(APPLE AND iconutil_FOUND)
    list(APPEND REQUIRED_IMAGE_FILES osxinstaller.png)
    if(iconutil_FOUND)
        list(APPEND REQUIRED_IMAGE_FILES comicsight.icns)
    endif(iconutil_FOUND)
endif(APPLE AND iconutil_FOUND)

if(UNIX AND NOT APPLE)
    list(APPEND REQUIRED_IMAGE_FILES
        comicsight.xpm
        comicsight.svg
        comicsight16.png
        comicsight22.png
        comicsight24.png
        comicsight32.png
        comicsight48.png
        comicsight64.png
        comicsight96.png)
endif(UNIX AND NOT APPLE)

add_custom_target(images ALL SOURCES ${REQUIRED_IMAGE_FILES})


# specify image files
if(Inkscape_EXECUTABLE)
    add_custom_command(
        OUTPUT "${PROJECT_BINARY_DIR}/comicsight.svg"
        COMMAND "${Inkscape_EXECUTABLE}" --vacuum-defs -z -l
          "${PROJECT_BINARY_DIR}/comicsight.svg"
          "${PROJECT_SOURCE_DIR}/res/img/comicsight.svg"
        DEPENDS "${PROJECT_SOURCE_DIR}/res/img/comicsight.svg"
        VERBATIM)
else(Inkscape_EXECUTABLE)
    add_custom_command(
        OUTPUT "${PROJECT_BINARY_DIR}/comicsight.svg"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
          "${PROJECT_SOURCE_DIR}/res/img/comicsight.svg"
          "${PROJECT_BINARY_DIR}/comicsight.svg"
        DEPENDS "${PROJECT_SOURCE_DIR}/res/img/comicsight.svg"
        VERBATIM)
endif(Inkscape_EXECUTABLE)

add_svg2png_command("${PROJECT_SOURCE_DIR}/res/img/comicsight.svg"
                    "${PROJECT_BINARY_DIR}/comicsight16.png"
                    16)
add_svg2png_command("${PROJECT_SOURCE_DIR}/res/img/comicsight.svg"
                    "${PROJECT_BINARY_DIR}/comicsight20.png"
                    20)
add_svg2png_command("${PROJECT_SOURCE_DIR}/res/img/comicsight.svg"
                    "${PROJECT_BINARY_DIR}/comicsight22.png"
                    22)
add_svg2png_command("${PROJECT_SOURCE_DIR}/res/img/comicsight.svg"
                    "${PROJECT_BINARY_DIR}/comicsight24.png"
                    24)
add_svg2png_command("${PROJECT_SOURCE_DIR}/res/img/comicsight.svg"
                    "${PROJECT_BINARY_DIR}/comicsight32.png"
                    32)
add_svg2png_command("${PROJECT_SOURCE_DIR}/res/img/comicsight.svg"
                    "${PROJECT_BINARY_DIR}/comicsight40.png"
                    40)
add_svg2png_command("${PROJECT_SOURCE_DIR}/res/img/comicsight.svg"
                    "${PROJECT_BINARY_DIR}/comicsight48.png"
                    48)
add_svg2png_command("${PROJECT_SOURCE_DIR}/res/img/comicsight.svg"
                    "${PROJECT_BINARY_DIR}/comicsight64.png"
                    64)
add_svg2png_command("${PROJECT_SOURCE_DIR}/res/img/comicsight.svg"
                    "${PROJECT_BINARY_DIR}/comicsight96.png"
                    96)
add_svg2png_command("${PROJECT_SOURCE_DIR}/res/img/comicsight.svg"
                    "${PROJECT_BINARY_DIR}/comicsight128.png"
                    128)
add_svg2png_command("${PROJECT_SOURCE_DIR}/res/img/comicsight.svg"
                    "${PROJECT_BINARY_DIR}/comicsight256.png"
                    256)
add_svg2png_command("${PROJECT_SOURCE_DIR}/res/img/comicsight.svg"
                    "${PROJECT_BINARY_DIR}/comicsight512.png"
                    256)
add_svg2png_command("${PROJECT_SOURCE_DIR}/res/img/comicsight.svg"
                    "${PROJECT_BINARY_DIR}/comicsight1024.png"
                    1024)
add_svg2png_command("${PROJECT_SOURCE_DIR}/res/img/eyes.svg"
                    "${PROJECT_BINARY_DIR}/eyes.png"
                    44)
add_svg2png_command("${PROJECT_SOURCE_DIR}/res/img/eyes-background.svg"
                    "${PROJECT_BINARY_DIR}/eyes-background.png"
                    384)
add_svg2png_command("${PROJECT_SOURCE_DIR}/res/img/eyes-foreground.svg"
                    "${PROJECT_BINARY_DIR}/eyes-foreground.png"
                    100)
add_svg2png_command("${PROJECT_SOURCE_DIR}/res/img/osxinstaller.svg"
                    "${PROJECT_BINARY_DIR}/osxinstaller.png"
                    528)

add_svg2png_command("${PROJECT_SOURCE_DIR}/res/img/wininstaller.svg"
                    "${PROJECT_BINARY_DIR}/wininstaller.png"
                    164)
add_svg2png_command("${PROJECT_SOURCE_DIR}/res/img/wininstallerheader.svg"
                    "${PROJECT_BINARY_DIR}/wininstallerheader.png"
                    150)

add_png2xpm_command("${PROJECT_BINARY_DIR}/comicsight96.png"
                    "${PROJECT_BINARY_DIR}/comicsight.xpm"
                    comicsight_icon)

add_custom_command(
    OUTPUT "${PROJECT_BINARY_DIR}/wininstaller.bmp"
    COMMAND "${ImageMagick_convert_EXECUTABLE}"
      "${PROJECT_BINARY_DIR}/wininstaller.png"
      -crop 164x314+0+0 -resize 164x314
      "BMP3:${PROJECT_BINARY_DIR}/wininstaller.bmp"
    DEPENDS
      "${PROJECT_BINARY_DIR}/wininstaller.png"
    VERBATIM)

add_custom_command(
    OUTPUT "${PROJECT_BINARY_DIR}/wininstallerheader.bmp"
    COMMAND "${ImageMagick_convert_EXECUTABLE}"
      "${PROJECT_BINARY_DIR}/wininstallerheader.png"
      -crop 150x57+0+0 -resize 150x57
      "BMP3:${PROJECT_BINARY_DIR}/wininstallerheader.bmp"
    DEPENDS
      "${PROJECT_BINARY_DIR}/wininstallerheader.png"
    VERBATIM)

add_custom_command(
    OUTPUT "${PROJECT_BINARY_DIR}/comicsight.ico"
    COMMAND "${ImageMagick_convert_EXECUTABLE}"
      "${PROJECT_BINARY_DIR}/comicsight16.png" "${PROJECT_BINARY_DIR}/comicsight20.png"
      "${PROJECT_BINARY_DIR}/comicsight24.png" "${PROJECT_BINARY_DIR}/comicsight32.png"
      "${PROJECT_BINARY_DIR}/comicsight40.png" "${PROJECT_BINARY_DIR}/comicsight48.png"
      "${PROJECT_BINARY_DIR}/comicsight64.png" -background black -alpha remove -colors 16
      "${PROJECT_BINARY_DIR}/comicsight16.png" "${PROJECT_BINARY_DIR}/comicsight20.png"
      "${PROJECT_BINARY_DIR}/comicsight24.png" "${PROJECT_BINARY_DIR}/comicsight32.png"
      "${PROJECT_BINARY_DIR}/comicsight40.png" "${PROJECT_BINARY_DIR}/comicsight48.png"
      "${PROJECT_BINARY_DIR}/comicsight64.png" -background black -alpha remove -colors 256
      "${PROJECT_BINARY_DIR}/comicsight256.png" ${ICO_PNG_COLOR_REDUCTION}
      "${PROJECT_BINARY_DIR}/comicsight16.png" "${PROJECT_BINARY_DIR}/comicsight20.png"
      "${PROJECT_BINARY_DIR}/comicsight24.png" "${PROJECT_BINARY_DIR}/comicsight32.png"
      "${PROJECT_BINARY_DIR}/comicsight40.png" "${PROJECT_BINARY_DIR}/comicsight48.png"
      "${PROJECT_BINARY_DIR}/comicsight64.png"
      "${PROJECT_BINARY_DIR}/comicsight.ico"
    DEPENDS
      "${PROJECT_BINARY_DIR}/comicsight16.png" "${PROJECT_BINARY_DIR}/comicsight20.png"
      "${PROJECT_BINARY_DIR}/comicsight24.png" "${PROJECT_BINARY_DIR}/comicsight32.png"
      "${PROJECT_BINARY_DIR}/comicsight40.png" "${PROJECT_BINARY_DIR}/comicsight48.png"
      "${PROJECT_BINARY_DIR}/comicsight64.png" "${PROJECT_BINARY_DIR}/comicsight256.png"
    VERBATIM)

if(iconutil_FOUND)
    add_custom_command(
        OUTPUT "${PROJECT_BINARY_DIR}/comicsight.icns"
        COMMAND "${CMAKE_COMMAND}" -E remove_directory
          "${PROJECT_BINARY_DIR}/osx/comicsight.iconset"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
          "${PROJECT_BINARY_DIR}/comicsight16.png"
          "${PROJECT_BINARY_DIR}/osx/comicsight.iconset/icon_16x16.png"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
          "${PROJECT_BINARY_DIR}/comicsight32.png"
          "${PROJECT_BINARY_DIR}/osx/comicsight.iconset/icon_16x16@2x.png"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
          "${PROJECT_BINARY_DIR}/comicsight32.png"
          "${PROJECT_BINARY_DIR}/osx/comicsight.iconset/icon_32x32.png"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
          "${PROJECT_BINARY_DIR}/comicsight64.png"
          "${PROJECT_BINARY_DIR}/osx/comicsight.iconset/icon_32x32@2x.png"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
          "${PROJECT_BINARY_DIR}/comicsight128.png"
          "${PROJECT_BINARY_DIR}/osx/comicsight.iconset/icon_128x128.png"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
          "${PROJECT_BINARY_DIR}/comicsight256.png"
          "${PROJECT_BINARY_DIR}/osx/comicsight.iconset/icon_128x128@2x.png"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
          "${PROJECT_BINARY_DIR}/comicsight256.png"
          "${PROJECT_BINARY_DIR}/osx/comicsight.iconset/icon_256x256.png"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
          "${PROJECT_BINARY_DIR}/comicsight512.png"
          "${PROJECT_BINARY_DIR}/osx/comicsight.iconset/icon_256x256@2x.png"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
          "${PROJECT_BINARY_DIR}/comicsight512.png"
          "${PROJECT_BINARY_DIR}/osx/comicsight.iconset/icon_512x512.png"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
          "${PROJECT_BINARY_DIR}/comicsight1024.png"
          "${PROJECT_BINARY_DIR}/osx/comicsight.iconset/icon_512x512@2x.png"
        COMMAND "${iconutil_EXECUTABLE}" --convert icns
          --output "${PROJECT_BINARY_DIR}/comicsight.icns"
          "${PROJECT_BINARY_DIR}/osx/comicsight.iconset"
        DEPENDS
          "${PROJECT_BINARY_DIR}/comicsight16.png" "${PROJECT_BINARY_DIR}/comicsight32.png"
          "${PROJECT_BINARY_DIR}/comicsight64.png" "${PROJECT_BINARY_DIR}/comicsight128.png"
          "${PROJECT_BINARY_DIR}/comicsight256.png" "${PROJECT_BINARY_DIR}/comicsight512.png"
          "${PROJECT_BINARY_DIR}/comicsight1024.png"
        VERBATIM)
endif(iconutil_FOUND)
