/*
 *  ORHV2132ModelController.cpp
 *  Orca
 *
 *  Created by Mark Howe on Sat Nov 16 2002.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
 */
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


#pragma mark ���Imported Files
#import "ORHV2132Controller.h"
#import "ORCamacExceptions.h"
#import "ORHV2132Model.h"
#import "ORTimedTextField.h"

#pragma mark ���Macros

// methods
@implementation ORHV2132Controller

#pragma mark ���Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"HV2132"];
    
    return self;
}

- (void) awakeFromNib
{
	[self populateChannelPU];
	[self populateMainFramePU];
#	ifndef HV2132ReadWorking
	[warningField setStringValue:@"WARNING: Readback faked using HV File"];
#	else
	[warningField setStringValue:@""];
#	endif

    [super awakeFromNib];
}

- (void) populateChannelPU
{
	[channelPU removeAllItems];
	[channelPU insertItemWithTitle:@"ALL" atIndex:0];
	int i;
	for(i=0;i<32;i++){
		[channelPU insertItemWithTitle:[NSString stringWithFormat:@"%d",i] atIndex:i+1];

	}
}

- (void) populateMainFramePU
{
	[mainFramePU removeAllItems];
	[mainFramePU insertItemWithTitle:@"ALL" atIndex:0];
	int i;
	for(i=0;i<16;i++){
		[mainFramePU insertItemWithTitle:[NSString stringWithFormat:@"%d",i] atIndex:i+1];

	}
}


#pragma mark ���Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(slotChanged:)
                         name : ORCamacCardSlotChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORHV2132SettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(hvValueChanged:)
                         name : ORHV2132ModelHvValueChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(mainFrameChanged:)
                         name : ORHV2132ModelMainFrameChanged
                        object: nil];
						
    [notifyCenter addObserver : self
                     selector : @selector(channelChanged:)
                         name : ORHV2132ModelChannelChanged
                        object: nil];	

    [notifyCenter addObserver : self
                     selector : @selector(dirChanged:)
                         name : ORHV2132StateFileDirChanged
						object: model];

}

#pragma mark ���Interface Management

- (void) updateWindow
{
    [super updateWindow];
    [self slotChanged:nil];
	
    [self dirChanged:nil];
    [self hvValueChanged:nil];
    [self mainFrameChanged:nil];
    [self channelChanged:nil];
    [self settingsLockChanged:nil];
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"HV2132 (Station %d)",[model stationNumber]]];
}

- (void) dirChanged:(NSNotification*)aNotification
{
	if([model dirName]!=nil)[hvStateDirField setStringValue: [model dirName]];
}

- (void) hvValueChanged:(NSNotification*)aNotification
{
	[hvValueStepper setIntValue:[model hvValue]];
	[hvValueTextField setIntValue:[model hvValue]];
}

- (void) mainFrameChanged:(NSNotification*)aNotification
{
	if([model mainFrame] == 0xff){
		[mainFramePU selectItemAtIndex:0];
	}
	else {
		[mainFramePU selectItemAtIndex:[model mainFrame]+1];
	}
}

- (void) channelChanged:(NSNotification*)aNotification
{
	if([model channel] == 0xff){
		[channelPU selectItemAtIndex:0];
	}
	else {
		[channelPU selectItemAtIndex:[model channel]+1];
	}
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORHV2132SettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORHV2132SettingsLock];
    BOOL locked = [gSecurity isLocked:ORHV2132SettingsLock];
    
    [settingLockButton setState: locked];


    [onButton setEnabled:!lockedOrRunningMaintenance];
    [offButton setEnabled:!lockedOrRunningMaintenance];
    [setButton setEnabled:!lockedOrRunningMaintenance];
    [readButton setEnabled:!lockedOrRunningMaintenance];
    [hvValueStepper setEnabled:!lockedOrRunningMaintenance];
    [hvValueTextField setEnabled:!lockedOrRunningMaintenance];

    [statusButton setEnabled:!lockedOrRunningMaintenance];
    [enableL1L2Button setEnabled:!lockedOrRunningMaintenance];
    [disableL1L2Button setEnabled:!lockedOrRunningMaintenance];
    [clearBufferButton setEnabled:!lockedOrRunningMaintenance];
    [mainFramePU setEnabled:!lockedOrRunningMaintenance];
    [channelPU setEnabled:!lockedOrRunningMaintenance];
	
        
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:ORHV2132SettingsLock])s = @"Not in Maintenance Run.";
    }
    [settingLockDocField setStringValue:s];
    
}

#pragma mark ���Actions
- (IBAction) hvValueAction:(id) sender
{
	if([model hvValue] != [sender intValue]){
		[model setHvValue:[sender intValue]];
	}
}

- (IBAction) mainFrameAction:(id) sender
{
	if([sender indexOfSelectedItem] == 0){
		[model setMainFrame:0xff];
	}
	else {
		[model setMainFrame:[sender indexOfSelectedItem]-1];
	}
}

