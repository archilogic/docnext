//
//  DebugLog.h
//  docnext
//
//  Created by  on 12/02/20.
//  Copyright (c) 2012 Archilogic. All rights reserved.
//

#define DebugLogLevelError 1

#ifdef DebugLogLevelError
#define DebugLogLevelWarn 1
#endif

#ifdef DebugLogLevelWarn
#define DebugLogLevelInfo 1
#endif

#ifdef DebugLogLevelInfo
//#define DebugLogLevelDebug 1
#endif

#ifdef DebugLogLevelDebug
//#define DebugLogLevelVerbose 1
#endif

//#define PRELOAD 1
