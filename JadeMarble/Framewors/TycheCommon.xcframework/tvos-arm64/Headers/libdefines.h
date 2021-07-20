/*
 * Summary: set of routines to process strings
 * Description: type and interfaces needed for the internal string handling
 *              of the library, especially UTF8 processing.
 *
 * Copy: See Copyright for the status of this software.
 *
 * Author: 
 */

#ifndef __LIB_DEFINES_H__
#define __LIB_DEFINES_H__

/*@{*/

#ifdef WIN32
#define DIR_SEPARATORCHAR		"\\"
#else
#define DIR_SEPARATORCHAR		"/"
#endif /* WIN32 */

#ifndef WIN32
#define _MAX_PATH				260		/* max. length of full pathname */
#define _MAX_DRIVE				256		/* max. length of drive component */
#define _MAX_DIR				256		/* max. length of path component */
#define _MAX_FNAME				256		/* max. length of file name component */
#define _MAX_EXT				256		/* max. length of extension component */
#endif /* WIN32 */

#ifndef WIN32
typedef unsigned char			u_char;
typedef unsigned short			u_short;
typedef unsigned int			u_int;
typedef unsigned long			u_long;
#endif /* WIN32 */

/* A wrapper for non-functional statements (typically, unreached returns)
 * that some compilers insist on and others complain about.
 * The behavior should really be determined by the compiler, not the OS.
 */
#ifdef WIN32
#define UNREACHED_STATEMENT(statement)	statement
#else
#define UNREACHED_STATEMENT(statement)
#endif /* WIN32 */

/* Some support for OS-independent thread manipulation.
 */
#ifdef WIN32
#include <process.h>
#define THREAD_RET_TYPE			unsigned
#define THREAD_CALLING_CONVENTION	__stdcall
#define THREAD_RETURN			return 0
#else
#include <pthread.h>
#define THREAD_RET_TYPE			void *
#define THREAD_CALLING_CONVENTION
#define THREAD_RETURN			return NULL
#endif /* WIN32 */

#ifndef WIN32
#define _open					open
#define _read					read
#define _close					close
#define _strdup					strdup
#define _getcwd					getcwd
#define _stricmp				stricmp
#define _mkdir					mkdir
#define _chdir					chdir
#define _rmdir					rmdir
#define _unlink					unlink
#define _tzset					tzset
#define _access					access
#define _chmod					chmod
#define _stat					stat
#endif /* WIN32 */

#ifdef WIN32
#define strcasecmp				_stricmp
#define strncasecmp				_strnicmp
#endif /* WIN32 */

#ifndef MAX
#define	MAX( a, b )				( ( ( a ) > ( b ) ) ? ( a ) : ( b ) )
#endif
#ifndef MIN
#define	MIN( a, b )				( ( ( a ) < ( b ) ) ? ( a ) : ( b ) )
#endif

#ifndef ARRAY_DIM
#define ARRAY_DIM( a )			( sizeof( a ) / sizeof( *( a ) ) )
#endif

/*@}*/

#endif /* __LIB_DEFINES_H__ */
