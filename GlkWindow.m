//
//  GlkWindow.m
//  CocoaGlk
//
//  Created by Andrew Hunter on Wed Jun 11 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "GlkWindow.h"
#import "GlkWindowView.h"
#import "GlkWindowStream.h"

#import "GlkImage.h"

// Utility functions
GlkArrangement GlkMakeArrangement(glui32 method, glui32 size, GlkWindow* keyWin) {
    GlkArrangement r;

    r.method = method;
    r.size   = size;
    r.keyWin = keyWin;

    return r;
}

GlkSize GlkMakeSize(int width, int height) {
    GlkSize r;

    r.width = width;
    r.height = height;

    return r;
}

GlkPoint GlkMakePoint(int x, int y) {
    GlkPoint r;

    r.x = x;
    r.y = y;

    return r;
}

@implementation GlkWindow

// Session initialisation
- (id) initWithSession: (GlkSession*) session {
    self = [super init];

    if (self) {
        // Note: to finish a session, all windows must first be closed
        ourSession = [session retain];

        type   = wintype_Blank;
        left   = right = nil;
        text   = nil;
        textBuffer = nil;
        grid   = nil;
        image  = nil;
        parent = nil;

        open   = YES;

        imageBackground = 0xffffff;

        pendingInput = [[NSMutableString allocWithZone: [self zone]] init];

        rock = 0;
        size = 0;

        isProportional = NO;
        isFixed        = NO;

        lineLength = 0;
        requestedLineEvents = requestedCharEvents = NO;

        actualSize = GlkMakeSize(0,0);
        cursorPoint = GlkMakePoint(0,0);

        echoStream = nil;

        needsArranging = NO;

        // Styles
        int x;
        for (x=0; x<style_NUMSTYLES; x++) {
            font[style_NUMSTYLES]      = nil;
            fontColour[style_NUMSTYLES] = nil;
            backColour[style_NUMSTYLES] = nil;

            int y;

            for (y=0; y<stylehint_NUMHINTS; y++) {
                styleHint[y][x] = [ourSession hintForStyle: x
                                                      hint: y
                                                   winType: type];
            }
        }

        stylesNeedRecalculating = YES;

        // Streams
        winStream = [[GlkWindowStream allocWithZone: [self zone]] initWithGlkWindow: self];

        // The view
        view = [[GlkWindowView allocWithZone: [self zone]] initWithGlkWindow: self];
		
		// Speech synthesizer, if requested and available:
		NSNumber* theBool = [[NSUserDefaults standardUserDefaults] objectForKey: @"speakOutput"];
		if( theBool && [theBool boolValue] == YES )
			[self toggleSpeechSynthesis: self];
    }

    return self;
}

- (void) dealloc {    
    [ourSession cancelEventsForWindow: self];
    [ourSession release];
    
    if (left)  [left release];
    if (right) [right release];
    if (text)  { [text setDelegate: nil]; [text release]; }
    if (textBuffer) [textBuffer release];
    if (image) [image release];
    if (echoStream) [echoStream release];

    if (view)  [view release];

    int sty;
    for (sty = 0; sty < style_NUMSTYLES; sty++) {
        // Release the old attributes
        if (font[sty] != nil)            [font[sty] release];
        if (fontColour[sty] != nil)      [fontColour[sty] release];
        if (backColour[sty] != nil)      [backColour[sty] release];
        if (paragraphStyle[sty] != nil)  [paragraphStyle[sty] release];
        if (styleAttributes[sty] != nil) [styleAttributes[sty] release];
    }
       
    [winStream release];
    [pendingInput release];

    int y;
    if (grid) {
        for (y=0; y<actualSize.height; y++) {
            free(grid[y]);
            free(gridStyle[y]);
        }

        free(grid);
        free(gridStyle);
    }
	
	[speaker release];
    
    [super dealloc];
}


// -----------------------------------------------------------------------------
//	toggleSpeechSynthesis:
//		Menu item action for turning on/off speaking game output. Does nothing
//		if we're running a MacOS version where NSSpeechSynthesizer isn't
//		available.
//
//		This also changes the user defaults.
//
//	REVISIONS:
//		2004-04-02	witness	Created.
// -----------------------------------------------------------------------------

-(void) toggleSpeechSynthesis: (id)sender
{
	if( speaker )
	{
		[speaker stopSpeaking];
		[speaker release];
		speaker = nil;
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:NO] forKey: @"speakOutput"];
	}
	else
	{
		Class   ssClass = NSClassFromString(@"NSSpeechSynthesizer");
		if( ssClass != Nil )	// We're running 10.3 or later?
		{
			speaker = [[ssClass alloc] init];
			[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:YES] forKey: @"speakOutput"];
		}
	}
}

