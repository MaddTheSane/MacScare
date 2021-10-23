//
//  GlkTextView.h
//  CocoaGlk
//
//  Created by Andrew Hunter on Sun Jun 15 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "GlkWindow.h"

@interface GlkTextView : NSTextView {
    GlkWindow* glkWin;
}

- (id) initWithFrame: (NSRect) frame
       textContainer: (NSTextContainer*) container
           glkWindow: (GlkWindow*) win;

@end
