/*
 * Summary: set of routines to process strings
 * Description: type and interfaces needed for the internal string handling
 *              of the library, especially UTF8 processing.
 *
 * Copy: See Copyright for the status of this software.
 *
 * Author: 
 */

#ifndef __LIB_TYPES_H__
#define __LIB_TYPES_H__

#ifndef WIN32
#include <pthread.h>			/* For pthread_t */
#endif

/*@{*/

/************************************************************************
 *
 *
 * Basic vs Types
 *
 * The following vs types are used in the vs interfaces and
 * implementation to improve portability. The basic vs types are:
 *
 *   mychar        Locality dependent char type
 *   mybool        Boolean with values TRUE or FALSE
 *   mybyte        Single byte
 *   myint         Native platform int
 *   myunsigned    Native platform unsigned int
 *   myint32       32-bit int
 *   mylong        Native platform long
 *   myulong       Native platform unsigned long
 *   myflt32       32-bit IEEE float
 *   myflt64       64-bit IEEE float
 *   myptr         Untyped pointer
 *
 ************************************************************************
 */

/**
 * i386-* bindings
 */
typedef unsigned int			mybool;
typedef unsigned char			mybyte;
typedef char					mychar;
typedef short					myshort;
typedef int						myint;
typedef unsigned int			myunsigned;
typedef int						myint32;
typedef long					mylong;
typedef unsigned long			myulong;
typedef float					myflt32;
typedef double					myflt64;
typedef void *					myptr;
#ifdef WIN32
typedef mylong					mythreadID;
#else
typedef pthread_t				mythreadID;
#endif

/**
 * True and false for mybool values
 */
#ifndef FALSE
#define FALSE					0
#endif

#ifndef TRUE
#define TRUE					1
#endif

/*@}*/

#endif /* __LIB_TYPES_H__ */
