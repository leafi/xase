#include <stdlib.h>

void abort() {
	// idk what to do here...
}

char *getenv(const char *name) {
	return NULL;
}

void *realloc3(void *ptr, size_t osize, size_t nsize) {
	if (nsize == 0) {
		free(ptr);
		return NULL;
	} else if (ptr == NULL) {
		return malloc(nsize);
	} else {
		if (osize < nsize) {
			void *newPtr = malloc(nsize);
			int i = 0;
			char* op = (char *)ptr;
			char* np = (char *)newPtr;
			for (; i < osize; i++) {
				*np = *op;
				op++;
				np++;
			}
			return newPtr;
		} else {
			return ptr; // don't care, then!
		}
	}
}

/*void free(void *ptr);

void *malloc(size_t size);*/
