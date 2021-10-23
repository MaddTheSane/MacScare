//
//  GlkFileRef.h
//  CocoaGlk
//
//  Created by Andrew Hunter on Wed Jun 11 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GlkSession.h"

@class GlkSession;
@interface GlkFileRef : NSObject {
    GlkSession* session;
    glui32 rock;
    glui32 usage;

    NSString* path;
}

- (id) initWithTempFileForSession: (GlkSession*) session
                        withUsage: (glui32) usage;
- (id) initWithName: (NSString*) fileName
          withUsage: (glui32) usage
         forSession: (GlkSession*) session;
- (id) initWithForcedName: (NSString*) fileName
                withUsage: (glui32) usage
               forSession: (GlkSession*) session;

- (void)   setRock: (glui32) rock;
- (glui32) rock;
- (glui32) usage;

- (void) deleteFile;
- (BOOL) fileExists;

- (NSString*) path;

@end
