#include <stddef.h>
#include <stdio.h>

int sprintf(char *buf, const char *fmt, ...) {
	// I don't have even the slightest clue how to implement this! Nor how to use '...' args!!
	buf[0] = '?';
	buf[1] = 0;
	return 1;
}

FILE *fopen(const char *filename, const char *mode) {
	return NULL;
}

int fclose(FILE *f) {
	// sure, whatever
	return 0;
}

int feof(FILE *stream) {
	return 1; // yes is eof
}

size_t fread(void *dst, size_t elementSize, size_t elementCount, FILE *f) {
	return 0;
}

int getc(FILE *f) {
	return EOF;
}

int ferror(FILE *stream) {
	return 1;
}
