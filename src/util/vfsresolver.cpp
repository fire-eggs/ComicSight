/*
 * Virtual File System Resolver
 * supports GVFS via FUSE and file URI scheme for local files
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

#include "vfsresolver.h"

#ifdef __unix

# include <dlfcn.h>

# define LOAD_SYM(handle, sym) \
    sym = reinterpret_cast<decltype(sym)>(dlsym(handle, #sym))

# define LOAD_SYM_OR_GOTO_ERROR(handle, sym) \
    LOAD_SYM(handle, sym); \
    if (dlerror() != nullptr) \
        goto error;

namespace
{
    struct GVfs;
    struct GFile;

    class GVFS
    {
        void* libgio;
        GVfs* (*g_vfs_get_default)(void);
        GFile* (*g_vfs_get_file_for_uri)(GVfs* vfs, const char* uri);
        char* (*g_file_get_path)(GFile* file);
        void (*g_free)(void* mem);
        void (*g_object_unref)(void* mem);
        void (*g_type_init)(void);
        const unsigned int* glib_major_version;
        const unsigned int* glib_minor_version;

    public:
        GVFS()
        {
            libgio = dlopen("libgio-2.0.so.0", RTLD_LAZY);
            if (dlerror() != nullptr)
                goto error;

            LOAD_SYM_OR_GOTO_ERROR(libgio, g_vfs_get_default);
            LOAD_SYM_OR_GOTO_ERROR(libgio, g_vfs_get_file_for_uri);
            LOAD_SYM_OR_GOTO_ERROR(libgio, g_file_get_path);
            LOAD_SYM_OR_GOTO_ERROR(libgio, g_free);
            LOAD_SYM_OR_GOTO_ERROR(libgio, g_object_unref);
            LOAD_SYM(libgio, g_type_init);
            LOAD_SYM_OR_GOTO_ERROR(libgio, glib_major_version);
            LOAD_SYM_OR_GOTO_ERROR(libgio, glib_minor_version);

            if (g_type_init && (*glib_major_version < 2 ||
                                (*glib_major_version == 2 && *glib_minor_version < 36)))
                g_type_init();

            return;

            error:
            if (libgio)
                dlclose(libgio);
            libgio = nullptr;
        }

        ~GVFS()
        {
            if (libgio)
                dlclose(libgio);
        }

        bool valid() const { return libgio; }

        std::string resolve(const std::string& path) const
        {
            auto result = std::string();
            if (valid())
            {
                if (auto file = g_vfs_get_file_for_uri(g_vfs_get_default(),
                                                       path.c_str()))
                {
                    if (auto path = g_file_get_path(file))
                    {
                        result = path;
                        g_free(path);
                    }
                    g_object_unref(file);
                }
            }
            return result;
        }
    };
}

#endif // __unix

namespace
{
    inline void decode_uri(std::string& file)
    {
        char a, b;
        size_t i = 0, j = 0;

#ifdef _WIN32
        if (file.size() > 2 && file[0] == '/' && (file[2] == ':' || file[2] == '|'))
            file[2] = ':', ++i;
#endif

        while (i < file.size())
            if (file[i] == '%' && i + 2 < file.size() &&
                isxdigit(a = file[i + 1]) && isxdigit(b = file[i + 2]))
            {
                a -= a > 'a' ? 'a' - 10 : a > 'A' ? 'A' - 10 : '0',
                b -= b > 'a' ? 'a' - 10 : b > 'A' ? 'A' - 10 : '0';
                file[j++] = (a << 4) + b;
                i += 3;
            }
#ifdef _WIN32
            else if (file[i] == '/')
                file[j++] = '\\', ++i;
#endif
            else
                file[j++] = file[i++];
        file.resize(j);
    }
}

std::string vfs_resolver::resolve(const std::string& path)
{
#ifdef __unix
    static GVFS gvfs;
    auto result = gvfs.resolve(path);
#else // __unix
    auto result = std::string();
#endif // __unix

    if (result.empty() && path.compare(0, 8, "file:///") == 0)
    {
        result = path.substr(7);
        decode_uri(result);
    }

    if (result.empty() && path.compare(0, 17, "file://localhost/") == 0)
    {
        result = path.substr(16);
        decode_uri(result);
    }

    if (result.empty())
        result = path;

    return result;
}
