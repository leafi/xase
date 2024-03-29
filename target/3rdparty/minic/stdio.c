#include <errno.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdint.h>
#include <limits.h>
#include <string.h>
#include <math.h>

#define uintmax_t unsigned long long
#define intmax_t long long

char _PDCLIB_digits[] = "0123456789abcdefghijklmnopqrstuvwxyz";

/* For _PDCLIB/print.c only; obsolete with ctype.h */
char _PDCLIB_Xdigits[] = "0123456789ABCDEF";

struct _PDCLIB_status_t
{
	int base;
	int flags;
	unsigned n;
	unsigned i;
	unsigned current;
	char *s;
	unsigned width;
	int prec;
	void *stream;
	va_list arg;
};

int sprintf(char *s, const char *format, ...) {
	// ripped from PDCLib
	int rc;
	va_list ap;
	va_start(ap, format);
	rc = vsnprintf(s, LONG_MAX, format, ap);
	va_end(ap);
	return rc;
}

const char * _PDCLIB_strtox_prelim( const char * p, char * sign, int * base )
{
    /* skipping leading whitespace */
    while ( isspace( *p ) ) ++p;
    /* determining / skipping sign */
    if ( *p != '+' && *p != '-' ) *sign = '+';
    else *sign = *(p++);
    /* determining base */
    if ( *p == '0' )
    {
        ++p;
        if ( ( *base == 0 || *base == 16 ) && ( *p == 'x' || *p == 'X' ) )
        {
            *base = 16;
            ++p;
            /* catching a border case here: "0x" followed by a non-digit should
               be parsed as the unprefixed zero.
               We have to "rewind" the parsing; having the base set to 16 if it
               was zero previously does not hurt, as the result is zero anyway.
            */
            if ( memchr( _PDCLIB_digits, tolower(*p), *base ) == NULL )
            {
                p -= 2;
            }
        }
        else if ( *base == 0 )
        {
            *base = 8;
        }
        else
        {
            --p;
        }
    }
    else if ( ! *base )
    {
        *base = 10;
    }
    return ( ( *base >= 2 ) && ( *base <= 36 ) ) ? p : NULL;
}

uintmax_t _PDCLIB_strtox_main( const char ** p, unsigned int base, uintmax_t error, uintmax_t limval, int limdigit, char * sign )
{
    uintmax_t rc = 0;
    int digit = -1;
    const char * x;
    while ( ( x = memchr( _PDCLIB_digits, tolower(**p), base ) ) != NULL )
    {
        digit = x - _PDCLIB_digits;
        if ( ( rc < limval ) || ( ( rc == limval ) && ( digit <= limdigit ) ) )
        {
            rc = rc * base + (unsigned)digit;
            ++(*p);
        }
        else
        {
            errno = ERANGE;
            /* TODO: Only if endptr != NULL - but do we really want *another* parameter? */
            /* TODO: Earlier version was missing tolower() here but was not caught by tests */
            while ( memchr( _PDCLIB_digits, tolower(**p), base ) != NULL ) ++(*p);
            /* TODO: This is ugly, but keeps caller from negating the error value */
            *sign = '+';
            return error;
        }
    }
    if ( digit == -1 )
    {
        *p = NULL;
        return 0;
    }
    return rc;
}

long int strtol( const char * s, char ** endptr, int base )
{
    long int rc;
    char sign = '+';
    const char * p = _PDCLIB_strtox_prelim( s, &sign, &base );
    if ( base < 2 || base > 36 ) return 0;
    if ( sign == '+' )
    {
        rc = (long int)_PDCLIB_strtox_main( &p, (unsigned)base, (uintmax_t)LONG_MAX, (uintmax_t)( LONG_MAX / base ), (int)( LONG_MAX % base ), &sign );
    }
    else
    {
        rc = (long int)_PDCLIB_strtox_main( &p, (unsigned)base, (uintmax_t)LONG_MIN, (uintmax_t)( LONG_MIN / -base ), (int)( -( LONG_MIN % base ) ), &sign );
    }
    if ( endptr != NULL ) *endptr = ( p != NULL ) ? (char *) p : (char *) s;
    return ( sign == '+' ) ? rc : -rc;
}

/* This macro delivers a given character to either a memory buffer or a stream,
   depending on the contents of 'status' (struct _PDCLIB_status_t).
   x - the character to be delivered
   i - pointer to number of characters already delivered in this call
   n - pointer to maximum number of characters to be delivered in this call
   s - the buffer into which the character shall be delivered
*/

/* !!! LEAFI HACK !!!: Stream is always null (removes ref to _PDCLIB_putc_unlocked) */

