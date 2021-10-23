//
//  GlkTextBufferView.h
//  CocoaGlk
//
//  Created by Andrew Hunter on Thu Jun 12 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "GlkWindow.h"
#import "GlkStream.h"


@interface GlkTextBufferView : NSView <NSTextViewDelegate> {
    GlkWindow* glkWin;

    NSScrollView* scrollView;
    NSTextView*   textView;
    NSTextContainer* container;
    NSLayoutManager* layoutManager;
}

- (id) initWithFrame: (NSRect) frame
              window: (GlkWindow*) win;
- (void) performResize;

- (void) windowRequestStatusChanged;
- (void) windowContentChanged;

- (NSLayoutManager*) layoutManager;

@end
