//
//  GlkAppDelegate.m
//  CocoaGlk
//
//  Created by Andrew Hunter on Thu Jun 12 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "GlkAppDelegate.h"
#import <GlkView/GlkHub.h>
#import "NSBundle+Types.h"
#import "ScareWindowController.h"


@implementation GlkAppDelegate

- (void)applicationWillFinishLaunching: (NSNotification*) aNotification {
	// Set up the hub
	[[GlkHub sharedGlkHub] setDelegate: self];
	
	[[GlkHub sharedGlkHub] setKeychainHubCookie];
	[[GlkHub sharedGlkHub] setHubName: @"CocoaGlk"];
	
#if 0
	// Start the test application (eventually we'll have a better way to do this, but for now, we do things this way)
	NSTask* testTask = [[[NSTask alloc] init] autorelease];
	NSString* taskPath = [[NSBundle mainBundle] pathForResource: @"glulxe"
														 ofType: nil];
	
	[testTask setLaunchPath: taskPath];
	[testTask setArguments: [NSArray arrayWithObjects: @"-hubname", [[GlkHub sharedGlkHub] hubName], @"-hubcookie", [[GlkHub sharedGlkHub] hubCookie], nil]];
	
	[testTask launch];
#else
	
	// Start another task, this time using the launch facility
	ScareWindowController* control = [[ScareWindowController alloc] init];
	
	[control showWindow: self];
	[[control glkView] launchClientApplication: [[NSBundle mainBundle] pathForResource: @"scare-client"
																				ofType: nil]
								 withArguments: nil];
#endif
}


#if 0
// -----------------------------------------------------------------------------
//	applicationOpenUntitledFile:
//		If the app is launched directly, we bring up an "open file" panel so
//		the user can select a game to play. This calls application:openFile:
//		to do the actual opening.
//
//	REVISIONS:
//		2004-03-13	witness	Created.
// -----------------------------------------------------------------------------

-(BOOL) applicationOpenUntitledFile: (NSApplication*)sender
{
	static BOOL			sAppOpenFileBusy = NO;
	BOOL				result = NO;
	
	if( !sAppOpenFileBusy )
	{
		sAppOpenFileBusy = YES; // Make sure this doesn't stack "open" dialogs.
			NSOpenPanel*		opp = [NSOpenPanel openPanel];
		opp.allowedFileTypes = NSBundle.mainBundle.types;
		if( [opp runModal] == NSModalResponseOK )
				result = [self application: NSApp openFile: [opp URL].path];
		sAppOpenFileBusy = NO;
	}
	
	return result;
}


// -----------------------------------------------------------------------------
//	application:openFile:
//		Called when a user double-clicks a file associated with this app in the
//		Finder. This is the main bottleneck we use for opening files. This
//		fetches the name of our session class from the info.plist's
//		GlkSessionClass key and then creates a new instance for that.
//
//	REVISIONS:
//		2004-03-13	witness	Created.
// -----------------------------------------------------------------------------

-(BOOL) application: (NSApplication*)sender openFile: (NSString*)filename
{
	NSString*			sessionClassName = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"GlkSessionClass"];
    Class				sessionClass = NSClassFromString( sessionClassName );
	if( sessionClass == Nil )
		sessionClass = [GlkSession class];
	
	GlkSession* testSess = [[sessionClass allocWithZone: [self zone]] init];
    [testSess queueTheMusic: filename];
	
	return YES;
}
#endif

// -----------------------------------------------------------------------------
//	applicationShouldTerminateAfterLastWindowClosed:
//		When the user closes our game window, or quits the game by typing in
//		the "quit" command, we want the app to quit as well.
//
//	REVISIONS:
//		2004-03-13	witness	Created.
// -----------------------------------------------------------------------------

-(BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication*)sender
{
	return YES;
}

#pragma mark - GlkHub delegate

- (id<GlkSession>) createAnonymousSession {
	ScareWindowController* control = [[ScareWindowController alloc] init];
	
	[control showWindow: self];
	
	return [control glkView];
}

@end
