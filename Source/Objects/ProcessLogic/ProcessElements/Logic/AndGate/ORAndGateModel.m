//
//  ORAndGateModel.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 18 2005.
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
#import "ORAndGateModel.h"

@implementation ORAndGateModel

#pragma mark ���Initialization
- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"AndGate"]];
}

-(void) makeConnectors
{
    [super makeConnectors];
	
	//adjust the positions
    ORConnector* aConnector;
    aConnector = [[self connectors] objectForKey:ORSimpleLogicIn1Connection];
    [aConnector setLocalFrame: NSMakeRect(3,3,kConnectorSize,kConnectorSize)];
    
    aConnector = [[self connectors] objectForKey:ORSimpleLogicIn2Connection];
    [aConnector setLocalFrame: NSMakeRect(3,[self frame].size.height-kConnectorSize-3,kConnectorSize,kConnectorSize)];
}

- (NSString*) elementName
{
	return @"And Gate";
}
//--------------------------------
//runs in the process logic thread
- (int) eval
{
    if(!alreadyEvaluated){
        alreadyEvaluated = YES;
		int theState = [self evalInput1] & [self evalInput2];
        [self setState: theState];
		[self setEvaluatedState: theState];
    }
	return evaluatedState;
}
//--------------------------------

@end

