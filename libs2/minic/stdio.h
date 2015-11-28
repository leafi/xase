#ifndef __STDIO_H
#define __STDIO_H

#include <stdarg.h>
#include <stddef.h>

struct _iobuf {
	char *_ptr;
	int _cnt;
	char *_base;
	int _flag;
	int _file;
	int _charbuf;
	int _bufsiz;
	char *_tmpfname;
};
typedef struct _iobuf FILE;

int sprintf(char *buf, const char *fmt, ...);

int vsnprintf(char *s, size_t n, const char *format, va_list arg);

FILE *fopen(const char *filename, const char *mode);
int fclose(FILE *f);

/* whatever, dude... */
#define BUFSIZ 512

int feof(FILE *stream);
size_t fread(void *dst, size_t elementSize, size_t elementCount, FILE *f);
int getc(FILE *f);

#define EOF (-1)

int ferror(FILE *stream);

#define L_tmpnam 16

#endif
