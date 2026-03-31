#include <stdlib.h>
#include "regrex.h"
#include <string.h>

static const char *regrex_error_msgid[] = {
    "Invalid multibyte sequence",
    "Capture group does not exist",
    "Exceeded group count limit"
};

/* 
    Calculate error map length dynamically to simplify extending with new errors 
    and avoid hardcoding any max value
*/
#define REGX_ERROR_COUNT (sizeof(regrex_error_msgid) / sizeof(regrex_error_msgid[0]))

/* 
    Allocate memory in C, otherwise Zig will always return `regex_t` as an opaque type
    Returns a pointer to an uninitialized `regex_t`
*/
regex_t* regrex_create(void) {
    return malloc(sizeof(regex_t));
}

/* Free memory allocated for `regex_t` */
void regrex_destroy(regex_t* re) {
    free(re);
}

/*
    Return an error message for custom error codes
    Copies `regerror` functionality:
      - if errbuf is NULL, returns required buffer size (nullterm included)
      - Else write message to errbuf up to errbuf_size bytes and return written msg length (with nullterm)
*/
size_t regrex_error(regrex_errcode_t errcode, char *errbuf, size_t errbuf_size) {
    const char *msg = "Unknown regrex error";

    if (errcode >= _REGX_ILLSEQ && errcode < _REGX_ILLSEQ + REGX_ERROR_COUNT) {
        msg = regrex_error_msgid[errcode - _REGX_ILLSEQ];
    }

    size_t len = strlen(msg) + 1;

    if (errbuf != NULL && errbuf_size > 0) {
        size_t copy_len = len < errbuf_size ? len : errbuf_size - 1;
        memcpy(errbuf, msg, copy_len);
        errbuf[copy_len] = '\0';
    }
    return len;
}
