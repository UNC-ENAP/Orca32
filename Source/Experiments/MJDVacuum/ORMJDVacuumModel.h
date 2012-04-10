//
//  ORMJDVacuumModel.h
//  Orca
//
//  Created by Mark Howe on Tues Mar 27, 2012.
//  Copyright © 2012 CENPA, University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#import "ORVacuumParts.h"
#import "ORAdcProcessing.h"
#import "ORBitProcessing.h"

@class ORVacuumGateValve;
@class ORLabJackUE9Model;

@interface ORMJDVacuumModel : OrcaObject <ORAdcProcessor,ORBitProcessor>
{
	NSMutableDictionary* partDictionary;
	NSMutableArray* parts;
	BOOL			showGrid;
	NSMutableArray* adcMapArray;
}

#pragma mark ***Accessors
- (void) setUpImage;
- (void) makeMainController;
- (NSArray*) parts;
- (BOOL) showGrid;
- (void) setShowGrid:(BOOL)aState;
- (void) toggleGrid;
- (int) stateOfRegion:(int)aTag;
- (int) stateOfGateValve:(int)aTag;
- (NSArray*) pipesForRegion:(int)aTag;
- (NSArray*) gateValves;
- (ORVacuumGateValve*) gateValve:(int)aTag;
- (NSArray*) dynamicLabels;

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

#pragma mark ***AdcProcessor Protocol
- (double) setProcessAdc:(int)channel value:(double)value isLow:(BOOL*)isLow isHigh:(BOOL*)isHigh;
- (NSString*) processingTitle;

#pragma mark ***BitProcessor Protocol
- (BOOL) setProcessBit:(int)channel value:(int)value;

@end

extern NSString* ORMJDVacuumModelPollTimeChanged;
extern NSString* ORMJDVacuumModelShowGridChanged;

