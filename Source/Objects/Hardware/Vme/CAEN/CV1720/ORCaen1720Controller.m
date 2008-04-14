//
//ORCaen1720Controller.m
//Orca
//
//Created by Mark Howe on Mon Apr 14 2008.
//Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
//
//-------------------------------------------------------------
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

#import "ORCaen1720Controller.h"
#import "ORCaenDataDecoder.h"
#import "ORCaen1720Model.h"

#define kNumChanConfigBits 5
#define kNumTrigSourceBits 10

int chanConfigToMaskBit[kNumChanConfigBits] = {1,3,4,6,11};
int trigSrcToMaskBit[kNumTrigSourceBits]    = {0,1,2,3,4,5,6,7,30,31};

@implementation ORCaen1720Controller

#pragma mark ***Initialization
- (id) init
{
    self = [ super initWithWindowNibName: @"Caen1720" ];
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) awakeFromNib
{

    settingSize     = NSMakeSize(280,400);
    thresholdSize   = NSMakeSize(490,470);
    
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];


    [registerAddressPopUp setAlignment:NSCenterTextAlignment];
    [channelPopUp setAlignment:NSCenterTextAlignment];
	    
    [self populatePullDown];
    
    [super awakeFromNib];

    NSString* key = [NSString stringWithFormat: @"orca.ORCaenCard%d.selectedtab",[model slot]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];

}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [ super registerNotificationObservers ];
	
    [notifyCenter addObserver:self
					 selector:@selector(baseAddressChanged:)
						 name:ORVmeIOCardBaseAddressChangedNotification
					   object:model];
	
    [notifyCenter addObserver:self
					 selector:@selector(selectedRegIndexChanged:)
						 name:ORCaen1720SelectedRegIndexChanged
					   object:model];
	
    [notifyCenter addObserver:self
					 selector:@selector(selectedRegChannelChanged:)
						 name:ORCaen1720SelectedChannelChanged
					   object:model];
		
    [notifyCenter addObserver:self
					 selector:@selector(writeValueChanged:)
						 name:ORCaen1720WriteValueChanged
					   object:model];
	
    [notifyCenter addObserver:self
					 selector:@selector(thresholdChanged:)
						 name:ORCaen1720ChnlThresholdChanged
					   object:model];
	
	[notifyCenter addObserver:self
					 selector:@selector(dacChanged:)
						 name:ORCaen1720ChnlDacChanged
					   object:model];
	
	[notifyCenter addObserver:self
					 selector:@selector(overUnderChanged:)
						 name:ORCaen1720OverUnderThresholdChanged
					   object:model];
	
    [notifyCenter addObserver : self
                     selector : @selector(channelConfigMaskChanged:)
                         name : ORCaen1720ModelChannelConfigMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(customSizeChanged:)
                         name : ORCaen1720ModelCustomSizeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(countAllTriggersChanged:)
                         name : ORCaen1720ModelCountAllTriggersChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(acquisitionModeChanged:)
                         name : ORCaen1720ModelAcquisitionModeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(coincidenceLevelChanged:)
                         name : ORCaen1720ModelCoincidenceLevelChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(triggerSourceMaskChanged:)
                         name : ORCaen1720ModelTriggerSourceMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(postTriggerSettingChanged:)
                         name : ORCaen1720ModelPostTriggerSettingChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(enabledMaskChanged:)
                         name : ORCaen1720ModelEnabledMaskChanged
						object: model];
	
   [notifyCenter addObserver : self
					 selector : @selector(basicLockChanged:)
						 name : ORCaen1720BasicLock
						object: nil];

   [notifyCenter addObserver : self
					 selector : @selector(settingsLockChanged:)
						 name : ORCaen1720SettingsLock
						object: nil];


}

#pragma mark ***Interface Management
- (void) updateWindow
{
	[super updateWindow];
    [self writeValueChanged:nil];
    [self selectedRegIndexChanged:nil];
    [self selectedRegChannelChanged:nil];
	[self baseAddressChanged:nil];
	[self dacChanged:nil];
	[self thresholdChanged:nil];
	[self overUnderChanged:nil];
	[self channelConfigMaskChanged:nil];
	[self customSizeChanged:nil];
	[self countAllTriggersChanged:nil];
	[self acquisitionModeChanged:nil];
	[self coincidenceLevelChanged:nil];
	[self triggerSourceMaskChanged:nil];
	[self postTriggerSettingChanged:nil];
	[self enabledMaskChanged:nil];
    [self basicLockChanged:nil];
    [self settingsLockChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORCaen1720BasicLock to:secure];
    [basicLockButton setEnabled:secure];
    [gSecurity setLock:ORCaen1720SettingsLock to:secure];
    [settingsLockButton setEnabled:secure];
}

