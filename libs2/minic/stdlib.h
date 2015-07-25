#ifndef __STDLIB_H
#define __STDLIB_H

#include <stddef.h>

void abort(void);

char *getenv(const char *name);

// lua does book-keeping of old size for us; so let's take advantage!
void *realloc3(void *ptr, size_t osize, size_t nsize);

void free(void *ptr);

void *malloc(size_t size);

#endif