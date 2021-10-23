//
//  glk_dispa.m
//  CocoaGlk
//
//  Created by Andrew Hunter on Wed Jun 11 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

// (Platform-dependent) Blorb functions

#import "glk.h"
#import "gi_dispa.h"
#import "glkInternal.h"

#import "GlkStatus.h"

// Y'know, I'm not even sure why these functions exist :-/

giblorb_err_t giblorb_set_resource_map(strid_t file) {
    giblorb_map_t* theMap;

    giblorb_err_t erm;

    erm = giblorb_create_map(file, &theMap);

    if (erm == giblorb_err_None) {
        [ourStatus setResourceMap: theMap];
    }

    return erm;
}

giblorb_map_t *giblorb_get_resource_map(void) {
    return [ourStatus getResourceMap];
}
