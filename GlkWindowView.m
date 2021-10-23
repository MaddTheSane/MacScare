//
//  GlkWindowView.m
//  CocoaGlk
//
//  Created by Andrew Hunter on Wed Jun 11 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "GlkWindowView.h"
#import "GlkTextBufferView.h"
#import "GlkTextGridView.h"

#import "GlkGraphicsView.h"


@implementation GlkWindowView

- (id) initWithGlkWindow: (GlkWindow*) win {
    self = [super initWithFrame: NSMakeRect(0,0,0,0)];

    if (self) {
        glkWin = win;

        [self setPostsFrameChangedNotifications: YES];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(frameChanged:)
                                                     name: NSViewFrameDidChangeNotification
                                                   object: self];

        madeSubviews = NO;
    }
    
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    [super dealloc];
}


-(BOOL) validateMenuItem: (NSMenuItem*)mi
{
	if( [mi action] == @selector(toggleSpeechSynthesis:) )
	{
		[mi setState: [glkWin speechSynthesisOn]];
		return YES;
	}
	else
		return NO;
}


-(void) toggleSpeechSynthesis: (id)sender
{
	[glkWin toggleSpeechSynthesis: sender];
}

- (void) performArrangement {
    [self setPostsFrameChangedNotifications: NO];
    
    NSRect bounds = [self bounds];

    if (!madeSubviews) {
        // Clear out any old subviews
        [[self subviews] makeObjectsPerformSelector: @selector(removeFromSuperview)];
        splitter = nil;
    }
    
    switch ([glkWin type]) {
        case wintype_Pair:
        {
            // Get the preferred sizes of the subviews
            leftSize = [[[glkWin left] view] preferredSize];

            glui32 position = [glkWin position];

            BOOL isFixed = [glkWin fixed];
            BOOL isProportional = [glkWin proportional];
            BOOL isVertical = (position==winmethod_Above||position==winmethod_Below)?YES:NO;

            float ourLen = isVertical?bounds.size.height:bounds.size.width;

            if (!isFixed && !isProportional) {
                // Is a resizable window - create the splitter
                if (!madeSubviews) {
                    splitter = [[NSSplitView allocWithZone: [self zone]] initWithFrame: bounds];

                    [splitter setDelegate: self];
                    [splitter setVertical: !isVertical];

                    if (position == winmethod_Above ||
                        position == winmethod_Left) {
                        [splitter addSubview: [[glkWin left] view]];
                        [splitter addSubview: [[glkWin right] view]];
                    } else {
                        [splitter addSubview: [[glkWin right] view]];
                        [splitter addSubview: [[glkWin left] view]];
                    }

                    [self addSubview: splitter];
                    //[splitter release];
                }

                [splitter setFrame: bounds];
                ourLen -= [splitter dividerThickness];
            } else {
                ourLen -= 2;

                if (!madeSubviews) {
                    [self addSubview: [[glkWin left] view]];
                    [self addSubview: [[glkWin right] view]];
                }
            }

            // Work out the actual sizes of the views to use
            if (!isFixed) {
                double lProp = leftSize / 100.0;

                leftSize = floor(lProp * ourLen + 0.5);
                rightSize = ourLen - leftSize;
                //rightSize = (1-lProp) * ourLen;
            } else {
                leftSize = floor(leftSize + 0.5);
                rightSize = ourLen - leftSize;
                if (rightSize < 4) {
                    rightSize = 4;
                    leftSize  = ourLen-4;
                }
            }

            // Size the subviews
            NSRect leftRect, rightRect;
            leftRect = rightRect = bounds;

            if (position == winmethod_Above ||
                position == winmethod_Below) {
                leftRect.size.height = leftSize;
                rightRect.size.height = rightSize;

                if (position == winmethod_Below) {
                    rightRect.origin.y += leftSize+2;
                    offset = leftSize;
                } else {
                    leftRect.origin.y += rightSize+2;
                    offset = rightSize;
                }
            }

            if (position == winmethod_Left ||
                position == winmethod_Right) {
                leftRect.size.width = leftSize;
                rightRect.size.width = rightSize;

                if (position == winmethod_Left) {
                    rightRect.origin.x += leftSize+2;
                    offset = leftSize;
                } else {
                    leftRect.origin.x += rightSize+2;
                    offset = rightSize;
                }
            }

            if (!isFixed && !isProportional) {
                [[[glkWin left] view] setFrameSize: leftRect.size];
                [[[glkWin right] view] setFrameSize: rightRect.size];
            } else {
                [[[glkWin left] view] setFrame: leftRect];
                [[[glkWin right] view] setFrame: rightRect];
            }

            [[[glkWin left] view] updateSize];
            [[[glkWin right] view] updateSize];

            [[[glkWin left] view] performArrangement];
            [[[glkWin right] view] performArrangement];
            break;
        }

        case wintype_TextBuffer:
            if (!madeSubviews) {
                subview = [[GlkTextBufferView allocWithZone: [self zone]]
                    initWithFrame: bounds
                           window: glkWin];
                [self addSubview: subview];
                [subview release];
            }

            [subview setFrame: bounds];
            [(GlkTextBufferView*)subview performResize];
            break;

        case wintype_TextGrid:
            if (!madeSubviews) {
                subview = [[GlkTextGridView allocWithZone: [self zone]]
                    initWithFrame: bounds
                           window: glkWin];
                [self addSubview: subview];
                [subview release];
            }

            [subview setFrame: bounds];
            break;

        case wintype_Graphics:
            if (!madeSubviews) {
                subview = [[GlkGraphicsView allocWithZone: [self zone]]
                    initWithFrame: bounds
                           window: glkWin];
                [self addSubview: subview];
                [subview release];
            }

            [subview setFrame: bounds];
            break;
            
        default:
            break;    
    }

    [self windowRequestStatusChanged];
    [self setPostsFrameChangedNotifications: YES];

    madeSubviews = YES;
}

