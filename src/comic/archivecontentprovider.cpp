/*
 * Archive Content Provider class
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

#ifdef HAVE_LIBARCHIVE
# include <archive.h>
# include <archive_entry.h>
#endif
#include "archivecontentprovider.h"

// some files in RAR archives cannot be extracted by libarchive
// see: http://code.google.com/p/libarchive/issues/detail?id=262
//      http://code.google.com/p/libarchive/issues/detail?id=338
// try to dynamically load unrar.dll under Windows for these cases
// try to execute unrar application on other systems

#ifdef _WIN32

# include <windows.h>

# define LOAD_PROC(module, proc) \
    proc = reinterpret_cast<decltype(proc)>(GetProcAddress(module, #proc))

# define LOAD_PROC_OR_GOTO_ERROR(module, proc) \
    if ((LOAD_PROC(module, proc)) == nullptr) \
        goto error;

namespace
{
    typedef void* HANDLE;
    typedef int (PASCAL *PROCESSDATAPROC)(unsigned char* Addr, int Size);

    const int RAR_OM_LIST = 0;
    const int RAR_OM_EXTRACT = 1;
    const int RAR_OM_LIST_INCSPLIT = 2;

    const int RAR_SKIP = 0;
    const int RAR_TEST = 1;
    const int RAR_EXTRACT = 2;

# pragma pack(push, 1)
    struct RAROpenArchiveData
    {
        const char* ArcName;
        unsigned int OpenMode;
        unsigned int OpenResult;
        char* CmtBuf;
        unsigned int CmtBufSize;
        unsigned int CmtSize;
        unsigned int CmtState;
    };

    struct RARHeaderData
    {
        char ArcName[260];
        char FileName[260];
        unsigned int Flags;
        unsigned int PackSize;
        unsigned int UnpSize;
        unsigned int HostOS;
        unsigned int FileCRC;
        unsigned int FileTime;
        unsigned int UnpVer;
        unsigned int Method;
        unsigned int FileAttr;
        char* CmtBuf;
        unsigned int CmtBufSize;
        unsigned int CmtSize;
        unsigned int CmtState;
    };
# pragma pack(pop)

    bool RARLibraryLoaded = false;
    std::stringstream* RARStringStream;

    HMODULE RARLibrary;
    HANDLE (PASCAL *RAROpenArchive)(RAROpenArchiveData* ArchiveData);
    int (PASCAL *RARCloseArchive)(HANDLE hArcData);
    int (PASCAL *RARReadHeader)(HANDLE hArcData, RARHeaderData* HeaderData);
    int (PASCAL *RARProcessFile)(HANDLE hArcData, int Operation,
                                 char* DestPath, char* DestName);
    void (PASCAL *RARSetProcessDataProc)(HANDLE hArcData,
                                         PROCESSDATAPROC ProcessDataProc);

    int PASCAL process_data_proc(unsigned char* Addr, int Size)
    {
        RARStringStream->write(reinterpret_cast<char*>(Addr), Size);
        return 1;
    }

    void read_rar_file_external(std::stringstream& stream,
                                const std::string& archive_file,
                                const std::string& file)
    {
        if (!RARLibraryLoaded)
        {
            RARLibraryLoaded = true;
            if ((RARLibrary = LoadLibrary("unrar.dll")))
            {
                LOAD_PROC_OR_GOTO_ERROR(RARLibrary, RAROpenArchive);
                LOAD_PROC_OR_GOTO_ERROR(RARLibrary, RARCloseArchive);
                LOAD_PROC_OR_GOTO_ERROR(RARLibrary, RARReadHeader);
                LOAD_PROC_OR_GOTO_ERROR(RARLibrary, RARProcessFile);
                LOAD_PROC_OR_GOTO_ERROR(RARLibrary, RARSetProcessDataProc);
            }
        }
        if (RARLibrary == nullptr)
            return;

        RAROpenArchiveData data;
        data.ArcName = archive_file.c_str();
        data.OpenMode = RAR_OM_EXTRACT;
        data.CmtBuf = nullptr;
        if (HANDLE handle = RAROpenArchive(&data))
        {
            RARHeaderData data;
            data.CmtBuf = nullptr;

            while (RARReadHeader(handle, &data) == 0)
                if (file.compare(data.FileName) == 0)
                {
                    char nullfile[MAX_PATH];
                    GetTempPathA(MAX_PATH, nullfile);
                    GetTempFileNameA(nullfile, "null", 0, nullfile);

                    printf(nullfile);

                    RARSetProcessDataProc(handle, process_data_proc);
                    RARStringStream = &stream;
                    RARProcessFile(handle, RAR_EXTRACT, nullptr, nullfile);

                    DeleteFileA(nullfile);
                    break;
                }
                else
                    RARProcessFile(handle, RAR_SKIP, nullptr, nullptr);

            RARCloseArchive(handle);
        }
        return;

        error:
        FreeLibrary(RARLibrary);
        RARLibrary = nullptr;
    }
}

#else // _WIN32

# include <cstdio>
# include <cstring>
# include <cstdlib>
# include <sys/types.h>
# include <sys/stat.h>
# include <sys/sysctl.h>
# include <unistd.h>
# ifdef __APPLE__
#  include <mach-o/dyld.h>
# endif

std::string get_unrar_executable()
{
    struct stat st;

# if defined(__APPLE__)

    uint32_t execpath_size = 0;
    _NSGetExecutablePath(nullptr, &execpath_size);

    char* execpath = new char[execpath_size + 8];
    _NSGetExecutablePath(execpath, &execpath_size);

# elif defined(__sun)

    const char* execname = getexecname();
    char* execpath = new char[strlen(execname) + 8];
    strcpy(execpath, execname);

# elif defined(__FreeBSD__)

    const int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PATHNAME, -1 };

    int length = 0;
    sysctl(mib, 4, nullptr, &length, nullptr, 0);

    char* execpath = new char[length + 8];
    sysctl(mib, 4, execpath, &length, nullptr, 0);

# else

    char* execpath = nullptr;

    const char* procs[] =
        { "/proc/self/exe", "/proc/curproc/exe", "/proc/curproc/file", nullptr };

    for (auto proc = procs; *proc; ++proc)
        if (lstat(*proc, &st) == 0)
        {
            auto length = ssize_t { st.st_size > 0 ? st.st_size : 255 };
            while (true)
            {
                execpath = new char[length + 8];
                if (readlink(*proc, execpath, length) >= length)
                {
                    delete [] execpath;
                    length += 255;
                }
                else
                    break;
            }
            break;
        }

    if (!execpath)
    {
        execpath = new char[8];
        execpath[0] = 0;
    }

# endif

    auto last = execpath;
    for (auto cur = execpath; *cur; ++cur)
        if(*cur == '/')
            last = cur + 1;
    strcpy(last, "unrar");

    auto unrar_executable =
            std::string { stat(execpath, &st) == 0 ? execpath : "unrar" };
    delete [] execpath;
    return unrar_executable;
}

std::string escape_argument(const std::string& argument)
{
    auto result = std::string();
    result.reserve(argument.size() + 4);
    result.push_back('\'');

    for (auto ch : argument)
        if (ch == '\'')
            result.append("'\\''");
        else
            result.push_back(ch);

    result.push_back('\'');
    return result;
}

void read_rar_file_external(std::stringstream& stream,
                            const std::string& archive_file,
                            const std::string& file)
{
    static auto unrar_executable = get_unrar_executable();
    char buffer[512];
    size_t size;

    auto command = escape_argument(unrar_executable) + " p -inul -p- -y " +
            escape_argument(archive_file) + ' ' + escape_argument(file);
    auto pipe = popen(command.c_str(), "r");

    while((size = fread(buffer, 1, 512, pipe)))
        stream.write(buffer, size);

    pclose(pipe);
}

#endif // _WIN32

ArchiveContentProvider::ArchiveContentProvider(const std::string& file)
    : _filename(file)
{
#ifdef HAVE_LIBARCHIVE
    auto archive = archive_read_new();
    archive_read_support_filter_all(archive);
    archive_read_support_format_all(archive);

    archive_entry* entry;
    if (archive_read_open_filename(archive, _filename.c_str(), 10240) == ARCHIVE_OK)
        while (archive_read_next_header(archive, &entry) == ARCHIVE_OK)
            if (archive_entry_filetype(entry) == AE_IFREG)
                _files.push_back(archive_entry_pathname(entry));
    archive_read_free(archive);
#endif
}

bool ArchiveContentProvider::can_provide(const std::string& file)
{
#ifdef HAVE_LIBARCHIVE
    auto archive = archive_read_new();
    archive_read_support_filter_all(archive);
    archive_read_support_format_all(archive);

    auto result = archive_read_open_filename(archive, file.c_str(), 10240);
    archive_read_free(archive);

    return result == ARCHIVE_OK;
#else
    return false;
#endif
}

std::istream& ArchiveContentProvider::open(const std::string& file)
{
#ifdef HAVE_LIBARCHIVE
    auto archive = archive_read_new();
    archive_read_support_filter_all(archive);
    archive_read_support_format_all(archive);

    archive_entry* entry;
    if (archive_read_open_filename(archive, _filename.c_str(), 10240) == ARCHIVE_OK)
        while (archive_read_next_header(archive, &entry) == ARCHIVE_OK)
        {
            if (archive_entry_filetype(entry) == AE_IFREG &&
                file.compare(archive_entry_pathname(entry)) == 0)
            {
                const void* buffer;
                size_t size;
                __LA_INT64_T offset;
                int result;

                _stream.str(std::string());
                _stream.clear();

                while ((result = archive_read_data_block(
                            archive, &buffer, &size, &offset)) == ARCHIVE_OK)
                    _stream.write(static_cast<const char*>(buffer), size);

                if (result != ARCHIVE_EOF &&
                        archive_format(archive) == ARCHIVE_FORMAT_RAR)
                {
                    _stream.str(std::string());
                    _stream.clear();
                    read_rar_file_external(_stream, _filename, file);
                }

                _stream.seekg(0);
                _stream.clear();
                break;
            }
        }
    archive_read_free(archive);
#endif
    return _stream;
}

void ArchiveContentProvider::close()
{
    _stream.str(std::string());
    _stream.clear();
}
