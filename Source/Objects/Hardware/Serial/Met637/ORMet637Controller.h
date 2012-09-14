//--------------------------------------------------------
// ORMet637Controller
// Created by Mark  A. Howe on Mon Jan 23, 2012
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2012 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ***Imported Files

@class ORCompositeTimeLineView;
@class ORSerialPortController;

@interface ORMet637Controller : OrcaObjectController
{
    IBOutlet NSTextField*	lockDocField;
	IBOutlet NSTextField*	dumpCountField;
	IBOutlet NSTextField*	dumpInProgressField;
	IBOutlet NSTextField*	timedOutField;
	IBOutlet NSButton*		isLogCB;
	IBOutlet NSTextField*	holdTimeField;
	IBOutlet NSTextField*	tempUnitsField;
	IBOutlet NSPopUpButton* tempUnitsPU;
	IBOutlet NSPopUpButton* countingModePU;
	IBOutlet NSPopUpButton* countUnitsPU;
	IBOutlet NSTextField*	humidityField;
	IBOutlet NSTextField*	temperatureField;
	
	IBOutlet NSMatrix*		countMatrix;
	IBOutlet NSTextField*	measurementDateField;

    IBOutlet NSButton*      lockButton;
    IBOutlet NSButton*      clearAllButton;
    IBOutlet NSButton*      dumpAllButton;
    IBOutlet NSButton*      dumpRecentButton;

	IBOutlet NSTextField*	cycleDurationField;
    IBOutlet NSButton*      startCycleButton;
    IBOutlet NSButton*      stopCycleButton;
    IBOutlet NSTextField*   cycleNumberField;
	IBOutlet NSTextField*	cycleWillEndField;
	IBOutlet NSTextField*	cycleStartedField;
	IBOutlet NSTextField*	runningField;
	IBOutlet NSTextField*	unitsField;
	IBOutlet NSTextField*	batteryStatusField;
	IBOutlet NSTextField*	sensorStatusField;
	IBOutlet NSTextField*	flowStatusField;
	IBOutlet NSTextField*   actualDurationField;
	
	IBOutlet ORCompositeTimeLineView*   plotter0;
	IBOutlet NSMatrix* countAlarmLimitMatrix;
	IBOutlet NSMatrix* maxCountsMatrix;
	
    IBOutlet ORSerialPortController* serialPortController;
}

#pragma mark ***Initialization
- (id) init;
- (void) dealloc;
- (void) awakeFromNib;

#pragma mark ***Notifications
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark ***Interface Management
- (void) dumpCountChanged:(NSNotification*)aNote;
- (void) dumpInProgressChanged:(NSNotification*)aNote;
- (void) timedOutChanged:(NSNotification*)aNote;
- (void) actualDurationChanged:(NSNotification*)aNote;
- (void) isLogChanged:(NSNotification*)aNote;
- (void) holdTimeChanged:(NSNotification*)aNote;
- (void) tempUnitsChanged:(NSNotification*)aNote;
- (void) countUnitsChanged:(NSNotification*)aNote;
- (void) statusBitsChanged:(NSNotification*)aNote;
- (void) humidityChanged:(NSNotification*)aNote;
- (void) temperatureChanged:(NSNotification*)aNote;
- (void) countAlarmLimitChanged:(NSNotification*)aNote;
- (void) maxCountsChanged:(NSNotification*)aNote;
- (void) cycleNumberChanged:(NSNotification*)aNote;
- (void) cycleWillEndChanged:(NSNotification*)aNote;
- (void) cycleStartedChanged:(NSNotification*)aNote;
- (void) runningChanged:(NSNotification*)aNote;
- (void) cycleDurationChanged:(NSNotification*)aNote;
- (void) countingModeChanged:(NSNotification*)aNote;
- (void) countChanged:(NSNotification*)aNote;
- (void) measurementDateChanged:(NSNotification*)aNote;
- (void) updateButtons;
- (void) lockChanged:(NSNotification*)aNote;
- (void) updateTimePlot:(NSNotification*)aNote;
- (void) scaleAction:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;

#pragma mark ***Actions
- (IBAction) isLogAction:(id)sender;
- (IBAction) holdTimeAction:(id)sender;
- (IBAction) tempUnitsAction:(id)sender;
- (IBAction) countAlarmLimitAction:(id)sender;
- (IBAction) maxCountsAction:(id)sender;
- (IBAction) lockAction:(id) sender;
- (IBAction) cycleDurationAction:(id)sender;
- (IBAction) startCycleAction:(id)sender;
- (IBAction) stopCycleAction:(id)sender;
- (IBAction) countUnitsAction:(id)sender;
- (IBAction) countingModeAction:(id)sender;
- (IBAction) dumpAllDataAction:(id)sender;
- (IBAction) dumpNewDataAction:(id)sender;
- (IBAction) clearAllAction:(id)sender;

- (void) clearDataSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;


#pragma mark ***Data Source
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
@end


