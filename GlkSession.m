//
//  GlkSession.m
//  CocoaGlk
//
//  Created by Andrew Hunter on Wed Jun 11 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "GlkSession.h"
#import "GlkWindowView.h"
#import "GlkFileStream.h"
#import "GlkMemoryStream.h"
#import "GlkStatus.h"
#import "glkstart.h"

@implementation GlkSession

#define propI    @"Gill Sans"
#define propII   @"Times-Italic"
#define propIII  @"Times-Bold"

#define fixFont  @"Courier"
#define propSize 14
#define fixSize  12

NSString*const GlkSessionKey = @"GlkSessionKey";
NSString*const GlkStatusKey  = @"GlkStatus";

NSString*const GlkFlushYourBuffers = @"GlkFlushDemBuffers";

enum glkSessionConditions {
    GlkSessionNoEvents = 0,
    GlkSessionEventsWaiting
};

#define runningInMainThread ([NSThread currentThread] == mainThread)

// == Startup ==

+ (void) initialize {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSDictionary *appDefaults = [NSDictionary
        dictionaryWithObject:NSHomeDirectory() forKey:@"SaveDirectory"];

    [defaults registerDefaults:appDefaults];
}

// == Initialisation ==
- (id) init {
    self = [super init];

    if (self) {
        // Setup
        rootWindow    = [[GlkWindow allocWithZone: [self zone]] initWithSession: self];
        currentWindow = nil;
        currentStream = nil;
        currentWindow = [rootWindow retain];
        currentStream = [[currentWindow stream] retain];

        arrangeWindow = nil;

        mainThread  = [NSThread currentThread];
        mainRunLoop = [NSRunLoop currentRunLoop];

        objectValue = nil;

        // Images
        imageCache = [[NSMutableArray allocWithZone: [self zone]] init];
        imageCacheNumbers = [[NSMutableArray allocWithZone: [self zone]] init];

        // Events
        eventQueue = [[NSMutableArray allocWithZone: [self zone]] init];
        currentEvent = nil;

        // Threads
        mainthreadConnection = nil;
        glkthreadConnection  = nil;
        port1                = nil;
        port2                = nil;
        
        // Create the user interface elements
        sessionWindow = [[NSWindow allocWithZone: [self zone]] initWithContentRect: NSMakeRect(100, 0, 800, 800)
																		 styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable|NSWindowStyleMaskResizable
                                                                           backing: NSBackingStoreBuffered
                                                                             defer: YES];
        [sessionWindow setDelegate: self];

        // Fonts
        fixedFont = [[NSFont fontWithName: fixFont
                                     size: fixSize]
            retain];
        propFont  = [[NSFont fontWithName: propI
                                     size: propSize]
            retain];

        // Styles
        int x;
        for (x=0; x<style_NUMSTYLES; x++) {
            int y;

            for (y=0; y<stylehint_NUMHINTS; y++) {
                defaultHint[y][x] = 0;
            }

            defaultHint[stylehint_TextColor][x] = 0;
            defaultHint[stylehint_BackColor][x] = 0xffffff;
            defaultHint[stylehint_Justification][x] = stylehint_just_LeftFlush;
            defaultHint[stylehint_Proportional][x]  = 1;
        }

        // Default stylehints
        defaultHint[stylehint_Weight][style_Subheader]     = 1;
        defaultHint[stylehint_Weight][style_Alert]         = 1;
        defaultHint[stylehint_Weight][style_Note]          = -1;
        defaultHint[stylehint_Weight][style_BlockQuote]    = 1;
        defaultHint[stylehint_Weight][style_Input]         = 1;

        defaultHint[stylehint_Oblique][style_Emphasized]   = 1;
        defaultHint[stylehint_Oblique][style_Alert]        = 1;

        defaultHint[stylehint_Size][style_Alert]           = 1;
        defaultHint[stylehint_Size][style_Header]          = 4;
        defaultHint[stylehint_Size][style_Subheader]       = 1;

        defaultHint[stylehint_Justification][style_Header] = stylehint_just_Centered;

        defaultHint[stylehint_Proportional][style_Preformatted] = 0;

        defaultHint[stylehint_Indentation][style_BlockQuote] = 10;
        
        for (x=0; x<style_NUMSTYLES; x++) {
            int y;

            for (y=0; y<stylehint_NUMHINTS; y++) {
                styleHint[y][x] = defaultHint[y][x];
            }
        }
        
        // Setup the UI, display the window
        [sessionWindow setDelegate: self];
        [sessionWindow setContentView: [rootWindow view]];
        [sessionWindow orderFront: self];
    }

    return self;
}

