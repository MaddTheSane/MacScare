//
//  glk.m
//  CocoaGlk
//
//  Created by Andrew Hunter on Wed Jun 11 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

// The wrappers

// Oh, well then, everything's wrapped up in a neat little package
//     -- Homer Simpson

#import <Cocoa/Cocoa.h>

#import "glk.h"
#import "glkInternal.h"
#import "GlkSession.h"
#import "GlkStatus.h"
#import "GlkWindowView.h"

#import "GlkWriteBufferedStream.h"

#undef GLKLOG

// == Some convienience functions + macros ==
#define cStream ([ourStatus currentStream]->stream)

static GlkWindow* glkwin(winid_t w) {
    if (w == NULL ||
        w->win == nil) {
        return [ourSession rootWindow];
    }

    return w->win;
}

static GlkStream* glkstr(strid_t s) {
    if (s == NULL) return nil;
    return s->stream;
}

static GlkFileRef* glkfref(frefid_t f) {
    if (f == NULL) return nil;
    return f->ref;
}

// == The actual functions ==
void glk_exit(void) {
#ifdef GLKLOG
    NSLog(@"glk_exit()");
#endif
    
    [[[NSThread currentThread] threadDictionary] removeObjectForKey: GlkStatusKey];

    [ourSession exit];
}

void glk_set_interrupt_handler(void (*func)(void)) {
#ifdef GLKLOG
    NSLog(@"glk_set_interrupt_handler()");
#endif

    // Implement me
}

void glk_tick(void) {
#ifdef GLKLOG
    // NSLog(@"glk_tick()");
#endif

    // [ourSession threadPoolFree];
    // [ourSession tick];
}

glui32 glk_gestalt(glui32 sel, glui32 val) {
    GlkSession* theSession = ourSession;

#ifdef GLKLOG
    NSLog(@"glk_gestalt()");
#endif
    
    return [theSession gestaltForSel: sel
                             withVal: val];
}

glui32 glk_gestalt_ext(glui32 sel, glui32 val, glui32 *arr,
                       glui32 arrlen) {
    GlkSession* theSession = ourSession;

#ifdef GLKLOG
    NSLog(@"glk_gestalt_ext()");
#endif
    
    return [theSession gestaltForSel: sel
                             withVal: val];
}

unsigned char glk_char_to_lower(unsigned char ch) {
#ifdef GLKLOG
    //NSLog(@"glk_char_to_lower()");
#endif

    return tolower(ch);
}

unsigned char glk_char_to_upper(unsigned char ch) {
#ifdef GLKLOG
    //NSLog(@"glk_char_to_upper()");
#endif

    return toupper(ch);
}

winid_t glk_window_get_root(void) {
#ifdef GLKLOG
    NSLog(@"glk_window_get_root()");
#endif

    return [ourStatus rootWindow];
}

winid_t glk_window_open(winid_t split, glui32 method, glui32 size,
                        glui32 wintype, glui32 rock) {
#ifdef GLKLOG
    NSLog(@"glk_window_open()");
#endif

    GlkStatus* status = ourStatus;
    
    [ourSession threadPoolFree];

    if (split == NULL) {
        size = 100;
        method = winmethod_Proportional|winmethod_Above;
    }
    
    GlkWindow* newWin = [glkwin(split) openWithMethod: method
                                                 size: size
                                                 type: wintype
                                                 rock: rock];
	
	if( [newWin speechSynthesisOn] )
		[newWin toggleSpeechSynthesis: nil];
	
    winid_t newerWin  = [status newWindow: newWin];
 
    // Set the root window if necessary
    if (split == NULL) {
        [status setRootWindow: newerWin];
    }

    return newerWin;
}

void glk_window_close(winid_t cwin, stream_result_t *result) {
#ifdef GLKLOG
    NSLog(@"glk_window_close()");
#endif

    stream_result_t r = [glkwin(cwin) close];

    if (result) *result = r;

    [ourStatus removeWindow: cwin];
}

void glk_window_get_size(winid_t cwin, glui32 *widthptr,
                         glui32 *heightptr) {
#ifdef GLKLOG
    NSLog(@"glk_window_get_size()");
#endif

    GlkSize sz = [glkwin(cwin) size];

    if (widthptr)  *widthptr  = sz.width;
    if (heightptr) *heightptr = sz.height;
}

