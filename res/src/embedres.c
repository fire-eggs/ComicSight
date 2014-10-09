/*
 * Creates a C source file with a variable containing a binary resource
 * Used during the build process to embed binary resources into the compilation
 *
 * Copyright (c) 2012, sfstewman
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
 *
 * original source from:
 * http://stackoverflow.com/questions/11813271/#answer-11814544
 */

#include <stdlib.h>
#include <stdio.h>

#if _MSC_VER
# define snprintf _snprintf
# pragma warning(push)
# pragma warning(disable:4996)
#endif

FILE* open_or_exit(const char* fname, const char* mode)
{
    FILE* f = fopen(fname, mode);
    if (f == NULL)
    {
        perror(fname);
        exit(EXIT_FAILURE);
    }
    return f;
}

int main(int argc, char** argv)
{
    const char* symbol;
    FILE* resfile, *symfile;
    size_t i, count, bytes_per_line = 0;
    char buffer[256];

    if (argc < 3)
    {
        fprintf(stderr,
                "USAGE: embedres {symbol} {resfile}\n"
                "       Creates {symbol}.res.c from the contents of {resfile}\n\n");
        return EXIT_FAILURE;
    }

    symbol = argv[1];
    resfile = open_or_exit(argv[2], "rb");

    snprintf(buffer, sizeof(buffer), "%s.res.c", symbol);
    symfile = open_or_exit(buffer, "wb");
    fprintf(symfile, "const unsigned char %s_data[] = {\n", symbol);

    while ((count = fread(buffer, 1, sizeof(buffer), resfile)))
        for (i = 0; i < count; ++i)
        {
            fprintf(symfile, "0x%02x, ", (unsigned char) buffer[i]);
            if (++bytes_per_line == 12)
            {
                fprintf(symfile, "\n");
                bytes_per_line = 0;
            }
        }

    if (bytes_per_line > 0)
        fprintf(symfile, "\n");
    fprintf(symfile, "};\n");
    fprintf(symfile, "const int %s_size = sizeof(%s_data);\n", symbol, symbol);

    fclose(resfile);
    fclose(symfile);

    return EXIT_SUCCESS;
}

#if _MSC_VER
# pragma warning(pop)
#endif