// -----------------------------------------------------------------------------
//	speechSynthesisOn:
//		Returns YES if speech synthesis is currently turned on for this
//		GlkWindow, no otherwise. Used to properly check our menu item.
//
//	REVISIONS:
//		2004-04-02	witness	Created.
// -----------------------------------------------------------------------------

-(BOOL) speechSynthesisOn
{
	return (speaker != nil);
}


// The glk functions
- (GlkWindow*)     openWithMethod: (glui32) method
                             size: (glui32) sz
                             type: (glui32) tp
                             rock: (glui32) rk {
    // Open by splitting this window

    // The parent of the two newly-split windows
    GlkWindow* newParent = [[GlkWindow allocWithZone: [self zone]] initWithSession: ourSession];

    // The new window
    GlkWindow* newWindow = [[GlkWindow allocWithZone: [self zone]] initWithSession: ourSession];

    // Set up the parent window
    newParent->type  = wintype_Pair;
    newParent->left  = [newWindow retain];
    newParent->right = [self retain];

    newParent->position       = method&winmethod_DirMask;
    newParent->isProportional = (method&winmethod_Proportional)!=0;
    newParent->isFixed        = (method&winmethod_Fixed)!=0;

    newParent->size           = size;

    // Set up the new window
    newWindow->type           = tp;
    newWindow->position       = winmethod_Left;
    newWindow->isProportional = NO;
    newWindow->isFixed        = NO;

    newWindow->rock           = rk;
    newWindow->size           = sz;
    size = 100-sz;
    
    newWindow->parent         = newParent;

    // Re-jig the parents, etc
    GlkWindow* oldParent = parent;
    
    newParent->parent = parent;
    parent = newParent;

    if (oldParent != nil) {
        if (oldParent->left == self) {
            [oldParent->left release];
            oldParent->left = [newParent retain];
        } else if (oldParent->right == self) {
            [oldParent->right release];
            oldParent->right = [newParent retain];
        } else {
            NSLog(@"Bug in window creation (parents fail to match)");
            abort();
        }
    } else {
        [ourSession setRootWindow: newParent];
    }

    // Force a rearrangement of the windows
    if (newParent->parent != nil) {
        [[newParent->parent view] forceViewReorder];
        [newParent->parent windowNeedsArranging];
    } else {
        [ourSession windowNeedsArranging];
    }

    [newWindow release];
    [newParent release];

    return newWindow;
}

- (stream_result_t) close {
    stream_result_t res;

    if (!open) {
        NSLog(@"Warning: attempt to close window that's already open");
        return res;
    }
    
    // Don't want to disappear mysteriously...
    [self retain];
    [self autorelease];

    // Close the stream
    res = [winStream close];

    // Remove from the tree
    if (parent != nil) {
        GlkWindow* remaining = [self sibling];

        if (parent->parent == nil) {
            [remaining retain];
            remaining->parent = nil;
            [ourSession setRootWindow: remaining];
            [remaining release];
        } else {
            if (parent->parent->left == parent) {
                parent->parent->left = [remaining retain];
            } else if (parent->parent->right == parent) {
                parent->parent->right = [remaining retain];
            } else {
                NSLog(@"Oops: window tree corrupted");
                abort();
            }

            remaining->parent = parent->parent;
            [parent->parent->view forceViewReorder];
            [parent->parent windowNeedsArranging];
            [parent release];
        }
    } else {
        // Wah, all gawn
        [ourSession setRootWindow: nil];
        //[ourSession setRootWindow: [[[GlkWindow allocWithZone: [self zone]] init] autorelease]];
    }

    parent = nil;
    open   = NO;

    [ourSession cancelEventsForWindow: self];
    [ourSession release];
    ourSession = nil;
    
    return res;
}

- (GlkSize)        size {
    return actualSize;
}

- (void)           setArrangement: (GlkArrangement) arrangement {
    if (type == wintype_Pair) {
        size = arrangement.size;

        position       = arrangement.method&winmethod_DirMask;
        isProportional = (arrangement.method&winmethod_Proportional)!=0;
        isFixed        = (arrangement.method&winmethod_Fixed)!=0;

        if (arrangement.keyWin == right) {
            GlkWindow* temp = left;

            left  = right;
            right = temp;
        }
        
        [view forceViewReorder];
        [self windowNeedsArranging];
    }
}

- (GlkArrangement) arrangement {
    GlkArrangement res;

    res.method = position | (isProportional?winmethod_Proportional:0) |
        (isFixed?winmethod_Fixed:0);
    res.size   = size;
    res.keyWin = left;

    return res;
}

- (glui32)         rock {
    return rock;
}

- (glui32) type {
    return type;
}