void glk_window_set_arrangement(winid_t cwin, glui32 method,
                                glui32 size, winid_t keywin) {
#ifdef GLKLOG
    NSLog(@"glk_window_set_arrangement()");
#endif

    GlkArrangement arr;

    arr.method = method;
    arr.size   = size;
    arr.keyWin = glkwin(keywin);

    [glkwin(cwin) setArrangement: arr];
}

void glk_window_get_arrangement(winid_t cwin, glui32 *methodptr,
                                glui32 *sizeptr, winid_t *keywinptr) {
#ifdef GLKLOG
    NSLog(@"glk_window_get_arrangement()");
#endif

    GlkArrangement arr = [glkwin(cwin) arrangement];

    if (methodptr) *methodptr = arr.method;
    if (sizeptr)   *sizeptr   = arr.size;
    if (keywinptr) *keywinptr = [ourStatus newWindow: arr.keyWin];
}

winid_t glk_window_iterate(winid_t cwin, glui32 *rockptr) {
#ifdef GLKLOG
    NSLog(@"glk_window_iterate()");
#endif

    GlkWindow* nextWin = [ourSession windowIterate: cwin?glkwin(cwin):nil
                                              rock: rockptr];

    if (nextWin == nil) {
        return NULL;
    }
    
    return [ourStatus newWindow: nextWin];
}

glui32 glk_window_get_rock(winid_t cwin) {
#ifdef GLKLOG
    NSLog(@"glk_window_get_rock()");
#endif

    return [glkwin(cwin) rock];
}

glui32 glk_window_get_type(winid_t cwin) {
#ifdef GLKLOG
    NSLog(@"glk_window_get_type()");
#endif

    return [glkwin(cwin) type];
}

winid_t glk_window_get_parent(winid_t cwin) {
#ifdef GLKLOG
    NSLog(@"glk_window_get_parent()");
#endif

    return [ourStatus newWindow: [glkwin(cwin) parent]];
}

winid_t glk_window_get_sibling(winid_t cwin) {
#ifdef GLKLOG
    NSLog(@"glk_window_get_sibling()");
#endif

    return [ourStatus newWindow: [glkwin(cwin) sibling]];
}

void glk_window_clear(winid_t cwin) {
#ifdef GLKLOG
    NSLog(@"glk_window_clear()");
#endif

    [glkwin(cwin) clear];
}

void glk_window_move_cursor(winid_t cwin, glui32 xpos, glui32 ypos) {
#ifdef GLKLOG
    NSLog(@"glk_window_move_cursor()");
#endif

    [(GlkWriteBufferedStream*)cwin->stream->stream flushBuffers];

    [glkwin(cwin) moveCursorToPoint: GlkMakePoint(xpos, ypos)];
}

strid_t glk_window_get_stream(winid_t cwin) {
#ifdef GLKLOG
    NSLog(@"glk_window_get_stream()");
#endif

    return cwin->stream;
}

void glk_window_set_echo_stream(winid_t cwin, strid_t str) {
#ifdef GLKLOG
    NSLog(@"glk_set_echo_stream()");
#endif

    [ourSession threadPoolFree];
    cwin->echostream = str;
    [glkwin(cwin) setEchoStream: glkstr(str)];
}

strid_t glk_window_get_echo_stream(winid_t cwin) {
#ifdef GLKLOG
    NSLog(@"glk_get_echo_stream()");
#endif

    return cwin->echostream;
}

void glk_set_window(winid_t cwin) {
#ifdef GLKLOG
    NSLog(@"glk_set_window()");
#endif

    [ourStatus setCurrentStream: cwin->stream];

    [[glkwin(cwin) view] focus];
    //[ourSession threadPoolFree];
    //[ourSession setGlkWindow: glkwin(cwin)];
}

strid_t glk_stream_open_file(frefid_t fileref, glui32 fmode,
                             glui32 rock) {
#ifdef GLKLOG
    NSLog(@"glk_stream_open_file()");
#endif

    [ourSession threadPoolFree];
    GlkStream* newStr = [ourSession openFile: glkfref(fileref)
                                    withMode: fmode
                                        rock: rock];

    return [ourStatus newStream: newStr];
}


