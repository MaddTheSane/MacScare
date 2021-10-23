//
//  GlkFileStream.h
//  CocoaGlk
//
//  Created by Andrew Hunter on Sun Jun 15 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GlkStream.h"
#import "GlkFileRef.h"

@interface GlkFileStream : GlkStream {
    GlkFileRef* ourRef;

    NSFileHandle* hdl;

    // Need this for decent performance
    NSData* buffer;
    int     bufpos;
}

- (id) initByOpeningFileRef: (GlkFileRef*) ref
                   withMode: (glui32) mode
                       rock: (glui32) rock;

@end
