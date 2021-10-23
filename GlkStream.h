//
//  GlkStream.h
//  CocoaGlk
//
//  Created by Andrew Hunter on Wed Jun 11 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GlkSession.h"
#import "glk.h"

@interface GlkStream : NSObject {
    // Variables that can be used by subclasses
    glui32 rock;

    int readcount;
    int writecount;
}

- (stream_result_t) close; // Or just release
- (glui32) rock;
- (void)       putString: (NSString*) string;

- (void)   setPosition: (glsi32) pos
              withMode: (glui32) seekMode;
- (glui32) getPosition;

- (void)       putChar: (unsigned char) ch;
- (void)       putBuffer: (NSData*) buffer;
- (void)       setGlkStyle: (glui32) styl;

- (glsi32)     getChar;
- (NSData*)    getLineInBuffer: (int) length;
- (NSData*)    getBuffer:       (int) length;

@end
