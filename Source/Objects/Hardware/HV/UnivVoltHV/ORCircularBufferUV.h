//
//  ORCircularBufferUV.h
//  Orca
//
//  Created by Jan Wouters on 4/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define CBkTimeKey = @"Time";
#define CBkHVKey = "@HVValue";

//const int CBkTimeIndex = 0;
//const int CBkHVIndex = 1;


@interface ORCircularBufferUV : NSObject {
	NSMutableArray*		mStorageArray;
	NSArray*			mKeys;
	long				mSize;
	long				mHeadIndex;
	long				mTailIndex;
	Boolean				mFWrapped;
	
}

- (id) init;
- (void) setSize: (long) aSize;
- (long) size;
- (void) insertHVEntry: (NSDate *) aDateOfAquistion hvValue: (NSNumber*) anHVEntry;
- (NSDictionary *) HVEntry: (long) anOffset;
- (NSArray *) mKeys;

@end
