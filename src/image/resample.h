/*
 * Image resampling
 * using fixed-point arithmetic and pre-calculated Lanczos value approximation
 * to gain better runtime performance
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

#include <functional>
#include <image/image.h>

#ifndef IMAGE_RESAMPLE_H
#define IMAGE_RESAMPLE_H

namespace image
{
    Image resample_nearest_neighbor_fast(const Image& image, float scale,
                                         int start_x, int start_y,
                                         int width, int height);
    Image resample_nearest_neighbor(const Image& image, float scale,
                                    int start_x, int start_y,
                                    int width, int height);
    Image resample_bilinear_fast(const Image& image, float scale,
                                 int start_x, int start_y,
                                 int width, int height);
    Image resample_bilinear(const Image& image, float scale,
                            int start_x, int start_y,
                            int width, int height,
                            std::function<bool()> canceled = []{ return false; });
    Image resample_lanczos(const Image& image, float scale,
                           int start_x, int start_y,
                           int width, int height,
                           std::function<bool()> canceled = []{ return false; });
}

#endif // IMAGE_RESAMPLE_H
