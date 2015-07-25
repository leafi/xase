#ifndef __STRING_H
#define __STRING_H

/* Courtesy of http://lua-users.org/lists/lua-l/2008-05/msg00666.html */

#include <stddef.h>

size_t strlen(const char *s);

char *strchr(const char *s, int c);

char *strcpy(char *d, const char *s);

char *strncpy(char *d, const char *s, size_t n);

char *strcat(char *d, const char *s);

char *strncat(char *d, const char *s, size_t n);

int strcmp(const char *s1, const char *s2);

int strncmp(const char *s1, const char *s2, int n);

int strcoll(const char *s1, const char *s2);

size_t strcspn(const char *s, const char *reject);

void *memcpy(void *d, const void *s, size_t n);

int memcmp(const void *s1, const void *s2, size_t n);

char *strerror(int errnum);

char *strstr(const char *haystack, const char *needle);

size_t strspn(const char *s, const char *accept);

int toupper(int c);

int tolower(int c);

int isalpha(int c);

int isdigit(int c);

int isalnum(int c);

int islower(int c);

int isupper(int c);

int isspace(int c);

int isxdigit(int c);

int iscntrl(int c);

int isgraph(int c);

int ispunct(int c);

void *memchr(const void *ptr, int value, size_t num);

char *strpbrk(const char *s, const char *chars);

#endif /* __STRING_H */