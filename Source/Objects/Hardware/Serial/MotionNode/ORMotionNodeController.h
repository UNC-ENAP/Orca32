//
//  ORHPMotionNodeController.h
//  Orca
//
//  Created by Mark Howe on Fri Apr 24, 2009.
//  Copyright (c) 2009 CENPA, University of Washington. All rights reserved.
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

#import "ORHPPulserController.h"

@class ORSerialPortController;
@class ORPlotter1D;

@interface ORMotionNodeController : OrcaObjectController 
{
	IBOutlet NSButton*		startButton;
	IBOutlet NSTextField*	temperatureField;
	IBOutlet NSButton*		stopButton;
	IBOutlet NSButton*		lockButton;
	IBOutlet NSTextField*	nodeRunningField;
	IBOutlet NSTextField*	packetLengthField;
	IBOutlet NSTextField*	isAccelOnlyField;
	IBOutlet NSTextField*	versionField;
	IBOutlet ORSerialPortController* serialPortController;
	IBOutlet ORPlotter1D*	tracePlot;
	IBOutlet NSMatrix*		displayComponentsMatrix;
	IBOutlet NSTextField*	xLabel;
	IBOutlet NSTextField*	yLabel;
	IBOutlet NSTextField*	zLabel;
}

#pragma mark ***Interface Management
- (void) temperatureChanged:(NSNotification*)aNote;
- (void) nodeRunningChanged:(NSNotification*)aNote;
- (void) traceIndexChanged:(NSNotification*)aNote;
- (void) packetLengthChanged:(NSNotification*)aNote;
- (void) isAccelOnlyChanged:(NSNotification*)aNote;
- (void) versionChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;
- (void) serialNumberChanged:(NSNotification*)aNote;
- (void) updateButtons;
- (void) portStateChanged:(NSNotification*)aNote;
- (void) dispayComponentsChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) settingLockAction:(id) sender;
- (IBAction) readOnboardMemory:(id)sender;
- (IBAction) readConnect:(id)sender;
- (IBAction) start:(id)sender;
- (IBAction) stop:(id)sender;
- (IBAction) displayComponentsAction:(id)sender;

@end