- (void) dealloc {
    [rootWindow    release];
    [currentWindow release];
    [currentStream release];
    [sessionWindow release];

    [fixedFont release];
    [propFont  release];

    if (mainthreadConnection) [mainthreadConnection release];
    if (glkthreadConnection)  [glkthreadConnection release];
    if (port1)                [port1 release];
    if (port2)                [port2 release];
    if (objectValue)          [objectValue release];

    [imageCache release];
    [imageCacheNumbers release];

    [eventQueue release];
    if (currentEvent) [currentEvent release];

    [super dealloc];
}

// == User functions ==

// -----------------------------------------------------------------------------
//	glkMain:
//		Run the specified game in this session. This synthesizes a command line
//		based on the file path passed in and hands that to the user's
//		glkunix_startup_code() function. Since we only allow one running game
//		right now, this quits the application after that.
//
//	REVISIONS:
//		2004-03-13	witness	Created.
// -----------------------------------------------------------------------------

- (void) glkMain: (NSString*)filename
{
	const char*				args[2];
	glkunix_startup_t   fakeArgs = { 2, args };
	GlkStatus* stat = [[GlkStatus allocWithZone: [self zone]] init];

    [[[NSThread currentThread] threadDictionary] setObject: stat
                                                    forKey: GlkStatusKey];
	[stat release];
	
	args[0] = [[[NSBundle mainBundle] executablePath] fileSystemRepresentation];
	args[1] = [filename fileSystemRepresentation];
	
	glkunix_startup_code( &fakeArgs );
	glk_main();
	
	[NSApp terminate: self];
}


// -----------------------------------------------------------------------------
//	_threadMain:
//		This hands on the file name of the game file to run to glkMain:.
//
//	REVISIONS:
//		2004-03-13	witness	Added filename parameter.
// -----------------------------------------------------------------------------

- (void) _threadMain: (NSString*)filename
{    
    threadPool = [[NSAutoreleasePool allocWithZone: [self zone]] init];

    glkThread = [NSThread currentThread];
    glkRunLoop = [NSRunLoop currentRunLoop];
    
    [[glkThread threadDictionary] setObject: self
                                     forKey: GlkSessionKey];

    [[NSRunLoop currentRunLoop] addPort: port2
                                forMode: NSDefaultRunLoopMode];

    glkthreadConnection = [[NSConnection allocWithZone: [self zone]]
        initWithReceivePort: port2
                   sendPort: port1];
    [glkthreadConnection setRootObject: self];
    
    [self glkMain: filename];
    [self exit];
}

- (void) threadPoolFree {
    [threadPool release];
    threadPool = [[NSAutoreleasePool allocWithZone: [self zone]] init];
}

// -----------------------------------------------------------------------------
//	queueTheMusic:
//		Actually starts this session and runs it in a separate thread.
//		This hands on the file name of the game file to run to _threadMain:.
//
//	REVISIONS:
//		2004-03-13	witness	Added filename parameter.
// -----------------------------------------------------------------------------

