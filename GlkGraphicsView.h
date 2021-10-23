//
//  GlkGraphicsView.h
//  CocoaGlk
//
//  Created by Andrew Hunter on Tue Jun 17 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "GlkWindow.h"

@interface GlkGraphicsView : NSView {
    GlkWindow* glkWin;
}

- (id) initWithFrame: (NSRect) frame
              window: (GlkWindow*) win;

@end
