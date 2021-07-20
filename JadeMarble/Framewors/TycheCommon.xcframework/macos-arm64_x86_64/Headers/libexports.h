/*
 * Summary: macros for marking symbols as exportable/importable.
 * Description: macros for marking symbols as exportable/importable.
 *
 * Copy: See Copyright for the status of this software.
 *
 * Author: 
 */

#ifndef __LIB_EXPORTS_H__
#define __LIB_EXPORTS_H__

/**
 * LIBPUBFUN, LIBPUBVAR, LIBCALL
 *
 * Macros which declare an exportable function, an exportable variable and
 * the calling convention used for functions.
 *
 * Please use an extra block for every platform/compiler combination when
 * modifying this, rather than overlong #ifdef lines. This helps
 * readability as well as the fact that different compilers on the same
 * platform might need different definitions.
 */

/**
 * LIBPUBFUN:
 *
 * Macros which declare an exportable function
 */
#define LIBPUBFUN
/**
 * LIBPUBVAR:
 *
 * Macros which declare an exportable variable
 */
#define LIBPUBVAR extern
/**
 * LIBCALL:
 *
 * Macros which declare the called convention for exported functions
 */
#define LIBCALL

/** DOC_DISABLE */

/* Windows platform with MS compiler */
#if defined(_WIN32) && defined(_MSC_VER)
	#undef LIBPUBFUN
	#undef LIBPUBVAR
	#undef LIBCALL

	#if defined(IN_LIB) && !defined(LIB_STATIC)
		#define LIBPUBFUN __declspec(dllexport)
		#define LIBPUBVAR __declspec(dllexport)
	#else
		#define LIBPUBFUN
		#if !defined(LIB_STATIC)
			#define LIBPUBVAR __declspec(dllimport) extern
		#else
			#define LIBPUBVAR extern
		#endif
	#endif
	#if defined(LIB_FASTCALL)
		#define LIBCALL __fastcall
	#else
		#define LIBCALL __stdcall
	#endif
	#if !defined _REENTRANT
		#define _REENTRANT
	#endif
#endif

/* Windows platform with Borland compiler */
#if defined(_WIN32) && defined(__BORLANDC__)
	#undef LIBPUBFUN
	#undef LIBPUBVAR
	#undef LIBCALL

	#if defined(IN_LIB) && !defined(LIB_STATIC)
		#define LIBPUBFUN __declspec(dllexport)
		#define LIBPUBVAR __declspec(dllexport) extern
	#else
		#define LIBPUBFUN
		#if !defined(LIB_STATIC)
			#define LIBPUBVAR __declspec(dllimport) extern
		#else
			#define LIBPUBVAR extern
		#endif
	#endif
	#define LIBCALL __stdcall
	#if !defined _REENTRANT
		#define _REENTRANT
	#endif
#endif

/* Windows platform with GNU compiler (Mingw) */
#if defined(_WIN32) && defined(__MINGW32__)
	#undef LIBPUBFUN
	#undef LIBPUBVAR
	#undef LIBCALL

	/*
	 * if defined(IN_LIB) this raises problems on mingw with msys
	 * _imp__xmlFree listed as missing. Try to workaround the problem
	 * by also making that declaration when compiling client code.
	 */
	#if defined(IN_LIB) && !defined(LIB_STATIC)
		#define LIBPUBFUN __declspec(dllexport)
		#define LIBPUBVAR __declspec(dllexport)
	#else
		#define LIBPUBFUN
		#if !defined(LIB_STATIC)
			#define LIBPUBVAR __declspec(dllimport) extern
		#else
			#define LIBPUBVAR extern
		#endif
	#endif
	#define LIBCALL __stdcall
	#if !defined _REENTRANT
		#define _REENTRANT
	#endif
#endif

/* Cygwin platform, GNU compiler */
#if defined(_WIN32) && defined(__CYGWIN__)
	#undef LIBPUBFUN
	#undef LIBPUBVAR
	#undef LIBCALL

	#if defined(IN_LIB) && !defined(LIB_STATIC)
		#define LIBPUBFUN __declspec(dllexport)
		#define LIBPUBVAR __declspec(dllexport)
	#else
		#define LIBPUBFUN
		#if !defined(LIB_STATIC)
			#define LIBPUBVAR __declspec(dllimport) extern
		#else
			#define LIBPUBVAR
		#endif
	#endif
	#define LIBCALL __stdcall
	#if !defined _REENTRANT
		#define _REENTRANT
	#endif
#endif

/* Compatibility */
#if !defined(LIBLIB_DLL_IMPORT)
#define LIBLIB_DLL_IMPORT LIBPUBVAR
#endif

#endif /* __LIB_EXPORTS_H__ */
