/**
 * \mainpage
 * \file libWakeupApi API declarations
 *
 * Copyright (C) 2017 SKTelecom Speech Recognition Team (SRT) reserved.
 *
 * $Id: libWakeupApi.h 2017-05-25 00:00:00 Exp $
 */

#ifndef __WAKEUPAPI_H__
#define __WAKEUPAPI_H__

#ifdef WIN32
#include <windows.h>
#endif

#ifndef WIN32
#include <sys/time.h>
#endif

#include "libtypes.h"
#include "libdefines.h"
#include "libexports.h"

/** Wakeup Engine Interface */
#define WAKEUP_MODE_ONLINE              0
#define WAKEUP_MODE_VERIFIER            1
#define WAKEUP_MODE_ONLINE_CONNECTED    2

typedef void* WakeupHandle;

//return value of putAudio
#define PUTAUDIO_WAKEUP_ERROR          (-2)
#define PUTAUDIO_WAKEUP_REJECTED       (-1)
#define PUTAUDIO_WAKEUP_DETECTING       (0)
#define PUTAUDIO_WAKEUP_DETECTED        (1)
#define PUTAUDIO_WAKEUP_DETECTED_READY  (2)

#ifdef __cplusplus
extern "C" {
#endif

/**
 * \brief .
 *
 * <b></b><br>
 *
 *
 * \param	assetPath
 *
 * \return						<ul>
 *								</ul>
 *
 * \sa		Wakeup_Create()
 *
 */
#ifdef INCLUDE_WAKEUP_HEADER_MODEL
LIBPUBFUN WakeupHandle LIBCALL Wakeup_Create(int mode);
#else
LIBPUBFUN WakeupHandle LIBCALL Wakeup_Create(const char* c_netfile, const char* c_searchfile, int mode);
#endif

/**
 * \brief .
 *
 * <b></b><br>
 *
 *
 * \param	WakeupHandle
 *
 * \return						<ul>
 *								</ul>
 *
 * \sa		Wakeup_PutAudio()
 *
 */
LIBPUBFUN int LIBCALL Wakeup_PutAudio(WakeupHandle p, short* pcm, int len);

/**
 * \brief .
 *
 * <b></b><br>
 *
 *
 * \param	WakeupHandle
 *
 * \return						<ul>
 *								</ul>
 *
 * \sa		Wakeup_Reset()
 *
 */
LIBPUBFUN void LIBCALL Wakeup_Reset(WakeupHandle p);

/**
 * \brief .
 *
 * <b></b><br>
 *
 *
 * \param	WakeupHandle
 *
 * \return						<ul>
 *								</ul>
 *
 * \sa		Wakeup_RejectDetection()
 *
 */
LIBPUBFUN int LIBCALL Wakeup_RejectDetection(WakeupHandle p);

/**
 * \brief .
 *
 * <b></b><br>
 *
 *
 * \param	WakeupHandle
 *
 * \return						<ul>
 *								</ul>
 *
 * \sa		Wakeup_Destroy()
 *
 */
LIBPUBFUN void LIBCALL Wakeup_Destroy(WakeupHandle p);

LIBPUBFUN int LIBCALL Wakeup_GetStartTime(WakeupHandle p);

LIBPUBFUN int LIBCALL Wakeup_GetEndTime(WakeupHandle p);

LIBPUBFUN int LIBCALL Wakeup_GetDetectionTime(WakeupHandle p);

LIBPUBFUN int LIBCALL Wakeup_GetDelayTime(WakeupHandle p);

LIBPUBFUN int LIBCALL Wakeup_GetSmoothingTime(WakeupHandle p);

LIBPUBFUN int LIBCALL Wakeup_GetStartMargin(WakeupHandle p);

LIBPUBFUN void LIBCALL Wakeup_SetPresetMargin(WakeupHandle p, float margin, int sec);

LIBPUBFUN float LIBCALL Wakeup_GetScore(WakeupHandle p);

LIBPUBFUN float LIBCALL Wakeup_GetPower(WakeupHandle p);

LIBPUBFUN void LIBCALL  Wakeup_SetDebugOutput(int useDebugOutput);

#ifdef __cplusplus
}
#endif

#endif /* __WAKEUPAPI_H__ */
