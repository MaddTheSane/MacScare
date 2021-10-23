//
//  GlkStatus.m
//  CocoaGlk
//
//  Created by Andrew Hunter on Sat Jun 14 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "GlkStatus.h"
#import "glkInternal.h"
#import "GlkWriteBufferedStream.h"


@implementation GlkStatus

- (id) init {
    self = [super init];

    if (self) {
        rootWindow = firstWindow = NULL;
        firstStream = NULL;
        currentStream = NULL;

        regFunc = NULL;
        unregFunc = NULL;
    }

    return self;
}

- (void) dealloc {
    while (firstWindow != NULL) {
        winid_t next = firstWindow->nextWindow;

        [self removeStream: firstWindow->stream];        
        [firstWindow->win release];
        
        free(firstWindow);

        firstWindow = next;
    }

    while (firstStream != NULL) {
        strid_t next = firstStream->next;

        [firstStream->stream release];
        free(firstStream);

        firstStream = next;
    }

    while (firstRef != NULL) {
        frefid_t next = firstRef->next;

        [firstRef->ref release];
        free(firstRef);

        firstRef = next;
    }
    
    [super dealloc];
}

// == Windows ==
- (winid_t) rootWindow {
    return rootWindow;
}

- (void)    setRootWindow: (winid_t) win {
    rootWindow = win;
}

- (winid_t) newWindow: (GlkWindow*) win {
    winid_t newWin = [self findIdForWindow: win];

    if (newWin != NULL) {
        return newWin;
    }

    newWin = malloc(sizeof(struct glk_window_struct));

    newWin->lastWindow = NULL;
    newWin->nextWindow = firstWindow;

    newWin->win    = [win retain];
    newWin->stream = [self newStream: [[[GlkWriteBufferedStream allocWithZone: [self zone]] initWithStream: [win stream]] autorelease]];
    newWin->echostream = NULL;

    if (firstWindow != NULL) {
        firstWindow->lastWindow = newWin;
    }
    
    firstWindow = newWin;

    if (regFunc) {
        newWin->giRock = (regFunc)(newWin, gidisp_Class_Window);
    }
    
    return newWin;
}

- (void) removeWindow: (winid_t) win {
    if (unregFunc) {
        (unregFunc)(win, gidisp_Class_Window, win->giRock);
    }

    [self removeStream: win->stream];

    [win->win release];
    
    if (win->lastWindow != NULL) {
        win->lastWindow->nextWindow = win->nextWindow;
    } else {
        firstWindow = win->nextWindow;
    }

    if (win->nextWindow != NULL) {
        win->nextWindow->lastWindow = win->lastWindow;
    }

    if (win == rootWindow) {
        rootWindow = NULL;
    }

    free(win);
}

- (winid_t) firstWindow {
    return firstWindow;
}

- (winid_t) findIdForWindow: (GlkWindow*) win {
    winid_t thisId = firstWindow;

    while (thisId != NULL) {
        if ([win isEqualTo:thisId->win]) {
            return thisId;
        }
        
        thisId = thisId->nextWindow;
    }

    return NULL;
}

- (void) closeAllWindows {
    while (firstWindow != NULL) {
        winid_t next = firstWindow->nextWindow;

        if (firstWindow->win != nil) {
            [firstWindow->win close];
            [firstWindow->win release];
        }

        free(firstWindow);

        firstWindow = next;
    }
}

// == Streams ==
- (strid_t) newStream: (GlkStream*) stream {
    if (stream == nil) {
        return NULL;
    }
    
    strid_t newStr = malloc(sizeof(struct glk_stream_struct));

    newStr->stream = [stream retain];
    
    newStr->next = firstStream;
    newStr->last = NULL;

    if (firstStream != NULL) {
        firstStream->last = newStr;
    }
    
    firstStream = newStr;

    if (regFunc) {
        newStr->giRock = (regFunc)(newStr, gidisp_Class_Stream);
    }
    
    return newStr;
}

- (void) removeStream: (strid_t) str {
    if (unregFunc) {
        (unregFunc)(str, gidisp_Class_Stream, str->giRock);
    }

    [str->stream release];

    if (str->last != NULL) {
        str->last->next = str->next;
    } else {
        firstStream = str->next;
    }
    
    if (str->next != NULL) {
        str->next->last = str->last;
    }

    free(str);
}

- (strid_t) firstStream {
    return firstStream;
}

- (strid_t) findIdForStream: (GlkStream*) stream {
    strid_t thisStream = firstStream;

    while (thisStream != NULL) {
        if ([thisStream->stream isEqualTo: stream]) {
            return thisStream;
        }
        
        thisStream = thisStream->next;
    }

    return NULL;
}

// == FileRefs ==
- (frefid_t) newFileRef: (GlkFileRef*) fileRef {
    if (fileRef == nil) {
        return NULL;
    }
    
    frefid_t newRef = malloc(sizeof(struct glk_fileref_struct));

    newRef->ref = [fileRef retain];

    newRef->next = firstRef;
    newRef->last = NULL;

    if (firstRef != NULL) {
        firstRef->last = newRef;
    }

    firstRef = newRef;

    if (regFunc) {
        newRef->giRock = (regFunc)(newRef, gidisp_Class_Fileref);
    }
    
    return newRef;
}

- (void) removeFileRef: (frefid_t) fref {
    if (unregFunc) {
        (unregFunc)(fref, gidisp_Class_Fileref, fref->giRock);
    }

    [fref->ref release];

    if (fref->last != NULL) {
        fref->last->next = fref->next;
    } else {
        firstRef = fref->next;
    }

    if (fref->next != NULL) {
        fref->next->last = fref->last;
    }

    free(fref);
}

- (frefid_t) firstRef {
    return firstRef;
}

- (frefid_t) findIdForFileRef: (GlkFileRef*) fref {
    frefid_t thisRef = firstRef;

    while (thisRef != NULL) {
        if ([thisRef->ref isEqualTo: fref]) {
            return thisRef;
        }

        thisRef = thisRef->next;
    }

    return NULL;
}

- (strid_t) currentStream {
    return currentStream;
}

- (void) setCurrentStream: (strid_t) str {
    currentStream = str;
}

// == Dispatch ==
- (void) setObjectRegistry: (glkDispatchRegFunc) rf
                     unreg: (glkDispatchUnregFunc) urf {
    regFunc   = rf;
    unregFunc = urf;

    if (regFunc) {
        // Register everything that already exists
        winid_t win  = firstWindow;
        strid_t str  = firstStream;
        frefid_t ref = firstRef;

        while (win != NULL) {
            win->giRock = (regFunc)(win, gidisp_Class_Window);
            win = win->nextWindow;
        }

        while (str != NULL) {
            str->giRock = (regFunc)(str, gidisp_Class_Stream);
            str = str->next;
        }

        while (ref != NULL) {
            ref->giRock = (regFunc)(ref, gidisp_Class_Fileref);
            ref = ref->next;
        }
    }
}

// == Blorb ==
- (void) setResourceMap: (giblorb_map_t*) map {
    resMap = map;
}

- (giblorb_map_t*) getResourceMap {
    return resMap;
}

@end