- (void) queueTheMusic: (NSString*)filename
{
    if (mainthreadConnection != nil) {
        return;
    }

    mainThread  = [NSThread currentThread];
    mainRunLoop = [NSRunLoop currentRunLoop];

    port1 = [[NSPort port] retain];
    port2 = [[NSPort port] retain];

    mainthreadConnection = [[NSConnection allocWithZone: [self zone]]
        initWithReceivePort: port1
                   sendPort: port2];
    [mainthreadConnection setRootObject: self];
    
    [NSThread detachNewThreadSelector: @selector(_threadMain:)
                             toTarget: self
                           withObject: filename];
}

// == Session management ==

// Top-level glk functions
- (void) exit {
    if (runningInMainThread) {
        NSLog(@"Calling exit from the main thread not implemented yet");
        abort();
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName: GlkFlushYourBuffers
                                                            object: self];
        [[self rootWindow] flushBuffer];
        [[self rootWindow] updateOpportunity];

        [[[NSThread currentThread] threadDictionary] removeObjectForKey: GlkSessionKey];
        [[[NSThread currentThread] threadDictionary] removeObjectForKey: GlkStatusKey];
        
        [threadPool release];

		@autoreleasepool {

        [glkthreadConnection release];
        [mainthreadConnection release];

        [port1 release];
        [port2 release];

        glkthreadConnection = nil;
        mainthreadConnection = nil;
        port1 = nil;
        port2 = nil;
        
		}
		
        [NSThread exit];
    }
}

- (void) tick {
    NSDate* tock = [NSDate date];
    tock = [tock dateByAddingTimeInterval: 0.01];
    
    [[NSRunLoop currentRunLoop] acceptInputForMode: NSDefaultRunLoopMode
                                        beforeDate: tock];    
}

- (void) setInterruptHandler: (id) handler
                withSelector: (SEL) selector {
    BUG(@"*** BUG: FUNCTION NOT IMPLEMENTED\n");
}


    // Gestalt functions
- (glui32)  gestaltForSel: (glui32)  sel
                  withVal: (glui32)  val {
    return [self gestaltForSel: sel
                       withVal: val
                           buf: NULL
                        length: 0];
}

- (glui32)  gestaltForSel: (glui32)  sel
                  withVal: (glui32)  val
                      buf: (glui32*) buf
                   length: (glui32)  bufLen {
    switch (sel) {
        case gestalt_Version:
            return 0x00000601;
            
        case gestalt_CharInput:
            // Grr
            if (val > 32 || (glsi32)val < 0)
                return 1;
            else
                return 0;
            break;

        case gestalt_LineInput:
            if ((glsi32)val > 32 && (glsi32)val < 256) {
                return 1;
            } else {
                return 0;
            }
            break;

        case gestalt_CharOutput:
            if ((glsi32)val > 32 && (glsi32)val < 256) {
                if (buf) *buf = 1;
                return gestalt_CharOutput_ExactPrint;
            } else {
                if (buf) *buf = 0;
                return 0;
            }
            break;

        case gestalt_MouseInput:
            return 0; // IMPLEMENT ME :-)

        case gestalt_Timer:
            return 0; // DITTO

        case gestalt_Graphics:
            return 1;

        case gestalt_DrawImage:
            switch (val) {
                case 0:
                    return 1;

                case wintype_Graphics:
                    return 1;
                    
                case wintype_TextBuffer:
                    return 1; // IMPLEMENT ME
                    
                case wintype_TextGrid:
                default:
                    return 0;
            }
            break;
            
        case gestalt_GraphicsTransparency:
            return 1;
           
        case gestalt_Sound:
        case gestalt_SoundVolume:
        case gestalt_SoundNotify:
        case gestalt_Hyperlinks:
        case gestalt_HyperlinkInput:
        case gestalt_SoundMusic:
        default:
            return 0; // IMPLEMENT THIS LOT
    }
}

- (unsigned char) charToLower: (unsigned char) ch {
    BUG(@"*** BUG: FUNCTION NOT IMPLEMENTED\n");
}