// -----------------------------------------------------------------------------
//	glkunix_stream_open_pathname:
//		Function that can be used by glkunix_startup_code() to open a stream for
//		a file outside the user-permitted folders. Using it at other times is
//		unportable. This may be used to open game files the user wants to open
//		at startup.
//
//	REVISIONS:
//		2004-03-13	witness	Created.
// -----------------------------------------------------------------------------

strid_t glkunix_stream_open_pathname(const char *pathname, glui32 textmode, glui32 rock)
{
#ifdef GLKLOG
    NSLog(@"glkunix_stream_open_pathname()");
#endif
	
	// TODO: Should we enforce that this is only available during glkunix_startup_code()?
	
    GlkStream* newStr = [ourSession openFileWithForcedName: [NSFileManager.defaultManager stringWithFileSystemRepresentation:pathname length:strlen(pathname)]
							usage: (textmode? fileusage_TextMode : fileusage_BinaryMode)
							withMode: filemode_Read rock: rock];

    return [ourStatus newStream: newStr];
	
}

strid_t glk_stream_open_memory(char *buf, glui32 buflen, glui32 fmode,
                               glui32 rock) {
#ifdef GLKLOG
    NSLog(@"glk_stream_open_memory()");
#endif

    GlkStream* newStr = [ourSession openMemory: buf
                                        length: buflen
                                      withMode: fmode
                                          rock: rock];

    return [ourStatus newStream: newStr];
}

void glk_stream_close(strid_t str, stream_result_t *result) {
#ifdef GLKLOG
    NSLog(@"glk_stream_close()");
#endif

    [ourSession threadPoolFree];
    stream_result_t r = [glkstr(str) close];

    if (result) *result = r;

    [ourStatus removeStream: str];
}

strid_t glk_stream_iterate(strid_t str, glui32 *rockptr) {
#ifdef GLKLOG
    NSLog(@"glk_stream_iterate()");
#endif

    if (str == NULL) {
        return [ourStatus firstStream];
    } else {
        return str->next;
    }
}

glui32 glk_stream_get_rock(strid_t str) {
#ifdef GLKLOG
    NSLog(@"glk_stream_get_rock()");
#endif

    return [glkstr(str) rock];
}

void glk_stream_set_position(strid_t str, glsi32 pos, glui32 seekmode) {
#ifdef GLKLOG
    NSLog(@"glk_stream_set_position()");
#endif

    [glkstr(str) setPosition: pos
                    withMode: seekmode];
}

glui32 glk_stream_get_position(strid_t str) {
#ifdef GLKLOG
    NSLog(@"glk_stream_get_position()");
#endif

    return [glkstr(str) getPosition];
}

void glk_stream_set_current(strid_t str) {
#ifdef GLKLOG
    NSLog(@"glk_stream_set_current()");
#endif

    [ourStatus setCurrentStream: str];
}

strid_t glk_stream_get_current(void) {
#ifdef GLKLOG
    NSLog(@"glk_stream_get_current()");
#endif

    return [ourStatus currentStream];
}

void glk_put_char(unsigned char ch) {
#ifdef GLKLOG
    printf("%c", ch);
#endif
    [cStream putChar: ch];
}

void glk_put_char_stream(strid_t str, unsigned char ch) {
#ifdef GLKLOG
    printf("%c", ch);
#endif
    [glkstr(str) putChar: ch];
}

void glk_put_string(char *s) {
#ifdef GLKLOG
    printf("%s", s);
#endif

    [cStream putString: [NSString stringWithCString: s encoding: NSUTF8StringEncoding]];
}

void glk_put_string_stream(strid_t str, char *s) {
#ifdef GLKLOG
    printf("%s", s);
#endif

    // [ourSession threadPoolFree];
    [glkstr(str) putString: [NSString stringWithCString: s encoding: NSUTF8StringEncoding]];
}

void glk_put_buffer(char *buf, glui32 len) {
#ifdef GLKLOG
    NSLog(@"glk_put_buffer(): %@", [NSData dataWithBytes: buf
                                                  length: len]);
#endif

    // [ourSession threadPoolFree];
    [cStream putBuffer: [NSData dataWithBytes: buf
                                       length: len]];
}

void glk_put_buffer_stream(strid_t str, char *buf, glui32 len) {
#ifdef GLKLOG
    NSLog(@"glk_put_buffer_stream()");
#endif

    // [ourSession threadPoolFree];
    [glkstr(str) putBuffer: [NSData dataWithBytes: buf
                                           length: len]];
}

