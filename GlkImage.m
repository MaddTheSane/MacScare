//
//  GlkImage.m
//  CocoaGlk
//
//  Created by Andrew Hunter on Wed Jun 18 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "GlkImage.h"
#import "GlkWindowView.h"

#import "glk.h"

NSString* GlkImageAttributeName = @"GlkImageAttribute";

@implementation GlkImage

- (id) initWithImage: (NSImage*)   img
           alignment: (glui32)     align
                size: (NSSize)     scaling
                 win: (GlkWindow*) win
            position: (int)        textPos {
    self = [super init];

    if (self) {
        image = [img retain];
        alignment = align;
        size = scaling;
        glkWin = win;
        pos = textPos;

        flowBreakPoint = -1;

        boundsNeedCalculating = YES;
    }

    return self;
}

- (void) dealloc {
    [image release];
    
    [super dealloc];
}

- (NSImage*) image {
    return image;
}

- (glui32) alignment {
    return alignment;
}

- (NSSize) size {
    return size;
}

- (void) setFlowBreakPoint: (int) point {
    flowBreakPoint = point;
}

- (int) flowBreakPoint {
    return flowBreakPoint;
}

- (NSRect)   bounds {
    if (boundsNeedCalculating) {
        // Re-entrancy might be a problem sometimes
        bounds = NSMakeRect(0,0,0,0);
        boundsNeedCalculating = 0;
        
        // Get the position of the glyph that this image is attached to
        NSLayoutManager* layout = [[glkWin view] layoutManager];
        NSRange ourLine;

        NSRange ourGlyph = [layout glyphRangeForCharacterRange: NSMakeRange(pos,1)
                                          actualCharacterRange: &ourLine];

        NSRect theGlyphLine = [layout lineFragmentRectForGlyphAtIndex: ourGlyph.location
                                                       effectiveRange: nil];

        // Bounds are dependent on the alignment type
        switch (alignment) {
            case imagealign_MarginRight:
                // Right margin alignment
                bounds = NSMakeRect(NSMaxX(theGlyphLine) - size.width,
                                    theGlyphLine.origin.y,
                                    size.width,
                                    size.height);
                break;
            
            case imagealign_MarginLeft:
            default:
                // Left margin alignment
                bounds = NSMakeRect(theGlyphLine.origin.x,
                                    theGlyphLine.origin.y,
                                    size.width,
                                    size.height);
        }

        // Invalidate...
        [layout invalidateLayoutForCharacterRange: ourLine
                                           isSoft: YES
                             actualCharacterRange: nil];

        // Done
    }

    return bounds;
}

- (void)     uncacheBounds {
    boundsNeedCalculating = YES;
}

@end