- (unsigned char) charToUpper: (unsigned char) ch {
    BUG(@"*** BUG: FUNCTION NOT IMPLEMENTED\n");
}

// == Window management ==
- (GlkWindow*) rootWindow {
    if (runningInMainThread) {
        // Return the window in this thread
        return rootWindow;
    } else {
        // Return a reference to the window
        return [(GlkSession*)[glkthreadConnection rootProxy] rootWindow];
    }
    // return rootWindow;
}

- (void) setGlkWindow: (GlkWindow*) window {
    if (currentWindow)
        [currentWindow autorelease];
    
    currentWindow = [window retain];
    [self setCurrentStream: [currentWindow stream]];
}

// == Stream management ==
- (GlkStream*) openFile: (GlkFileRef*) ref
               withMode: (glui32) mode
                   rock: (glui32) rock {
    GlkFileStream* str;

    str = [[GlkFileStream allocWithZone: [self zone]] initByOpeningFileRef: ref
                                                                  withMode: mode
                                                                      rock: rock];

    if (str) {
        return [str autorelease];
    } else {
        return nil;
    }
}


// -----------------------------------------------------------------------------
//	openFileWithForcedName:usage:withMode:rock:
//		This method allows opening a GlkStream for *any* file. This is used
//		by glkunix_stream_open_pathname() to allow opening streams to game files
//		at startup.
//
//	REVISIONS:
//		2004-03-13	witness	Created.
// -----------------------------------------------------------------------------

-(GlkStream*)   openFileWithForcedName: (NSString*) fname
							usage: (glui32)usage
							withMode: (glui32) mode
							rock: (glui32) rock
{
    GlkFileStream*  str;
	GlkFileRef*		ref = [[GlkFileRef allocWithZone: [self zone]] initWithForcedName: fname
									withUsage: usage
									forSession: self];
	
    str = [[GlkFileStream allocWithZone: [self zone]] initByOpeningFileRef: ref
                                                                  withMode: mode
                                                                      rock: rock];

    if (str) {
        return [str autorelease];
    } else {
        return nil;
    }
}

- (GlkStream*) openMemory: (char*) buf
                   length: (glui32) buflen
                 withMode: (glui32) mode
                     rock: (glui32) rock {
    // Memory is owned by whoever creates the stream
    // Currently we ignore mode...
    
    GlkMemoryStream* str;

    str = [[GlkMemoryStream allocWithZone: [self zone]] initWithBuffer: buf
                                                                length: buflen
                                                                  rock: rock];

    return [str autorelease];
}

@synthesize currentStream;

- (void)       putChar: (unsigned char) ch {
    [currentStream putChar: ch];
}

- (void)       putString: (const char*) s {
    [currentStream putString: @(s)];
}

- (void)       putBuffer: (const char*) buf
                  length: (glui32) len {
    [currentStream putBuffer: [NSData dataWithBytes: buf
                                             length: len]];
}

- (void)       setGlkStyle: (glui32) styl {
    [currentStream setGlkStyle: styl];
}

- (void) setStyleHint: (glui32) winType
                style: (glui32) styl
                 hint: (glui32) hint
                value: (glsi32) val {
    if (!runningInMainThread) {
        [(GlkSession*)[glkthreadConnection rootProxy] setStyleHint: winType
                                                             style: styl
                                                              hint: hint
                                                             value: val];
        return;
    }

    styleHint[hint][styl] = val;
}

- (void) clearStyleHint: (glui32) wintype
                  style: (glui32) styl
                   hint: (glui32) hint {
    if (!runningInMainThread) {
        [(GlkSession*)[glkthreadConnection rootProxy] clearStyleHint: wintype
                                                               style: styl
                                                                hint: hint];
        return;
    }
    
    styleHint[hint][styl] = defaultHint[hint][styl];
}