#define PUT( x ) \
do { \
    int character = x; \
    if ( status->i < status->n ) { \
    	status->s[status->i] = character; \
    } \
    ++(status->i); \
} while ( 0 )

/* Using an integer's bits as flags for both the conversion flags and length
   modifiers.
*/
/* FIXME: one too many flags to work on a 16-bit machine, join some (e.g. the
          width flags) into a combined field.
*/
#define E_minus    (1<<0)
#define E_plus     (1<<1)
#define E_alt      (1<<2)
#define E_space    (1<<3)
#define E_zero     (1<<4)
#define E_done     (1<<5)

#define E_char     (1<<6)
#define E_short    (1<<7)
#define E_long     (1<<8)
#define E_llong    (1<<9)
#define E_intmax   (1<<10)
#define E_size     (1<<11)
#define E_ptrdiff  (1<<12)
#define E_intptr   (1<<13)

#define E_ldouble  (1<<14)

#define E_lower    (1<<15)
#define E_unsigned (1<<16)

#define E_TYPES (E_char | E_short | E_long | E_llong | E_intmax \
                | E_size | E_ptrdiff | E_intptr)

/* Maximum number of output characters = 
 *   number of bits in (u)intmax_t / number of bits per character in smallest 
 *   base. Smallest base is octal, 3 bits/char.
 *
 * Additionally require 2 extra characters for prefixes
 */
static const size_t maxIntLen = sizeof(intmax_t) * CHAR_BIT / 3 + 1;


static void int2base( uintmax_t value, struct _PDCLIB_status_t * status )
{
    char sign = 0;
    if ( ! ( status->flags & E_unsigned ) ) 
    {
        intmax_t signval = (intmax_t) value;
        bool negative = signval < 0;
        value = signval < 0 ? -signval : signval;

        if ( negative ) 
        {
            sign = '-';
        } 
        else if ( status->flags & E_plus ) 
        {
            sign = '+';
        }
        else if (status->flags & E_space )
        {
            sign = ' ';
        }
    }

    // The user could theoretically ask for a silly buffer length here. 
    // Perhaps after a certain size we should malloc? Or do we refuse to protect
    // them from their own stupidity?
    size_t bufLen = (status->width > maxIntLen ? status->width : maxIntLen) + 2;
    char outbuf[bufLen];
    char * outend = outbuf + bufLen;
    int written = 0;

    // Build up our output string - backwards
    {
        const char * digits = (status->flags & E_lower) ? 
                                _PDCLIB_digits : _PDCLIB_Xdigits;
        uintmax_t remaining = value;
        if(status->prec != 0 || remaining != 0) do {
            uintmax_t digit = remaining % status->base;
            remaining /= status->base;

            outend[-++written] = digits[digit];
        } while(remaining != 0);
    }

    // Pad field out to the precision specification
    while( (long) written < status->prec ) outend[-++written] = '0';

    // If a field width specified, and zero padding was requested, then pad to
    // the field width
    unsigned padding = 0;
    if ( ( ! ( status->flags & E_minus ) ) && ( status->flags & E_zero ) )    
    {
        while( written < (int) status->width ) 
        {
            outend[-++written] = '0';
            padding++;
        }
    }

    // Prefixes
    if ( sign != 0 )
    {
        if ( padding == 0 ) written++;
        outend[-written] = sign;
    }
    else if ( status->flags & E_alt )
    {
        switch ( status->base )
        {
            case 8:
                if ( outend[-written] != '0' ) outend[-++written] = '0';
                break;
            case 16:
                // No prefix if zero
                if ( value == 0 ) break;

                written += padding < 2 ? 2 - padding : 0;
                outend[-written    ] = '0';
                outend[-written + 1] = (status->flags & E_lower) ? 'x' : 'X';
                break;
            default:
                break;
        }
    }

    // Space padding to field width
    if ( ! ( status->flags & ( E_minus | E_zero ) ) )
    {
        while( written < (int) status->width ) outend[-++written] = ' ';
    }

    // Write output
    status->current = written;
    while ( written )
        PUT( outend[-written--] );
}

static void printstr( const char * str, struct _PDCLIB_status_t * status )
{
    if ( status->width == 0 || status->flags & E_minus )
    {
        // Simple case or left justification
        while ( str[status->current] && 
            ( status->prec < 0 || (long)status->current < status->prec ) )
        {
            PUT( str[status->current++] );
        }

        while( status->current < status->width ) 
        {
            PUT( ' ' );
            status->current++;
        }
    } else {
        // Right justification
        size_t len = status->prec >= 0 ? strnlen( str, status->prec ) 
                                       :  strlen( str );
        int padding = status->width - len;
        while((long)status->current < padding)
        {
            PUT( ' ' );
            status->current++;
        }

        for( size_t i = 0; i != len; i++ )
        {
            PUT( str[i] );
            status->current++;
        }
    }
}

