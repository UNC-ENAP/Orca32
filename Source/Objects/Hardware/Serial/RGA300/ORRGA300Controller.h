//--------------------------------------------------------
// ORRGA300Controller
// Created by Mark  A. Howe on Tues Jan 4, 2012
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2012 CENPA, University of Washington. All rights reserved.
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
//for the us of this software.
//-------------------------------------------------------------

#pragma mark •••Imported Files

@class StopLightView;
@class ORCompositePlotView;
@class ORSerialPortController;

@interface ORRGA300Controller : OrcaObjectController
{
	IBOutlet NSTextField* serialNumberField;
	IBOutlet NSTextField* scanNumberField;
	IBOutlet NSTextField* currentAmuIndexField;
	IBOutlet NSTextField* currentActivityField;
	IBOutlet NSPopUpButton* opModePU;
	IBOutlet NSTextField* elecMultGainRBField;
	IBOutlet NSTextField* elecMultHVBiasRBField;
	IBOutlet NSTextField* noiseFloorSettingRBField;
	
	IBOutlet NSTextField* ionizerFocusPlateVoltageRBField;
	IBOutlet NSTextField* ionizerIonEnergyRBField;
	IBOutlet NSTextField* ionizerElectronEnergyRBField;
	IBOutlet NSTextField* ionizerFilamentCurrentRBField;
	
	IBOutlet NSTextField* elecMultGainField;
	IBOutlet NSTextField* electronMultiOptionField;
	IBOutlet NSTextField* measuredIonCurrentField;
	IBOutlet NSTextField* numberScansField;
	IBOutlet NSTextField* stepsPerAmuField;
	IBOutlet NSTextField* initialMassField;
	IBOutlet NSTextField* finalMassField;
	IBOutlet NSTextField* histoScanPointsField;
	IBOutlet NSTextField* analogScanPointsField;
	IBOutlet NSTextField* noiseFloorSettingField;
	IBOutlet NSTextField* elecMultHVBiasField;
	
	IBOutlet NSMatrix*		rs232ErrWordMatrix;
	IBOutlet NSMatrix*		filErrWordMatrix;
	IBOutlet NSMatrix*		cemErrWordMatrix;
	IBOutlet NSMatrix*		qmfErrWordMatrix;
	IBOutlet NSMatrix*		detErrWordMatrix;
	IBOutlet NSMatrix*		psErrWordMatrix;
	IBOutlet NSMatrix*		statusWordMatrix;
	IBOutlet NSTextField*	firmwareVersionField;
	IBOutlet NSTextField*	modelNumberField;
    IBOutlet NSButton*		lockButton;
    IBOutlet ORCompositePlotView*	plotter;
    IBOutlet ORSerialPortController* serialPortController;
	
	IBOutlet NSTextField*	ionizerFocusPlateVoltageField;
	IBOutlet NSPopUpButton* ionizerIonEnergyPU;
	IBOutlet NSTextField*	ionizerEmissionCurrentField;
	IBOutlet NSTextField*	ionizerElectronEnergyField;
	IBOutlet NSTextField*	ionizerDegassTimeField;

    IBOutlet NSButton*		filamentOnOffButton;
    IBOutlet NSMatrix*		useIonizerDefaultsMatrix;
	IBOutlet NSButton*		elecMultHVBiasOnOffButton;
	IBOutlet NSMatrix*		useDetectorDefaultsMatrix;
	IBOutlet NSButton*		startMeasurementButton;
	IBOutlet NSButton*		stopMeasurementButton;
	IBOutlet NSProgressIndicator* scanProgressBar;
	IBOutlet NSDrawer*		errorDrawer;
	IBOutlet NSButton*		detailsButton;
	IBOutlet NSTableView*	amuTable;
    IBOutlet NSButton*      addAmuButton;
    IBOutlet NSButton*      removeAmuButton;
}

#pragma mark •••Initialization
- (id) init;
- (void) dealloc;
- (void) awakeFromNib;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) updateButtons;

