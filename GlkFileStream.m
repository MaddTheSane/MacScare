//
//  GlkFileStream.m
//  CocoaGlk
//
//  Created by Andrew Hunter on Sun Jun 15 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "GlkFileStream.h"


@implementation GlkFileStream

#define bufSize 16384

- (id) initByOpeningFileRef: (GlkFileRef*) ref
                   withMode: (glui32) mode
                       rock: (glui32) rk {
    self = [super init];

    if (self) {
        ourRef = [ref retain];
        rock = rk;

        readcount  = 0;
        writecount = 0;

        hdl = nil;

        buffer = nil;

        if (mode == filemode_Write ||
            mode == filemode_ReadWrite ||
            mode == filemode_WriteAppend) {
            if (![[NSFileManager defaultManager] fileExistsAtPath: [ourRef path]]) {
                NSString* fileType;
                NSString* creator;

                NSNumber* typeCode, *creatorCode;

                creator = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleSignature"];
                if (creator == nil) {
                    creator = @"????";
                }

                switch ([ourRef usage]) {
                    default:
                        fileType = @"TEXT";
                }
                
                creatorCode = [NSNumber numberWithUnsignedLong: NSHFSTypeCodeFromFileType([NSString
            stringWithFormat:@"'%@'",creator])];
                typeCode = [NSNumber numberWithUnsignedLong: NSHFSTypeCodeFromFileType([NSString
            stringWithFormat:@"'%@'",fileType])];
                
                NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys:
                    typeCode, NSFileHFSTypeCode,
                    creatorCode, NSFileHFSCreatorCode,
                    nil];
                
                [[NSFileManager defaultManager] createFileAtPath: [ourRef path]
                                                        contents: nil
                                                      attributes: attr];
            }
        }

        switch (mode) {
            case filemode_Write:
                hdl = [[NSFileHandle fileHandleForWritingAtPath: [ourRef path]] retain];
                if (hdl) [hdl truncateFileAtOffset: 0];
                break;

            case filemode_Read:
                hdl = [[NSFileHandle fileHandleForReadingAtPath: [ourRef path]] retain];
                break;

            case filemode_ReadWrite:
                hdl = [[NSFileHandle fileHandleForUpdatingAtPath: [ourRef path]]
                    retain];
                break;

            case filemode_WriteAppend:
                hdl = [[NSFileHandle fileHandleForUpdatingAtPath: [ourRef path]]
                    retain];
                if (hdl) [hdl seekToEndOfFile];
                break;
        }

        // If we fail to open the file
        if (!hdl) {
            [self release];
            return nil;
        }
    }

    return self;
}

- (void) dealloc {
    if (hdl) [hdl release];
    [ourRef release];

    [super dealloc];
}

- (stream_result_t) close {
    [hdl closeFile];
    [hdl release];
    hdl = nil;

    if (buffer) {
        [buffer release];
        buffer = nil;
    }
    
    return [super close];
}

- (void) refreshBuffer {
    if (buffer != nil) {
        [buffer release];
    }

    bufpos = 0;
    buffer = [[hdl readDataOfLength: bufSize] retain];
}

- (void) clearBuffer {
    if (buffer) {
        [hdl seekToFileOffset: [hdl offsetInFile] - [buffer length]];

        [buffer release];
        buffer = nil;
    }
}

- (void) setPosition: (glsi32) pos
            withMode: (glui32) seekMode {
    unsigned long offset;

    switch (seekMode) {
        case seekmode_End:
            [hdl seekToEndOfFile];
        case seekmode_Current:
            offset = [hdl offsetInFile] + pos;
            break;
            
        case seekmode_Start:
        default:
            offset = pos;
    }

    [hdl seekToFileOffset: offset];
    [self refreshBuffer];
}

- (glui32) getPosition {
    return [hdl offsetInFile] - [buffer length] + bufpos;
}

- (void) putChar: (unsigned char) ch {
    [self clearBuffer];
    
    [hdl writeData: [NSData dataWithBytes: &ch
                                   length: 1]];
    writecount++;
}

- (void) putBuffer: (NSData*) buf {
    [self clearBuffer];
    
    [hdl writeData: buf];
    writecount += [buf length];
}

- (void) setGlkStyle: (glui32) styl {
    // Do nothing
}

- (glsi32)  getChar {
    if (buffer == nil || bufpos >= [buffer length]) {
        [self refreshBuffer];
    }
   
    if ([buffer length] == 0) {
        NSLog(@"EOF");
        return -1;
    }

    readcount++;
    return ((unsigned char*)[buffer bytes])[bufpos++];
}

- (NSData*) getLineInBuffer: (int) length {
    NSMutableData* res = [[NSMutableData allocWithZone: [self zone]] init];

    glsi32 ch;
    ch = [self getChar];
    while (ch >= 0 && ch != '\n') {
        [res appendBytes: &ch
                  length: 0];
        
        ch = [self getChar];
    }

    ch = 0;
    [res appendBytes: &ch
              length: 0];

    readcount += [res length];

    return [res autorelease];
}

- (NSData*) getBuffer: (int) length {
    if (length == 0) {
        return nil;
    }
    
    NSData* bufRes = nil;
    NSData* restRes = nil;
    NSData* res;

    // Read some from the buffer...
    if (buffer != nil && bufpos < [buffer length]) {
        int maxLen = [buffer length] - bufpos;

        if (length <= maxLen) {
            bufRes = [NSData dataWithBytes: [buffer bytes] + bufpos
                                    length: length];
            
            bufpos += length;
            length = 0;
        } else {
            bufRes = [NSData dataWithBytes: [buffer bytes] + bufpos
                                    length: maxLen];
            bufpos += maxLen;
            length -= maxLen;
        }
    }

    // ...and anything remaining from the file
    if (length > 0) {
        restRes = [hdl readDataOfLength: length];
        [self refreshBuffer];
    }

    if (restRes == nil)  {
        res = bufRes;
    } else if (bufRes == nil) {
        res = restRes;
    } else {
        res = [[NSMutableData allocWithZone: [self zone]] initWithData: bufRes];
        [(NSMutableData*)res appendData: restRes];
        [res autorelease];
    }

    readcount += [res length];
    
    return res;
}

@end