- (IBAction) channelAction:(id) sender
{
	if([sender indexOfSelectedItem] == 0){
		[model setChannel:0xff];
	}
	else {
		[model setChannel:[sender indexOfSelectedItem]-1];
	}
}

- (IBAction) onAction:(id) sender
{
    NS_DURING
		[model setHV:YES mainFrame:[model mainFrame]];
        NSLog(@"HV2132 Station %d MainFrame %d Channel %d ON\n",[model stationNumber],[model mainFrame],[model channel]);
    NS_HANDLER
	
        [self showError:localException name:@"HV On Error"];
    NS_ENDHANDLER
}

- (IBAction) offAction:(id) sender
{
    NS_DURING
		[model setHV:NO mainFrame:[model mainFrame]];
        NSLog(@"HV2132 Station %d MainFrame %d Channel %d OFF\n",[model stationNumber],[model mainFrame],[model channel]);
    NS_HANDLER
	
        [self showError:localException name:@"HV Off Error"];
    NS_ENDHANDLER
}

- (IBAction) setAction:(id) sender
{
    NS_DURING
		[self endEditing];
		[model setVoltage:[model hvValue] mainFrame:[model mainFrame] channel:[model channel]];
        NSLog(@"HV2132 Station %d MainFrame %d Channel %d SetTo: %d\n",[model stationNumber],[model mainFrame],[model channel],[model hvValue]);
    NS_HANDLER
        [self showError:localException name:@"HV Set Error"];
    NS_ENDHANDLER
}

- (IBAction) readAction:(id) sender
{
    NS_DURING
		[self endEditing];
		int value;
		[model readVoltage:&value mainFrame:[model mainFrame] channel:[model channel]];
        NSLog(@"HV2132 Station %d MainFrame %d Channel %d Voltage: %d\n",[model stationNumber],[model mainFrame],[model channel],value);
    NS_HANDLER
        [self showError:localException name:@"HV Read Error"];
    NS_ENDHANDLER
}


- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORHV2132SettingsLock to:[sender intValue] forWindow:[self window]];
}


- (void) showError:(NSException*)anException name:(NSString*)name
{
    NSLog(@"Failed Cmd: %@\n",name);
    if([[anException name] isEqualToString: OExceptionNoCamacCratePower]) {
        [[model crate]  doNoPowerAlert:anException action:[NSString stringWithFormat:@"%@",name]];
    }
    else {
        NSRunAlertPanel([anException name], @"%@\n%@", @"OK", nil, nil,
                        [anException name],name);
    }
}

- (IBAction) enableL1L2Action:(id) sender
{
    NS_DURING
		[model enableL1L2:YES];
        NSLog(@"HV2132 Station %d L1 L2 enabled\n",[model stationNumber]);
    NS_HANDLER
        [self showError:localException name:@"L1, L2 enable failed"];
    NS_ENDHANDLER
}

- (IBAction) disableL1L2Action:(id) sender
{
   NS_DURING
		[model enableL1L2:YES];
        NSLog(@"HV2132 Station %d L1 L2 disabled\n",[model stationNumber]);
    NS_HANDLER
        [self showError:localException name:@"L1, L2 disable failed"];
    NS_ENDHANDLER
}

- (IBAction) clearBufferAction:(id) sender
{
   NS_DURING
		[model clearBuffer];
        NSLog(@"HV2132 Station %d MainFrame %d buffer cleared\n",[model stationNumber],[model mainFrame]);
    NS_HANDLER
        [self showError:localException name:@"Buffer Clear Error"];
    NS_ENDHANDLER
	
}

- (IBAction) statusAction:(id) sender
{
   NS_DURING
		int aValue;
		unsigned short failed;
		
		[model readStatus:&aValue failedMask:&failed mainFrame:[model mainFrame]];
		if(aValue&0x1)NSLog(@"MainFrame %d HV ON\n",[model mainFrame]);
		else          NSLog(@"MainFrame %d HV OFF\n",[model mainFrame]);
		if(failed){
			NSLog(@"MainFrame %d Failed Mask: 0x%016x\n",[model mainFrame],failed);
		}
    NS_HANDLER
        [self showError:localException name:@"Read Status Error"];
    NS_ENDHANDLER
}

- (IBAction) chooseDir:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setPrompt:@"Choose"];
	[openPanel beginSheetForDirectory:NSHomeDirectory()
								 file:nil
								types:nil
					   modalForWindow:[self window]
						modalDelegate:self
					   didEndSelector:@selector(_openPanelDidEnd:returnCode:contextInfo:)
						  contextInfo:NULL];
	
}

- (void)_openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
	if(returnCode){
		NSString* dirName = [[[sheet filenames] objectAtIndex:0] stringByAbbreviatingWithTildeInPath];
		[model setDirName:dirName];
	}
}

@end

