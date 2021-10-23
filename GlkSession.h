//
//  GlkSession.h
//  CocoaGlk
//
//  Created by Andrew Hunter on Wed Jun 11 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

// The top-level Glk object: this represents a session with Glk

#import <Cocoa/Cocoa.h>
#import "glk.h"

@class GlkWindow;
@class GlkStream;
@class GlkFileRef;
@class GlkSchannel;
@class GlkEvent;

#define BUG(x) NSLog(x); abort()

// == Dictionary keys ==
extern NSString* GlkSessionKey;
extern NSString* GlkStatusKey;

// == Notifications ==
extern NSString* GlkFlushYourBuffers;

// == The session object ==
@interface GlkSession : NSObject {
    NSWindow*  sessionWindow;
    
    GlkWindow* rootWindow;
    GlkWindow* currentWindow;
    GlkStream* currentStream;

    GlkWindow* arrangeWindow;

    id objectValue;

    // Threading
    NSAutoreleasePool* threadPool;

    NSThread* mainThread;
    NSThread* glkThread;

    NSRunLoop* mainRunLoop;
    NSRunLoop* glkRunLoop;

    NSConnection*      mainthreadConnection;
    NSConnection*      glkthreadConnection;
    NSPort*            port1;
    NSPort*            port2;

    BOOL wakeup;

    // Save/open panels
    BOOL      savePanelFinished;
    NSString* savePanelFilename;

    // Styles
    NSFont*    fixedFont;
    NSFont*    propFont;

    glsi32 defaultHint[stylehint_NUMHINTS][style_NUMSTYLES];
    glsi32 styleHint[stylehint_NUMHINTS][style_NUMSTYLES];

    // Events
    NSMutableArray* eventQueue;
    GlkEvent*       currentEvent;

    // Images
    NSMutableArray* imageCache;
    NSMutableArray* imageCacheNumbers;
}

// User functions
- (void) glkMain: (NSString*)filename;

// Function to start things rolling
- (void) queueTheMusic: (NSString*)filename; // SoundTracker player for RISC OS ;-)

// Top-level glk functions
- (void) exit;
- (void) tick;
- (void) setInterruptHandler: (id) handler
                withSelector: (SEL) selector;

// Gestalt functions
- (glui32)  gestaltForSel: (glui32)  sel
                  withVal: (glui32)  val;
- (glui32)  gestaltForSel: (glui32)  sel
                  withVal: (glui32)  val
                      buf: (glui32*) buf
                   length: (glui32)  bufLen;

- (unsigned char) charToLower: (unsigned char) ch;
- (unsigned char) charToUpper: (unsigned char) ch;

// Window management
- (GlkWindow*) rootWindow;

- (void)       setGlkWindow: (GlkWindow*) window;

// Stream management
- (GlkStream*) openFile: (GlkFileRef*) ref
               withMode: (glui32) mode
                   rock: (glui32) rock;
- (GlkStream*) openMemory: (char*) buf
                   length: (glui32) buflen
                 withMode: (glui32) mode
                     rock: (glui32) rock;
-(GlkStream*)   openFileWithForcedName: (NSString*) fname
							usage: (glui32)usage
							withMode: (glui32) mode
							rock: (glui32) rock;
- (void)       setCurrentStream: (GlkStream*) stream;
- (GlkStream*) currentStream;

- (void)       putChar: (unsigned char) ch;
- (void)       putString: (const char*) s;
- (void)       putBuffer: (const char*) buf
                  length: (glui32) len;
- (void)       setGlkStyle: (glui32) styl;

- (void) setStyleHint: (glui32) winType
                style: (glui32) styl
                 hint: (glui32) hint
                value: (glsi32) val;
- (void) clearStyleHint: (glui32) wintype
                  style: (glui32) styl
                   hint: (glui32) hint;

// Filerefs
- (GlkFileRef*) fileRefTemp: (glui32) rock
                  withUsage: (glui32) usage;
- (GlkFileRef*) fileRefForName: (char*) name
                          rock: (glui32) rock
                     withUsage: (glui32) usage;
- (GlkFileRef*) fileRefByPromptingForMode: (glui32) fmode
                                     rock: (glui32) rock
                                withUsage: (glui32) usage;
- (GlkFileRef*) fileRefFromFileRef: (GlkFileRef*) ref
                              rock: (glui32) rock
                         withUsage: (glui32) usage;

// The iteration functions
- (GlkWindow*) windowIterate: (GlkWindow*) win
                        rock: (glui32*)    rock;
- (GlkStream*) streamIterate: (GlkStream*) stream
                        rock: (glui32*)    rock;

// Glk events
- (GlkEvent*) select: (event_t*) event;
- (GlkEvent*) selectPoll;

- (void) requestTimerEvents: (glui32) millisecs;

- (void) showSavePanelForMode: (NSNumber*) fm;

// Housekeeping
- (void) setRootWindow: (GlkWindow*) newRoot;
- (void) windowNeedsArranging;
- (void) windowHasBeenArranged: (GlkWindow*) win;

- (NSFont*) fixedPitchFont;
- (NSFont*) proportionalFont;

- (BOOL) isMainThread;

- (void) threadPoolFree;

- (glsi32) hintForStyle: (glui32) styl
                   hint: (glui32) hint
                winType: (glui32) wintype;

- (id)   objectValue;
- (void) setObjectValue: (id) object;

// Sending event data from the subthread to the main thread
- (void)      queueEvent: (GlkEvent*) event;
- (GlkEvent*) nextEvent;
- (void)      cancelEventsForWindow: (GlkWindow*) win;

- (NSWindow*) window;

// Image support
- (NSImage*) createImageResource:  (glui32) image; // Overridden by subclasses

- (NSImage*) getImageResource:     (glui32) image;
- (void)     uncacheImageResource: (glui32) image;

- (NSImage*) logoImage;

@end

#import "GlkEvent.h"
#import "GlkWindow.h"
#import "GlkStream.h"
#import "GlkFileRef.h"