- (glsi32) hintForStyle: (glui32) styl
                   hint: (glui32) hint
                winType: (glui32) wintype {
    return styleHint[hint][styl];
}

// == Filerefs ==
- (GlkFileRef*) fileRefTemp: (glui32) rock
                  withUsage: (glui32) usage {
    GlkFileRef* res = [[GlkFileRef allocWithZone: [self zone]]
        initWithTempFileForSession: self
                         withUsage: usage];

    if (res) {
        [res setRock: rock];
        return [res autorelease];
    }

    return nil;
}

- (GlkFileRef*) fileRefForName: (char*) name
                          rock: (glui32) rock
                     withUsage: (glui32) usage {
    GlkFileRef* res = [[GlkFileRef allocWithZone: [self zone]]
        initWithName: @(name)
           withUsage: usage
          forSession: self];

    if (res) {
        [res setRock: rock];
        return [res autorelease];
    }

    return nil;
}

- (void) doneSaving: (NSString*) filename {
    if (runningInMainThread) {
        [(GlkSession*)[mainthreadConnection rootProxy] doneSaving: filename];
    } else {
        savePanelFinished = YES;

        if (filename) {
            savePanelFilename = [filename retain];
        } else {
            savePanelFilename = nil;
        }
    }
}

- (GlkFileRef*) fileRefByPromptingForMode: (glui32) fmode
                                     rock: (glui32) rock
                                withUsage: (glui32) usage {
    if (!runningInMainThread) {
        // Send a request that the dialog be shown
        savePanelFinished = NO;

        [(GlkSession*)[glkthreadConnection rootProxy] showSavePanelForMode: [NSNumber numberWithInt: fmode]];

        // Wait for the dialog to finish
        while (!savePanelFinished) {
            NSAutoreleasePool* loopPool = [[NSAutoreleasePool allocWithZone: [self zone]] init];

            [glkRunLoop acceptInputForMode: NSDefaultRunLoopMode
                                beforeDate: [NSDate distantFuture]];

            [loopPool release];            
        }

        if (savePanelFilename) {
            GlkFileRef* ref;

            ref = [[GlkFileRef allocWithZone: [self zone]] initWithForcedName: savePanelFilename
                                                                    withUsage: usage
                                                                   forSession: self];
            [savePanelFilename release];

            return [ref autorelease];
        }

        return nil;
            
        /*
        return [(GlkSession*)[glkthreadConnection rootProxy] fileRefByPromptingForMode: fmode
                                                                                  rock: rock
                                                                             withUsage: usage];
         */
    } else {
        NSLog(@"fileRefByPromptingForMode cannot be run in the main thread");
        return nil;
    }
}

- (GlkFileRef*) fileRefFromFileRef: (GlkFileRef*) ref
                              rock: (glui32) rock
                         withUsage: (glui32) usage {
    BUG(@"*** BUG: FUNCTION NOT IMPLEMENTED\n");
}

// == Dealing with save/open panels ==
- (void) showSavePanelForMode: (NSNumber*) fm {
    glui32 fmode = [fm intValue];

    NSSavePanel* thePanel = nil;
    BOOL openPanel = NO;

    switch (fmode) {
        case filemode_Write:
        case filemode_WriteAppend:
            thePanel = [NSSavePanel savePanel];
            break;

        case filemode_Read:
        case filemode_ReadWrite:
            thePanel = [NSOpenPanel openPanel];
            openPanel = YES;
            break;
    }

    if (thePanel == nil) {
        // Unknown mode
        [glkRunLoop performSelector: @selector(doneSaving:)
                             target: self
                           argument: nil
                              order: 128
                              modes: [NSArray arrayWithObjects:
                                  NSDefaultRunLoopMode,
                                  NSModalPanelRunLoopMode,
                                  nil]];
        return;
    }

    // Display the panel
	thePanel.directoryURL = [NSUserDefaults.standardUserDefaults URLForKey:@"SaveDirectory"];
    if (!openPanel) {
		[thePanel beginSheetModalForWindow:sessionWindow completionHandler:^(NSModalResponse result) {
			[self savePanelDidEnd:thePanel returnCode:result contextInfo:NULL];
		}];
    } else {
		[(NSOpenPanel*)thePanel beginSheetModalForWindow:sessionWindow completionHandler:^(NSModalResponse result) {
			[self openPanelDidEnd:(NSOpenPanel*)thePanel returnCode:result contextInfo:NULL];
		}];
    }
}

