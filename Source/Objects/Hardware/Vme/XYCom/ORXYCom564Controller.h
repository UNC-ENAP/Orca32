//-------------------------------------------------------------------------
//  ORXYCom564Controller.h
//
//  Created by Michael G. Marino on 10/21/1011
//  Copyright (c) 2008 CENPA. University of Washington. All rights reserved.
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
#import "OrcaObjectController.h"
#import "ORXYCom564Model.h"

#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
@interface ORXYCom564Controller : OrcaObjectController <NSTableViewDataSource>
#else
@interface ORXYCom564Controller : OrcaObjectController
#endif

{	
    // Register Box
	IBOutlet NSTextField*   slotField;
	IBOutlet NSTextField*   addressText;
    IBOutlet NSTextField* 	addressTextField;
    
    IBOutlet NSTextField* 	writeValueTextField;
    
    IBOutlet NSPopUpButton*	registerAddressPopUp;
    IBOutlet NSPopUpButton*	operationModePopUp;
    IBOutlet NSPopUpButton*	autoscanModePopUp;    
    
    IBOutlet NSMatrix*      channelLabels;
    IBOutlet NSMatrix*      channelGainSettings;    
    IBOutlet NSPopUpButton*	setAllChannelGains;
    IBOutlet NSButton*      setAllChannelGainsButton;    
    
    IBOutlet NSButton*		basicWriteButton;
    IBOutlet NSButton*		basicReadButton;
	
    IBOutlet NSTextField*	registerOffsetField;
	IBOutlet NSTextField*   regNameField;
    IBOutlet NSPopUpButton*	addressModifierPopUp;
	IBOutlet NSTextField*	readbackField;
    
    IBOutlet NSButton*      basicOpsLockButton;
    IBOutlet NSButton*      settingLockButton;
    
	IBOutlet NSButton*		initBoardButton;
	IBOutlet NSButton*		resetBoardButton;    
	IBOutlet NSButton*		reportButton;
    
    IBOutlet NSButton*      shipRecordsButton;
    IBOutlet NSButton*      pollButton;    
    
    IBOutlet NSTableView*   adcCountsAndChannels;
    
    IBOutlet NSTextField*	pollingState;
	 
}

- (id)   init;
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark •••Interface Management
- (void) modelChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) baseAddressChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;
- (void) readoutModeChanged:(NSNotification*) aNotification;
- (void) operationModeChanged:(NSNotification*) aNotification;
- (void) autoscanModeChanged:(NSNotification*) aNotification;
- (void) channelGainsChanged:(NSNotification*) aNotification;
- (void) displayRawChanged:(NSNotification*)aNote;
- (void) pollingStateChanged:(NSNotification*)aNote;
- (void) pollingActivityChanged:(NSNotification*)aNote;
- (void) shipRecordsChanged:(NSNotification*)aNote;
- (void) updateRegisterDescription:(short) aRegisterIndex;

#pragma mark •••Actions
- (IBAction) baseAddressAction:(id)sender;
- (IBAction) lockAction:(id) sender;
- (IBAction) writeValueAction: (id) aSender;
- (IBAction) selectRegisterAction: (id) aSender;
- (IBAction) selectReadoutModeAction:(id) aSender;
- (IBAction) selectOperationModeAction:(id) aSender;
- (IBAction) selectAutoscanModeAction:(id) aSender;
- (IBAction) setPollingAction:(id)sender;
- (IBAction) startPollingActivityAction:(id)sender;
- (IBAction) setShipRecordsAction:(id)sender;

- (IBAction) read: (id) pSender;
- (IBAction) write: (id) pSender;
- (IBAction) initBoard:(id)sender;
- (IBAction) resetBoard:(id)sender;
- (IBAction) report:(id)sender;
- (IBAction) setAllChannelGains:(id)sender;
- (IBAction) setOneChannelGain:(id)sender;

#pragma mark •••Misc Helpers
- (void) populatePopups;
@end

