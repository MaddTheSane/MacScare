//
//  GlkMemoryStream.h
//  CocoaGlk
//
//  Created by Andrew Hunter on Mon Jun 16 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GlkStream.h"

@interface GlkMemoryStream : GlkStream {
    char*  buffer;
    glui32 buflen;

    glsi32 bufpos;

    BOOL open;
}

- (id) initWithBuffer: (char*) buf
               length: (glui32) len
                 rock: (glui32) rock;

@end