- (void) drawRect: (NSRect) r {
    if ([glkWin fixed] || [glkWin proportional]) {
        NSRect cRect1, cRect2;
        NSRect bounds = [self bounds];

        if ([glkWin position] == winmethod_Above ||
            [glkWin position] == winmethod_Below) {
            cRect1 = NSMakeRect(bounds.origin.x,
                                bounds.origin.y + offset + 1,
                                bounds.size.width,
                                1);
            cRect2 = cRect1;
            cRect2.origin.y -= 1;
        } else {
            cRect1 = NSMakeRect(bounds.origin.x + offset + 1,
                                bounds.origin.y,
                                1,
                                bounds.size.height);
            cRect2 = cRect1;
            cRect2.origin.x -= 1;
        }

        [[NSColor controlShadowColor] set];
        NSRectFill(cRect1);
        [[NSColor controlHighlightColor] set];
        NSRectFill(cRect2);
    }
    
    [super drawRect: r];
}

- (double) preferredSize {
    if ([glkWin parent] != nil && [[glkWin parent] fixed]) {
        double sz = [glkWin sizeValue];

        switch ([glkWin type]) {
            case wintype_Graphics:
                return sz;
                break;
            
            default:
            {
                NSDictionary* attr = [glkWin attributesForStyle: style_Normal];
                NSSize fntSz       = [@"0" sizeWithAttributes: attr];

                double fntSz2 = ([[glkWin parent] position]==winmethod_Above||[[glkWin parent] position]==winmethod_Below)?fntSz.height:fntSz.width;

                return fntSz2 * sz;
            }
        }
    } else {
        return [glkWin sizeValue];
    }
}

- (void) forceViewReorder {
    madeSubviews = NO;

    if ([glkWin type] == wintype_Pair) {
        [[[glkWin left] view] forceViewReorder];
        [[[glkWin right] view] forceViewReorder];
    }

    [[self subviews] makeObjectsPerformSelector: @selector(removeFromSuperview)];
}

- (void) windowRequestStatusChanged {
    switch ([glkWin type]) {
        case wintype_TextBuffer:
            if (subview != nil) {
                [(GlkTextBufferView*)subview windowRequestStatusChanged];
            }
            break;

        case wintype_TextGrid:
            if (subview != nil &&
                ([glkWin requestedLineEvents] ||
                 [glkWin requestedCharEvents])) {
                [[[glkWin session] window] makeFirstResponder: subview];
            }
            break;

        default:
            // Do nothing
            break;
    }
}

- (void) windowContentChanged {
    switch ([glkWin type]) {
        case wintype_TextBuffer:
            if (subview != nil) {
                [(GlkTextBufferView*)subview windowContentChanged];
            }
            break;

        case wintype_TextGrid:
        case wintype_Graphics:
            if (subview) {
                [subview setNeedsDisplay: YES];
            }
            break;

        default:
            // Do nothing
            break;
    }
}

- (void) focus {
    if (subview != nil &&
        ([glkWin requestedLineEvents] ||
         [glkWin requestedCharEvents])) {
        [[[glkWin session] window] makeFirstResponder: subview];
    }
}

- (void)keyDown:(NSEvent *)theEvent {
    if (![glkWin handleKeyDown: theEvent]) {
        [super keyDown: theEvent];
    }
}

- (NSLayoutManager*) layoutManager {
    // Need to know this to perform image layout
    if ([glkWin type] == wintype_TextBuffer) {
        return [(GlkTextBufferView*)subview layoutManager];
    } else {
        return nil;
    }
}

// Event handling
- (void) frameChanged: (NSNotification*) aNot {
    [self performArrangement];
}

- (void) updateSize {
    NSRect bounds = [self bounds];

    if ([glkWin type] == wintype_Graphics) {
        [glkWin sizeIsNow: GlkMakeSize(bounds.size.width,
                                       bounds.size.height)];
    } else {
        NSDictionary* attr = [glkWin attributesForStyle: style_Normal];
        NSSize fntSz       = [@"0" sizeWithAttributes: attr];

        GlkSize sz = GlkMakeSize(bounds.size.width / fntSz.width,
                                 bounds.size.height / fntSz.height);

        [glkWin sizeIsNow: sz];
    }
}

@end
