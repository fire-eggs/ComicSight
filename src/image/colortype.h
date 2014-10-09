/*
 * Color type conversion
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

#include <image/image.h>

#ifndef IMAGE_COLORTYPE_H
#define IMAGE_COLORTYPE_H

namespace image
{
    Image grayscale(const Image& image, bool reduce_channels = true);
    void grayscale_inplace(Image& image, bool reduce_channels = true);
    Image ensure_rgb(const Image& image);
    void ensure_rgb_inplace(Image& image);
    Image drop_alpha(const Image& image);
    void drop_alpha_inplace(Image& image);
    Image ensure_alpha(const Image& image, image::sample default_alpha = 255);
    void ensure_alpha_inplace(Image& image, image::sample default_alpha = 255);
}

#endif // IMAGE_COLORTYPE_H