#pragma mark •••Interface Management
- (void) drawDidOpen:(NSNotification*)aNote;
- (void) drawDidClose:(NSNotification*)aNote;
- (void) scanDataChanged:(NSNotification*)aNote;
- (void) scanNumberChanged:(NSNotification*)aNote;
- (void) scanProgressChanged:(NSNotification*)aNote;
- (void) currentActivityChanged:(NSNotification*)aNote;
- (void) opModeChanged:(NSNotification*)aNote;
- (void) elecMultGainRBChanged:(NSNotification*)aNote;
- (void) elecMultHVBiasRBChanged:(NSNotification*)aNote;
- (void) noiseFloorSettingRBChanged:(NSNotification*)aNote;
- (void) ionizerFocusPlateVoltageRBChanged:(NSNotification*)aNote;
- (void) ionizerIonEnergyRBChanged:(NSNotification*)aNote;
- (void) ionizerElectronEnergyRBChanged:(NSNotification*)aNote;
- (void) ionizerFilamentCurrentRBChanged:(NSNotification*)aNote;
- (void) elecMultGainChanged:(NSNotification*)aNote;
- (void) electronMultiOptionChanged:(NSNotification*)aNote;
- (void) measuredIonCurrentChanged:(NSNotification*)aNote;
- (void) numberScansChanged:(NSNotification*)aNote;
- (void) stepsPerAmuChanged:(NSNotification*)aNote;
- (void) initialMassChanged:(NSNotification*)aNote;
- (void) finalMassChanged:(NSNotification*)aNote;
- (void) histoScanPointsChanged:(NSNotification*)aNote;
- (void) analogScanPointsChanged:(NSNotification*)aNote;
- (void) noiseFloorSettingChanged:(NSNotification*)aNote;
- (void) elecMultHVBiasChanged:(NSNotification*)aNote;
- (void) ionizerFocusPlateVoltageChanged:(NSNotification*)aNote;
- (void) ionizerIonEnergyChanged:(NSNotification*)aNote;
- (void) ionizerEmissionCurrentChanged:(NSNotification*)aNote;
- (void) ionizerElectronEnergyChanged:(NSNotification*)aNote;
- (void) ionizerDegassTimeChanged:(NSNotification*)aNote;
- (void) rs232ErrWordChanged:(NSNotification*)aNote;
- (void) filErrWordChanged:(NSNotification*)aNote;
- (void) cemErrWordChanged:(NSNotification*)aNote;
- (void) qmfErrWordChanged:(NSNotification*)aNote;
- (void) detErrWordChanged:(NSNotification*)aNote;
- (void) psErrWordChanged:(NSNotification*)aNote;
- (void) statusWordChanged:(NSNotification*)aNote;
- (void) serialNumberChanged:(NSNotification*)aNote;
- (void) firmwareVersionChanged:(NSNotification*)aNote;
- (void) modelNumberChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;
- (void) scaleAction:(NSNotification*)aNotification;
- (void) miscAttributesChanged:(NSNotification*)aNote;
- (void) amuCountChanged:(NSNotification*)aNote;
- (void) currentAmuIndexChanged:(NSNotification*)aNote;
- (void) useIonizerDefaultsChanged:(NSNotification*)aNote;
- (void) useDetectorDefaultsChanged:(NSNotification*)aNote;
- (BOOL) portLocked;
- (void) setupPlotter;

- (void) _syncSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;

#pragma mark •••Actions
- (IBAction) startMeasurementAction:(id)sender;
- (IBAction) stopMeasurementAction:(id)sender;
- (IBAction) opModeAction:(id)sender;
- (IBAction) elecMultGainAction:(id)sender;
- (IBAction) queryAllAction:(id)sender;
- (IBAction) syncDialogAction:(id)sender;
- (IBAction) numberScansAction:(id)sender;
- (IBAction) stepsPerAmuAction:(id)sender;
- (IBAction) initialMassAction:(id)sender;
- (IBAction) finalMassAction:(id)sender;
- (IBAction) noiseFloorSettingAction:(id)sender;
- (IBAction) elecMultHVBiasAction:(id)sender;
- (IBAction) ionizerFocusPlateVoltageAction:(id)sender;
- (IBAction) ionizerIonEnergyAction:(id)sender;
- (IBAction) ionizerEmissionCurrentAction:(id)sender;
- (IBAction) ionizerElectronEnergyAction:(id)sender;
- (IBAction) ionizerDegassTimeAction:(id)sender;
- (IBAction) lockAction:(id) sender;
- (IBAction) resetAction:(id)sender;
- (IBAction) standByAction:(id)sender;
- (IBAction) degassAction:(id)sender;
- (IBAction) addAmuAction:(id)sender;
- (IBAction) removeAmuAction:(id)sender;
- (IBAction) toggleHVBiasAction:(id)sender;	
- (IBAction) toggleIonizerAction:(id)sender;	
- (IBAction) useIonizerDefaultsAction:(id)sender;
- (IBAction) useDectorDefaultsAction:(id)sender;

- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
- (int) numberOfRowsInTableView:(NSTableView *)tableView;
- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;

@end


