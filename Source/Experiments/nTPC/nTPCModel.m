//
//  nTPCModel.m
//  Orca
//
//  Created by Mark Howe on Wed Aug 15 2007.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ���Imported Files
#import "nTPCModel.h"
#import "nTPCController.h"
#import "ORSegmentGroup.h"
#import "nTPCConstants.h"

@implementation nTPCModel

#pragma mark ���Initialization
- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"nTPC"]];
}

- (void) makeMainController
{
    [self linkToController:@"nTPCController"];
}


#pragma mark ���Segment Group Methods
- (void) makeSegmentGroups
{
    ORSegmentGroup* group = [[ORSegmentGroup alloc] initWithName:@"Anode Plane" numSegments:kNumAnodeWires];
	[self addGroup:group];
	[group release];
	
    group = [[ORSegmentGroup alloc] initWithName:@"Cathode Plane" numSegments:kNumCathodeWires];
	[self addGroup:group];
	[group release];
}

- (int)  maxNumSegments
{
	return kNumAnodeWires;
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)aDictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];

    //[objDictionary setObject:NSStringFromClass([self class]) forKey:@"Class Name"];
    
    NSEnumerator* segEnum = [segmentGroups objectEnumerator];
	
    NSMutableArray* array = [NSMutableArray array];
	id seg;
    while(seg = [segEnum nextObject]){
		NSString* contents = [NSString stringWithContentsOfFile: [[seg mapFile] stringByExpandingTildeInPath]] ;
		NSArray* lines = [contents componentsSeparatedByString:@"\n"]; 
		NSEnumerator* e = [lines objectEnumerator];
		NSString* aLine;
		//limit to the first three items
		while(aLine = [e nextObject]){
			NSMutableArray* items = [[aLine componentsSeparatedByString:@","] mutableCopy];
			if([items count] > 3)[items removeObjectsInRange:NSMakeRange(3,[items count]-3)];
			[array addObject: [items componentsJoinedByString:@","]];
			[items release];
		} 
    }
    if([array count])[objDictionary setObject:array forKey:@"Geometry"];
        
    [aDictionary setObject:objDictionary forKey:@"nTPC"];
    return aDictionary;
}


#pragma mark ���Specific Dialog Lock Methods
- (NSString*) experimentMapLock
{
	return @"nTPCMapLock";
}

- (NSString*) experimentDetectorLock
{
	return @"nTPCDetectorLock";
}

- (NSString*) experimentDetailsLock	
{
	return @"nTPCDetailsLock";
}
@end

