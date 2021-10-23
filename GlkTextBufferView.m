//
//  GlkTextBufferView.m
//  CocoaGlk
//
//  Created by Andrew Hunter on Thu Jun 12 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "GlkTextBufferView.h"
#import "GlkTextView.h"
#import "GlkTextContainer.h"


@implementation GlkTextBufferView

- (id)initWithFrame:(NSRect)frame
             window: (GlkWindow*) win {
    self = [super initWithFrame:frame];
    if (self) {        
        glkWin = win;

        // The scroll view and the text view that it contains
        scrollView = [[NSScrollView allocWithZone: [self zone]] initWithFrame: frame];

        // Set up the scroll view resizing
        [scrollView setBorderType:NSNoBorder];
        [scrollView setHasVerticalScroller:YES];
        [scrollView setHasHorizontalScroller:NO];
        [[scrollView contentView] setAutoresizesSubviews:YES];

        NSSize contentSize = [scrollView contentSize];
       
        // Create the storage space we're going to to use
        NSTextStorage* storage = [glkWin textStorage];

        while ([[storage layoutManagers] count] > 0) {
            [storage removeLayoutManager: [[storage layoutManagers] objectAtIndex: 0]];
        }

        // Create the layout manager we're going to use
        layoutManager = [[NSLayoutManager allocWithZone: [self zone]] init];
        [storage addLayoutManager: layoutManager];
        [layoutManager release];
        
        // Create the container we're going to use
        container = [[GlkTextContainer allocWithZone: [self zone]] initWithWindow: glkWin size: NSMakeSize(contentSize.width, 1e8)];
        [layoutManager addTextContainer: container];
        [container release];

        // Set up the container
        [container setContainerSize: NSMakeSize(contentSize.width, 1e8)];
        [container setWidthTracksTextView:YES];
        [container setHeightTracksTextView:NO];
        
        // Put it together
        textView = [[GlkTextView allocWithZone: [self zone]] initWithFrame: NSMakeRect(0,0, contentSize.width, contentSize.height)
                                                            textContainer: container
                                                                 glkWindow: glkWin];

        // Text view sizing
        [textView setMinSize:NSMakeSize(0.0, contentSize.height)];
        [textView setMaxSize:NSMakeSize(1e8, 1e8)];
        [textView setVerticallyResizable:YES];
        [textView setHorizontallyResizable:NO];
        [textView setAutoresizingMask:NSViewWidthSizable];

        [textView setDelegate: self];

        [textView setPostsFrameChangedNotifications: YES];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(textViewFrameChanged:)
                                                     name: NSViewFrameDidChangeNotification
                                                   object: textView];

        // Add the views
        [scrollView setDocumentView: textView];
        [self addSubview: scrollView];

        [self windowRequestStatusChanged];
        
        [textView release];
        [scrollView release];
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    [super dealloc];
}

- (void) performResize {
    [scrollView setFrame: [self bounds]];
}

- (BOOL)    	textView:(NSTextView *)aTextView
shouldChangeTextInRange:(NSRange)affectedCharRange
    replacementString:(NSString *)replacementString {
    if (affectedCharRange.location < [glkWin inputPos]) {
        return NO;
    } else {
        return YES;
    }
}

- (void) windowRequestStatusChanged {
    if ([glkWin requestedLineEvents] ||
        [glkWin requestedCharEvents]) {
        // Focus to the text view
        [textView setEditable: YES];
        [textView setSelectedRange: NSMakeRange([[glkWin textStorage] length], 0)
                          affinity: NSSelectionAffinityDownstream
                    stillSelecting: NO];
            
        [[[glkWin session] window] makeFirstResponder: textView];
    } else {
        [textView setEditable: NO];
    }
}

- (void) windowContentChanged {
    // Scroll to the bottom of the view
}

- (void) textViewFrameChanged: (NSNotification*) not {
    [[scrollView contentView] scrollToPoint:
        NSMakePoint(0,
                    [textView bounds].size.height -
                    [[scrollView contentView] bounds].size.height)];
}

- (NSLayoutManager*) layoutManager {
    return layoutManager;
}

@end
