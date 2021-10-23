//
//  GlkStatus.h
//  CocoaGlk
//
//  Created by Andrew Hunter on Sat Jun 14 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

// Status values for a running C GLK session

#import <Foundation/Foundation.h>

#import "GlkWindow.h"
#import "GlkStream.h"
#import "GlkFileRef.h"
#import "glkInternal.h"

#import "glk.h"
#import "gi_blorb.h"

@interface GlkStatus : NSObject {
    winid_t firstWindow;
    winid_t rootWindow;

    strid_t firstStream;
    strid_t currentStream;

    frefid_t firstRef;

    glkDispatchRegFunc   regFunc;
    glkDispatchUnregFunc unregFunc;

    giblorb_map_t* resMap;
}

// Windows
- (winid_t) rootWindow;
- (void)    setRootWindow: (winid_t) win;
- (winid_t) newWindow:     (GlkWindow*) win;
- (void)    removeWindow:  (winid_t) str;
- (winid_t) findIdForWindow: (GlkWindow*) win;
- (winid_t) firstWindow;

// Streams
- (strid_t) newStream: (GlkStream*) stream;
- (void)    removeStream: (strid_t) str;
- (strid_t) firstStream;
- (strid_t) findIdForStream: (GlkStream*) stream;

- (strid_t) currentStream;
- (void)    setCurrentStream: (strid_t) stream;

// Filerefs
- (frefid_t) newFileRef: (GlkFileRef*) fileRef;
- (void)     removeFileRef: (frefid_t) fref;
- (frefid_t) firstRef;
- (frefid_t) findIdForFileRef: (GlkFileRef*) fref;

// Dispatch layer
- (void) setObjectRegistry: (glkDispatchRegFunc) regFunc
                     unreg: (glkDispatchUnregFunc) unregFunc;
// Blorb layer
- (void)           setResourceMap: (giblorb_map_t*) map;
- (giblorb_map_t*) getResourceMap;

@end
