#ifndef _LIB_POSIX_H
#define _LIB_POSIX_H

#include <regex.h>
#include <stdalign.h>

/* cflags for regcomp */
/* If this bit is set, use extended syntax; basic posix syntax otherwise */
#ifndef REG_EXTENDED
#define REG_EXTENDED 1
#endif
/* If this bit is set, ignore character case */
#ifndef REG_ICASE
#define REG_ICASE (1 << 1)
#endif
/* If this bit is set, anchors do not match at new line chars inside the string */
#ifndef REG_NEWLINE
#define REG_NEWLINE (1 << 2)
#endif
/* If this bit is set, return only success or fail */
#ifndef REG_NOSUB
#define REG_NOSUB (1 << 3)
#endif

/* eflags for regexec */
/* If this bit is set, beginning-of-line character doesn't match beginning of string */
#ifndef REG_NOTBOL
#define REG_NOTBOL 1
#endif
/* Same as REG_NOTBOL but for the end of line*/
#ifndef REG_NOTEOL
#define REG_NOTEOL (1 << 1)
#endif
/* If this bit is set, limit start and end of search in buffer by PMATCH[0]*/
#ifndef REG_STARTEND
#define REG_STARTEND (1 << 2)
#endif

const size_t sizeof_regex_t = sizeof(regex_t);
const size_t alignof_regex_t = alignof(regex_t);

#endif /* lib_posix.h */
