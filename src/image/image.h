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

#include <fstream>
#include <cstring>
#include <cstdint>

#ifndef IMAGE_H
#define IMAGE_H

namespace image
{
    typedef uint8_t sample;
}

class Image
{
public:
    Image() : _width(0), _height(0), _channels(0), _data(nullptr) { }

    Image(int width, int height, int channels)
        : _width(width), _height(height), _channels(channels),
          _data(new image::sample[width * height * channels]) { }

    Image(const Image& image)
        : _width(image._width), _height(image._height), _channels(image._channels),
          _data(new image::sample[_width * _height * _channels])
    {
        memcpy(_data, image._data, _width * _height * _channels);
    }

    Image(Image&& image)
        : _width(image._width), _height(image._height), _channels(image._channels),
          _data(image._data)
    {
        image._data = nullptr, image._width = image._height =image._channels = 0;
    }

    Image& operator=(const Image& image)
    {
        if (&image != this)
        {
            delete [] _data;
            _width = image._width, _height = image._height, _channels = image._channels;
            _data = new image::sample[_width * _height * _channels];
            memcpy(_data, image._data, _width * _height * _channels);
        }
        return *this;
    }

    Image& operator=(Image&& image)
    {
        if (&image != this)
        {
            delete [] _data;
            _data = image._data, _width = image._width, _height = image._height, _channels = image._channels;
            image._data = nullptr, image._width = image._height = image._channels = 0;
        }
        return *this;
    }

    ~Image() { delete [] _data; }

    int width() const { return _width; }
    int height() const { return _height; }
    int channels() const { return _channels; }
    int size() const { return _width * _height * _channels; }
    bool empty() const { return !_width || !_height; }

    void clear()
    {
        delete [] _data;
        _data = nullptr, _width = _height = _channels = 0;
    }

    void reset(int width, int height, int channels)
    {
        if (width * height * channels > _width * _height * _channels)
        {
            delete [] _data;
            _data = new image::sample[width * height * channels];
        }
        _width = width, _height = height, _channels = channels;
    }

    const image::sample* data() const { return _data; }
    image::sample* data() { return _data; }

    const image::sample* data(int x, int y, int c = 0) const
        { return _data + (y * _width + x) * _channels + c; }
    image::sample* data(int x, int y, int c = 0)
        { return _data + (y * _width + x) * _channels + c; }

    const image::sample& operator[](int index) const { return _data[index]; }
    image::sample& operator[](int index) { return _data[index]; }

    const image::sample& operator()(int x, int y, int c = 0) const
        { return _data[(y * _width + x) * _channels + c]; }
    image::sample& operator()(int x, int y, int c = 0)
        { return _data[(y * _width + x) * _channels + c]; }

    bool load(const char* filename);
    bool load(std::istream& stream, const char* filename = nullptr);

private:
    int _width, _height, _channels;
    image::sample* _data;
};

#endif // IMAGE_H
