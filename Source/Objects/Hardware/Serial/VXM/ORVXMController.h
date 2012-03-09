//--------------------------------------------------------
// ORVXMController
// Created by Mark  A. Howe on Fri Jul 22 2005
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2005 CENPA, University of Washington. All rights reserved.
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


@interface ORVXMController : OrcaObjectController
{
    IBOutlet NSTextField*   lockDocField;
	IBOutlet NSMatrix*		useCmdQueueMatrix;
	IBOutlet NSTextField*	waitingField;
	IBOutlet NSTextField*	customCmdField;
	IBOutlet NSTextField*	cmdListExecutingField;
	IBOutlet NSButton*		shipRecordsCB;
	IBOutlet NSTextField*	numTimesToRepeatField;
	IBOutlet NSTextField*	cmdIndexField;
	IBOutlet NSButton*		stopRunWhenDoneCB;
	IBOutlet NSTextField*	repeatCountField;
	IBOutlet NSButton*		repeatCmdsCB;
	IBOutlet NSButton*		syncWithRunCB;
	IBOutlet NSMatrix*		displayRawMatrix;
    IBOutlet NSTextField*   portStateField;
    IBOutlet NSPopUpButton* portListPopup;
    IBOutlet NSButton*      openPortButton;
	IBOutlet NSButton*      lockButton;
	IBOutlet NSButton*      loadListButton;
	IBOutlet NSButton*      saveListButton;
	IBOutlet NSButton*      addCustomCmdButton;
	IBOutlet NSButton*		sendGoButton;
	IBOutlet NSButton*		removeAllCmdsButton;
	
	IBOutlet NSButton*      getPositionButton;
    IBOutlet NSMatrix*      conversionMatrix;
    IBOutlet NSMatrix*      fullScaleMatrix;
    IBOutlet NSMatrix*      speedMatrix;
    IBOutlet NSMatrix*      motorEnabledMatrix;
    IBOutlet NSMatrix*		positionMatrix;
    IBOutlet NSMatrix*		targetMatrix;
    IBOutlet NSMatrix*		addButtonMatrix;
    IBOutlet NSMatrix*		absMotionMatrix;
    IBOutlet NSButton*		zeroCounterButton;
    IBOutlet NSMatrix*		homePlusMatrix;
    IBOutlet NSMatrix*		homeMinusMatrix;
    IBOutlet NSTableView*	cmdQueueTable;
	
	IBOutlet NSButton*      stopAllMotionButton;
	IBOutlet NSButton*      stopGoNextCmdButton;
	IBOutlet NSButton*      manualStartButton;
	IBOutlet NSButton*      stopWithRunButton;
    IBOutlet NSTextField*   statusField;

	//unit labels
    IBOutlet NSTextField*   fullScaleLabelField;
    IBOutlet NSTextField*   speedLabelField;
    IBOutlet NSTextField*   currentPositionLabelField;
    IBOutlet NSTextField*   targetLabelField;

}

#pragma mark ***Initialization
- (id) init;
- (void) dealloc;
- (void) awakeFromNib;
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) setFormats;

#pragma mark ***Interface Management
- (void) useCmdQueueChanged:(NSNotification*)aNote;
- (void) waitingChanged:(NSNotification*)aNote;
- (void) customCmdChanged:(NSNotification*)aNote;
- (void) cmdTypeExecutingChanged:(NSNotification*)aNote;
- (void) shipRecordsChanged:(NSNotification*)aNote;
- (void) numTimesToRepeatChanged:(NSNotification*)aNote;
- (void) cmdIndexChanged:(NSNotification*)aNote;
- (void) stopRunWhenDoneChanged:(NSNotification*)aNote;
- (void) repeatCountChanged:(NSNotification*)aNote;
- (void) repeatCmdsChanged:(NSNotification*)aNote;
- (void) syncWithRunChanged:(NSNotification*)aNote;
- (void) displayRawChanged:(NSNotification*)aNote;
- (void) updateButtons:(NSNotification*)aNote;
- (void) portNameChanged:(NSNotification*)aNote;
- (void) portStateChanged:(NSNotification*)aNote;
- (void) positionChanged:(NSNotification*)aNote;
- (void) conversionChanged:(NSNotification*)aNote;
- (void) fullScaleChanged:(NSNotification*)aNote;
- (void) motorEnabledChanged:(NSNotification*)aNote;
- (void) speedChanged:(NSNotification*)aNote;
- (void) targetChanged:(NSNotification*)aNote;
- (void) updateCmdTable:(NSNotification*)aNote;
- (void) absoluteMotionChanged:(NSNotification*)aNote;
- (void) goingHomeChanged:(NSNotification*)aNote;
- (void) itemsAdded:(NSNotification*)aNote;
- (void) itemsRemoved:(NSNotification*)aNote;

#pragma mark ***Actions
- (IBAction) useCmdQueueAction:(id)sender;
- (IBAction) customCmdAction:(id)sender;
- (IBAction) shipRecordsAction:(id)sender;
- (IBAction) numTimesToRepeatAction:(id)sender;
- (IBAction) stopRunWhenDoneAction:(id)sender;
- (IBAction) repeatCountAction:(id)sender;
- (IBAction) repeatCmdsAction:(id)sender;
- (IBAction) syncWithRunAction:(id)sender;
- (IBAction) displayRawAction:(id)sender;
- (IBAction) lockAction:(id) sender;
- (IBAction) portListAction:(id) sender;
- (IBAction) openPortAction:(id)sender;
- (IBAction) getPositionAction:(id)sender;
- (IBAction) goAllHomeAction:(id)sender;
- (IBAction) stopAllAction:(id)sender;
- (IBAction) conversionAction:(id)sender;
- (IBAction) fullScaleAction:(id)sender;
- (IBAction) speedAction:(id)sender;
- (IBAction) motorEnabledAction:(id)sender;
- (IBAction) targetPositionAction:(id)sender;
- (IBAction) goToNextCommandAction:(id)sender;
- (IBAction) addButtonAction:(id)sender;
- (IBAction) absoluteMotionAction:(id)sender;
- (IBAction) removeAllAction:(id)sender;
- (IBAction) manualStateAction:(id)sender;
- (IBAction) addZeroCounterAction:(id)sender;
- (IBAction) addHomePlusAction:(id)sender;
- (IBAction) addHomeMinusAction:(id)sender;
- (IBAction) saveListAction:(id)sender;
- (IBAction) loadListAction:(id)sender;
- (IBAction) removeItemAction:(id)sender;
- (IBAction) addCustomCmdAction:(id)sender;
- (IBAction) delete:(id)sender;
- (IBAction) cut:(id)sender;
- (IBAction) sendGoAction:(id)sender;

#pragma mark •••Table Data Source
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex;
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;

@end