void glk_set_style(glui32 styl) {
#ifdef GLKLOG
    NSLog(@"glk_set_style()");
#endif

    [cStream setGlkStyle: styl];
}

void glk_set_style_stream(strid_t str, glui32 styl) {
#ifdef GLKLOG
    NSLog(@"glk_set_style_stream()");
#endif

    [glkstr(str) setGlkStyle: styl];
}

glsi32 glk_get_char_stream(strid_t str) {
#ifdef GLKLOG
    // NSLog(@"glk_get_char_stream()"); -- waay too many of these
#endif

    return [glkstr(str) getChar];
}

glui32 glk_get_line_stream(strid_t str, char *buf, glui32 len) {
#ifdef GLKLOG
    NSLog(@"glk_get_line_stream()");
#endif

    [ourSession threadPoolFree];
    NSData* line = [glkstr(str) getLineInBuffer: len];

    if (line != nil) {
        memcpy(buf, [line bytes], [line length]);
        return (glui32)[line length];
    }

    return 0;
}

glui32 glk_get_buffer_stream(strid_t str, char *buf, glui32 len) {
#ifdef GLKLOG
    NSLog(@"glk_get_buffer_stream()");
#endif

    [ourSession threadPoolFree];
    NSData* line = [glkstr(str) getBuffer: len];

    if (line != nil) {
        memcpy(buf, [line bytes], [line length]);
        return (int)[line length];
    }

    return 0;
}

void glk_stylehint_set(glui32 wintype, glui32 styl, glui32 hint,
                       glsi32 val) {
#ifdef GLKLOG
    NSLog(@"glk_stylehint_set()");
#endif

    [ourSession setStyleHint: wintype
                       style: styl
                        hint: hint
                       value: val];
}

void glk_stylehint_clear(glui32 wintype, glui32 styl, glui32 hint) {
#ifdef GLKLOG
    NSLog(@"glk_stylehint_clear()");
#endif

    [ourSession clearStyleHint: wintype
                         style: styl
                          hint: hint];
}

glui32 glk_style_distinguish(winid_t cwin, glui32 styl1, glui32 styl2) {
#ifdef GLKLOG
    NSLog(@"glk_style_distinguish()");
#endif

    return [glkwin(cwin) distinguishStyle: styl1
                                fromStyle: styl2];
}

glui32 glk_style_measure(winid_t cwin, glui32 styl, glui32 hint,
                         glui32 *result) {
#ifdef GLKLOG
    NSLog(@"glk_style_measure()");
#endif

    return [glkwin(cwin) measureStyle: styl
                                hint: hint
                            resultIn: result];
}

frefid_t glk_fileref_create_temp(glui32 usage, glui32 rock) {
#ifdef GLKLOG
    NSLog(@"glk_fileref_create_temp()");
#endif

    return [ourStatus newFileRef: [ourSession fileRefTemp: rock
                                                withUsage: usage]];
}

frefid_t glk_fileref_create_by_name(glui32 usage, char *name,
                                    glui32 rock) {
#ifdef GLKLOG
    NSLog(@"glk_fileref_create_by_name()");
#endif

    [ourSession threadPoolFree];
    return [ourStatus newFileRef: [ourSession fileRefForName: name
                                                        rock: rock
                                                withUsage: usage]];
}

frefid_t glk_fileref_create_by_prompt(glui32 usage, glui32 fmode,
                                      glui32 rock) {
#ifdef GLKLOG
    NSLog(@"glk_fileref_create_by_prompt()");
#endif

    [ourSession threadPoolFree];
    return [ourStatus newFileRef: [ourSession fileRefByPromptingForMode: fmode
                                                                   rock: rock
                                                              withUsage: usage]];
}

frefid_t glk_fileref_create_from_fileref(glui32 usage, frefid_t fref,
                                         glui32 rock) {
#ifdef GLKLOG
    NSLog(@"glk_fileref_create_from_fileref()");
#endif

    [ourSession threadPoolFree];
    return [ourStatus newFileRef: [ourSession fileRefFromFileRef: glkfref(fref)
                                                            rock: rock
                                                       withUsage: usage]];
}

