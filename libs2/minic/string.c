
#include <string.h>

extern void printk(char* s);

size_t strlen(const char *s)
{
	size_t n = 0;
	while (*s != 0) {
		s++;
		n++;
	}
	return n;
}

char *strchr(const char *s, int c)
{
	while (*s != c && *s != 0) s++;
	return (*s == c) ? (char*)s : NULL;
}

char *strcpy(char *d, const char *s)
{
	char *t = d;
	while ((*t++ = *s++));
	return d;
}

char *strncpy(char *d, const char *s, size_t n)
{
	char *t = d;
	while (n-- && (*t++ = *s++));
#if 0
	if (n + 1) while (n--) *t++ = '-';
#endif
	return d;
}

char *strcat(char *d, const char *s)
{
	return strcpy(d + strlen(d), s);
}

char *strncat(char *d, const char *s, size_t n)
{
	return strncpy(d + strlen(d), s, n);
}

int strcmp(const char *s1, const char *s2)
{
	const unsigned char *a = s1;
	const unsigned char *b = s2;
	while (*a == *b && *a != 0 && *b != 0) a++, b++;
	return *a - *b;
}

int strncmp(const char *s1, const char *s2, int n)
{
	const unsigned char *a = s1;
	const unsigned char *b = s2;
	int j = 0;
	while (j < n && *a == *b && *a != 0 && *b != 0) a++, b++, j++;
	return *a - *b;
}

int strcoll(const char *s1, const char *s2)
{
	return strcmp(s1, s2);
}

size_t strcspn(const char *s, const char *reject)
{
	size_t n = 0;
	for (n = 0; *s; n++, s++)
	{
		const char *r;
		for (r = reject; *r; r++) if (*r == *s) return n;
	}
	return n;
}

void *memcpy(void *d, const void *s, size_t n)
{
	char *a = d;
	const char *b = s;
	while (n--) *a++ = *b++;
	return d;
}

int memcmp(const void *s1, const void *s2, size_t n)
{
	const unsigned char *a = s1;
	const unsigned char *b = s2;
	if (n == 0) return 0;
	while (--n && *a == *b) a++, b++;
	return *a - *b;
}

char* the_err = "ENOSYS";

char *strerror(int errnum) {
	return the_err;
}

/* ripped; 3-clause bsd, apple xnu (google is as google does) */
char *strstr(const char *in, const char *str)
{
	char c;
	size_t len;

	c = *str++;
	if (!c)
		return (char *)in;	// Trivial empty string case

	len = strlen(str);
	do {
		char sc;

		do {
			sc = *in++;
			if (!sc)
				return (char *)0;
		} while (sc != c);
	} while (strncmp(in, str, len) != 0);

	return (char *)(in - 1);
}

// me!
size_t strspn(const char *s, const char *accept) {
	const char *a = s;
	const char *b = accept;
	size_t n = 0;
	while (*a == *b) a++, b++, n++;
	return n;
}

int toupper(int c) {
	if (c >= 'a' && c <= 'z') {
		return c - 'a' + 'A';
	} else {
		return c;
	}
}

int tolower(int c) {
	if (c >= 'A' && c <= 'Z') {
		return c - 'A' + 'a';
	} else {
		return c;
	}
}

int isalpha(int c) {
	return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
}

int isdigit(int c) {
	return c >= '0' && c <= '9';
}

int isalnum(int c) {
	return isalpha(c) || isdigit(c);
}

int islower(int c) {
	return (c >= 'a' && c <= 'z');
}

int isupper(int c) {
	return (c >= 'A' && c <= 'Z');
}

int isspace(int c) {
	return c == ' ' || c == '\t' || c == '\n' || c == '\v' || c == '\f' || c == '\r';
}

int isxdigit(int c) {
	return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
}

int iscntrl(int c) {
	return (c >= 0x0 && c <= 0x1f) || c == 0x7f;
}

int isgraph(int c) {
	return c >= 0x21 && c <= 0x7e;
}

int ispunct(int c) {
	return (c >= 0x21 && c <= 0x2f) || (c >= 0x3a && c <= 0x40) || (c >= 0x5b && c <= 0x60) || (c >= 0x7b && c <= 0x7e);
}

void *memchr(const void *ptr, int value, size_t num) {
	unsigned char *p = (unsigned char *)ptr;

	for (int i = 0; i < num; i++) {
		if (*p == (unsigned char)value) {
			return (void *)p;
		}
		p++;
	}
	return NULL;
}

char *strpbrk(const char *s, const char *chars) {
	for (; *s != 0; s++) {
		for (const char *ohch; *ohch != 0; ohch++) {
			if (*s == *ohch) {
				return s;
			}
		}
	}
	if (*s == 0) {
		return NULL;
	}
}