- (void) writeValueChanged:(NSNotification*) aNotification
{
	//  Set value of both text and stepper
	[self updateStepper:writeValueStepper setting:[model writeValue]];
	[writeValueTextField setIntValue:[model writeValue]];
}

- (void) selectedRegIndexChanged:(NSNotification*) aNotification
{

	//  Set value of popup
	short index = [model selectedRegIndex];
	[self updatePopUpButton:registerAddressPopUp setting:index];
	[self updateRegisterDescription:index];


	BOOL readAllowed = [model getAccessType:index] == kReadOnly || [model getAccessType:index] == kReadWrite;
	BOOL writeAllowed = [model getAccessType:index] == kWriteOnly || [model getAccessType:index] == kReadWrite;

	[basicWriteButton setEnabled:writeAllowed];
	[basicReadButton setEnabled:readAllowed];
 
	BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORCaen1720BasicLock];
	if ([model selectedRegIndex] >= kZS_Thres && [model selectedRegIndex]<=kAdcConfig){
		[channelPopUp setEnabled:!lockedOrRunningMaintenance];
	}
	else [channelPopUp setEnabled:NO];

}

- (void) selectedRegChannelChanged:(NSNotification*) aNotification
{
	[self updatePopUpButton:channelPopUp setting:[model selectedChannel]];
}

- (void) enabledMaskChanged:(NSNotification*)aNote
{
	int i;
	unsigned short mask = [model enabledMask];
	for(i=0;i<[model numberOfChannels];i++){
		[[enabledMaskMatrix cellWithTag:i] setIntValue:(mask & (1<<i)) !=0];
	}
}

- (void) postTriggerSettingChanged:(NSNotification*)aNote
{
	[postTriggerSettingTextField setIntValue: [model postTriggerSetting]];
}

- (void) triggerSourceMaskChanged:(NSNotification*)aNote
{
	int i;
	unsigned short mask = [model triggerSourceMask];
	for(i=0;i<kNumTrigSourceBits;i++){
		[[triggerSourceMaskMatrix cellWithTag:i] setIntValue:(mask & (1<<trigSrcToMaskBit[i])) !=0];
	}
}

- (void) coincidenceLevelChanged:(NSNotification*)aNote
{
	[coincidenceLevelTextField setIntValue: [model coincidenceLevel]];
}

- (void) acquisitionModeChanged:(NSNotification*)aNote
{
	[acquisitionModeMatrix selectCellWithTag:[model acquisitionMode]];
}

- (void) countAllTriggersChanged:(NSNotification*)aNote
{
	[countAllTriggersMatrix selectCellWithTag: [model countAllTriggers]];
}

- (void) customSizeChanged:(NSNotification*)aNote
{
	[customSizeTextField setIntValue: [model customSize]];
}

- (void) channelConfigMaskChanged:(NSNotification*)aNote
{
	int i;
	unsigned short mask = [model channelConfigMask];
	for(i=0;i<kNumChanConfigBits;i++){
		[[channelConfigMaskMatrix cellWithTag:i] setIntValue:(mask & (1<<chanConfigToMaskBit[i])) !=0];
	}


}

- (void) baseAddressChanged:(NSNotification*) aNotification
{
	//  Set value of both text and stepper
	 [self updateStepper:addressStepper setting:[model baseAddress]];
	 [addressTextField setIntValue:[model baseAddress]];
}

- (void) thresholdChanged:(NSNotification*) aNotification
{
// Get the channel that changed and then set the GUI value using the model value.
	int chnl = [[[aNotification userInfo] objectForKey:ORCaen1720Chnl] intValue];
	[[thresholdMatrix cellWithTag:chnl] setIntValue:[model threshold:chnl]];
}

- (void) dacChanged: (NSNotification*) aNotification
{
	if(aNotification){
		int chnl = [[[aNotification userInfo] objectForKey:ORCaen1720Chnl] intValue];
		[[dacMatrix cellWithTag:chnl] setFloatValue:[model convertDacToVolts:[model dac:chnl]]];
	}
	else {
		int i;
		for (i = 0; i < [model numberOfChannels]; i++){
			[[dacMatrix cellWithTag:i] setFloatValue:[model convertDacToVolts:[model dac:i]]];
		}
	}
}

