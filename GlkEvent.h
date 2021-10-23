//
//  GlkEvent.h
//  CocoaGlk
//
//  Created by Andrew Hunter on Sat Jun 14 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GlkWindow.h"
#import "glk.h"

@interface GlkEvent : NSObject <NSCopying> {
    glui32 type;
    GlkWindow* win;
    glui32 val1, val2;

    NSData* data;
}

+ (id) eventWithType: (glui32) type
                 win: (GlkWindow*) win
                val1: (glui32) val1
                val2: (glui32) val2;
+ (id) eventWithEvent: (GlkEvent*) event;

- (id) initWithType: (glui32) type
                win: (GlkWindow*) win
               val1: (glui32) val1
               val2: (glui32) val2;

- (glui32)     type;
- (GlkWindow*) win;
- (glui32)     val1;
- (glui32)     val2;

- (void)    setData: (NSData*) data;
- (NSData*) data;

@end
