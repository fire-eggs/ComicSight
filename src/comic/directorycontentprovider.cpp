/*
 * Directory Content Provider class
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

#include <dirent.h>
#include <sys/stat.h>
#include <cstring>
#include <fstream>
#include <streambuf>
#include "directorycontentprovider.h"

#ifdef _WIN32
# define stat _stat
#endif

DirectoryContentProvider::DirectoryContentProvider(const std::string& path)
    : _path(path)
{
    DIR* directory;
    struct dirent* entry;
    struct stat statbuf;

    if ((directory = opendir(path.c_str())) == nullptr)
        return;

    while ((entry = readdir(directory)) != nullptr)
    {
        if (entry->d_name[0] == '.' &&
            (entry->d_name[1] == 0 ||
             (entry->d_name[1] == '.' && entry->d_name[2] == 0)))
            continue;

#ifdef _WIN32
        auto entry_path = path + '\\' + entry->d_name;
#else
        auto entry_path = path + '/' + entry->d_name;
#endif

        if (stat(entry_path.c_str(), &statbuf) != -1 && S_ISREG(statbuf.st_mode))
            _files.push_back(entry->d_name);
    }
    closedir(directory);
}

std::istream& DirectoryContentProvider::open(const std::string& file)
{
#ifdef _WIN32
    _stream.open((_path + '\\' + file).c_str(), std::ios::in | std::ios::binary);
#else
    _stream.open((_path + '/' + file).c_str(), std::ios::in | std::ios::binary);
#endif
    return _stream;
}

void DirectoryContentProvider::close()
{
    _stream.close();
}
