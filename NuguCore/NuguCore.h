//
//  NuguCore.h
//  NuguCore
//
//  Created by yonghoonKwon on 2019/11/08.
//  Copyright (c) 2019 SK Telecom Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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
#import "opus_defines.h"
#import "opus_multistream.h"
#import "opus_projection.h"
#import "opus_types.h"

//! Project version number for NuguCore.
FOUNDATION_EXPORT double NuguCoreVersionNumber;

//! Project version string for NuguCore.
FOUNDATION_EXPORT const unsigned char NuguCoreVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <NuguCore/PublicHeader.h>


