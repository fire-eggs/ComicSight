/*
 * Comic class
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

#include <string>
#include <memory>
#include <image/image.h>
#include <comic/contentprovider.h>

#ifndef COMIC_H
#define COMIC_H

class Comic
{
public:
    Comic(Comic&& comic) :
        _page(std::move(comic._page)),
        _provider(std::move(comic._provider)),
        _pages(std::move(comic._pages)),
        _images(std::move(comic._images)) { }
    Comic& operator=(Comic&& comic)
    {
        _page = std::move(comic._page),
        _provider = std::move(comic._provider),
        _pages = std::move(comic._pages),
        _images = std::move(comic._images);
        return *this;
    }

    Comic();
    Comic(const std::string &path);

    bool valid() const { return _provider != nullptr; }

    int page_index(const std::string& page) const;
    int page_count() const { return static_cast<int>(_pages.size()); }
    int page() const { return _page; }
    bool page(int page);

    const Image& page_image() const { return page_image(page()); }
    const Image& page_image(int page) const;

protected:
    int _page;
    std::unique_ptr<ContentProvider> _provider;
    std::vector<std::string> _pages;
    mutable std::vector<std::unique_ptr<Image>> _images;

    std::string createProvider(std::string path);
};

#endif // COMIC_H
