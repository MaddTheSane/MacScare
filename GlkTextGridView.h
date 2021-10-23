//
//  GlkTextGridView.h
//  CocoaGlk
//
//  Created by Andrew Hunter on Sun Jun 15 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "GlkWindow.h"

@interface GlkTextGridView : NSView {
    GlkWindow* glkWin;

    GlkPoint flashPoint;
    BOOL flashOn;

    NSTimer* timer;
}

- (id) initWithFrame: (NSRect) frame
              window: (GlkWindow*) win;

@end