- (GlkWindow*)     parent {
    return parent;
}

- (GlkWindow*)     sibling {
    if (parent == nil) {
        return nil;
    }

    if ([parent left] != self) {
        return [parent left];
    } else {
        return [parent right];
    }
}

- (void) clear {
    if (text != nil) {
        inputPos = 0;
        [[text mutableString] setString: @""];
        [[textBuffer mutableString] setString: @""];
    }

    if (grid != nil) {
        int x,y;

        for (y=0; y<actualSize.height; y++) {
            for (x=0; x<actualSize.width; x++) {
                grid[y][x] = ' ';
                gridStyle[y][x] = style_Normal;
            }
        }

        //[view windowContentChanged];
        needsDisplay = YES;
    }

    cursorPoint = GlkMakePoint(0,0);
}

- (void)           moveCursorToPoint: (GlkPoint) point {
    wasFlushed = [self flushBuffer];
    cursorPoint = point;
}

- (GlkPoint) cursorPoint {
    return cursorPoint;
}

- (GlkStream*)     stream {
    return winStream;
}

- (void) setEchoStream: (GlkStream*) stream {
    if (echoStream) [echoStream release];
    echoStream = [stream retain];
}

- (GlkStream*) echoStream {
    return echoStream;
}

- (glui32)         distinguishStyle: (glui32) styl1
                          fromStyle: (glui32) styl2 {
    BUG(@"*** BUG: FUNCTION NOT IMPLEMENTED\n");
}

- (glui32)         measureStyle: (glui32) styl
                           hint: (glui32) hint
                       resultIn: (glui32*) result {
    BUG(@"*** BUG: FUNCTION NOT IMPLEMENTED\n");
}

- (void) requestLineEvent: (int)    length
                     init: (NSString*) init {
    if (requestedCharEvents ||
        requestedLineEvents) {
        NSLog(@"Warning: requestLineEvent called when there were already keyboard input requests pending");
    }
    
    requestedCharEvents = NO;
    requestedLineEvents++;

    lineLength = length;

    if (init != nil && [init length] > 0) {
        NSAttributedString* initStr = [[NSAttributedString allocWithZone: [self zone]] initWithString: init
                                                                                           attributes: [self attributesForStyle: style_Input]];

        [text replaceCharactersInRange: NSMakeRange(inputPos, [text length]-inputPos)
                  withAttributedString: initStr];
    }

    [view windowRequestStatusChanged];
}

- (void) requestCharEvent {
    if (requestedCharEvents ||
        requestedLineEvents) {
        NSLog(@"Warning: requestCharEvent called when there were already keyboard input requests pending");
    }

    requestedCharEvents = YES;

    [view windowRequestStatusChanged];
}

- (void) requestMouseEvent {
    requestedMouseEvents = YES;
}

- (GlkEvent*) cancelLineEvent {
    if (requestedLineEvents <= 0) {
        return [GlkEvent eventWithType: evtype_None
                                   win: self
                                  val1: 0
                                  val2: 0];
    }
    
    requestedLineEvents--;
    [view windowRequestStatusChanged];

    if (text && inputPos < [text length]) {
        // There is input data waiting... Clear it out
        int iLen = [text length]-inputPos;

        [pendingInput appendString:
            [[text string] substringWithRange: NSMakeRange(inputPos,
                                                           iLen)]];
        [text replaceCharactersInRange: NSMakeRange(inputPos, iLen)
                            withString: @""];
    }

    NSData* lineData = [[self stream] getLineInBuffer: lineLength];

    GlkEvent* evt = [GlkEvent eventWithType: evtype_LineInput
                                        win: self
                                       val1: lineData!=nil?[lineData length]:0
                                       val2: 0];

    [evt setData: lineData];

    return evt;
}

- (void) cancelCharEvent {
    requestedCharEvents = NO;

    [view windowRequestStatusChanged];
}

- (void) cancelMouseEvent {
    requestedMouseEvents = NO;
    
    [view windowRequestStatusChanged];
}

