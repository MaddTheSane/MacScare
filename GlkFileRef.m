//
//  GlkFileRef.m
//  CocoaGlk
//
//  Created by Andrew Hunter on Wed Jun 11 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "GlkFileRef.h"
#import "GlkSession.h"


@implementation GlkFileRef

- (id) initWithTempFileForSession: (GlkSession*) ss
                        withUsage: (glui32) us {
    self = [super init];

    if (self) {
        path    = [@(tmpnam(NULL)) retain];
        usage   = us;
        session = [ss retain];
    }

    return self;
}

- (id) initWithName: (NSString*) fileName
          withUsage: (glui32) us
         forSession: (GlkSession*) ss {
    NSMutableString* validFilename = [fileName mutableCopy];

    // Replace any invalid characters (fairly strictly)
    int x;

    for (x=0; x<[validFilename length]; x++) {
        unichar chr = [validFilename characterAtIndex: x];

        if (chr < 31 || chr > 255 || chr == 127) {
            chr = '_';
        }

        switch (chr) {
            case '/':
                chr = '_';
                break;

            case '\\':
                chr = '_';
                break;

            case ' ':
                chr = '_';
                break;
            
            default:
                // Do nothing
                break;
        }
    }

    // Must be in the user's home directory
    [validFilename insertString: @"/Documents/CocoaGlk/"
                        atIndex: 0];
    [validFilename insertString: NSHomeDirectory()
                        atIndex: 0];

    // Make sure our directory exists
    NSMutableString* ourDir = [NSHomeDirectory() mutableCopy];
    [ourDir appendString: @"/Documents/CocoaGlk"];

    BOOL isDir;

    if (![[NSFileManager defaultManager] fileExistsAtPath:ourDir
                                              isDirectory:&isDir]) {
        isDir = [[NSFileManager defaultManager] createDirectoryAtPath:ourDir
										  withIntermediateDirectories:YES
                                                           attributes:nil
																error:NULL];
    }

    if (!isDir) {
        NSLog(@"Save directory '%@' not available", ourDir);

        self = [super init];
        if (self) [self release];
        return nil;
    }

    // Do the actual initialisation 
    return [self initWithForcedName: [validFilename autorelease]
                          withUsage: us
                         forSession: ss];
}

- (id) initWithForcedName: (NSString*) fileName
                withUsage: (glui32) us
               forSession: (GlkSession*) ss {
    self = [super init];

    if (self) {
        usage = us;
        session = [ss retain];

        path = [fileName copy];
    }

    return self;
}

- (void) dealloc {
    [session release];
    [path    release];

    [super dealloc];
}

- (void)   setRock: (glui32) rk {
    rock = rk;
}

- (glui32) rock {
    return rock;
}

- (glui32) usage {
    return usage;
}

- (NSString*) path {
    return path;
}

- (void) deleteFile {
    if ([[NSFileManager defaultManager] isDeletableFileAtPath: path]) {
        [[NSFileManager defaultManager] removeItemAtPath: path
												   error: NULL];
    }
}

- (BOOL) fileExists {
    return [[NSFileManager defaultManager] fileExistsAtPath: path];
}

@end