- (void) overUnderChanged: (NSNotification*) aNotification
{
	if(aNotification){
		int chnl = [[[aNotification userInfo] objectForKey:ORCaen1720Chnl] intValue];
		[[overUnderMatrix cellWithTag:chnl] setIntValue:[model overUnderThreshold:chnl]];
	}
	else {
		int i;
		for (i = 0; i < [model numberOfChannels]; i++){
			[[overUnderMatrix cellWithTag:i] setIntValue:[model overUnderThreshold:i]];
		}
	}
}

- (void) basicLockChanged:(NSNotification*)aNotification
{	
    BOOL runInProgress				= [gOrcaGlobals runInProgress];
    BOOL locked						= [gSecurity isLocked:ORCaen1720BasicLock];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORCaen1720BasicLock];
	
	[softwareTriggerButton setEnabled: !locked && !runInProgress]; 
    [basicLockButton setState: locked];
    
    [addressStepper setEnabled:!locked && !runInProgress];
    [addressTextField setEnabled:!locked && !runInProgress];

    [writeValueStepper setEnabled:!lockedOrRunningMaintenance];
    [writeValueTextField setEnabled:!lockedOrRunningMaintenance];
    [registerAddressPopUp setEnabled:!lockedOrRunningMaintenance];

    [self selectedRegIndexChanged:nil];

    [basicWriteButton setEnabled:!lockedOrRunningMaintenance];
    [basicReadButton setEnabled:!lockedOrRunningMaintenance]; 
    
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
		if(runInProgress && ![gSecurity isLocked:ORCaen1720BasicLock])s = @"Not in Maintenance Run.";
    }
    [basicLockDocField setStringValue:s];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{	
   // BOOL runInProgress				= [gOrcaGlobals runInProgress];
   // BOOL locked						= [gSecurity isLocked:ORCaen1720BasicLock];
   // BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORCaen1720BasicLock];
}

#pragma mark •••Actions
- (IBAction) baseAddressAction:(id) aSender
{
    // Make sure that value has changed.
    if ([aSender intValue] != [model baseAddress]){
		[[[model document] undoManager] setActionName:@"Set Base Address"]; // Set undo name.
		[model setBaseAddress:[aSender intValue]]; // set new value.
    }
} 

- (IBAction) read:(id) pSender
{
	NS_DURING
		[self endEditing];		// Save in memory user changes before executing command.
		[model read];
    NS_HANDLER
        NSRunAlertPanel([localException name], @"%@\nRead of %@ failed", @"OK", nil, nil,
                        localException,[model getRegisterName:[model selectedRegIndex]]);
    NS_ENDHANDLER
}

- (IBAction) write:(id) pSender
{
	NS_DURING
		[self endEditing];		// Save in memory user changes before executing command.
		[model write];
    NS_HANDLER
        NSRunAlertPanel([localException name], @"%@\nWrite to %@ failed", @"OK", nil, nil,
                        localException,[model getRegisterName:[model selectedRegIndex]]);
    NS_ENDHANDLER
}

- (IBAction) writeValueAction:(id) aSender
{
    // Make sure that value has changed.
    if ([aSender intValue] != [model writeValue]){
		[[[model document] undoManager] setActionName:@"Set Write Value"]; // Set undo name.
		[model setWriteValue:[aSender intValue]]; // Set new value
    }
}

- (IBAction) selectRegisterAction:(id) aSender
{
    // Make sure that value has changed.
    if ([aSender indexOfSelectedItem] != [model selectedRegIndex]){
	    [[[model document] undoManager] setActionName:@"Select Register"]; // Set undo name
	    [model setSelectedRegIndex:[aSender indexOfSelectedItem]]; // set new value
    }
}

- (IBAction) selectChannelAction:(id) aSender
{
    // Make sure that value has changed.
    if ([aSender indexOfSelectedItem] != [model selectedChannel]){
		[[[model document] undoManager] setActionName:@"Select Channel"]; // Set undo name
		[model setSelectedChannel:[aSender indexOfSelectedItem]]; // Set new value
    }
}
- (IBAction) basicLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORCaen1720BasicLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) settingsLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORCaen1720SettingsLock to:[sender intValue] forWindow:[self window]];
}