// == Some convienience functions for input handling ==
- (BOOL) handleKeyDown: (NSEvent*) theEvent {
    if (!requestedCharEvents) {
        return NO;
    }

    NSString* chars = [theEvent characters];

    if ([chars length] != 1) {
        return NO;
    }

    unichar chr = [chars characterAtIndex: 0];

    // Latin-1 character codes
    if (chr < 256 && chr > 31 && chr != 127) {
        [ourSession queueEvent: [GlkEvent eventWithType: evtype_CharInput
                                                    win: self
                                                   val1: chr
                                                   val2: 0]];
        [self cancelCharEvent];
        return YES;
    }

    // 'Special' character codes
    glui32 chrCode = 0;

    switch (chr) {
        case NSDownArrowFunctionKey:
            chrCode = keycode_Down;
            break;
        case NSLeftArrowFunctionKey:
            chrCode = keycode_Left;
            break;
        case NSRightArrowFunctionKey:
            chrCode = keycode_Right;
            break;
        case NSUpArrowFunctionKey:
            chrCode = keycode_Up;
            break;

        case 0x0a:
        case 0x0d:
            chrCode = keycode_Return;
            break;

        case 0x08:
        case 127:
        case NSDeleteFunctionKey:
            chrCode = keycode_Delete;
            break;

        case 27:
            chrCode = keycode_Escape;
            break;

        case NSTabCharacter:
            chrCode = keycode_Tab;
            break;

        case NSPageUpFunctionKey:
            chrCode = keycode_PageUp;
            break;
        case NSPageDownFunctionKey:
            chrCode = keycode_PageDown;
            break;

        case NSHomeFunctionKey:
            chrCode = keycode_Home;
            break;
        case NSEndFunctionKey:
            chrCode = keycode_End;
            break;

        case NSF1FunctionKey:
            chrCode = keycode_Func1;
            break;
        case NSF2FunctionKey:
            chrCode = keycode_Func2;
            break;
        case NSF3FunctionKey:
            chrCode = keycode_Func3;
            break;
        case NSF4FunctionKey:
            chrCode = keycode_Func4;
            break;
        case NSF5FunctionKey:
            chrCode = keycode_Func5;
            break;
        case NSF6FunctionKey:
            chrCode = keycode_Func6;
            break;
        case NSF7FunctionKey:
            chrCode = keycode_Func7;
            break;
        case NSF8FunctionKey:
            chrCode = keycode_Func8;
            break;
        case NSF9FunctionKey:
            chrCode = keycode_Func9;
            break;
        case NSF10FunctionKey:
            chrCode = keycode_Func10;
            break;
        case NSF11FunctionKey:
            chrCode = keycode_Func11;
            break;
        case NSF12FunctionKey:
            chrCode = keycode_Func12;
            break;
    }

    if (chrCode != 0) {
        [ourSession queueEvent: [GlkEvent eventWithType: evtype_CharInput
                                                    win: self
                                                   val1: chrCode
                                                   val2: 0]];
        [self cancelCharEvent];
        return YES;
    }

    printf("%i\n", chr);

    // Not our code
    return NO;
}

// == Our housekeeping functions ==
- (GlkSession*) session {
    return ourSession;
}

- (void)        windowNeedsArranging {
    [view performArrangement];
}

- (void) queueArrangement {
    needsArranging = YES;
}

- (void) alreadyArranged {
    needsArranging = NO;

    if (left) {
        [left alreadyArranged];
    }
    if (right) {
        [right alreadyArranged];
    }
}

- (GlkWindowView*) view {
    return view;
}

- (glui32) position {
    return position;
}

- (GlkWindow*) left {
    return left;
}

- (GlkWindow*) right {
    return right;
}

- (BOOL)       fixed {
    return isFixed;
}

- (BOOL)       proportional {
    return isProportional;
}

- (double)     sizeValue {
    return size;
}

- (void) setSizeValue: (double) sz {
    size = sz;
}

- (NSMutableAttributedString*) textBuffer {    
    if (text == nil) {
        text = [[NSTextStorage allocWithZone: [self zone]] initWithString: @""
                                                               attributes: [self attributesForStyle: style_Input]];

        inputPos = 0;

        [text setDelegate: self];

        [textBuffer release];
        textBuffer = [[NSMutableAttributedString allocWithZone: [self zone]] initWithString: @""
                                                                                 attributes: nil];
    }

    return textBuffer;
}

- (NSTextStorage*)   textStorage {
    [self textBuffer];

    return text;
}

- (int) inputPos {
    return inputPos;
}

- (void) setInputPos: (int) newPos {
    inputPos = newPos;
}

- (NSMutableString*) pendingInput {
    return pendingInput;
}

- (void) updateOpportunity {
    if (left != nil) {
        [left updateOpportunity];
    }
    if (right != nil) {
        [right updateOpportunity];
    }
    
    if (needsDisplay) {
        [view windowContentChanged];
        [view setNeedsDisplay: YES];
    }
}

