//
//  GlkStream.m
//  CocoaGlk
//
//  Created by Andrew Hunter on Wed Jun 11 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "GlkStream.h"


@implementation GlkStream

- (stream_result_t) close {
    // Do nothing
    stream_result_t res;

    res.readcount = readcount;
    res.writecount = writecount;

    return res;
}

- (glui32) rock {
    return rock;
}

- (void)   setPosition: (glsi32) pos
              withMode: (glui32) seekMode {
    NSLog(@"*** BUG: setPosition not implemented in class %@\n",
           [self class]);
}

- (glui32) getPosition {
    NSLog(@"*** BUG: getPosition not implemented in class %@\n",
           [self class]);

    return 0;
}

- (void)       putChar: (unsigned char) ch {
    NSLog(@"*** BUG: putChar not implemented in class %@\n",
           [self class]);
}

- (void)       putString: (NSString*) string {
    [self putBuffer: [NSData dataWithBytes: [string cString]
                                    length: [string cStringLength]]];
}

- (void)       putBuffer: (NSData*) buffer {
    NSLog(@"*** BUG: putBuffer not implemented in class %@\n",
          [self class]);
}

- (void)       setGlkStyle: (glui32) styl {
    NSLog(@"*** BUG: setStyle not implemented in class %@\n",
           [self class]);
}

- (glsi32)     getChar {
    NSLog(@"*** BUG: getChar not implemented in class %@\n",
           [self class]);

    return 0;
}

- (NSData*) getLineInBuffer: (int) length {
    NSLog(@"*** BUG: getLineInBuffer not implemented in class %@\n",
           [self class]);

    return 0;
}

- (NSData*) getBuffer: (int) length {
    NSLog(@"*** BUG: getBuffer not implemented in class %@\n",
           [self class]);

    return 0;
}

@end
