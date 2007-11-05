//
//  ORFanOutController.h
//  Orca
//
//  Created by Mark Howe on Wed Jan 1, 2003.
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


@interface ORFanOutController : OrcaObjectController {
    IBOutlet NSTextField* fanOutTextField;
    IBOutlet NSStepper*   fanOutStepper;
 }

#pragma mark ���Initialization
- (void) registerNotificationObservers;

#pragma mark ���Accessors

#pragma mark ���Actions
- (IBAction) fanOutAction:(id)sender;

#pragma mark ���Interface Management
- (void) fanOutChanged:(NSNotification*)aNotification;

@end
