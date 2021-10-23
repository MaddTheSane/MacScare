//
//  GlkWindowStream.h
//  CocoaGlk
//
//  Created by Andrew Hunter on Thu Jun 12 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GlkWindow.h"
#import "GlkStream.h"


@interface GlkWindowStream : GlkStream {
    GlkWindow* glkWin;
    glui32     style;
}

- (id) initWithGlkWindow: (GlkWindow*) win;

@end
