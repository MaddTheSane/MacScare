//
//  GlkTextView.m
//  CocoaGlk
//
//  Created by Andrew Hunter on Sun Jun 15 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "GlkTextView.h"
#import "GlkImage.h"


@implementation GlkTextView

- (id) initWithFrame: (NSRect) frame
       textContainer: (NSTextContainer*) container
           glkWindow: (GlkWindow*) win {
    self = [super initWithFrame: frame
                  textContainer: container];

    if (self) {
        glkWin = win;
    }

    return self;
}

- (void)keyDown:(NSEvent *)theEvent {
    if (![glkWin handleKeyDown: theEvent]) {
        [super keyDown: theEvent];
    }
}

- (void) drawRect: (NSRect) rect {
    [super drawRect: rect];
    
    // Draw any images that need drawing
    // For each image..
    NSEnumerator* imgEnum = [[glkWin inlineImages] objectEnumerator];
    GlkImage*     img;

    while (img = [imgEnum nextObject]) {
        // Retrieve/calculate the bounds of this image
        NSRect theseBounds = [img bounds];

        // If it intersects, then update the notification about which
        // overlap image we're dealing with
        if (NSIntersectsRect(theseBounds, rect)) {
            NSImage* drawMe = [img image];

            [drawMe setFlipped: YES];

            [drawMe drawInRect: theseBounds
                      fromRect: NSMakeRect(0,0,
                                           [drawMe size].width,
                                           [drawMe size].height)
                     operation: NSCompositeSourceOver
                      fraction: 1.0];

            [drawMe setFlipped: NO];
        }

        if (theseBounds.origin.y > NSMaxY(rect)) {
            // No following images
            break;
        }
    }
}

@end
