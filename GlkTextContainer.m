//
//  GlkTextContainer.m
//  CocoaGlk
//
//  Created by Andrew Hunter on Fri Jun 20 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "GlkTextContainer.h"
#import "GlkImage.h"


@implementation GlkTextContainer

- (id) initWithWindow: (GlkWindow*) win
                 size: (NSSize) size {
    self = [super initWithContainerSize: size];
    
    if (self) {
        glkWin = win;
    }

    return self;
}

- (BOOL)isSimpleRectangularTextContainer {
    return NO;
}

- (NSRect)lineFragmentRectForProposedRect:(NSRect)proposedRect
                           sweepDirection:(NSLineSweepDirection)sweepDirection
                        movementDirection:(NSLineMovementDirection)movementDirection
                            remainingRect:(NSRect *)remainingRect {
    NSRect res = [super lineFragmentRectForProposedRect: proposedRect
                                         sweepDirection: sweepDirection
                                      movementDirection: movementDirection
                                          remainingRect: remainingRect];

    // *remainingRect = NSZeroRect;

    // Check for images that distort this line
    NSRect imgBounds = NSMakeRect(0,0,0,0);

    // For each image..
    NSEnumerator* imgEnum = [[glkWin inlineImages] objectEnumerator];
    GlkImage*     img;

    GlkImage* overlapImage = nil;

    while (img = [imgEnum nextObject]) {
        // Retrieve/calculate the bounds of this image
        NSRect theseBounds = [img bounds];

        // If it intersects, then update the notification about which
        // overlap image we're dealing with
        if (NSIntersectsRect(theseBounds, res)) {
            overlapImage = img;
            imgBounds = theseBounds;

            int bpoint = [img flowBreakPoint];

            if (bpoint >= 0) {
                //NSLayoutManager* mgr = [[win view] layoutManager];
                
            }

            // .. and update the bounds appropriately
            switch ([img alignment]) {
                case imagealign_MarginRight:
                    // Right alignment
                    res.size.width -= (NSMaxX(res) - NSMinX(theseBounds));
                    break;
                
                case imagealign_MarginLeft:
                default:
                    // Left alignment
                    res.size.width -= (NSMaxX(theseBounds) - NSMinX(res));
                    res.origin.x    = NSMaxX(theseBounds);
            }
        }

        if (theseBounds.origin.y > NSMaxY(res)) {
            // No following images
            break;
        }
    }

    return res;
}

@end
