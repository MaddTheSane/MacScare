/*
 *  glkstart.h
 *  CocoaGlk
 *
 *  Created by Uli Kusterer on Sat Feb 14 2004.
 *  Copyright (c) 2004 M. Uli Kusterer. All rights reserved.
 *
 */


// The following declarations borrowed from:
// http://justice.loyola.edu/~lraszews/if/readme


// Headers:
#include "glk.h"


// This is passed to your glkunix_startup_code() function:
//  (CocoaGlk fakes this, it simply passes the path to the application's
//  executable and the name of the file to open as the two arguments)
typedef struct glkunix_startup_struct {
    int argc;
    const char **argv;
} glkunix_startup_t;


// You should declare a glkunix_arguments array:
//  (unused by CocoaGlk, but Unix Glk's require this)
enum
{
	glkunix_arg_NoValue,
	glkunix_arg_ValueFollows,
	glkunix_arg_ValueCanFollow,
	glkunix_arg_NumberValue,
	glkunix_arg_End
};

typedef struct glkunix_argumentlist_struct {
    char *name;
    int argtype;
    char *desc;
} glkunix_argumentlist_t;

extern glkunix_argumentlist_t glkunix_arguments[];


// Additional functions you can call from your glkunix_startup_code():
strid_t glkunix_stream_open_pathname(const char *pathname, glui32 textmode, 
    glui32 rock);


// Stuff you implement:
int glkunix_startup_code( glkunix_startup_t* startupArgs );

