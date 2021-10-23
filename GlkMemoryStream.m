//
//  GlkMemoryStream.m
//  CocoaGlk
//
//  Created by Andrew Hunter on Mon Jun 16 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "GlkMemoryStream.h"


@implementation GlkMemoryStream

- (id) initWithBuffer: (char*) buf
               length: (glui32) len
                 rock: (glui32) rk {
    self = [super init];

    if (self) {
        buffer = buf;
        buflen = len;
        rock   = rk;

        bufpos = 0;

        open = YES;

        readcount = writecount = 0;
    }

    return self;
}

- (stream_result_t) close {
    open = NO;

    buffer = NULL;
    buflen = 0;

    return [super close];
}

- (void) setPosition: (glsi32) pos
            withMode: (glui32) seekMode {
    if (!open)
        return;

    switch (seekMode) {
        case seekmode_End:
            bufpos = buflen;
        case seekmode_Current:
            bufpos += pos;
            break;

        case seekmode_Start:
        default:
            bufpos = pos;
            break;
    }

    if (bufpos < 0) bufpos = 0;
    if (bufpos > buflen) bufpos = buflen;
}

- (glui32) getPosition {
    if (!open) {
        return 0xffffffff;
    }
    
    return bufpos;
}

- (void) putChar: (unsigned char) ch {
    writecount++;

    if (!open || bufpos >= buflen) {
        return;
    }

    buffer[bufpos++] = ch;
}

- (void) putBuffer: (NSData*) data {
    writecount += [data length];

    if (!open) {
        return;
    }
    
    NSInteger len = [data length];

    if (bufpos + len > buflen) {
        len = buflen - bufpos;
    }

    memcpy(buffer + bufpos, [data bytes], len);

    bufpos += len;
}

- (void) setGlkStyle: (glui32) styl {
    // Do nothing
}

- (glsi32) getChar {
    if (!open || bufpos >= buflen) {
        return -1;
    }

    glsi32 chr = (unsigned char)buffer[bufpos++];
    readcount++;

    return chr;
}

- (NSData*) getLineInBuffer: (int) length {
    if (!open || bufpos >= buflen) {
        return nil;
    }

    NSData* res;

    int len = 0;
    
    while (bufpos + len < buflen &&
           buffer[bufpos + len] != '\n') {
        len++;
    }

    res = [NSData dataWithBytes: buffer + bufpos
                         length: len];

    if (bufpos + len < buflen) {
        len++;
    }

    bufpos += len;
    readcount += len;

    return res;
}

- (NSData*) getBuffer: (int) length {
    if (!open) {
        return nil;
    }

    if (bufpos + length > buflen) {
        length = buflen - bufpos;
    }

    NSData* res = [NSData dataWithBytes: buffer + bufpos
                                 length: length];

    bufpos += length;
    readcount += length;

    return res;
}

@end
