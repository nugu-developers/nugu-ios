//
//  JadeMarble.h
//  JadeMarble
//
//  Created by yonghoonKwon on 2019/11/08.
//  Copyright © 2019 SK Telecom Co., Ltd. All rights reserved.
//

#ifdef __OBJC__
    #import <Foundation/Foundation.h>
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
#import "libEpdApi.h"
#import "libexports.h"
#import "libSpeexApi.h"
#import "libtypes.h"

//! Project version number for JadeMarble.
FOUNDATION_EXPORT double JadeMarbleVersionNumber;

//! Project version string for JadeMarble.
FOUNDATION_EXPORT const unsigned char JadeMarbleVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <JadeMarble/PublicHeader.h>


