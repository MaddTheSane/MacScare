//
//  GlkWindowView.h
//  CocoaGlk
//
//  Created by Andrew Hunter on Wed Jun 11 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GlkWindow.h"

@interface GlkWindowView : NSView <NSSplitViewDelegate> {
    GlkWindow* glkWin;
    NSSplitView* splitter;

    NSView*      subview;

    BOOL madeSubviews;

    double leftSize, rightSize, offset;
}

- (id)     initWithGlkWindow: (GlkWindow*) win;
- (double) preferredSize;

-(void)    toggleSpeechSynthesis: (id)sender;

- (void)   performArrangement;
- (void)   forceViewReorder;

- (void)   windowRequestStatusChanged;
- (void)   windowContentChanged;

- (void)   focus;

- (void)   updateSize;

- (NSLayoutManager*) layoutManager;

@end