- (BOOL) flushBuffer {
    BOOL res = wasFlushed;
    wasFlushed = NO;

    if (needsArranging) {
        [view performArrangement];
        [self alreadyArranged];
    }
    
    if (left != nil) {
        [left flushBuffer];
    }
    if (right != nil) {
        [right flushBuffer];
    }

    if (type == wintype_TextGrid && textBuffer != nil && [textBuffer length] > 0) {
        const char* cStr = [[textBuffer string] cString];
        int x;

        x = 0;
        while (cStr[x] != 0) {
            if (cStr[x] == '\n') {
                // Newline
                cursorPoint.y++;
                cursorPoint.x = 0;
            } else if (cStr[x] >= 32) {
                // Character
                if (cursorPoint.x > actualSize.width) {
                    cursorPoint.x = 0;
                    cursorPoint.y++;
                }

                if (cursorPoint.y < actualSize.height) {
                    grid[cursorPoint.y][cursorPoint.x] = cStr[x];
                    cursorPoint.x++;
                }
            }

            x++;
        }

 		[speaker startSpeakingString: [textBuffer string]];
		[textBuffer release];
        textBuffer = [[NSMutableAttributedString allocWithZone: [self zone]] initWithString: @"" attributes: nil];

        res = YES;
    } else if (text != nil && [textBuffer length] > 0) {
        int iPos = inputPos;

        inputPos += [[textBuffer string] length];
        [text replaceCharactersInRange: NSMakeRange(iPos, 0)
                  withAttributedString: textBuffer];

		[speaker startSpeakingString: [textBuffer string]];
        [textBuffer release];
        textBuffer = [[NSMutableAttributedString allocWithZone: [self zone]] initWithString: @"" attributes: nil];

        res = YES;
    }

    if (res) {
        // [view windowContentChanged];
        needsDisplay = YES;
    }

    return res;
}

- (char**) textGrid {
    return grid;
}

- (BOOL) requestedLineEvents {
    return requestedLineEvents != 0;
}

- (BOOL) requestedCharEvents {
    return requestedCharEvents;
}

- (BOOL) requestedMouseEvent {
    return requestedMouseEvents;
}

// == Styles ==
- (NSFont*)  fontForStyle: (glui32) style {
    if (stylesNeedRecalculating) {
        [self recalculateStyles];
    }

    if (style >= style_NUMSTYLES) {
        style = 0;
    }

    return font[style];
}

- (NSColor*) colorForStyle: (glui32) style {
    if (stylesNeedRecalculating) {
        [self recalculateStyles];
    }

    if (style >= style_NUMSTYLES) {
        style = 0;
    }

    return fontColour[style];
}

- (NSColor*) backColorForStyle: (glui32) style {
    if (stylesNeedRecalculating) {
        [self recalculateStyles];
    }

    if (style >= style_NUMSTYLES) {
        style = 0;
    }

    return backColour[style];
}

- (NSParagraphStyle*) paragraphStyleForStyle: (glui32) style {
    if (stylesNeedRecalculating) {
        [self recalculateStyles];
    }

    if (style >= style_NUMSTYLES) {
        style = 0;
    }

    return paragraphStyle[style];
}

- (NSDictionary*) attributesForStyle: (glui32) style {
    if (stylesNeedRecalculating) {
        [self recalculateStyles];
    }

    if (style >= style_NUMSTYLES) {
        style = 0;
    }
    
    return styleAttributes[style];
}

static void addFontAttribute(NSMutableArray* fontList,
                             NSArray*        attributeChoices) {
    NSEnumerator*   objEnum  = [fontList objectEnumerator];
    NSMutableArray* newToTry = [NSMutableArray array];

    NSString* name;

    while (name = [objEnum nextObject]) {
        BOOL hasSeparator = NO;

        int x;
        for (x=0; x<[name length]; x++) {
            if ([name characterAtIndex: x] == '-') {
                hasSeparator = YES;
                break;
            }
        }

        NSEnumerator* attrEnum = [attributeChoices objectEnumerator];
        NSString*     attrName;

        while (attrName = [attrEnum nextObject]) {
            NSMutableString* newName = [NSMutableString stringWithString: name];

            if (!hasSeparator) {
                [newName appendString: @"-"];
            }

            [newName appendString: attrName];
            [newToTry addObject: newName];
        }
    }

    [fontList addObjectsFromArray: newToTry];
}

