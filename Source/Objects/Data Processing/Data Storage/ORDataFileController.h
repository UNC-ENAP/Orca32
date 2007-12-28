//
//  ORDataFileController.h
//  Orca
//
//  Created by Mark Howe on Sat Nov 23 2002.
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


@interface ORDataFileController : OrcaObjectController  {
    @private
	IBOutlet NSTextField* 	dirTextField;
	IBOutlet NSTextField*	maxFileSizeTextField;
	IBOutlet NSButton*		limitSizeCB;
	IBOutlet NSTextField* 	fileTextField;
	IBOutlet NSTextField* 	statusTextField;
	IBOutlet NSTextField* 	sizeTextField;
	IBOutlet NSButton*      saveConfigurationCB;
	
	IBOutlet NSDrawer*      copyDrawer;

	IBOutlet NSTextField* 	copyDataField;
	IBOutlet NSTextField* 	deleteDataField;

	IBOutlet NSTextField* 	copyStatusField;
	IBOutlet NSTextField* 	deleteStatusField;

	IBOutlet NSTextField* 	copyConfigField;
	IBOutlet NSTextField* 	deleteConfigField;

	IBOutlet NSButton*      stopSendingButton;
	IBOutlet NSTextField* 	queueDataField;
	IBOutlet NSTextField* 	queueStatusField;
	IBOutlet NSTextField* 	queueConfigField;

	IBOutlet NSButton*      lockButton;
	IBOutlet NSTabView*     tabView;
}

#pragma mark ���Accessors

#pragma  mark ���Actions
- (IBAction) maxFileSizeTextFieldAction:(id)sender;
- (IBAction) limitSizeAction:(id)sender;
- (IBAction) saveConfigurationAction:(id)sender;

- (IBAction) stopSendingAction:(id)sender;
- (IBAction) lockButtonAction:(id)sender;

#pragma mark ���Interface Management
- (void) maxFileSizeChanged:(NSNotification*)aNote;
- (void) limitSizeChanged:(NSNotification*)aNote;
- (void) registerNotificationObservers;

#pragma mark ���Interface Management
- (void) drawerDidOpen:(NSNotification *)note;
- (void) fileChanged:(NSNotification*)note;
- (void) fileStatusChanged:(NSNotification*)note;
- (void) fileSizeChanged:(NSNotification*)note;
- (void) lockChanged:(NSNotification*)note;
- (void) saveConfigurationChanged:(NSNotification*)note;
- (void) dirChanged:(NSNotification*)note;
- (void) copyEnabledChanged:(NSNotification*)note;
- (void) deleteWhenCopiedChanged:(NSNotification*)note;
- (void) fileQueueStatusChanged:(NSNotification*)note;
- (void) drawerDidOpen:(NSNotification *)notification;


@end