static void printchar( char chr, struct _PDCLIB_status_t * status )
{
    if( ! ( status->flags & E_minus ) )
    {
        // Right justification
        for( ; status->current + 1 < status->width; status->current++)
        {
            PUT( ' ' );
        }
        PUT( chr );
        status->current++;
    } else {
        // Left justification
        PUT( chr );
        status->current++;

        for( ; status->current < status->width; status->current++)
        {
            PUT( ' ' );
        }
    }
}

const char * _PDCLIB_print( const char * spec, struct _PDCLIB_status_t * status )
{
    const char * orig_spec = spec;
    if ( *(++spec) == '%' )
    {
        /* %% -> print single '%' */
        PUT( *spec );
        return ++spec;
    }
    /* Initializing status structure */
    status->flags = 0;
    status->base  = 0;
    status->current  = 0;
    status->width = 0;
    status->prec  = EOF;

    /* First come 0..n flags */
    do
    {
        switch ( *spec )
        {
            case '-':
                /* left-aligned output */
                status->flags |= E_minus;
                ++spec;
                break;
            case '+':
                /* positive numbers prefixed with '+' */
                status->flags |= E_plus;
                ++spec;
                break;
            case '#':
                /* alternative format (leading 0x for hex, 0 for octal) */
                status->flags |= E_alt;
                ++spec;
                break;
            case ' ':
                /* positive numbers prefixed with ' ' */
                status->flags |= E_space;
                ++spec;
                break;
            case '0':
                /* right-aligned padding done with '0' instead of ' ' */
                status->flags |= E_zero;
                ++spec;
                break;
            default:
                /* not a flag, exit flag parsing */
                status->flags |= E_done;
                break;
        }
    } while ( ! ( status->flags & E_done ) );

    /* Optional field width */
    if ( *spec == '*' )
    {
        /* Retrieve width value from argument stack */
        int width = va_arg( status->arg, int );
        if ( width < 0 )
        {
            status->flags |= E_minus;
            status->width = abs( width );
        }
        else
        {
            status->width = width;
        }
        ++spec;
    }
    else
    {
        /* If a width is given, strtol() will return its value. If not given,
           strtol() will return zero. In both cases, endptr will point to the
           rest of the conversion specifier - just what we need.
        */
        status->width = (int)strtol( spec, (char**)&spec, 10 );
    }

    /* Optional precision */
    if ( *spec == '.' )
    {
        ++spec;
        if ( *spec == '*' )
        {
            /* Retrieve precision value from argument stack. A negative value
               is as if no precision is given - as precision is initalized to
               EOF (negative), there is no need for testing for negative here.
            */
            status->prec = va_arg( status->arg, int );
            ++spec;
        }
        else
        {
            status->prec = (int)strtol( spec, (char**) &spec, 10 );
        }
        /* Having a precision cancels out any zero flag. */
        status->flags &= ~E_zero;
    }

    /* Optional length modifier
       We step one character ahead in any case, and step back only if we find
       there has been no length modifier (or step ahead another character if it
       has been "hh" or "ll").
    */
    switch ( *(spec++) )
    {
        case 'h':
            if ( *spec == 'h' )
            {
                /* hh -> char */
                status->flags |= E_char;
                ++spec;
            }
            else
            {
                /* h -> short */
                status->flags |= E_short;
            }
            break;
        case 'l':
            if ( *spec == 'l' )
            {
                /* ll -> long long */
                status->flags |= E_llong;
                ++spec;
            }
            else
            {
                /* k -> long */
                status->flags |= E_long;
            }
            break;
        case 'j':
            /* j -> intmax_t, which might or might not be long long */
            status->flags |= E_intmax;
            break;
        case 'z':
            /* z -> size_t, which might or might not be unsigned int */
            status->flags |= E_size;
            break;
        case 't':
            /* t -> ptrdiff_t, which might or might not be long */
            status->flags |= E_ptrdiff;
            break;
        case 'L':
            /* L -> long double */
            status->flags |= E_ldouble;
            break;
        default:
            --spec;
            break;
    }

    /* Conversion specifier */
    switch ( *spec )
    {
        case 'd':
            /* FALLTHROUGH */
        case 'i':
            status->base = 10;
            break;
        case 'o':
            status->base = 8;
            status->flags |= E_unsigned;
            break;
        case 'u':
            status->base = 10;
            status->flags |= E_unsigned;
            break;
        case 'x':
            status->base = 16;
            status->flags |= ( E_lower | E_unsigned );
            break;
        case 'X':
            status->base = 16;
            status->flags |= E_unsigned;
            break;
        case 'f':
        case 'F':
        case 'e':
        case 'E':
        case 'g':
        case 'G':
            break;
        case 'a':
        case 'A':
            break;
        case 'c':
            /* TODO: wide chars. */
            printchar( va_arg( status->arg, int ), status );
            return ++spec;
        case 's':
            /* TODO: wide chars. */
            {
                char * s = va_arg( status->arg, char * );
                printstr( s, status );
                return ++spec;
            }
        case 'p':
            status->base = 16;
            status->flags |= ( E_lower | E_unsigned | E_alt | E_intptr );
            break;
        case 'n':
           {
               int * val = va_arg( status->arg, int * );
               *val = status->i;
               return ++spec;
           }
        default:
            /* No conversion specifier. Bad conversion. */
            return orig_spec;
    }
    /* Do the actual output based on our findings */
    if ( status->base != 0 )
    {
        /* Integer conversions */
        /* TODO: Check for invalid flag combinations. */
        if ( status->flags & E_unsigned )
        {
            uintmax_t value;
            switch ( status->flags & E_TYPES )
            {
                case E_char:
                    value = (uintmax_t)(unsigned char)va_arg( status->arg, int );
                    break;
                case E_short:
                    value = (uintmax_t)(unsigned short)va_arg( status->arg, int );
                    break;
                case 0:
                    value = (uintmax_t)va_arg( status->arg, unsigned int );
                    break;
                case E_long:
                    value = (uintmax_t)va_arg( status->arg, unsigned long );
                    break;
                case E_llong:
                    value = (uintmax_t)va_arg( status->arg, unsigned long long );
                    break;
                case E_size:
                    value = (uintmax_t)va_arg( status->arg, size_t );
                    break;
                case E_intptr:
                    value = (uintmax_t)va_arg( status->arg, uintptr_t );
                    break;
                case E_ptrdiff:
                    value = (uintmax_t)va_arg( status->arg, ptrdiff_t );
                    break;
                case E_intmax:
                    value = va_arg( status->arg, uintmax_t );
            }
            int2base( value, status );
        }
        else
        {
            switch ( status->flags & E_TYPES )
            {
                case E_char:
                    int2base( (intmax_t)(char)va_arg( status->arg, int ), status );
                    break;
                case E_short:
                    int2base( (intmax_t)(short)va_arg( status->arg, int ), status );
                    break;
                case 0:
                    int2base( (intmax_t)va_arg( status->arg, int ), status );
                    break;
                case E_long:
                    int2base( (intmax_t)va_arg( status->arg, long ), status );
                    break;
                case E_llong:
                    int2base( (intmax_t)va_arg( status->arg, long long ), status );
                    break;
                case E_size:
                    int2base( (intmax_t)va_arg( status->arg, size_t ), status );
                    break;
                case E_intptr:
                    int2base( (intmax_t)va_arg( status->arg, intptr_t ), status );
                    break;
                case E_ptrdiff:
                    int2base( (intmax_t)va_arg( status->arg, ptrdiff_t ), status );
                    break;
                case E_intmax:
                    int2base( va_arg( status->arg, intmax_t ), status );
                    break;
            }
        }
        if ( status->flags & E_minus )
        {
            while ( status->current < status->width )
            {
                PUT( ' ' );
                ++(status->current);
            }
        }
        if ( status->i >= status->n && status->n > 0 )
        {
            status->s[status->n - 1] = '\0';
        }
    }
    return ++spec;
}

int vsnprintf(char *s, size_t n, const char *format, va_list arg) {
	// ripped from PDCLib
    /* TODO: This function should interpret format as multibyte characters.  */
    struct _PDCLIB_status_t status;
    status.base = 0;
    status.flags = 0;
    status.n = n;
    status.i = 0;
    status.current = 0;
    status.s = s;
    status.width = 0;
    status.prec = 0;
    status.stream = NULL;
    va_copy( status.arg, arg );

    while ( *format != '\0' )
    {
        const char * rc;
        if ( ( *format != '%' ) || ( ( rc = _PDCLIB_print( format, &status ) ) == format ) )
        {
            /* No conversion specifier, print verbatim */
            if ( status.i < n )
            {
                s[ status.i ] = *format;
            }
            status.i++;
            format++;
        }
        else
        {
            /* Continue parsing after conversion specifier */
            format = rc;
        }
    }
    if ( status.i  < n )
    {
        s[ status.i ] = '\0';
    }
    va_end( status.arg );
    return status.i;
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
