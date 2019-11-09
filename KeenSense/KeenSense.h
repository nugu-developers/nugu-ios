//
//  KeenSense.h
//  KeenSense
//
//  Created by yonghoonKwon on 2019/11/08.
//  Copyright © 2019 SK Telecom Co., Ltd. All rights reserved.
//

#ifdef __OBJC__
    #import <UIKit/UIKit.h>
#else
    #ifndef FOUNDATION_EXPORT
        #if defined(__cplusplus)
            #define FOUNDATION_EXPORT extern "C"
        #else
            #define FOUNDATION_EXPORT extern
        #endif
    #endif
#endif

#import "debugLog.h"
#import "libdefines.h"
#import "libexports.h"
#import "libSpeexApi.h"
#import "libtypes.h"
#import "libWakeupApi.h"

//! Project version number for KeenSense.
FOUNDATION_EXPORT double KeenSenseVersionNumber;

//! Project version string for KeenSense.
FOUNDATION_EXPORT const unsigned char KeenSenseVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <KeenSense/PublicHeader.h>