- (void) sizeIsNow: (GlkSize) newSize {
    GlkSize oldSize = actualSize;
    
    actualSize = newSize;

    if (type == wintype_TextGrid) {
        if (actualSize.width == oldSize.width &&
            actualSize.height == oldSize.height) {
            return;
        }
        
        int x,y;

        // Free up any rows that aren't being used any more
        if (actualSize.height < oldSize.height) {
            for (y=actualSize.height; y<oldSize.height; y++) {
                free(grid[y]);
                free(gridStyle[y]);
            }
        }

        // Reallocate
        grid      = realloc(grid, sizeof(char*) * actualSize.height);
        gridStyle = realloc(gridStyle, sizeof(glui32*) * actualSize.height);

        // Create new rows
        if (actualSize.height > oldSize.height) {
            for (y=oldSize.height; y<actualSize.height; y++) {
                grid[y]      = malloc(sizeof(char) * oldSize.width);
                gridStyle[y] = malloc(sizeof(glui32) * oldSize.width);

                for (x=0; x<oldSize.width; x++) {
                    grid[y][x]      = ' ';
                    gridStyle[y][x] = style_Normal;
                }
            }
        }

        // Fill in the blanks
        if (actualSize.width > oldSize.width) {
            for (y=0; y<actualSize.height; y++) {
                for (x=oldSize.width; x<actualSize.width; x++) {
                    grid[y]      = realloc(grid[y], sizeof(char) * actualSize.width);
                    gridStyle[y] = realloc(gridStyle[y], sizeof(glui32) * actualSize.width);
                    
                    grid[y][x]      = ' ';
                    gridStyle[y][x] = style_Normal;
                }
            }
        }

        //[view windowContentChanged];
        needsDisplay = YES;

        [ourSession windowHasBeenArranged: self];
    } else if (type == wintype_Graphics) {
        if (oldSize.width != actualSize.width ||
            oldSize.height != actualSize.height) {
            if (image) {
                [image release];
            }

            NSBitmapImageRep* theImageRep = [[NSBitmapImageRep allocWithZone: [self zone]] initWithBitmapDataPlanes: nil pixelsWide: actualSize.width pixelsHigh: actualSize.height bitsPerSample: 8 samplesPerPixel: 3 hasAlpha: NO isPlanar: NO colorSpaceName: NSDeviceRGBColorSpace bytesPerRow: 0 bitsPerPixel: 32];
            [theImageRep autorelease];

            image = [[NSImage allocWithZone: [self zone]] initWithSize: NSMakeSize(actualSize.width, actualSize.height)];
            [image addRepresentation: theImageRep];

            [image lockFocus];
            [[NSColor colorWithDeviceRed: ((double)((imageBackground>>0)&0xff))/255.0
                                   green: ((double)((imageBackground>>8)&0xff))/255.0
                                    blue: ((double)((imageBackground>>16)&0xff))/255.0
                                   alpha: 1.0] set];
            NSRectFill(NSMakeRect(0,0, actualSize.width, actualSize.height));
            [image unlockFocus];

            [ourSession queueEvent: [GlkEvent eventWithType: evtype_Redraw
                                                        win: self
                                                       val1: 0
                                                       val2: 0]];
        }
    }
}

