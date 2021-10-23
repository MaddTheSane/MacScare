//
//  GlkWriteBufferedStream.h
//  CocoaGlk
//
//  Created by Andrew Hunter on Mon Jun 16 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GlkStream.h"

@interface GlkWriteBufferedStream : GlkStream {
    NSMutableData* writeBuffer;
    GlkStream*     bufferedStream;
}

- (id)   initWithStream: (GlkStream*) stream;
- (void) flushBuffers;

@end
