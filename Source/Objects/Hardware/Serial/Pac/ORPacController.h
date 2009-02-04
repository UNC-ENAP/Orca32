//--------------------------------------------------------
// ORPacController
// Created by Mark  A. Howe on Tue Jan 6, 2009
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2009 CENPA, University of Washington. All rights reserved.
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

@class ORPlotter1D;

@interface ORPacController : OrcaObjectController
{
    IBOutlet NSTextField*   lockDocField;
	IBOutlet NSButton*		shipAdcsButton;
    IBOutlet NSButton*      lockButton;
    IBOutlet NSButton*      portDButton;
    IBOutlet NSTextField*   portStateField;
    IBOutlet NSPopUpButton* portListPopup;
    IBOutlet NSPopUpButton* pollTimePopup;
    IBOutlet NSButton*      openPortButton;
    IBOutlet NSButton*      readAdcsButton;
    IBOutlet NSMatrix*      adcMatrix;
    IBOutlet NSMatrix*      adc1Matrix;
    IBOutlet NSMatrix*      timeMatrix;
	IBOutlet ORPlotter1D*   plotter0;
    IBOutlet NSMatrix*      portDMatrix;
	IBOutlet NSMatrix*		dacMatrix;
    IBOutlet NSButton*      readDacButton;
    IBOutlet NSButton*      writeDacButton;
    IBOutlet NSButton*      setLcmEnaButton;
    IBOutlet NSButton*      clrLcmEnaButton;
}

#pragma mark •••Initialization
- (id) init;
- (void) dealloc;
- (void) awakeFromNib;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark •••Interface Management
- (void) updateTimePlot:(NSNotification*)aNote;
- (void) scaleAction:(NSNotification*)aNote;
- (void) shipAdcsChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;
- (void) portNameChanged:(NSNotification*)aNote;
- (void) portStateChanged:(NSNotification*)aNote;
- (void) adcChanged:(NSNotification*)aNote;
- (void) dacChanged:(NSNotification*)aNote;
- (void) pollTimeChanged:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;
- (void) scaleAction:(NSNotification*)aNote;
- (void) loadAdcTimeValuesForIndex:(int)index;
- (void) portDMaskChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) shipAdcsAction:(id)sender;
- (IBAction) lockAction:(id) sender;
- (IBAction) portListAction:(id) sender;
- (IBAction) openPortAction:(id)sender;
- (IBAction) readAdcsAction:(id)sender;
- (IBAction) pollTimeAction:(id)sender;
- (IBAction) portDAction:(id) sender;
- (IBAction) dacAction:(id) sender;
- (IBAction) writePortDAction:(id) sender;
- (IBAction) dacAction:(id)sender;
- (IBAction) readDacAction:(id)sender;
- (IBAction) writeDacAction:(id)sender;
- (IBAction) setLcmEnaAction:(id)sender;
- (IBAction) clrLcmEnaAction:(id)sender;

@end