- (void) recalculateStyles {    
    NSFont* propFont  = [ourSession proportionalFont];
    NSFont* fixedFont = [ourSession fixedPitchFont];

    if (type == wintype_TextGrid) {
        propFont = fixedFont;
    }

    double indentMetric = [fixedFont widthOfString: @"0"]/2;

    int sty;

    for (sty = 0; sty < style_NUMSTYLES; sty++) {        
        // Release the old attributes
        if (font[sty] != nil)            [font[sty] release];
        if (fontColour[sty] != nil)      [fontColour[sty] release];
        if (backColour[sty] != nil)      [backColour[sty] release];
        if (paragraphStyle[sty] != nil)  [paragraphStyle[sty] release];
        if (styleAttributes[sty] != nil) [styleAttributes[sty] release];
        
        NSFont* baseFont = styleHint[stylehint_Proportional][sty]?propFont:fixedFont;

        // Work out the font to use
        if (styleHint[stylehint_Size][sty] == 0 &&
            styleHint[stylehint_Weight][sty] == 0 &&
            styleHint[stylehint_Oblique][sty] == 0) {
            font[sty] = [baseFont retain];
        } else {
            NSString* fontFamily = [baseFont familyName];
            NSString* fontName   = [baseFont fontName];

            double    sz         = [baseFont pointSize];

            if (styleHint[stylehint_Size][sty] < 0) {
                double shrink = 1 - (((double)styleHint[stylehint_Size][sty])/4.0);

                sz /= shrink;
            } else {
                double magnify = 1 + (((double)styleHint[stylehint_Size][sty])/4.0);

                sz *= magnify;
            }

            NSMutableArray* fontsToTry = [NSMutableArray array];

            // Start it off
            [fontsToTry addObject: fontName];
            [fontsToTry addObject: fontFamily];

            // Add the various attributes as required
            if (styleHint[stylehint_Weight][sty] < 0) {
                addFontAttribute(fontsToTry, [NSArray arrayWithObject: @"Light"]);
            } else if (styleHint[stylehint_Weight][sty] == 0) {
                //addFontAttribute(fontsToTry, [NSArray arrayWithObject: @"Medium"]);
            } else if (styleHint[stylehint_Weight][sty] > 0) {
                addFontAttribute(fontsToTry, [NSArray arrayWithObject: @"Bold"]);
            }

            if (styleHint[stylehint_Oblique][sty] != 0) {
                addFontAttribute(fontsToTry, [NSArray arrayWithObjects: @"Oblique",
                    @"Italic", nil]);
            }

            // Try the various combinations until we find one that produces a
            // valid font
            NSFont* fnt = nil;
            NSEnumerator* nameEnum = [fontsToTry reverseObjectEnumerator];
            NSString*     name;

            while (fnt == nil && (name = [nameEnum nextObject])) {
                fnt = [NSFont fontWithName: name
                                      size: sz];
            }

            if (fnt == nil) fnt = baseFont;

            font[sty] = [fnt retain];
        }

        // Paragraph style
        if (styleHint[stylehint_Indentation][sty] != 0 ||
            styleHint[stylehint_ParaIndentation][sty] != 0 ||
            styleHint[stylehint_Justification][sty] != stylehint_just_LeftFlush) {
            NSMutableParagraphStyle* pStyle = [[NSMutableParagraphStyle allocWithZone: [self zone]] init];

            // Indentation
            double indent = indentMetric * styleHint[stylehint_Indentation][sty];
            if (indent < 0) {
                // Can't outdent
                indent = 0;
            }

            double paraIndent = indent + (indentMetric * styleHint[stylehint_ParaIndentation][sty]);

            if (paraIndent < 0) {
                // Can't outdent
                paraIndent = 0;
            }

            [pStyle setHeadIndent: indent];
            [pStyle setTailIndent: -indent];
            [pStyle setFirstLineHeadIndent: paraIndent];

            // Alignment
            switch (styleHint[stylehint_Justification][sty]) {
                case stylehint_just_RightFlush:
                    [pStyle setAlignment: NSRightTextAlignment];
                    break;

                case stylehint_just_Centered:
                    [pStyle setAlignment: NSCenterTextAlignment];
                    break;
                    
                case stylehint_just_LeftRight:
                    [pStyle setAlignment: NSJustifiedTextAlignment];
                    break;

                case stylehint_just_LeftFlush:
                default:
                    [pStyle setAlignment: NSLeftTextAlignment];
                    break;
            }

            paragraphStyle[sty] = pStyle;
        } else {
            // No style
            paragraphStyle[sty] = nil;
        }

        // Colours
        glui32 fcol = styleHint[stylehint_TextColor][sty];
        glui32 bcol = styleHint[stylehint_BackColor][sty];

        if (styleHint[stylehint_ReverseColor][sty]) {
            glui32 tmp = fcol;

            fcol = bcol;
            bcol = tmp;
        }

        fontColour[sty] = [[NSColor colorWithDeviceRed: ((double)((fcol>>0)&0xff))/255.0
                                                green: ((double)((fcol>>8)&0xff))/255.0
                                                 blue: ((double)((fcol>>16)&0xff))/255.0
                                                 alpha: 1.0] retain];
        
        backColour[sty] = [[NSColor colorWithDeviceRed: ((double)((bcol>>0)&0xff))/255.0
                                                 green: ((double)((bcol>>8)&0xff))/255.0
                                                  blue: ((double)((bcol>>16)&0xff))/255.0
                                                 alpha: 1.0] retain];

        // Attributes
        NSMutableDictionary* attr = [[NSMutableDictionary allocWithZone: [self zone]] init];

        [attr setObject: font[sty]
                 forKey: NSFontAttributeName];
        [attr setObject: fontColour[sty]
                 forKey: NSForegroundColorAttributeName];
        [attr setObject: backColour[sty]
                 forKey: NSBackgroundColorAttributeName];

        if (paragraphStyle[sty] != nil) {
            [attr setObject: paragraphStyle[sty]
                     forKey: NSParagraphStyleAttributeName];
        }

        styleAttributes[sty] = attr;
    }

    stylesNeedRecalculating = NO;
}

// == NSTextStorage delegate functions ==
- (void)textStorageDidProcessEditing:(NSNotification *)aNotification {
    // Set the input character attributes to the input style
    [text setAttributes: [self attributesForStyle: style_Input]
                  range: NSMakeRange(inputPos,
                                     [text length]-inputPos)];

    // Check to see if there's any newlines in the input...
    int newlinePos = -1;
    do {
        int x;
        NSString* str = [text string];
        int len = [str length];

        newlinePos = -1;

        for (x=inputPos; x < len; x++) {
            if ([str characterAtIndex: x] == '\n') {
                newlinePos = x;
                break;
            }
        }

        if (newlinePos >= 0) {
            [pendingInput appendString:
                [str substringWithRange: NSMakeRange(inputPos,
                                                     newlinePos-inputPos+1)]];
            inputPos = newlinePos + 1;

            if (requestedLineEvents > 0) {                
                // Generate an event (the actual reading is done later)
                GlkEvent* newEvent = [GlkEvent eventWithType: evtype_LineInput
                                                         win: self
                                                        val1: 0
                                                        val2: 0];

                // val1, val2 filled in later
                [ourSession queueEvent: newEvent];
            }
        }
    } while (newlinePos >= 0);
}

