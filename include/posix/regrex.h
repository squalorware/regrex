/* 
    regrex.h — definitions to ensure compatibility with the POSIX 
    standards and the GNU C Library implementation of regular expressions
    for the regrex library written in the Zig programming language.
    Copyright (C) 2026 oniko94

    This file is part of regrex

    regrex is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    regrex is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    See the GNU Lesser General Public License for more details. 
*/

#ifndef REGREX_H
#define REGREX_H

#include <stddef.h>
#include <regex.h>

#ifdef __cplusplus
extern "C" {
#endif
/* 
    Fallback definitions for `cflags` and `eflags` which may differ for platforms
*/
#ifndef REG_EXTENDED
/* If this bit is set, use extended syntax; basic posix syntax otherwise */
#define REG_EXTENDED 1
#endif

#ifndef REG_ICASE
/* If this bit is set, ignore character case */
#define REG_ICASE (1 << 1)
#endif

#ifndef REG_NEWLINE
/* If this bit is set, anchors do not match at new line chars inside the string */
#define REG_NEWLINE (1 << 2)
#endif

#ifndef REG_NOSUB
/* If this bit is set, return only success or fail */
#define REG_NOSUB (1 << 3)
#endif

#ifndef REG_NOTBOL
/* If this bit is set, beginning-of-line character doesn't match beginning of string */
#define REG_NOTBOL 1
#endif

#ifndef REG_NOTEOL
/* Same as REG_NOTBOL but for the end of line */
#define REG_NOTEOL (1 << 1)
#endif

#ifndef REG_STARTEND
/* If this bit is set, limit start and end of search in buffer by PMATCH[0]*/
#define REG_STARTEND (1 << 2)
#endif

/*
    Custom error definitions
    Copies POSIX implementation for API consistency
*/
typedef enum : signed int { 
    _REGX_ILLSEQ = 17,
    _REGX_BADGRP,
    _REGX_EGRPLMT
} regrex_errcode_t;

#define REGX_ILLSEQ _REGX_ILLSEQ
#define REGX_BADGRP _REGX_BADGRP
#define REGX_EGRPLMT _REGX_EGRPLMT

regex_t* regrex_create(void);

void regrex_destroy(regex_t* re);

size_t regrex_error(regrex_errcode_t errcode, char *errbuf, size_t errbuf_size);

/* Define semver */
#define REGREX_VERSION_MAJOR 0
#define REGREX_VERSION_MINOR 1
#define REGREX_VERSION_PATCH 0
#define REGREX_VERSION_NUM ( \
    (REGREX_VERSION_MAJOR << 16) | \
    (REGREX_VERSION_MINOR << 8) | \
    (REGREX_VERSION_PATCH << 4))

#ifdef __cplusplus
}
#endif    /* extern "C" */

#endif /* REGREX_H */
