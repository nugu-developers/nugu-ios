/**
 * \mainpage
 * \file libVadApi API declarations
 *
 * Copyright (C) 2017 SKTelecom
 *
 * $Id: libVadApi.h 2017-07-17 00:00:00 Exp $
 */

#ifndef _LIBVADAPI_H_
#define _LIBVADAPI_H_

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
typedef void* EpdHandle;

#ifdef __cplusplus
extern "C" {
#endif

LIBPUBFUN int LIBCALL setMaxSpeechDur
(
	EpdHandle	handle,
	const int	nMaxSpeechDur,
	const int	nTimeOut,
	const int	nPauseLen
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
 * \sa		epdClientChannelSTART()
 *
 */
LIBPUBFUN EpdHandle LIBCALL epdClientChannelSTART
(
	const char* BinaryPath,
	int		nSampleRate,
	int		n_idat,	//input data type
	int		n_odat,	//output data type
	int		e_flag,	//EPD flag
	int		n_mdur,	//maximum speech duration (sec)
	int		n_tout,	//time-out duration (sec)
	int		e_plen	//pause length to detect end-point of speech period (msec) : unused
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
 * \sa		epdClientChannelRELEASE()
 *
 */
LIBPUBFUN int LIBCALL epdClientChannelRELEASE(EpdHandle handle);

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
 * \sa		epdClientChannelRESET()
 *
 */
LIBPUBFUN int LIBCALL epdClientChannelRESET(EpdHandle handle, int EPDMode);

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
 * \sa		epdClientChannelRESTART()
 *
 */
LIBPUBFUN int LIBCALL epdClientChannelRESTART(EpdHandle handle);

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
 * \sa		epdClientChannelPRERUN()
 *
 */
LIBPUBFUN int LIBCALL epdClientChannelPRERUN
(
	EpdHandle	handle,
	const void*	pSpeechData,
	const int	n_len
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
 * \sa		epdClientChannelRUN()
 *
 */
LIBPUBFUN int LIBCALL epdClientChannelRUN
(
	EpdHandle	handle,
	const void*	pSpeechData,
	const int	n_len,
	const int	n_beos
);

LIBPUBFUN int LIBCALL epdClientChannelGetOutputDataSize(EpdHandle handle);

LIBPUBFUN int LIBCALL epdClientChannelGetOutputData
(
	EpdHandle	handle,
	char*		pOutData,
	int			n_size
);

/**
 *	get signal amplitude of last input pcm
 *
 *	@return signal amplitude of last input pcm
 */
LIBPUBFUN int LIBCALL epdClientChannelGetSignalAmplitude
(
	EpdHandle	handle
);

/**
 *	get speech amplitude of last input pcm
 *
 *	@return speech amplitude of last input pcm
 */
LIBPUBFUN int LIBCALL epdClientChannelGetSpeechAmplitude
(
	EpdHandle	handle
);

/**
 *	get local SNR
 *
 *	@return local SNR.
 */
/*
LIBPUBFUN int LIBCALL epdClientChannelGetLocalSNR
(
	EpdHandle	handle
);
*/

LIBPUBFUN int LIBCALL epdClientGetSpeechStartDetectPoint(EpdHandle handle);
LIBPUBFUN int LIBCALL epdClientGetSpeechEndDetectPoint(EpdHandle handle);
LIBPUBFUN int LIBCALL epdClientGetSpeechStartPoint(EpdHandle handle, int margin);
LIBPUBFUN int LIBCALL epdClientGetSpeechEndPoint(EpdHandle handle, int margin);

/**
 *	Get speech boundary positions in sample points.
 *
 *	@return return 0 if speech boundary points were returned successfully, otherwise return -1.
 */
LIBPUBFUN int LIBCALL epdClientChannelGetSpeechBoundary
(
	EpdHandle	handle,
	int*		nStartPoint,
	int*		nEndPoint,
	const int	nStartMarginMSec,
	const int	nEndMarginMSec
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
 * \sa		epdClientSaveRecordedSpeechData()
 *
 */
LIBPUBFUN int LIBCALL epdClientSaveRecordedSpeechData
(
	EpdHandle	handle,
	const char*	c_path,
	const char*	c_file
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
 * \sa		epdClientSaveEpdSpeechData()
 *
 */
LIBPUBFUN int LIBCALL epdClientSaveEpdSpeechData
(
	EpdHandle	handle,
	const char*	c_path,
	const char*	c_file
);

LIBPUBFUN int LIBCALL epdClientGetConsecutivePauseLength(EpdHandle handle);

LIBPUBFUN int LIBCALL epdClientGetInputDataSize(EpdHandle handle);

LIBPUBFUN int LIBCALL epdClientGetInputData(EpdHandle handle, char* buf, int offset, int len);

LIBPUBFUN int LIBCALL epdClientSetEPDStatus(EpdHandle handle, int newStatus);

LIBPUBFUN int LIBCALL epdClientSetNoiseMaskingLevel(EpdHandle handle, float avgBackgroundPwr);

LIBPUBFUN int LIBCALL epdClientSetModelName(EpdHandle handle, const char* modelName);

LIBPUBFUN int LIBCALL epdClientGetVADInfo(EpdHandle handle, int n_VADInfo, float* VADInfo);

//input param : none
//return value: current threshold for Start-Of-Speech (SOS)
LIBPUBFUN float LIBCALL epdClientGetSOSThreshold(EpdHandle handle);

//input param : new threshold for SOS
//return value: previous SOS threshold
LIBPUBFUN float LIBCALL epdClientSetSOSThreshold(EpdHandle handle, float newThreshold);

//input param : none
//return value: current threshold for End-Of-Speech (EOS)
LIBPUBFUN float LIBCALL epdClientGetEOSThreshold(EpdHandle handle);

//input param : new threshold for EOS
//return value: previous EOS threshold
LIBPUBFUN float LIBCALL epdClientSetEOSThreshold(EpdHandle handle, float newThreshold);

///////////////////////////////////////////////////////////////////////////////////////////////////

LIBPUBFUN int LIBCALL epdClientGetVersion( void );

LIBPUBFUN int LIBCALL epdClientHasDefaultModel( void );

/**
 * @}
 */

#ifdef __cplusplus
}
#endif

#endif /* _LIBVADAPI_H_ */