- (void)savePanelDidEnd:(NSSavePanel *)sheet
             returnCode:(NSModalResponse)returnCode
            contextInfo:(void  *)contextInfo {
	if (returnCode == NSModalResponseOK) {
        [[NSUserDefaults standardUserDefaults] setURL: [sheet directoryURL]
                                                  forKey: @"SaveDirectory"];
        [self doneSaving: [sheet URL].path];
    } else {
        [self doneSaving: nil];
    }
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet
             returnCode:(NSModalResponse)returnCode
            contextInfo:(void  *)contextInfo {
	if (returnCode == NSModalResponseOK) {
        [[NSUserDefaults standardUserDefaults] setURL: [sheet directoryURL]
                                                  forKey: @"SaveDirectory"];
        [self doneSaving: [sheet URL].path];
    } else {
        [self doneSaving: nil];
    }
}

// == The iteration functions ==
- (GlkWindow*) windowIterate: (GlkWindow*) win
                        rock: (glui32*)    rock {
    if (win == nil) {
        return rootWindow;
    }
    
    if ([win left]) {
        return [win left];
    } else {
        GlkWindow* newWin, *lastWin;

        lastWin = win;
        newWin  = [win parent];

        while (newWin != nil &&
               [newWin left] != lastWin) {
            lastWin = newWin;
            newWin = [newWin parent];
        }

        if (newWin == nil) {
            return nil;
        }

        return [newWin right];
    }
}

- (GlkStream*) streamIterate: (GlkStream*) stream
                        rock: (glui32*)    rock {
    BUG(@"*** BUG: FUNCTION NOT IMPLEMENTED\n");
}

// == Glk events ==
- (void) _preSelect {
    [[NSNotificationCenter defaultCenter] postNotificationName: GlkFlushYourBuffers
                                                        object: self];

    if (arrangeWindow != nil) {
        // Queue an arrange event
        GlkEvent* evt = [GlkEvent eventWithType: evtype_Arrange
                                            win: arrangeWindow
                                           val1: 0
                                           val2: 0];
        arrangeWindow = nil;
        
        [self queueEvent: evt];
    }
}

- (void) _wakeupThread {
    // Dummy method called to force an NSRunloop to retun
    wakeup = YES;
}

- (GlkEvent*) select: (event_t*) event {
    GlkEvent* theEvent;

    if (runningInMainThread) {
        NSLog(@"Warning: select: called from main thread");
    }

    // Setup
    [self _preSelect];

    // Flush any buffers
    [[self rootWindow] flushBuffer];
    [[self rootWindow] updateOpportunity];

    // Release any autoreleased objects that are pending
    [threadPool release];
    threadPool = [[NSAutoreleasePool allocWithZone: [self zone]] init];
    
    // Get the next event
    theEvent = [GlkEvent eventWithEvent: [self nextEvent]];

    // Wait for an event to arrive (if none are waiting)
    while (theEvent == nil) {
        NSAutoreleasePool* loopPool = [[NSAutoreleasePool allocWithZone: [self zone]] init];

        // Do the RunLoop thang (allow other threads to call us)
        [[NSRunLoop currentRunLoop] acceptInputForMode: NSDefaultRunLoopMode
                                            beforeDate: [NSDate distantFuture]];

        [loopPool release];

        if (wakeup) {
            // Use eventWithEvent to create a local copy of the event
            theEvent = [GlkEvent eventWithEvent: [self nextEvent]];
            wakeup = NO;
        }
    }
    
    if ([theEvent type] == evtype_LineInput) {
        GlkWindow* theWin = [theEvent win];
        
        theEvent = [theWin cancelLineEvent];
    }
    
    event->type = [theEvent type];
    event->win  = (winid_t)[theEvent win];
    event->val1 = [theEvent val1];
    event->val2 = [theEvent val2];

    return theEvent;
}

- (GlkEvent*) selectPoll {
    // Run only in the main thread
    if (!runningInMainThread) {
        return [(GlkSession*)[glkthreadConnection rootProxy] selectPoll];
    }

    NSEnumerator* evEnum = [eventQueue objectEnumerator];
    GlkEvent* ev;

    while (ev = [evEnum nextObject]) {
        glui32 type = [ev type];

        if (type != evtype_CharInput &&
            type != evtype_LineInput &&
            type != evtype_MouseInput) {
            break;
        }
    }

    if (ev == nil) {
        return nil;
    }
    
    [ev retain];
    [eventQueue removeObjectIdenticalTo: ev];

    return [ev autorelease];
}

- (void) requestTimerEvents: (glui32) millisecs {
    BUG(@"*** BUG: FUNCTION NOT IMPLEMENTED\n");
}

// == Housekeeping ==
- (void) setRootWindow: (GlkWindow*) newRoot {
    if (newRoot != nil) {
        [newRoot retain];
        [rootWindow release];
        rootWindow = newRoot;

        [[newRoot view] forceViewReorder];

        [sessionWindow setContentView: [newRoot view]];
    } else {
        [sessionWindow setContentView: nil];
        [rootWindow release];
        rootWindow = nil;
    }
}

- (void) windowNeedsArranging {
    [rootWindow windowNeedsArranging];
    [[rootWindow view] setNeedsDisplay: YES];
}

- (NSFont*) fixedPitchFont {
    return fixedFont;
}

- (NSFont*) proportionalFont {
    return propFont;
}

@synthesize objectValue;

// Threading
- (BOOL) isMainThread {
    return [NSThread currentThread] == mainThread;
}

// The window
- (NSWindow*) window {
    return sessionWindow;
}

// == Event handling ==
- (void) queueEvent: (GlkEvent*) event {
    if (!runningInMainThread) {
        [(GlkSession*)[glkthreadConnection rootProxy] queueEvent: event];
    } else {
        if (event == nil) {
            NSLog(@"Attempt to queue nil event");
            return;
        }

        [eventQueue addObject: event];

        // Signal the thread
        if (mainthreadConnection) {
            [(GlkSession*)[mainthreadConnection rootProxy] _wakeupThread];
        }
    }
}

- (void) cancelEventsForWindow: (GlkWindow*) win {
    if (!runningInMainThread) {
        NSLog(@"Warning: cancelEventsForWindow called from the wrong thread");
        [(GlkSession*)[glkthreadConnection rootProxy] cancelEventsForWindow: win];
    } else {
        if (currentEvent != nil && [win isEqualTo: [currentEvent win]]) {
            [currentEvent release];
            currentEvent = nil;
        }

        NSEnumerator* evtEnum = [eventQueue objectEnumerator];
        NSMutableArray* toRemove = [NSMutableArray array];
        GlkEvent* evt;

        while (evt = [evtEnum nextObject]) {
            if ([win isEqualTo: [evt win]]) {
                [toRemove addObject: evt];
            }
        }

        evtEnum = [toRemove objectEnumerator];
        while (evt = [evtEnum nextObject]) {
            [eventQueue removeObjectIdenticalTo: evt];
        }
    }
}

- (GlkEvent*) nextEvent {
    // Only execute this in the main thread
    if (!runningInMainThread) {
        return [(GlkSession*)[glkthreadConnection rootProxy] nextEvent];
    } else {
        // Pop the next event
        if (currentEvent) { [currentEvent release]; currentEvent = nil; }

        if ([eventQueue count] <= 0) {
            // No events
            return nil;
        }
        
        currentEvent = [[eventQueue objectAtIndex: 0] retain];
        [eventQueue removeObjectAtIndex: 0];

        // Unlock the lock
        return currentEvent;
    }
}

- (void) windowHasBeenArranged: (GlkWindow*) win {
    if (!runningInMainThread) {
        NSLog(@"windowHasBeenArranged can only be called from the main thread");
        return;
    }
    
    if (arrangeWindow != nil) {
        if (arrangeWindow != win) {
            arrangeWindow = rootWindow;
        }
    } else {
        arrangeWindow = win;
    }
}

// == Window events ==
- (void)windowDidResize:(NSNotification *)aNotification {
    if (arrangeWindow != nil) {
        // Queue an arrange event
        GlkEvent* evt = [GlkEvent eventWithType: evtype_Arrange
                                            win: arrangeWindow
                                           val1: 0
                                           val2: 0];
        arrangeWindow = nil;

        [self queueEvent: evt];
    }
}

- (void)windowWillClose:(NSNotification *)aNotification {
    if (rootWindow) {
        [rootWindow close];
    }

    if (rootWindow) {
        [rootWindow release];
        rootWindow = nil;
    }

    [sessionWindow setContentView: nil];

    if (currentWindow) {
        [currentWindow release];
        currentWindow = nil;
    }

    if (currentStream) {
        [currentStream release];
        currentStream = nil;
    }

    if (currentEvent) {
        [currentEvent release];
        currentEvent = nil;
    }

    [sessionWindow setDelegate: nil];
    sessionWindow = nil;
    
    [self release];
}

// == Images ==
static const int IMAGECACHESIZE = 32;

- (NSImage*) createImageResource:  (glui32) image {
    return nil;
}

- (NSImage*) getImageResource: (glui32) image {
    if (!runningInMainThread) {
        return [(GlkSession*)[glkthreadConnection rootProxy] getImageResource: image];
    }

    NSInteger cachePos = [imageCacheNumbers indexOfObject: @(image)];

    if (cachePos == NSNotFound) {
        // Create the image
        NSImage* img = [[self createImageResource: image] retain];

        if (img == nil) {
            NSLog(@"Image %i not found", image);
            return nil;
        }

        [imageCache addObject: img];
        [imageCacheNumbers addObject: @(image)];

        if ([imageCache count] > IMAGECACHESIZE) {
            [imageCache removeObjectAtIndex: 0];
            [imageCacheNumbers removeObjectAtIndex: 0];
        }

        return [img autorelease];
    } else {
        // Get the image fromt the cache
        NSImage* img = [[imageCache objectAtIndex: cachePos] retain];

        // Move the object to the front of the cache
        [imageCache removeObjectAtIndex: cachePos];
        [imageCacheNumbers removeObjectAtIndex: cachePos];
        
        [imageCache addObject: img];
        [imageCacheNumbers addObject: @(image)];
        
        return [img autorelease];
    }
}

- (void) uncacheImageResource: (glui32) image {

    NSInteger cachePos = [imageCacheNumbers indexOfObject: @(image)];

    if (cachePos != NSNotFound) {
        [imageCache removeObjectAtIndex: cachePos];
        [imageCacheNumbers removeObjectAtIndex: cachePos];
    }
}

- (NSImage*) logoImage {
    if (!runningInMainThread) {
        return [(GlkSession*)[glkthreadConnection rootProxy] logoImage];
    }
    
    return [[[NSImage allocWithZone:[self zone]] initWithContentsOfFile:
        [[NSBundle mainBundle] pathForResource:@"logo" ofType:@"png" inDirectory:nil]] autorelease];
}

@end