void glk_fileref_destroy(frefid_t fref) {
#ifdef GLKLOG
    NSLog(@"glk_fileref_destroy()");
#endif

    [ourSession threadPoolFree];
    [ourStatus removeFileRef: fref];
}

frefid_t glk_fileref_iterate(frefid_t fref, glui32 *rockptr) {
#ifdef GLKLOG
    NSLog(@"glk_fileref_iterate()");
#endif

    if (fref == NULL) {
        return [ourStatus firstRef];
    } else {
        return fref->next;
    }
}

glui32 glk_fileref_get_rock(frefid_t fref) {
#ifdef GLKLOG
    NSLog(@"glk_fileref_get_rock()");
#endif

    return [glkfref(fref) rock];
}

void glk_fileref_delete_file(frefid_t fref) {
#ifdef GLKLOG
    NSLog(@"glk_fileref_delete_file()");
#endif

    [glkfref(fref) deleteFile];
}

glui32 glk_fileref_does_file_exist(frefid_t fref) {
#ifdef GLKLOG
    NSLog(@"glk_fileref_does_file_exist()");
#endif

    return [glkfref(fref) fileExists]==YES?1:0;
}

void glk_select(event_t *event) {
#ifdef GLKLOG
    NSLog(@"glk_select()");
#endif

    GlkEvent* theEvent = [ourSession select: event];

    if (event) {
        event->win = [ourStatus findIdForWindow: [theEvent win]];

        if ([theEvent type] == evtype_LineInput && event->win != NULL) {
            memcpy(event->win->outBuf,
                   [[theEvent data] bytes],
                   [[theEvent data] length]);
        }
    }
}

void glk_select_poll(event_t *event) {
#ifdef GLKLOG
    NSLog(@"glk_select_poll()");
#endif

    [ourSession threadPoolFree];
    GlkEvent* evt = [ourSession selectPoll];

    if (evt == nil) {
        event->type = evtype_None;
    } else {
        event->type = [evt type];
        event->win  = [ourStatus findIdForWindow: [evt win]];
        event->val1 = [evt val1];
        event->val2 = [evt val2];
    }
}

void glk_request_timer_events(glui32 millisecs) {
#ifdef GLKLOG
    NSLog(@"glk_request_timer_events()");
#endif

    BUG(@"glk_request_timer_events not implemented yet");
}

void glk_request_line_event(winid_t cwin, char *buf, glui32 maxlen,
                            glui32 initlen) {
#ifdef GLKLOG
    NSLog(@"glk_request_line_event()");
#endif

    [ourSession threadPoolFree];
    cwin->outBuf = buf;
    cwin->bufLen = maxlen;
	
	NSData *nsBuf = [NSData dataWithBytes:buf length:initlen];
	NSString *strBuf = [[NSString alloc] initWithData:nsBuf encoding:NSUTF8StringEncoding];
    [glkwin(cwin) requestLineEvent: maxlen
                              init: strBuf];
	[strBuf release];
}

void glk_request_char_event(winid_t cwin) {
#ifdef GLKLOG
    NSLog(@"glk_request_char_event()");
#endif

    [glkwin(cwin) requestCharEvent];
}

void glk_request_mouse_event(winid_t cwin) {
#ifdef GLKLOG
    NSLog(@"glk_request_mouse_event()");
#endif

    [glkwin(cwin) requestMouseEvent];
}

void glk_cancel_line_event(winid_t cwin, event_t *event) {
#ifdef GLKLOG
    NSLog(@"glk_cancel_line_event()");
#endif

    GlkEvent* theEvent = [glkwin(cwin) cancelLineEvent];

    if (event) {
        event->type = [theEvent type];
        event->win  = (winid_t)[theEvent win];
        event->val1 = [theEvent val1];
        event->val2 = [theEvent val2];
    }        
    
    if (event) {
        event->win = [ourStatus findIdForWindow: [theEvent win]];

        if ([theEvent type] == evtype_LineInput && event->win != NULL) {
            memcpy(event->win->outBuf,
                   [[theEvent data] bytes],
                   [[theEvent data] length]);
        }
    }
}

void glk_cancel_char_event(winid_t cwin) {
#ifdef GLKLOG
    NSLog(@"glk_cancel_char_event()");
#endif

    [glkwin(cwin) cancelCharEvent];
}

