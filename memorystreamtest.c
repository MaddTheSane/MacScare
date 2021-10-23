//
//  memorystreamtest.c
//  CocoaGlk
//
//  Created by Andrew Hunter on Wed Jun 11 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#include "glk.h"
#include <stdio.h>

void glk_main(void) {
    char someData[256];
    char moreData[256];

    int x;
    
    winid_t rootwin   = glk_window_open(0,0,0, wintype_TextBuffer, 1);
    strid_t memStream = glk_stream_open_memory(someData, 256, filemode_ReadWrite,
                                               1);

    stream_result_t streamRes;

    glk_set_window(rootwin);

    glk_put_string("Echoing this to memory...\n\n");

    glk_window_set_echo_stream(rootwin, memStream);
    glk_set_style(style_Subheader);
    glk_put_string("Yet another boring room\n");
    glk_set_style(style_Normal);
    glk_put_string("Hey, at least it's bouncy\n\n");
    glk_put_string("Your diary lurks on the floor near that worrying stain. Guess it's time to make another log entry... Let's see, \"");
    for (x=0; x<64; x++) {
        glk_put_char(rand()%32 + 65);
    }
    glk_put_string("\", you write (holding your pen in your mouth), marvelling at your own literary genius.\n");
    glk_window_set_echo_stream(rootwin, NULL);

    glk_put_string("\nOK, we're done... ");
    glk_stream_close(memStream, &streamRes);

    sprintf(moreData, "%u bytes written\n\n", streamRes.writecount);

    glk_put_string(moreData);

    glk_put_string("And those bytes were:\n");
    glk_set_style(style_BlockQuote);
    glk_put_buffer(someData, streamRes.writecount);

    glk_put_string("\n");
    glk_set_style(style_Normal);
    glk_put_string("Bye\n\n");
}
