//
//  GlkTextGridView.m
//  CocoaGlk
//
//  Created by Andrew Hunter on Sun Jun 15 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "GlkTextGridView.h"


@implementation GlkTextGridView

- (id) initWithFrame: (NSRect) frame
              window: (GlkWindow*) win {
    self = [super initWithFrame:frame];
    if (self) {
        glkWin = win;
        flashOn = NO;

        timer = nil;
    }
    return self;
}

- (void) dealloc {
    if (timer) {
        [timer invalidate];
        [timer release];

        timer = nil;
    }

    [super dealloc];
}

- (void)drawRect:(NSRect)rect {
    int y;
    GlkSize winSize = [glkWin size];
    NSPoint pos;

    char** grid = [glkWin textGrid];

    NSEraseRect(rect);
    
    NSDictionary* attr = [glkWin attributesForStyle: style_Normal];
    NSSize fntSz       = [@"0" sizeWithAttributes: attr];

    pos = NSMakePoint(0,0);

    for (y=0; y<winSize.height; y++) {
		if (/* DISABLES CODE */ (1) || (pos.y >= rect.origin.y &&
            pos.y <= rect.origin.y + fntSz.height)) {
            NSMutableAttributedString* lineToDraw;

			NSData *lineData = [NSData dataWithBytes:grid[y]
											  length:winSize.width];
            NSString* lineString = [[NSString alloc] initWithData:lineData
														 encoding:NSUTF8StringEncoding];

            lineToDraw =
                [[NSMutableAttributedString allocWithZone: [self zone]] initWithString: lineString
                                                                     attributes: attr];
			[lineString release];

            if (flashOn && [glkWin cursorPoint].y == y) {
                NSMutableDictionary* newAttr = [attr mutableCopy];

                flashPoint = [glkWin cursorPoint];

                [newAttr setObject: [NSColor selectedTextBackgroundColor]
                            forKey: NSBackgroundColorAttributeName];
                [newAttr setObject: [NSColor blackColor]
                            forKey: NSForegroundColorAttributeName];
                
                [[lineToDraw mutableString] appendString: @" "];
                [lineToDraw setAttributes: newAttr
                                    range: NSMakeRange(flashPoint.x, 1)];
            }

            [lineToDraw drawAtPoint: pos];
            [lineToDraw release];
        }

        pos.y += fntSz.height;
    }
}

- (BOOL) acceptsFirstResponder {
    if ([glkWin requestedCharEvents]) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL) isFlipped {
    return YES;
}

- (void) needsFlashDisplay {
    NSDictionary* attr = [glkWin attributesForStyle: style_Normal];
    NSSize fntSz       = [@"0" sizeWithAttributes: attr];

    NSRect r;

    r.origin = NSMakePoint(fntSz.width*flashPoint.x,
                           [self bounds].size.height - fntSz.height*(flashPoint.y+1));
    r.size = fntSz;

    [self setNeedsDisplayInRect: r];
}

- (BOOL) becomeFirstResponder {
    flashOn = YES;
    [self needsFlashDisplay];

    if (timer) {
        [timer invalidate];
        [timer release];

        timer = nil;
    }

    timer = [[NSTimer scheduledTimerWithTimeInterval:0.5
                                              target:self
                                            selector:@selector(flashTick)
                                            userInfo:nil
                                             repeats:YES]
        retain];
    
    return YES;
}

- (BOOL) resignFirstResponder {
    if (timer) {
        [timer invalidate];
        [timer release];

        timer = nil;
    }
    
    flashOn = NO;
    [self needsFlashDisplay];
    
    return YES;
}

- (void)keyDown:(NSEvent *)theEvent {
    if (![glkWin handleKeyDown: theEvent]) {
        [super keyDown: theEvent];
    }
}

- (void)mouseDown:(NSEvent*) theEvent {
    if (![glkWin requestedMouseEvent]) {
        [super mouseDown: theEvent];
    } else {
        NSRect bounds = [self bounds];
        
        NSDictionary* attr = [glkWin attributesForStyle: style_Normal];
        NSSize fntSz       = [@"0" sizeWithAttributes: attr];

        NSPoint clickPos = [self convertPoint: [theEvent locationInWindow]
                                     fromView: nil];

        [[glkWin session] queueEvent: [GlkEvent eventWithType: evtype_MouseInput
                                                          win: glkWin
                                                         val1: clickPos.x / fntSz.width
                                                         val2: (bounds.size.height - clickPos.y) / fntSz.height]];
        
        [glkWin cancelMouseEvent];
    }
}

- (void) flashTick {
    flashOn = !flashOn;
    [self needsFlashDisplay];
}

@end
