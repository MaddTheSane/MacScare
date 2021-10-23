//
//  NSBundle+Types.m
//  MacScare
//
//  Created by Uli Kusterer on Sat Mar 13 2004.
//  Copyright (c) 2004 M. Uli Kusterer. All rights reserved.
//

#import "NSBundle+Types.h"


@implementation NSBundle (Types)

-(NSArray*) types
{
	NSDictionary*		infoPlist = [self infoDictionary];
	NSArray*			docTypes = [infoPlist objectForKey: @"CFBundleDocumentTypes"];
	NSEnumerator*		enny = [docTypes objectEnumerator];
	NSMutableArray*		types = [NSMutableArray array];
	NSDictionary*		docType;
	
	while( (docType = [enny nextObject]) )
	{
		NSArray*		extensions = [docType objectForKey: @"CFBundleTypeExtensions"];
		NSEnumerator*   extEnny = [extensions objectEnumerator];
		NSString*		currExt = nil;
		
		while( (currExt = [extEnny nextObject]) )
			[types addObject: currExt];
	}
	
	return types;
}

@end