- (void) enabledMaskAction:(id)sender
{
	int i;
	unsigned short mask = 0;
	for(i=0;i<[model numberOfChannels];i++){
		if([[sender cellWithTag:i] intValue]) mask |= (1 << i);
	}
	[model setEnabledMask:mask];	

}

- (void) postTriggerSettingTextFieldAction:(id)sender
{
	[model setPostTriggerSetting:[sender intValue]];	
}

- (IBAction) triggerSourceMaskAction:(id)sender
{
	int i;
	unsigned short mask = 0;
	for(i=0;i<kNumTrigSourceBits;i++){
		if([[sender cellWithTag:i] intValue]) mask |= (1 << trigSrcToMaskBit[i]);
	}
	[model setTriggerSourceMask:mask];	
}

- (IBAction) coincidenceLevelTextFieldAction:(id)sender
{
	[model setCoincidenceLevel:[sender intValue]];	
}
- (IBAction) generateTriggerAction:(id)sender
{
	NS_DURING
		[model generateSoftwareTrigger];
	NS_HANDLER
        NSRunAlertPanel([localException name], @"%@\nSoftware Trigger Failed", @"OK", nil, nil,
                        localException);
	NS_ENDHANDLER
}

- (IBAction) acquisitionModeAction:(id)sender
{
	[model setAcquisitionMode:[[sender selectedCell] tag]];	
}

- (IBAction) countAllTriggersAction:(id)sender
{
	[model setCountAllTriggers:[[sender selectedCell] tag]];	
}

- (IBAction) customSizeAction:(id)sender
{
	[model setCustomSize:[sender intValue]];	
}

- (IBAction) channelConfigMaskAction:(id)sender
{
	int i;
	unsigned short mask = 0;
	for(i=0;i<kNumChanConfigBits;i++){
		if([[sender cellWithTag:i] intValue]) mask |= (1 << chanConfigToMaskBit[i]);
	}
	[model setChannelConfigMask:mask];	
}

- (IBAction) dacAction:(id) aSender
{
	[[[model document] undoManager] setActionName:@"Set dacs"]; // Set name of undo.
	[model setDac:[[aSender selectedCell] tag] withValue:[model convertVoltsToDac:[[aSender selectedCell] floatValue]]]; // Set new value
}

- (IBAction) thresholdAction:(id) aSender
{
    if ([aSender intValue] != [model threshold:[[aSender selectedCell] tag]]){
        [[[model document] undoManager] setActionName:@"Set thresholds"]; // Set name of undo.
        [model setThreshold:[[aSender selectedCell] tag] threshold:[aSender intValue]]; // Set new value
    }
}

#pragma mark ***Misc Helpers
- (void) populatePullDown
{
    short	i;
        
    [registerAddressPopUp removeAllItems];
    [channelPopUp removeAllItems];
    
    for (i = 0; i < [model getNumberRegisters]; i++) {
        [registerAddressPopUp insertItemWithTitle:[model 
                                    getRegisterName:i] 
                                            atIndex:i];
    }
 
	for (i = 0; i < 8 ; i++) {
        [channelPopUp insertItemWithTitle:[NSString stringWithFormat:@"%d", i] 
                                    atIndex:i];
    }
    [channelPopUp insertItemWithTitle:@"All" atIndex:8];
    
    [self selectedRegIndexChanged:nil];
    [self selectedRegChannelChanged:nil];

}

- (void) updateRegisterDescription:(short) aRegisterIndex
{
    NSString* types[] = {
		@"[ReadOnly]",
		@"[WriteOnly]",
		@"[ReadWrite]"
    };

    [registerOffsetTextField setStringValue:
    [NSString stringWithFormat:@"0x%04x",
    [model getAddressOffset:aRegisterIndex]]];
	
    [registerReadWriteTextField setStringValue:types[[model getAccessType:aRegisterIndex]]];
    [regNameField setStringValue:[model getRegisterName:aRegisterIndex]];

    [drTextField setStringValue:[model dataReset:aRegisterIndex] ? @"Y" :@"N"];
    [srTextField setStringValue:[model swReset:aRegisterIndex]   ? @"Y" :@"N"];
    [hrTextField setStringValue:[model hwReset:aRegisterIndex]   ? @"Y" :@"N"];    
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:settingSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 1){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:thresholdSize];
		[[self window] setContentView:tabView];
    }

    NSString* key = [NSString stringWithFormat: @"orca.ORCaenCard%d.selectedtab",[model slot]];
    int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];

}

@end
