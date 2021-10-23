//
//  NSBundle+Types.h
//  MacScare
//
//  Created by Uli Kusterer on Sat Mar 13 2004.
//  Copyright (c) 2004 M. Uli Kusterer. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSBundle (Types)

// Return an array of types extracted from our info.plist, ready for use with NSOpenPanel:
-(NSArray*) types;

@end
