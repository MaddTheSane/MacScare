//
//  GlkTextContainer.h
//  CocoaGlk
//
//  Created by Andrew Hunter on Fri Jun 20 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GlkWindow.h"

@interface GlkTextContainer : NSTextContainer{
    GlkWindow* glkWin;
}

- (id) initWithWindow: (GlkWindow*) win
                 size: (NSSize) size;

@end