// == Images ==
- (NSImage*)         image {
    return image;
}

- (void) drawImage: (NSImage*) drawMe
              val1: (glsi32) v1
              val2: (glsi32) v2 {
    if (type == wintype_TextBuffer) {
        [[textBuffer mutableString] appendString: @" "];
        [self flushBuffer];

        GlkImage* theImage = [[GlkImage allocWithZone: [self zone]]
                initWithImage: drawMe
                    alignment: v1
                         size: [drawMe size]
                          win: self
                     position: inputPos-1];

        if (!inlineImages) {
            inlineImages = [[NSMutableArray allocWithZone: [self zone]] init];
        }

        [inlineImages addObject: theImage];
        return;
    }
    
    if (type != wintype_Graphics) {
        NSLog(@"Images only supported in graphics windows (FIXME)");
        return;
    }

    if (image == nil) {
        NSLog(@"drawImage called before the window image was created");
        return;
    }

    [image lockFocus];

    // Annoying flipped coordinate system
    v2 = [image size].height - v2 - [drawMe size].height;

    [drawMe drawAtPoint: NSMakePoint(v1, v2)
               fromRect: NSMakeRect(0,0,
                                    [drawMe size].width,
                                    [drawMe size].height)
              operation: NSCompositeSourceOver
               fraction: 1.0];

    [image unlockFocus];

    needsDisplay = YES;
}

- (void) drawImageScaled: (NSImage*) drawMe
                    val1: (glsi32) v1
                    val2: (glsi32) v2
               withWidth: (glui32) width
                  height: (glui32) height {
    if (type != wintype_Graphics) {
        NSLog(@"Images only supported in graphics windows (FIXME)");
        return;
    }

    if (image == nil) {
        NSLog(@"drawImage called before the window image was created");
        return;
    }

    [image lockFocus];

    [[NSGraphicsContext currentContext]  setImageInterpolation:
        NSImageInterpolationHigh];
    
    // Annoying flipped coordinate system
    v2 = [image size].height - v2 - height;
    
    [drawMe drawInRect: NSMakeRect(v1, v2, width, height)
              fromRect: NSMakeRect(0,0,
                                   [drawMe size].width,
                                   [drawMe size].height)
             operation: NSCompositeSourceOver
              fraction: 1.0];

    [image unlockFocus];

    needsDisplay = YES;
}

- (void) setBackground: (glui32) background {
    if (!image) {
        NSLog(@"setBackground called for non-graphics window");
        return;
    }
    
    imageBackground = background;
    
    [image lockFocus];
    [[NSColor colorWithDeviceRed: ((double)((imageBackground>>0)&0xff))/255.0
                           green: ((double)((imageBackground>>8)&0xff))/255.0
                            blue: ((double)((imageBackground>>16)&0xff))/255.0
                           alpha: 1.0] set];
    NSRectFill(NSMakeRect(0,0, actualSize.width, actualSize.height));
    [image unlockFocus];

    needsDisplay = YES;
}

- (void) fillRect: (NSRect) rect
       withColour: (glui32) colour {
    if (colour == 0xffffffff) {
        colour = imageBackground;
    }

    // Flip that coordinate system
    rect.origin.y = [image size].height - rect.origin.y - rect.size.height;

    [image lockFocus];
    [[NSColor colorWithDeviceRed: ((double)((colour>>0)&0xff))/255.0
                           green: ((double)((colour>>8)&0xff))/255.0
                            blue: ((double)((colour>>16)&0xff))/255.0
                           alpha: 1.0] set];
    NSRectFill(rect);
    [image unlockFocus];

    needsDisplay = YES;
}

- (void) breakFlow {
    if (type == wintype_TextBuffer) {
        if (inlineImages == nil) {
            return;
        }

        // Find the last image without a flow break
        NSEnumerator* breakImg = [inlineImages reverseObjectEnumerator];
        GlkImage* img = nil;

        while (img = [breakImg nextObject]) {
            if ([img flowBreakPoint] < 0) {
                break;
            }
        }

        // Add a flow break
        if (img != nil) {
            [self flushBuffer];
            
            [img setFlowBreakPoint: inputPos];
        }

        return;
    }

    NSLog(@"breakFlow not implemented for this window type");
}

- (NSMutableArray*) inlineImages {
    return inlineImages;
}

@end
