//
//  glk_dispa.m
//  CocoaGlk
//
//  Created by Andrew Hunter on Wed Jun 11 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

// (Platform-dependent) Dispatch functions

#import "glk.h"
#import "gi_dispa.h"
#import "glkInternal.h"

#import "GlkStatus.h"

void gidispatch_set_object_registry(gidispatch_rock_t (*regi)(void *obj, glui32 objclass),
                                    void (*unregi)(void *obj, glui32 objclass, gidispatch_rock_t objrock)) {
    [ourStatus setObjectRegistry: regi
                           unreg: unregi];
}

gidispatch_rock_t gidispatch_get_objrock(void *obj, glui32 objclass) {
    switch (objclass) {
        case gidisp_Class_Window:
            return ((winid_t)obj)->giRock;
        case gidisp_Class_Stream:
            return ((strid_t)obj)->giRock;
        case gidisp_Class_Fileref:
            return ((frefid_t)obj)->giRock;

        default:
        {
            NSLog(@"Warning: unknown object class %i in dispatch layer", objclass);
            
            gidispatch_rock_t r;

            r.num = 0;
            return r;
        }
    }
}

/* -- IMPLEMENT ME
void gidispatch_set_retained_registry(gidispatch_rock_t (*regi)(void *array, glui32 len, char *typecode),
                                      void (*unregi)(void *array, glui32 len, char *typecode,
                                                     gidispatch_rock_t objrock)) {
}
*/

