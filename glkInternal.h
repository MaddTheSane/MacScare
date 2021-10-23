//
//  glkInternal.h
//  CocoaGlk
//
//  Created by Andrew Hunter on Wed Jun 11 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "GlkWindow.h"
#import "GlkStream.h"
#import "GlkFileRef.h"

#import "glk.h"
#import "gi_dispa.h"
#import "gi_blorb.h"

// == Some convienience functions + macros ==

#define ourSession ((GlkSession*)[[[NSThread currentThread] threadDictionary] objectForKey: GlkSessionKey])
#define ourStatus  ((GlkStatus*)[[[NSThread currentThread] threadDictionary] objectForKey: GlkStatusKey])

// == The type definitions ==
struct glk_window_struct {
    GlkWindow* win;
    strid_t stream;
    strid_t echostream;

    char*   outBuf;
    int     bufLen;

    gidispatch_rock_t giRock;

    winid_t    nextWindow;
    winid_t    lastWindow;
};

struct glk_stream_struct {
    GlkStream* stream;

    gidispatch_rock_t giRock;

    strid_t next, last;
};

struct glk_fileref_struct {
    GlkFileRef* ref;

    gidispatch_rock_t giRock;

    frefid_t next, last;
};

// == Dispatch ==
typedef gidispatch_rock_t (*glkDispatchRegFunc)(void *obj, glui32 objclass);
typedef void (*glkDispatchUnregFunc)(void *obj, glui32 objclass, gidispatch_rock_t objrock);

// == Blorb ==


