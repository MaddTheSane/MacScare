//
//  GlkWindowStream.m
//  CocoaGlk
//
//  Created by Andrew Hunter on Thu Jun 12 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "GlkWindowStream.h"
#import "GlkWindowView.h"

@implementation GlkWindowStream

- (id) initWithGlkWindow: (GlkWindow*) win {
    self = [super init];

    if (self) {
        glkWin = win;
        style = 0;

        readcount = writecount = 0;
    }

    return self;
}

- (void) dealloc {
    [super dealloc];
}

- (void)   setPosition: (glsi32) pos
              withMode: (glui32) seekMode {
    // Do nothing
}

- (glui32) getPosition {
    return 0;
}

- (void) putChar: (unsigned char) ch {
    [self putBuffer: [NSData dataWithBytes: &ch
                                    length: 1]];
}

- (void) putBuffer: (NSData*) buf {
    if ([glkWin echoStream]) {
        [[glkWin echoStream] putBuffer: buf];
    }
    
    switch ([glkWin type]) {
        case wintype_TextBuffer:
        case wintype_TextGrid:
        {
            NSAttributedString* str;

            NSDictionary* attr = [glkWin attributesForStyle: style];

            str = [[NSAttributedString allocWithZone: [self zone]] initWithString: [NSString stringWithCString: [buf bytes] length: [buf length]]
                                                                       attributes: attr];

            // Send the text to the window
            [[glkWin textBuffer] appendAttributedString: str];

            [str release];

            writecount += [buf length];
        }
            break;

        case wintype_Pair:
            NSLog(@"Attempt to send data to a wintype_Pair window (assuming you meant to send to the key window)");
            [[[glkWin left] stream] putBuffer: buf];
            break;

        default:
            // Do nothing
            NSLog(@"Stream behaviour not defined for window of type %i (data %@)", [glkWin type], buf);
            break;
    }
}

- (void) setGlkStyle: (glui32) styl {
    style = styl;
}

- (glsi32) getChar {
    NSMutableString* pending = [glkWin pendingInput];

    // If there's nothing waiting, return -1
    if ([pending length] == 0) {
        return -1;
    }

    // Return the first waiting character (255 if out of the latin-1 character set)
    int chr = [pending characterAtIndex: 0];
    [pending deleteCharactersInRange: NSMakeRange(0,1)];

    if (chr > 255)
        chr = 255;

    readcount++;

    if ([glkWin echoStream]) {
        [[glkWin echoStream] putChar: chr];
    }

    return chr;
}

- (NSData*) getLineInBuffer: (int) length {
    NSMutableString* pending = [glkWin pendingInput];
    NSMutableData* buf = [NSMutableData dataWithBytes: [pending cString]
                                               length: [pending cStringLength]+1];
    
    char* data = [buf mutableBytes];

    int pos = 0;

    while (data[pos] != '\n' && data[pos] != 0) {
        pos++;
    }

    if (pos == 0) {
        buf = nil;
    } else {
        [buf setLength: (pos>length)?length:pos];
    }

    if (data[pos] != 0) {
        data[pos] = 0;
        pos++;
    }
    
    // Delete the relevent characters from the pending input
    [pending deleteCharactersInRange: NSMakeRange(0, pos)];
    
    readcount += pos;

    if ([glkWin echoStream]) {
        [[glkWin echoStream] putBuffer: buf];
        [[glkWin echoStream] putChar: '\n'];
    }
    
    // Done
    return buf;
}

- (NSData*) getBuffer: (int) length {
    NSLog(@"getBuffer not implemented for window streams\n");
    return 0;
}

@end
