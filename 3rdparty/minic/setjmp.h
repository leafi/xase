#ifndef __SETJMP_H
#define __SETJMP_H

/* "borrowed" from linux... need to put something proper here once i understand what i'm actually doing*/

struct __jmp_buf {
	unsigned long __rbx;
	unsigned long __rsp;
	unsigned long __rbp;
	unsigned long __r12;
	unsigned long __r13;
	unsigned long __r14;
	unsigned long __r15;
	unsigned long __rip;
};

typedef struct __jmp_buf jmp_buf[1];

int setjmp(jmp_buf);

void longjmp(jmp_buf, int);

#endif