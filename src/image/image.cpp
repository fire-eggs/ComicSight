/*
 * Simple image class
 *
 * Copyright (c) 2014, Pascal Weisenburger
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <cstring>
#include <cctype>

#ifdef HAVE_LIBPNG
# include <png.h>
#endif

#ifdef HAVE_LIBJPEG
# include <jpeglib.h>
# include <jerror.h>
#endif

#include "image.h"

namespace
{
#ifdef HAVE_LIBPNG
    namespace png
    {
        void read(png_structp png_ptr, png_bytep data, png_size_t length)
        {
            std::istream* stream = static_cast<std::istream*>(png_get_io_ptr(png_ptr));
            stream->read(reinterpret_cast<char*>(data), length);

            if (static_cast<size_t>(stream->gcount()) != length)
#if PNG_LIBPNG_VER >= 10500
                png_longjmp(png_ptr, 1);
#else
                longjmp(png_ptr->jmpbuf, 1);
#endif
        }

        bool load(std::istream& stream, image::sample** data,
                  int* width, int* height, int* channels)
        {
            volatile bool header_checked = false;
            image::sample** volatile rows_checked = nullptr;
            image::sample** rows = nullptr;
            png_structp png_ptr = nullptr;
            png_infop info_ptr = nullptr;

            if ((png_ptr =
                   png_create_read_struct(PNG_LIBPNG_VER_STRING,
                                          nullptr, nullptr, nullptr)) == nullptr ||
                (info_ptr = png_create_info_struct(png_ptr)) == nullptr ||
                setjmp(png_jmpbuf(png_ptr)))
            {
#ifdef __clang_analyzer__
                longjump:
#endif
                png_destroy_read_struct(png_ptr ? &png_ptr : nullptr,
                                        info_ptr ? &info_ptr : nullptr,
                                        nullptr);
                if (rows_checked)
                    delete [] rows_checked;
                return header_checked;
            }

            png_set_read_fn(png_ptr, &stream, read);
//          png_set_crc_action(png_ptr, PNG_CRC_QUIET_USE, PNG_CRC_QUIET_USE);

            int image_bit_depth, image_color_type;
            png_uint_32 image_width, image_height;
            png_read_info(png_ptr, info_ptr);
            png_get_IHDR(png_ptr, info_ptr, &image_width, &image_height,
                         &image_bit_depth, &image_color_type,
                         nullptr, nullptr, nullptr);

            if (image_bit_depth < 8)
                png_set_packing(png_ptr);
            else if (image_bit_depth > 8)
                png_set_strip_16(png_ptr);
            png_set_expand(png_ptr);

            png_read_update_info(png_ptr, info_ptr);

            *width = static_cast<int>(image_width);
            *height = static_cast<int>(image_height);
            *channels = static_cast<int>(png_get_channels(png_ptr, info_ptr));

            const int rowbytes = *width * *channels;
            image::sample* row = *data = new image::sample[*height * rowbytes];
            memset(row, 0, *height * rowbytes);
            header_checked = true;

            rows_checked = rows = new image::sample*[*height];
            for (int i = 0; i < *height; i++)
            {
                rows[i] = row;
                row += rowbytes;
            }

            png_read_image(png_ptr, rows);
            png_read_end(png_ptr, info_ptr);
            png_destroy_read_struct(&png_ptr, &info_ptr, nullptr);

#ifdef __clang_analyzer__
            goto longjump;
#endif

            delete [] rows;
            return true;
        }
    }
#endif // HAVE_LIBPNG

#ifdef HAVE_LIBJPEG
    namespace jpeg
    {
        struct stream_mgr
        {
            jpeg_source_mgr pub;
            std::istream* stream;
            JOCTET buffer[1024];
            static const int buffer_size;
        };

        const int stream_mgr::buffer_size = 1024;

        struct error_mgr
        {
            jpeg_error_mgr pub;
            jmp_buf jump;
        };

        METHODDEF(void) error_exit(j_common_ptr cinfo)
        {
            error_mgr* err = reinterpret_cast<error_mgr*>(cinfo->err);
            longjmp(err->jump, 1);
        }

        static void init_source(j_decompress_ptr cinfo)
        {
            // do nothing
            (void) cinfo;
        }

        boolean fill_input_buffer(j_decompress_ptr cinfo)
        {
            stream_mgr* src = reinterpret_cast<stream_mgr*>(cinfo->src);
            src->stream->read(reinterpret_cast<char*>(src->buffer),
                              stream_mgr::buffer_size);

            if (src->stream->gcount() == 0)
                ERREXIT(cinfo, JERR_INPUT_EOF);

            src->pub.next_input_byte = src->buffer;
            src->pub.bytes_in_buffer = static_cast<size_t>(src->stream->gcount());

            return TRUE;
        }

        void skip_input_data(j_decompress_ptr cinfo, long num_bytes)
        {
            stream_mgr* src = reinterpret_cast<stream_mgr*>(cinfo->src);
            size_t count = static_cast<size_t>(num_bytes);

            while (count > src->pub.bytes_in_buffer)
            {
                count -= src->pub.bytes_in_buffer;
                fill_input_buffer(cinfo);
            }

            src->pub.next_input_byte += count;
            src->pub.bytes_in_buffer -= count;
        }

        void term_source(j_decompress_ptr cinfo)
        {
            // do nothing
            (void) cinfo;
        }

        bool load(std::istream& stream, image::sample** data,
                  int* width, int* height, int* channels)
        {
            volatile bool header_checked = false;
            stream_mgr src;
            jpeg_decompress_struct cinfo;
            error_mgr err;

            cinfo.err = jpeg_std_error(&err.pub);
            err.pub.error_exit = error_exit;
            if (setjmp(err.jump))
            {
#ifdef __clang_analyzer__
                longjump:
#endif
                jpeg_destroy_decompress(&cinfo);
                return header_checked;
            }

            jpeg_create_decompress(&cinfo);
            src.pub.init_source = init_source;
            src.pub.fill_input_buffer = fill_input_buffer;
            src.pub.skip_input_data = skip_input_data;
            src.pub.resync_to_restart = jpeg_resync_to_restart;
            src.pub.term_source = term_source;
            src.stream = &stream;
            src.pub.bytes_in_buffer = 0;
            src.pub.next_input_byte = nullptr;
            cinfo.src = reinterpret_cast<jpeg_source_mgr*>(&src);

            jpeg_read_header(&cinfo, TRUE);
//          cinfo.buffered_image = TRUE;
            jpeg_start_decompress(&cinfo);

            *width = static_cast<int>(cinfo.output_width);
            *height = static_cast<int>(cinfo.output_height);
            *channels = static_cast<int>(cinfo.output_components);

            const int rowbytes = *width * *channels;
            image::sample* row = *data = new image::sample[*height * rowbytes];
            memset(row, 0, *height * rowbytes);
            header_checked = true;

//          while (!jpeg_input_complete(&cinfo))
//          {
//              jpeg_start_output(&cinfo, cinfo.input_scan_number);
                while (cinfo.output_scanline < cinfo.output_height)
                {
                    jpeg_read_scanlines(&cinfo, &row, 1);
                    row += rowbytes;
                }
//              jpeg_finish_output(&cinfo);
//          }

            jpeg_finish_decompress(&cinfo);
            jpeg_destroy_decompress(&cinfo);

#ifdef __clang_analyzer__
            goto longjump;
#endif

            return true;
        }
    }
#endif // HAVE_LIBJPEG

    bool ends_with(const char* str, const char* end)
    {
        size_t str_len = strlen(str), end_len = strlen(end);
        if (str_len < end_len)
            return false;

        str = str + str_len - end_len;
        while (*end)
            if (tolower(*str) == tolower(*end))
                str++, end++;
            else
                return false;

        return true;
    }
}

bool Image::load(const char* filename)
{
    std::ifstream stream(filename, std::ios::in | std::ios::binary);
    return load(stream, filename);
}

bool Image::load(std::istream& stream, const char* filename)
{
#if defined(HAVE_LIBPNG) || defined(HAVE_LIBJPEG)
    bool (*load_func[])(std::istream& stream, image::sample** data,
                        int* width, int* height, int* channels) =
    {
        nullptr,
# ifdef HAVE_LIBPNG
        png::load,
# endif
# ifdef HAVE_LIBJPEG
        jpeg::load,
# endif
    };

    static const struct
    {
        const char* ext;
        bool (*load_func)(std::istream& stream, image::sample** data,
                          int* width, int* height, int* channels);
    }
    ext_load_func[] =
    {
# ifdef HAVE_LIBPNG
        {".png", png::load},
# endif
# ifdef HAVE_LIBJPEG
        {".jpg", jpeg::load},
        {".jpeg", jpeg::load},
        {".jpe", jpeg::load},
        {".jfif", jpeg::load},
        {".jif", jpeg::load},
        {".jfi", jpeg::load},
# endif
    };
    static const int load_func_count = sizeof load_func / sizeof *load_func;
    static const int ext_load_func_count = sizeof ext_load_func / sizeof *ext_load_func;

    if (filename)
        for (int i = 0; i < ext_load_func_count; i++)
            if (ends_with(filename, ext_load_func[i].ext))
            {
                load_func[0] = ext_load_func[i].load_func;
                break;
            }

    clear();
    const std::streampos begin = stream.tellg();
    for (int i = 0; i < load_func_count; i++)
        if (load_func[i] && (i == 0 || load_func[i] != load_func[0]))
        {
            // load image file
            if (load_func[i](stream, &_data, &_width, &_height, &_channels))
                return true;
            else
            {
                clear();
                stream.seekg(begin, std::ios::beg);
            }
        }
#endif
    return false;
}
