//
//  OROrderedObjManager.h
//  Orca
//
//  Created by Mark Howe on 11/19/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#import "OROrderedObjHolding.h"

@interface OROrderedObjManager : NSObject {
	id<OROrderedObjHolding> containerObj;
}
+ (id) for:(id<OROrderedObjHolding>)aContainerObj;

- (id) initForContainer:(id<OROrderedObjHolding>)aContainerObj;
- (NSPoint) suggestLocationFor:(id)aCard;
- (BOOL) dropPositionOK:(NSPoint)aPoint;
- (void) moveObject:(id)obj to:(NSPoint)aPoint;
- (id) cardInSlot:(int)aSlot;
- (BOOL) slotRangeEmpty:(NSRange)slotRange;
- (BOOL) canAddObject:(id)obj atPoint:(NSPoint)aPoint;
- (void) moveSelectedObjects:(NSPoint)delta;
@end
