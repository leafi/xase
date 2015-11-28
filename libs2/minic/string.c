
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

// vvv ripped from PDCLib vvv
size_t strnlen( const char * s, size_t maxlen )
{
	for( size_t len = 0; len != maxlen; len++ )
	{
		if(s[len] == '\0')
			return len;
	}
	return maxlen;
}

char *strchr(const char *s, int c)
{
	//printk("{1}");
	/*while (*s != c && *s != 0) s++;
	return (*s == c) ? (char*)s : NULL;*/
	do
	{
		if (*s == (char)c)
			return (char *)s;
	} while (*s++);
	return NULL;
}

char *strcpy(char *d, const char *s)
{
	printk("{2}");
	char *t = d;
	while ((*t++ = *s++));
	return d;
}

char *strncpy(char *d, const char *s, size_t n)
{
	printk("{3}");
	char *t = d;
	while (n-- && (*t++ = *s++));
#if 0
	if (n + 1) while (n--) *t++ = '-';
#endif
	return d;
}

char *strcat(char *d, const char *s)
{
	printk("{4}");
	return strcpy(d + strlen(d), s);
}

char *strncat(char *d, const char *s, size_t n)
{
	printk("{5}");
	return strncpy(d + strlen(d), s, n);
}

int strcmp(const char *s1, const char *s2)
{
	//printk("{6}");
	const char *a = s1;
	const char *b = s2;
	//while (*a == *b && *a != 0 && *b != 0) a++, b++;
	while ((*a) && (*a == *b))
	{
		++a;
		++b;
	}
	return ((unsigned char)*a) - ((unsigned char)*b);
}

int strncmp(const char *s1, const char *s2, int n)
{
	printk("{7}");
	const char *a = s1;
	const char *b = s2;
	int j = 0;
	while (j < n && *a == *b && *a != 0 && *b != 0) a++, b++, j++;
	return ((unsigned char)*a) - ((unsigned char)*b);
}

int strcoll(const char *s1, const char *s2)
{
	printk("{8}");
	return strcmp(s1, s2);
}

size_t strcspn(const char *s, const char *reject)
{
	printk("{9}");
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
	while (n--)
	{
		if (*a != *b)
			return *a - *b;
		++a;
		++b;
	}
	return 0;
}

char* the_err = "ENOSYS";

char *strerror(int errnum) {
	printk("{c}");
	return the_err;
}

/* ripped; 3-clause bsd, apple xnu (google is as google does) */
char *strstr(const char *in, const char *str)
{
	printk("{d}");
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
	printk("{e}");
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
	//printk("{f}");
	unsigned char *p = (unsigned char *)ptr;

	for (int i = 0; i < num; i++) {
		if (*p == (unsigned char)value) {
			return (void *)p;
		}
		p++;
	}
	return NULL;
}

/*char *strpbrk(const char *s, const char *chars) {
	printk("{g}");
	for (; *s != 0; s++) {
		for (const char *ohch; *ohch != 0; ohch++) {
			if (*s == *ohch) {
				return (char *)s;
			}
		}
	}
	if (*s == 0) {
		return NULL;
	}
}*/

char * strpbrk( const char * s1, const char * s2 )
{
    const char * p1 = s1;
    const char * p2;
    while ( *p1 )
    {
        p2 = s2;
        while ( *p2 )
        {
            if ( *p1 == *p2++ )
            {
                return (char *) p1;
            }
        }
        ++p1;
    }
    return NULL;
}
