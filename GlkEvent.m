//
//  GlkEvent.m
//  CocoaGlk
//
//  Created by Andrew Hunter on Sat Jun 14 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "GlkEvent.h"


@implementation GlkEvent

+ (id) eventWithType: (glui32) tp
                 win: (GlkWindow*) wn
                val1: (glui32) v1
                val2: (glui32) v2 {
    return [[[GlkEvent allocWithZone: nil] initWithType: tp
                                                    win: wn
                                                   val1: v1
                                                   val2: v2] autorelease];
}

+ (id) eventWithEvent: (GlkEvent*) event {
    if (event == nil)
        return nil;
    
    return [[[GlkEvent allocWithZone: nil] initWithType: [event type]
                                                    win: [event win]
                                                   val1: [event val1]
                                                   val2: [event val2]] autorelease];
}

- (id) initWithType: (glui32) tp
                win: (GlkWindow*) wn
               val1: (glui32) v1
               val2: (glui32) v2 {
    self = [super init];

    if (self) {
        type = tp;
        win = [wn retain];
        val1 = v1;
        val2 = v2;

        data = nil;
    }

    return self;
}

- (void) dealloc {
    [win release];

    if (data) [data release];
    
    [super dealloc];
}

- (glui32) type {
    return type;
}

- (GlkWindow*) win {
    return win;
}

- (glui32) val1 {
    return val1;
}

- (glui32) val2 {
    return val2;
}

- (void)    setData: (NSData*) dt {
    data = [dt retain];
}

- (NSData*) data {
    return data;
}

// == NSCopying ==
- (id) copyWithZone: (NSZone*) zone {
    GlkEvent* cpy = [[GlkEvent allocWithZone: zone] initWithType: type
                                                             win: win
                                                            val1: val1
                                                            val2: val2];

    return cpy;
}

@end
