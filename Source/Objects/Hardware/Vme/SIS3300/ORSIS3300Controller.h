//-------------------------------------------------------------------------
//  ORSIS3300Controller.h
//
//  Created by Mark A. Howe on Wednesday 9/30/08.
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "OrcaObjectController.h"
#import "ORSIS3300Model.h"
@class ORValueBar;
@class ORPlotView;

@interface ORSIS3300Controller : OrcaObjectController 
{
    IBOutlet NSTabView* 	tabView;
	
	//base address
    IBOutlet NSTextField*   slotField;
    IBOutlet NSTextField*   addressText;
	
	//CSR
	IBOutlet NSMatrix*		csrMatrix;
	IBOutlet NSMatrix*		acqMatrix;
	IBOutlet NSMatrix*		eventConfigMatrix;
	
	IBOutlet NSButton*		stopTriggerButton;
	IBOutlet NSButton*		randomClockButton;
	IBOutlet NSButton*		startDelayEnabledButton;
	IBOutlet NSButton*		stopDelayEnabledButton;
	IBOutlet NSButton*		writeThresholdButton;
	IBOutlet NSButton*		readThresholdButton;
	IBOutlet NSTextField*	startDelayField;
	IBOutlet NSPopUpButton* clockSourcePU;
	IBOutlet NSTextField*	stopDelayField;
	IBOutlet NSPopUpButton* pageSizePU;
	IBOutlet ORPlotView*   plotter;

	//thresholds
	IBOutlet NSMatrix*		enabledMatrix;
	IBOutlet NSMatrix*		ltGtMatrix;
	IBOutlet NSMatrix*		thresholdMatrix;

    IBOutlet NSButton*      settingLockButton;
    IBOutlet NSButton*      initButton;
    IBOutlet NSButton*      statusButton;
	IBOutlet NSButton*		checkEventButton;
	IBOutlet NSButton*		testMemoryButton;

    //rate page
    IBOutlet NSMatrix*      rateTextFields;
    IBOutlet NSStepper*     integrationStepper;
    IBOutlet NSTextField*   integrationText;
    IBOutlet NSTextField*   totalRateText;
    IBOutlet NSMatrix*      enabled2Matrix;

    IBOutlet ORValueBar*    rate0;
    IBOutlet ORValueBar*    totalRate;
    IBOutlet NSButton*      rateLogCB;
    IBOutlet NSButton*      totalRateLogCB;
    IBOutlet ORPlotView*	timeRatePlot;
    IBOutlet NSButton*      timeRateLogCB;
	IBOutlet NSTextField*	moduleIDField;
	
    NSView *blankView;
    NSSize settingSize;
    NSSize rateSize;
}

- (id)   init;
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark •••Interface Management
- (void) csrChanged:(NSNotification*)aNote;
- (void) acqChanged:(NSNotification*)aNote;
- (void) eventConfigChanged:(NSNotification*)aNote;

- (void) stopTriggerChanged:(NSNotification*)aNote;
- (void) randomClockChanged:(NSNotification*)aNote;
- (void) stopDelayChanged:(NSNotification*)aNote;
- (void) startDelayChanged:(NSNotification*)aNote;
- (void) clockSourceChanged:(NSNotification*)aNote;
- (void) stopDelayChanged:(NSNotification*)aNote;
- (void) pageSizeChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) baseAddressChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) registerRates;
- (void) rateGroupChanged:(NSNotification*)aNote;
- (void) waveFormRateChanged:(NSNotification*)aNote;
- (void) totalRateChanged:(NSNotification*)aNote;
- (void) enabledChanged:(NSNotification*)aNote;
- (void) ltGtChanged:(NSNotification*)aNote;
- (void) thresholdChanged:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;
- (void) moduleIDChanged:(NSNotification*)aNote;

- (void) scaleAction:(NSNotification*)aNote;
- (void) integrationChanged:(NSNotification*)aNote;
- (void) updateTimePlot:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) csrAction:(id)sender;
- (IBAction) acqAction:(id)sender;
- (IBAction) eventConfigAction:(id)sender;
- (IBAction) pageSizeAction:(id)sender;

- (IBAction) stopTriggerAction:(id)sender;
- (IBAction) randomClockAction:(id)sender;
- (IBAction) startDelayEnabledAction:(id)sender;
- (IBAction) stopDelayEnabledAction:(id)sender;
- (IBAction) stopDelayAction:(id)sender;
- (IBAction) startDelayAction:(id)sender;
- (IBAction) clockSourceAction:(id)sender;
- (IBAction) baseAddressAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) initBoard:(id)sender;
- (IBAction) integrationAction:(id)sender;
- (IBAction) probeBoardAction:(id)sender;

- (IBAction) enabledAction:(id)sender;
- (IBAction) ltGtAction:(id)sender;
- (IBAction) thresholdAction:(id)sender;
- (IBAction) writeThresholdsAction:(id)sender;
- (IBAction) readThresholdsAction:(id)sender;
- (IBAction) testMemoryBankAction:(id)sender;
- (IBAction) checkEvent:(id)sender;

#pragma mark •••Data Source
- (double)  getBarValue:(int)tag;
- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end
