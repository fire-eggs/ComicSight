/*
 * Win32 integration
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

#ifdef _WIN32
# include <windows.h>
# include <fcntl.h>
# include <io.h>
# include <cstdio>
# include <iostream>
#endif
#include "win32.h"

void win32::redirect_std_to_console()
{
#ifdef _WIN32
    HANDLE stdoutHandle = GetStdHandle(STD_OUTPUT_HANDLE);
    HANDLE stdinHandle = GetStdHandle(STD_INPUT_HANDLE);
    HANDLE stderrHandle = GetStdHandle(STD_ERROR_HANDLE);

    if (stdoutHandle != INVALID_HANDLE_VALUE &&
        stdinHandle != INVALID_HANDLE_VALUE &&
        stderrHandle != INVALID_HANDLE_VALUE &&
        GetFileType(stdoutHandle) == FILE_TYPE_UNKNOWN &&
        GetFileType(stdinHandle) == FILE_TYPE_UNKNOWN &&
        GetFileType(stderrHandle) == FILE_TYPE_UNKNOWN &&
        AttachConsole(ATTACH_PARENT_PROCESS))
    {
        HANDLE handle;
        int file;
        FILE* stream;

        // redirect unbuffered STDOUT to the console
        if ((handle = GetStdHandle(STD_OUTPUT_HANDLE)) != INVALID_HANDLE_VALUE &&
            (file = _open_osfhandle(
                 reinterpret_cast<intptr_t>(handle), _O_TEXT)) != -1 &&
            (stream = _fdopen(file, "w")) != nullptr)
        {
            *stdout = *stream;
            setvbuf(stdout, nullptr, _IONBF, 0);
        }

        // redirect unbuffered STDIN to the console
        if ((handle = GetStdHandle(STD_INPUT_HANDLE)) != INVALID_HANDLE_VALUE &&
            (file = _open_osfhandle(
                 reinterpret_cast<intptr_t>(handle), _O_TEXT)) != -1 &&
            (stream = _fdopen(file, "w")) != nullptr)
        {
            *stdin = *stream;
            setvbuf(stdin, nullptr, _IONBF, 0);
        }

        // redirect unbuffered STDERR to the console
        if ((handle = GetStdHandle(STD_ERROR_HANDLE)) != INVALID_HANDLE_VALUE &&
            (file = _open_osfhandle(
                 reinterpret_cast<intptr_t>(handle), _O_TEXT)) != -1 &&
            (stream = _fdopen(file, "w")) != nullptr)
        {
            *stderr = *stream;
            setvbuf(stderr, nullptr, _IONBF, 0);
        }

        // make cout, wcout, cin, wcin, wcerr, cerr, wclog and clog
        // point to console as well
        std::ios::sync_with_stdio();
    }
#endif
}