void glk_cancel_mouse_event(winid_t cwin) {
#ifdef GLKLOG
    NSLog(@"glk_cancel_mouse_event()");
#endif

    [glkwin(cwin) cancelMouseEvent];
}

#ifdef GLK_MODULE_IMAGE

glui32 glk_image_draw(winid_t cwin, glui32 image,
                      glsi32 val1, glsi32 val2) {
    NSImage* img = [ourSession getImageResource: image];

    if (img) {
        [glkwin(cwin) drawImage: img
                           val1: val1
                           val2: val2];

        return 1;
    } else {
        return 0;
    }
}

glui32 glk_image_draw_scaled(winid_t cwin, glui32 image,
                             glsi32 val1, glsi32 val2,
                             glui32 width, glui32 height) {
    NSImage* img = [ourSession getImageResource: image];

    if (img) {
        [glkwin(cwin) drawImageScaled: img
                                 val1: val1
                                 val2: val2
                            withWidth: width
                               height: height];
		return 1;
    }
	return 0;
}

glui32 glk_image_get_info(glui32 image, glui32 *width, glui32 *height) {
    NSImage* img = [ourSession getImageResource: image];

    if (img == nil) {
        return 0;
    }

    if (width) {
        *width = [img size].width;
    }
    if (height) {
        *height = [img size].height;
    }

    return 1;
}

void glk_window_flow_break(winid_t cwin) {
    [glkwin(cwin) breakFlow];
}

void glk_window_erase_rect(winid_t cwin,
                           glsi32 left, glsi32 top,
                           glui32 width, glui32 height) {
    [glkwin(cwin) fillRect: NSMakeRect(left, top, width, height)
                withColour: 0xffffffff];
}

void glk_window_fill_rect(winid_t cwin, glui32 color,
                          glsi32 left, glsi32 top,
                          glui32 width, glui32 height) {
    [glkwin(cwin) fillRect: NSMakeRect(left, top, width, height)
                withColour: color];
}

void glk_window_set_background_color(winid_t cwin, glui32 color)  {
    [glkwin(cwin) setBackground: color];
}

#endif /* GLK_MODULE_IMAGE */

#ifdef GLK_MODULE_SOUND

schanid_t glk_schannel_create(glui32 rock) {
    NSLog(@"Function glk_schannel_create not implemented");
	return NULL;
}

void glk_schannel_destroy(schanid_t chan) {
    NSLog(@"Function glk_schannel_destroy not implemented");
}

schanid_t glk_schannel_iterate(schanid_t chan, glui32 *rockptr) {
    NSLog(@"Function glk_schannel_iterate not implemented");
    return NULL;
}

glui32 glk_schannel_get_rock(schanid_t chan) {
    NSLog(@"Function glk_schannel_get_rock not implemented");
	return UINT32_MAX;
}

glui32 glk_schannel_play(schanid_t chan, glui32 snd) {
    NSLog(@"Function glk_schannel_play not implemented");
	return UINT32_MAX;
}

glui32 glk_schannel_play_ext(schanid_t chan, glui32 snd, glui32 repeats,
                                    glui32 notify) {
    NSLog(@"Function glk_schannel_play_ext not implemented");
	return UINT32_MAX;
}

void glk_schannel_stop(schanid_t chan) {
    NSLog(@"Function glk_schannel_stop not implemented");
}

void glk_schannel_set_volume(schanid_t chan, glui32 vol) {
    NSLog(@"Function glk_schannel_set_volume not implemented");
}

void glk_sound_load_hint(glui32 snd, glui32 flag) {
    NSLog(@"Function glk_sound_load_hint not implemented");
}

#endif /* GLK_MODULE_SOUND */

#ifdef GLK_MODULE_HYPERLINKS

void glk_set_hyperlink(glui32 linkval) {
    NSLog(@"Function glk_set_hyperlink not implemented");
}

void glk_set_hyperlink_stream(strid_t str, glui32 linkval) {
    NSLog(@"Function glk_hyperlink_stream not implemented");
}

void glk_request_hyperlink_event(winid_t win) {
    NSLog(@"Function glk_request_hyperlink_event not implemented");
}

void glk_cancel_hyperlink_event(winid_t win) {
    NSLog(@"Function glk_cancel_hyperlink_event not implemented");
}


#endif /* GLK_MODULE_HYPERLINKS */
