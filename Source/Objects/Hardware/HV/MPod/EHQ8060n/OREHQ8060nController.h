//-------------------------------------------------------------------------
//  OREHQ8060nController.h
//
//  Created by Mark Howe on Thurs Jan 6,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
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

#pragma mark ***Imported Files
#import "OrcaObjectController.h";

@interface OREHQ8060nController : OrcaObjectController 
{
	IBOutlet NSMatrix*		stateMatrix;
	IBOutlet NSTextField*	riseRateField;
	IBOutlet NSMatrix*		targetMatrix;
	IBOutlet NSMatrix*		voltageMatrix;
	IBOutlet NSMatrix*		currentMatrix;
    IBOutlet NSButton*      settingLockButton;
	IBOutlet NSPopUpButton*	pollRatePopup;
	IBOutlet NSProgressIndicator*	pollRunningIndicator;
    IBOutlet NSMatrix*		onlineMaskMatrix;
    IBOutlet NSButton*      syncButton;
}

- (id)   init;
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark •••Interface Management
- (void) slotChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) riseRateChanged:(NSNotification*)aNote;
- (void) targetChanged:(NSNotification*)aNote;
- (void) voltageChanged:(NSNotification*)aNote;
- (void) currentChanged:(NSNotification*)aNote;
- (void) pollRateChanged:(NSNotification*)aNote;
- (void) pollRunningChanged:(NSNotification*)aNote;
- (void) onlineMaskChanged:(NSNotification*)aNote;
- (void) channelReadParamsChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) settingLockAction:(id) sender;
- (IBAction) riseRateAction:(id)sender;
- (IBAction) targetAction:(id)sender;
- (IBAction) currentAction:(id)sender;
- (IBAction) pollNowAction:(id)sender;
- (IBAction) pollNowAction:(id)sender;
- (IBAction) pollRateAction:(id)sender;
- (IBAction) onlineAction:(id)sender;
- (IBAction) syncAction:(id)sender;

@end
