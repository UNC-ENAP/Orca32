//
//  ORSNOCard.m
//  Orca
//
//  Created by Mark Howe on Tue, Apr 30, 2008.
//  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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

#pragma mark •••Imported Files
#import "ORSNOCard.h"

#pragma mark •••Notification Strings
NSString* ORSNOCardSlotChanged		= @"ORSNOCardSlotChanged";
NSString* ORSNOCardBoardIDChanged 	= @"ORSNOCardBoardIDChanged";

@implementation ORSNOCard

#pragma mark •••Accessors
- (Class) guardianClass 
{
	return NSClassFromString(@"ORSNOCrateModel");
}

- (NSString*) cardSlotChangedNotification
{
    return ORSNOCardSlotChanged;
}

- (int) tagBase
{
    return 0;
}

- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard
{
}

- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian
{
}

- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian
{
}

- (void) positionConnector:(ORConnector*)aConnector
{
}
#pragma mark •••Accessors
- (NSString*) boardID
{
	return boardID;
}

- (void) setBoardID:(NSString*)anId
{
	[boardID autorelease];
    boardID = [anId copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOCardBoardIDChanged object:self];
	
}

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setBoardID:	[decoder decodeObjectForKey:  @"boardID"]];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
	[encoder encodeObject:boardID forKey:@"boardID"];
}

@end
