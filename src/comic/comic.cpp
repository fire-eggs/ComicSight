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

#include <sys/stat.h>
#include <algorithm>
#include <cctype>
#include "image/colortype.h"
#include "comic/archivecontentprovider.h"
#include "comic/directorycontentprovider.h"
#include "comic.h"

#ifdef _WIN32
# define stat _stat
# ifndef S_ISDIR
#  define S_ISDIR(mode) (((mode) & S_IFMT) == S_IFDIR)
# endif
# ifndef S_ISREG
#  define S_ISREG(mode) (((mode) & S_IFMT) == S_IFREG)
# endif
#endif

namespace
{
    const static char* image_extensions[] =
    {
        ".png", ".jpg", ".jpeg",
        ".gif", ".bmp", ".dib", ".tiff", ".tif",
        ".jpe",  ".jfif", ".jif", ".jfi"
    };
}

Comic::Comic()
    : _page(-1)
{
}

Comic::Comic(const std::string& path)
    : _page(-1)
{
    auto pagename = createProvider(path);
    if (valid())
    {
        // filter files by file extension to keep only image files as pages
        _pages.reserve(_provider->files().size());
        for (auto& page : _provider->files())
        {
            auto index = page.rfind('.');
            if (index != std::string::npos)
            {
                auto page_ext = page.substr(index);
                std::transform(page_ext.begin(), page_ext.end(),
                               page_ext.begin(),
                               [](char a) { return std::tolower(a); });

                for (auto ext : image_extensions)
                    if (strcmp(page_ext.c_str(), ext) == 0)
                    {
                        _pages.push_back(page);
                        break;
                    }
            }
        }

        std::sort(
            _pages.begin(), _pages.end(),
            [](std::string const& a, std::string const& b)
            {
                return std::lexicographical_compare(
                    a.begin(), a.end(),
                    b.begin(), b.end(),
                    [](char a, char b)
                    {
                        return std::tolower(a) < std::tolower(b);
                    });
            });

        _images.resize(page_count());

        // try to find page given by name or index
        auto index = page_index(pagename);
        if (index == -1)
            index = atoi(pagename.c_str()) - 1;

        page(0);
        page(index);
    }
}

std::string Comic::createProvider(std::string path)
{
    if (path.empty() || _provider)
        return std::string();

    auto page = std::string();

    // find path prefix (segmented by path separators) that is an existing file
    // or directory and keep the remaining suffix as part of the current page
    // identifier
    if (path[path.size() - 1] == '/' || path[path.size() - 1] == '\\')
        path.erase(path.size() - 1, 1);

    struct stat statbuf;
    while (stat(path.c_str(), &statbuf) == -1)
    {
        auto pos = path.find_last_of("/\\");
        if (pos == std::string::npos)
            return std::string();

        if (page.empty())
            page = path.substr(pos + 1);
        else
            page = path.substr(pos + 1) + '/' + page;
        path.erase(pos);
    }

    // the path names a directory, this is the directory that includes the images
    if (S_ISDIR(statbuf.st_mode))
        _provider.reset(new DirectoryContentProvider(path));

    // the path names a file, this may be archive file that includes the images
    // or an image file in a directory
    else if (S_ISREG(statbuf.st_mode))
    {
        if (ArchiveContentProvider::can_provide(path))
            _provider.reset(new ArchiveContentProvider(path));
        else
        {
            auto pos = path.find_last_of("/\\");

            if (page.empty())
                page = path.substr(pos + 1);
            else
                page = path.substr(pos + 1) + '/' + page;

            if (pos == std::string::npos)
                path = ".";
            else
                path.erase(pos);

            _provider.reset(new DirectoryContentProvider(path));
        }
    }
    else
        return std::string();

    return page;
}

bool Comic::page(int page)
{
    if (page < 0 || page >= page_count())
        return false;
    _page = page;
    return true;
}


int Comic::page_index(const std::string& page) const
{
    if (valid())
        for (auto i = 0u; i < _pages.size(); i++)
            if (_pages[i] == page)
                return static_cast<int>(i);
    return -1;
}

const Image& Comic::page_image(int page) const
{
    static auto empty = Image();

    if (page < 0 || page >= page_count())
        return empty;

    if (!_images[page])
    {
        auto& pagename = _pages[page];
        _images[page].reset(new Image);

        //std::string p;
        //_provider->path(pagename, p);
        //_images[page]->load(p.c_str());

        _images[page]->load(_provider->open(pagename), pagename.c_str());
        _provider->close();

        image::drop_alpha_inplace(*_images[page]);
        image::ensure_rgb_inplace(*_images[page]);
    }
    return *_images[page];
}
