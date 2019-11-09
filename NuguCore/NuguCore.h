//
//  NuguCore.h
//  NuguCore
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

#import "ObjcExceptionCatcher.h"
#import "opus.h"
#import "opus_custom.h"
#import "opus_defines.h"
#import "opus_multistream.h"
#import "opus_projection.h"
#import "opus_types.h"

//! Project version number for NuguCore.
FOUNDATION_EXPORT double NuguCoreVersionNumber;

//! Project version string for NuguCore.
FOUNDATION_EXPORT const unsigned char NuguCoreVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <NuguCore/PublicHeader.h>


