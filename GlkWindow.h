//
//  GlkWindow.h
//  CocoaGlk
//
//  Created by Andrew Hunter on Wed Jun 11 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

// This represents a window (in the Glk sense rather than the Cocoa sense)

#import <Cocoa/Cocoa.h>
#import "GlkSession.h"

@class GlkWindow;
@class GlkWindowView;

// Types
typedef struct GlkArrangement {
    glui32        method;
    glui32        size;
    GlkWindow*    keyWin;
} GlkArrangement;

typedef struct GlkSize {
    glui32 width;
    glui32 height;
} GlkSize;

typedef struct GlkPoint {
    glui32 x;
    glui32 y;
} GlkPoint;

// Utility functions
extern GlkArrangement GlkMakeArrangement(glui32 method, glui32 size, GlkWindow* keyWin);
extern GlkSize GlkMakeSize(int width, int height);
extern GlkPoint GlkMakePoint(int x, int y);

@interface GlkWindow : NSObject <NSTextStorageDelegate> {
    GlkSession* ourSession;
    glui32      type;

    GlkWindow*  parent;
    BOOL open;

    // Pair window type
    GlkWindow*  left;
    GlkWindow*  right;

    // Window attributes
    glui32 position;
    BOOL   isProportional;
    BOOL   isFixed;

    double size;

    glui32 rock;

    glui32 requestedLineEvents;
    BOOL requestedCharEvents;
    BOOL requestedMouseEvents;

    int lineLength;

    GlkSize  actualSize;
    GlkPoint cursorPoint;

    // Echo stream
    GlkStream* echoStream;

    // Text window type
    NSTextStorage*             text;
    NSMutableAttributedString* textBuffer;
    int                        inputPos;

    NSMutableArray*            inlineImages;

    NSMutableString* pendingInput;

    // Grid window type
    char**   grid;
    glui32** gridStyle;

    BOOL wasFlushed;

    // Image window type
    NSImage* image;
    glui32   imageBackground;
    BOOL     needsDisplay;

    // This window's stream
    GlkStream* winStream;

    // The view representing this window
    GlkWindowView* view;

    // This window's styles
    NSFont*           font           [style_NUMSTYLES];
    NSColor*          fontColour     [style_NUMSTYLES];
    NSColor*          backColour     [style_NUMSTYLES];
    NSParagraphStyle* paragraphStyle [style_NUMSTYLES];
    NSDictionary*     styleAttributes[style_NUMSTYLES];

    glsi32 styleHint[stylehint_NUMHINTS][style_NUMSTYLES];

    BOOL stylesNeedRecalculating;

    BOOL needsArranging;
	
	// Speech output:
	NSSpeechSynthesizer*	speaker;
}

// Initialisation
- (id) initWithSession: (GlkSession*) session;

// The glk functions
- (GlkWindow*)     openWithMethod: (glui32) method
                             size: (glui32) size
                             type: (glui32) type
                             rock: (glui32) rock;
- (stream_result_t) close;
- (GlkSize)        size;
- (void)           setArrangement: (GlkArrangement) arrangement;
- (GlkArrangement) arrangement;
- (glui32)         rock;
- (glui32)         type;
- (GlkWindow*)     parent;
- (GlkWindow*)     sibling;
- (void)           clear;
- (void)           moveCursorToPoint: (GlkPoint) point;

- (GlkStream*)     stream;
- (void)           setEchoStream: (GlkStream*) stream;
- (GlkStream*)     echoStream;

- (glui32)         distinguishStyle: (glui32) styl1
                          fromStyle: (glui32) styl2;
- (glui32)         measureStyle: (glui32) styl
                           hint: (glui32) hint
                       resultIn: (glui32*) result;

- (void)          requestLineEvent: (int)       length
                              init: (NSString*) init;
- (void)          requestCharEvent;
- (void)          requestMouseEvent;

- (GlkEvent*)     cancelLineEvent;
- (void)          cancelCharEvent;
- (void)          cancelMouseEvent;

-(void)			  toggleSpeechSynthesis: (id)sender;
-(BOOL)			  speechSynthesisOn;

// Images
- (void)          drawImage: (NSImage*) drawMe
                       val1: (glsi32) v1
                       val2: (glsi32) v2;
- (void)    drawImageScaled: (NSImage*) drawMe
                       val1: (glsi32) v1
                       val2: (glsi32) v2
                  withWidth: (glui32) width
                     height: (glui32) height;
- (void)      setBackground: (glui32) background;
- (void)           fillRect: (NSRect) rect
                 withColour: (glui32) colour; // == 0xffffffff for background

- (void)          breakFlow;

- (NSImage*)         image;
- (NSMutableArray*)  inlineImages;

// Our housekeeping functions
- (GlkSession*) session;
- (void)        windowNeedsArranging;
- (GlkWindowView*) view;

- (glui32)      position;

- (GlkWindow*) left;
- (GlkWindow*) right;

- (BOOL)       fixed;
- (BOOL)       proportional;
- (double)     sizeValue;
- (void)       setSizeValue: (double) size;

- (NSMutableAttributedString*) textBuffer;
- (NSTextStorage*)   textStorage;
- (int)              inputPos;
- (void)             setInputPos: (int) newPos;
- (NSMutableString*) pendingInput;
- (void)             updateOpportunity;
- (BOOL)             flushBuffer;

- (void)             queueArrangement;
- (void)             alreadyArranged;

- (char**)           textGrid;

- (BOOL)             requestedLineEvents;
- (BOOL)             requestedCharEvents;
- (BOOL)             requestedMouseEvent;

- (void)             sizeIsNow: (GlkSize) size;

- (BOOL) handleKeyDown: (NSEvent*) theEvent;

- (GlkPoint) cursorPoint;

// Styles
- (NSFont*)           fontForStyle: (glui32) style;
- (NSColor*)          colorForStyle: (glui32) style;
- (NSColor*)          backColorForStyle: (glui32) style;
- (NSParagraphStyle*) paragraphStyleForStyle: (glui32) style;

- (NSDictionary*)     attributesForStyle: (glui32) style;

- (void)              recalculateStyles;

@end
