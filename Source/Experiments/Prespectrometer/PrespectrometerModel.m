//
//  PrespectrometerModel.m
//  Orca
//
//  Created by Mark Howe on Tue Jun 28 2005.
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
#import "PrespectrometerModel.h"
#import "ORSegmentGroup.h"
#import "ORDataSet.h"

@implementation PrespectrometerModel

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"prespectrometer"]];
}

- (void) makeMainController
{
    [self linkToController:@"PrespectrometerController"];
}

#pragma mark ���Segment Group Methods
- (void) makeSegmentGroups
{
    ORSegmentGroup* group = [[ORSegmentGroup alloc] initWithName:@"Prespectrometer" numSegments:64];
	[self addGroup:group];
	[group release];
}

- (void) showDataSetForSet:(int)aSet segment:(int)index
{ 
	if(aSet>=0 && aSet < [segmentGroups count]){
		ORSegmentGroup* aGroup = [segmentGroups objectAtIndex:aSet];
		NSString* cardName = [aGroup segment:index objectForKey:@"kCardSlot"];
		NSString* chanName = [aGroup segment:index objectForKey:@"kChannel"];
		if(cardName && chanName && ![cardName hasPrefix:@"-"] && ![chanName hasPrefix:@"-"]){
			ORDataSet* aDataSet = nil;
			[[[self document] collectObjectsOfClass:NSClassFromString(@"OrcaObject")] makeObjectsPerformSelector:@selector(clearLoopChecked)];
			NSArray* objs = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
			if([objs count]){
				NSArray* arrayOfHistos = [[objs objectAtIndex:0] collectConnectedObjectsOfClass:NSClassFromString(@"ORHistoModel")];
				if([arrayOfHistos count]){
					id histoObj = [arrayOfHistos objectAtIndex:0];
					if([[aGroup adcClassName] isEqualToString:@"ORShaperModel"]){
						aDataSet = [histoObj objectForKeyArray:[NSMutableArray arrayWithObjects:@"Shaper", @"Crate  0",
																[NSString stringWithFormat:@"Card %2d",[cardName intValue]], 
																[NSString stringWithFormat:@"Channel %2d",[chanName intValue]],
																nil]];
					}
					else if([[aGroup adcClassName] isEqualToString:@"ORKatrinFLTModel"]){
						aDataSet = [histoObj objectForKeyArray:[NSMutableArray arrayWithObjects:@"Shaper", @"Crate  0",
																[NSString stringWithFormat:@"Station %2d",[cardName intValue]], 
																[NSString stringWithFormat:@"Channel %2d",[chanName intValue]],
																nil]];
					}
					
					[aDataSet doDoubleClick:nil];
				}
			}
		}
	}
}

- (int)  maxNumSegments
{
	return 64;
}

#pragma mark ���Specific Dialog Lock Methods
- (NSString*) experimentMapLock
{
	return @"PrespectrometerMapLock";
}

- (NSString*) experimentDetectorLock
{
	return @"PrespectrometerDetectorLock";
}

- (NSString*) experimentDetailsLock	
{
	return @"PrespectrometerDetailsLock";
}

@end