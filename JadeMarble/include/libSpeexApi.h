/**
 * \mainpage
 * \file libSpeexApi API declarations
 *
 * Copyright (C) 2019 SKTelecom
 *
 * $Id: libSpeexApi.h 2019-01-16 00:00:00 Exp $
 */

#ifndef _LIBSPEEXAPI_H_
#define _LIBSPEEXAPI_H_

#ifdef WIN32
#include <windows.h>
#endif

#ifndef WIN32
#include <sys/time.h>
#endif
#include "libtypes.h"
#include "libdefines.h"
#include "libexports.h"

/*
//input/output data type: ref. format/wave_format.h
typedef enum {
	DATA_LINEAR_PCM16	= 0,
	DATA_LINEAR_PCM8	= 1,
	DATA_A_LAW			= 2,
	DATA_MU_LAW			= 3,
	DATA_SPEEX_STREAM	= 4,
	DATA_FEAT_STREAM	= 5,
}  DATA_TYPE;
*/

/** End point detection Engine Interface */
typedef void* SpeexHandle;

#ifdef __cplusplus
extern "C" {
#endif

/**
 * \brief .
 *
 * <b></b><br>
 *
 *
 * \param	handle
 *
 * \return						<ul>
 *								</ul>
 *
 * \sa		speexSTART()
 *
 */
LIBPUBFUN SpeexHandle LIBCALL speexSTART
(
	myint		nSampleRate,
	myint		inputType,	//input data type
	myint		outputType	//output data type
);

/**
 * \brief .
 *
 * <b></b><br>
 *
 *
 * \param	handle
 *
 * \return						<ul>
 *								</ul>
 *
 * \sa		speexRELEASE()
 *
 */
LIBPUBFUN myint LIBCALL speexRELEASE(SpeexHandle handle);

/**
 * \brief .
 *
 * <b></b><br>
 *
 *
 * \param	handle
 *
 * \return						<ul>
 *								</ul>
 *
 * \sa		speexRESET()
 *
 */
LIBPUBFUN myint LIBCALL speexRESET(SpeexHandle handle);

/**
 * \brief .
 *
 * <b></b><br>
 *
 *
 * \param	handle
 *
 * \return						<ul>
 *								</ul>
 *
 * \sa		speexRUN()
 *
 */
LIBPUBFUN myint LIBCALL speexRUN
(
	SpeexHandle	handle,
	const myptr	pSpeechData,
	const myint	n_len,
	const myint	n_beos
);

LIBPUBFUN myint LIBCALL speexGetOutputDataSize(SpeexHandle handle);

LIBPUBFUN myint LIBCALL speexGetOutputData
(
	SpeexHandle	handle,
	mychar*		pOutData,
	myint		n_size
);

LIBPUBFUN myint LIBCALL speexGetVersion( void );

/**
 * @}
 */

#ifdef __cplusplus
}
#endif

#endif /* _LIBVADAPI_H_ */
