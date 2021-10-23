//
//  GlkGraphicsView.m
//  CocoaGlk
//
//  Created by Andrew Hunter on Tue Jun 17 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "GlkGraphicsView.h"


@implementation GlkGraphicsView


- (id) initWithFrame: (NSRect) frame
              window: (GlkWindow*) win {
    self = [super initWithFrame:frame];
    if (self) {
        glkWin = win;
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    NSImage* img = [glkWin image];
    
    [img drawInRect: [self bounds]
           fromRect: NSMakeRect(0,0,
                                [img size].width, [img size].height)
          operation: NSCompositingOperationSourceOver
           fraction: 1.0];
}

- (void)mouseDown:(NSEvent*) theEvent {
    if (![glkWin requestedMouseEvent]) {
        [super mouseDown: theEvent];
    } else {
        NSRect bounds = [self bounds];

        NSPoint clickPos = [self convertPoint: [theEvent locationInWindow]
                                     fromView: nil];

        [[glkWin session] queueEvent: [GlkEvent eventWithType: evtype_MouseInput
                                                          win: glkWin
                                                         val1: clickPos.x
                                                         val2: (bounds.size.height - clickPos.y)]];

        [glkWin cancelMouseEvent];
    }
}

@end
