//
//  GlkImage.h
//  CocoaGlk
//
//  Created by Andrew Hunter on Wed Jun 18 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GlkWindow.h"
#import "glk.h"

extern NSString* GlkImageAttributeName;

@class GlkWindow;
@interface GlkImage : NSObject {
    NSImage* image;
    glui32   alignment;
    GlkWindow* glkWin;
    int pos;

    int flowBreakPoint;

    NSSize   size;

    BOOL boundsNeedCalculating;

    NSRect bounds;
}

- (id) initWithImage: (NSImage*)   img
           alignment: (glui32)     align
                size: (NSSize)     scaling
                 win: (GlkWindow*) win
            position: (int)        textPos;

- (NSImage*) image;
- (glui32)   alignment;
- (NSSize)   size;

- (NSRect)   bounds;
- (void)     uncacheBounds;

- (int)      flowBreakPoint;
- (void)     setFlowBreakPoint: (int) point;

@end
