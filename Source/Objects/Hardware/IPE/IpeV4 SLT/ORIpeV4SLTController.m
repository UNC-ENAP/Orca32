//
//  ORIpeV4SLTController.m
//  Orca
//
//  Created by Mark Howe on Wed Aug 24 2005.
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


#pragma mark •••Imported Files
#import "ORIpeV4SLTController.h"
#import "ORIpeV4SLTModel.h"
#import "TimedWorker.h"

#define kFltNumberTriggerSources 5

NSString* fltV4TriggerSourceNames[2][kFltNumberTriggerSources] = {
{
	@"Software",
	@"Right",
	@"Left",
	@"Mirror",
	@"External",
},
{
	@"Software",
	@"N/A",
	@"N/A",
	@"Multiplicity",
	@"External",
}
};

@implementation ORIpeV4SLTController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"IpeV4SLT"];
    
    return self;
}

#pragma mark •••Initialization
- (void) dealloc
{
	[xImage release];
	[yImage release];
    [super dealloc];
}

- (void) awakeFromNib
{
	controlSize			= NSMakeSize(555,670);
    statusSize			= NSMakeSize(555,610);
    lowLevelSize		= NSMakeSize(555,340);
    cpuManagementSize	= NSMakeSize(555,450);
    cpuTestsSize		= NSMakeSize(555,305);
	
	[[self window] setTitle:@"IPE-DAQ-V4 SLT"];	
	
    [super awakeFromNib];
    [self updateWindow];
	
	[self populatePullDown];
	[pageStatusMatrix setMode:NSRadioModeMatrix];
	[pageStatusMatrix setTarget:self];
	[pageStatusMatrix setAction:@selector(dumpPageStatus:)];
	
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
	
	[notifyCenter addObserver : self
                     selector : @selector(hwVersionChanged:)
                         name : ORIpeV4SLTModelHwVersionChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(statusRegChanged:)
                         name : ORIpeV4SLTModelStatusRegChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(controlRegChanged:)
                         name : ORIpeV4SLTModelControlRegChanged
                       object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(selectedRegIndexChanged:)
						 name : ORIpeV4SLTSelectedRegIndexChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(writeValueChanged:)
						 name : ORIpeV4SLTWriteValueChanged
					   object : model];
		
    [notifyCenter addObserver : self
                     selector : @selector(pulserAmpChanged:)
                         name : ORIpeV4SLTPulserAmpChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pulserDelayChanged:)
                         name : ORIpeV4SLTPulserDelayChanged
                       object : model];
		
    [notifyCenter addObserver : self
                     selector : @selector(pageSizeChanged:)
                         name : ORIpeV4SLTModelPageSizeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pageSizeChanged:)
                         name : ORIpeV4SLTModelDisplayEventLoopChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pageSizeChanged:)
                         name : ORIpeV4SLTModelDisplayTriggerChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(interruptMaskChanged:)
                         name : ORIpeV4SLTModelInterruptMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(nextPageDelayChanged:)
                         name : ORIpeV4SLTModelNextPageDelayChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pollRateChanged:)
                         name : TimedWorkerTimeIntervalChangedNotification
                       object : [model poller]];
	
    [notifyCenter addObserver : self
                     selector : @selector(pollRunningChanged:)
                         name : TimedWorkerIsRunningChangedNotification
                       object : [model poller]];
	
    [notifyCenter addObserver : self
                     selector : @selector(patternFilePathChanged:)
                         name : ORIpeV4SLTModelPatternFilePathChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(secondsSetChanged:)
                         name : ORIpeV4SLTModelSecondsSetChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(pageManagerRegChanged:)
                         name : ORIpeV4SLTModelPageManagerRegChanged
						object: model];

}

#pragma mark •••Interface Management

- (void) pageManagerRegChanged:(NSNotification*)aNote
{
	unsigned long pageManagerReg = [model pageManagerReg];
	
	if(!xImage)xImage = [[NSImage imageNamed:@"exMark"] retain];
	if(!yImage)yImage = [[NSImage imageNamed:@"checkMark"] retain];
	
	unsigned long oldest = (pageManagerReg & kPageMngOldestPage) >> kPageMngOldestPageShift;
	unsigned long newest = (pageManagerReg & kPageMngNextPage) >> kPageMngNextPageShift;
	int i;
	for(i=0;i<64;i++){
		NSCell* aCell = [[pageStatusMatrix cells] objectAtIndex:i];
		if(i>=oldest && i<newest)[aCell setImage:yImage];
		else [aCell setImage:xImage];
	}
	[pageStatusMatrix setNeedsDisplay:YES];
	
	[oldestPageField setIntValue:oldest];
	[nextPageField setIntValue:  newest];
}

- (void) secondsSetChanged:(NSNotification*)aNote
{
	[secondsSetField setIntValue: [model secondsSet]];
}

- (void) statusRegChanged:(NSNotification*)aNote
{
	unsigned long statusReg = [model statusReg];
	[[statusMatrix cellWithTag:0] setStringValue: IsBitSet(statusReg,kStatusWDog)?@"ERR":@"OK"];
	[[statusMatrix cellWithTag:1] setStringValue: IsBitSet(statusReg,kStatusPixErr)?@"ERR":@"OK"]; 
	[[statusMatrix cellWithTag:2] setStringValue: IsBitSet(statusReg,kStatusPpsErr)?@"ERR":@"OK"]; 
	[[statusMatrix cellWithTag:3] setStringValue: [NSString stringWithFormat:@"0x%02x",ExtractValue(statusReg,kStatusClkErr,4)]]; 
	[[statusMatrix cellWithTag:4] setStringValue: IsBitSet(statusReg,kStatusGpsErr)?@"ERR":@"OK"]; 
	[[statusMatrix cellWithTag:5] setStringValue: IsBitSet(statusReg,kStatusVttErr)?@"ERR":@"OK"]; 
	[[statusMatrix cellWithTag:6] setStringValue: IsBitSet(statusReg,kStatusFanErr)?@"ERR":@"OK"]; 

}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	[super tabView:aTabView didSelectTabViewItem:tabViewItem];
	
    switch([tabView indexOfTabViewItem:tabViewItem]){
        case  0: [self resizeWindowToSize:controlSize];			break;
		case  1: [self resizeWindowToSize:statusSize];			break;
		case  2: [self resizeWindowToSize:lowLevelSize];	    break;
		case  3: [self resizeWindowToSize:cpuManagementSize];	break;
		default: [self resizeWindowToSize:cpuTestsSize];	    break;
    }
}

- (void) patternFilePathChanged:(NSNotification*)aNote
{
	NSString* thePath = [[model patternFilePath] stringByAbbreviatingWithTildeInPath];
	if(!thePath)thePath = @"---";
	[patternFilePathField setStringValue: thePath];
}

- (void) pollRateChanged:(NSNotification*)aNotification
{
    if(aNotification== nil || [aNotification object] == [model poller]){
        [pollRatePopup selectItemAtIndex:[pollRatePopup indexOfItemWithTag:[[model poller] timeInterval]]];
    }
}

- (void) pollRunningChanged:(NSNotification*)aNotification
{
    if(aNotification== nil || [aNotification object] == [model poller]){
        if([[model poller] isRunning])[pollRunningIndicator startAnimation:self];
        else [pollRunningIndicator stopAnimation:self];
    }
}

- (void) nextPageDelayChanged:(NSNotification*)aNote
{
	[nextPageDelaySlider setIntValue:100-[model nextPageDelay]];
	[nextPageDelayField  setFloatValue:[model nextPageDelay]*102.3/100.];
}

- (void) interruptMaskChanged:(NSNotification*)aNote
{
	unsigned long aMaskValue = [model interruptMask];
	int i;
	for(i=0;i<9;i++){
		if(aMaskValue & (1L<<i))[[interruptMaskMatrix cellWithTag:i] setIntValue:1];
		else [[interruptMaskMatrix cellWithTag:i] setIntValue:0];
	}
}

- (void) pageSizeChanged:(NSNotification*)aNote
{
	[pageSizeField setIntValue: [model pageSize]];
	[pageSizeStepper setIntValue: [model pageSize]];
}


- (void) updateWindow
{
    [super updateWindow];
	[self hwVersionChanged:nil];
	[self controlRegChanged:nil];
    [self writeValueChanged:nil];
    [self pulserAmpChanged:nil];
    [self pulserDelayChanged:nil];
    [self selectedRegIndexChanged:nil];
	[self pageSizeChanged:nil];	
	[self displayEventLoopChanged:nil];	
	[self displayTriggerChanged:nil];	
	[self interruptMaskChanged:nil];
	[self nextPageDelayChanged:nil];
    [self pollRateChanged:nil];
    [self pollRunningChanged:nil];
	[self patternFilePathChanged:nil];
	[self statusRegChanged:nil];
	[self secondsSetChanged:nil];
}


- (void) checkGlobalSecurity
{
    [super checkGlobalSecurity]; 
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:[model sbcLockName] to:secure];
}


- (void) settingsLockChanged:(NSNotification*)aNotification
{
    [super settingsLockChanged:aNotification];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORIpeV4SLTSettingsLock];
    BOOL locked = [gSecurity isLocked:ORIpeV4SLTSettingsLock];
	BOOL isRunning = [gOrcaGlobals runInProgress];
	
	
	[triggerEnableMatrix setEnabled:!lockedOrRunningMaintenance]; 
    [inhibitEnableMatrix setEnabled:!lockedOrRunningMaintenance];
	[hwVersionButton setEnabled:!isRunning];
	[deadTimeButton setEnabled:!isRunning];
	[vetoTimeButton setEnabled:!isRunning];
	[runTimeButton setEnabled:!isRunning];
	[secondsCounterButton setEnabled:!isRunning];
	[subsecondsCounterButton setEnabled:!isRunning];
	[loadSecondsButton setEnabled:!isRunning];

	[calibrateButton setEnabled:!lockedOrRunningMaintenance];
	[loadPatternFileButton setEnabled:!lockedOrRunningMaintenance];
	[definePatternFileButton setEnabled:!lockedOrRunningMaintenance];
	[setSWInhibitButton setEnabled:!lockedOrRunningMaintenance];
	[relSWInhibitButton setEnabled:!lockedOrRunningMaintenance];
	[resetPageManagerButton setEnabled:!lockedOrRunningMaintenance];
	[forceTriggerButton setEnabled:!lockedOrRunningMaintenance];
	[initBoardButton setEnabled:!lockedOrRunningMaintenance];
	[initBoard1Button setEnabled:!lockedOrRunningMaintenance];
	[readBoardButton setEnabled:!lockedOrRunningMaintenance];
	[secStrobeSrcPU setEnabled:!lockedOrRunningMaintenance]; 
	[startSrcPU setEnabled:!lockedOrRunningMaintenance]; 
	
	[setSWInhibitButton setEnabled:!lockedOrRunningMaintenance];
	[relSWInhibitButton setEnabled:!lockedOrRunningMaintenance];
	[forceTrigger1Button setEnabled:!lockedOrRunningMaintenance];

	[resetHWButton setEnabled:!isRunning];
	[usePBusSimButton setEnabled:!isRunning];
	
	[pulserAmpField setEnabled:!locked];
		
	[pageSizeField setEnabled:!lockedOrRunningMaintenance];
	[pageSizeStepper setEnabled:!lockedOrRunningMaintenance];
	
	
	[nextPageDelaySlider setEnabled:!lockedOrRunningMaintenance];
	
	[self enableRegControls];
}

- (void) enableRegControls
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORIpeV4SLTSettingsLock];
	short index = [model selectedRegIndex];
	BOOL readAllowed = !lockedOrRunningMaintenance && ([model getAccessType:index] & kIpeRegReadable)>0;
	BOOL writeAllowed = !lockedOrRunningMaintenance && ([model getAccessType:index] & kIpeRegWriteable)>0;
	
	[regWriteButton setEnabled:writeAllowed];
	[regReadButton setEnabled:readAllowed];
	
	[regWriteValueStepper setEnabled:writeAllowed];
	[regWriteValueTextField setEnabled:writeAllowed];
}

- (void) endAllEditing:(NSNotification*)aNotification
{
}

- (void) hwVersionChanged:(NSNotification*) aNote
{
	NSString* s = [NSString stringWithFormat:@"%d.%d.%d",[model projectVersion],[model documentVersion],[model implementation]];
	[hwVersionField setStringValue:s];
}

- (void) writeValueChanged:(NSNotification*) aNote
{
	[self updateStepper:regWriteValueStepper setting:[model writeValue]];
	[regWriteValueTextField setIntValue:[model writeValue]];
}

- (void) usePBusSimChanged:(NSNotification*) aNote
{
	//	[usePBusSimButton setState:[model pBusSim]];
}

- (void) displayEventLoopChanged:(NSNotification*) aNote
{
	[displayEventLoopButton setState:[model displayEventLoop]];
}

- (void) displayTriggerChanged:(NSNotification*) aNote
{
	[displayTriggerButton setState:[model displayTrigger]];
}


- (void) selectedRegIndexChanged:(NSNotification*) aNote
{
	short index = [model selectedRegIndex];
	[self updatePopUpButton:registerPopUp	 setting:index];
	
	[self enableRegControls];
}


- (void) controlRegChanged:(NSNotification*)aNote
{
	unsigned long value = [model controlReg];
	unsigned long aMask = (value & kCtrlTrgEnMask)>>kCtrlTrgEnShift;
	int i;
	for(i=0;i<6;i++)[[triggerEnableMatrix cellWithTag:i] setIntValue:aMask & (0x1<<i)];
	
	aMask = (value & kCtrlInhEnMask)>>kCtrlInhEnShift;
	for(i=0;i<4;i++)[[inhibitEnableMatrix cellWithTag:i] setIntValue:aMask & (0x1<<i)];
	
	aMask = (value & kCtrlTpEnMask)>>kCtrlTpEnEnShift;
	[testPatternEnableMatrix selectCellWithTag:aMask];
	
	[[miscCntrlBitsMatrix cellWithTag:0] setIntValue:value & kCtrlPPSMask];
	[[miscCntrlBitsMatrix cellWithTag:1] setIntValue:value & kCtrlShapeMask];
	[[miscCntrlBitsMatrix cellWithTag:2] setIntValue:value & kCtrlRunMask];
	[[miscCntrlBitsMatrix cellWithTag:3] setIntValue:value & kCtrlTstSltMask];
	[[miscCntrlBitsMatrix cellWithTag:4] setIntValue:value & kCtrlIntEnMask];
	[[miscCntrlBitsMatrix cellWithTag:5] setIntValue:value & kCtrlLedOffmask];	
}

- (void) populatePullDown
{
    short	i;
	
	// Clear all the popup items.
    [registerPopUp removeAllItems];
    
	// Populate the register popup
    for (i = 0; i < [model getNumberRegisters]; i++) {
        [registerPopUp insertItemWithTitle:[model getRegisterName:i] atIndex:i];
    }
}

- (void) pulserAmpChanged:(NSNotification*) aNote
{
	[pulserAmpField setFloatValue:[model pulserAmp]];
}

- (void) pulserDelayChanged:(NSNotification*) aNote
{
	[pulserDelayField setFloatValue:[model pulserDelay]];
}

#pragma mark ***Actions

//----------working actions ----------
- (IBAction) loadSecondsAction:(id)sender
{
	@try {
		[model loadSecondsReg];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception load SLT Seconds\n");
		NSRunAlertPanel([localException name], @"%@\nSLT%d Set Seconds failed", @"OK", nil, nil,
						localException,[model stationNumber]);
	}
	
}

- (IBAction) secondsSetAction:(id)sender
{
	[model setSecondsSet:[sender intValue]];	
}

- (IBAction) triggerEnableAction:(id)sender
{
	unsigned long aMask = 0;
	int i;
	for(i=0;i<6;i++){
		if([[triggerEnableMatrix cellWithTag:i] intValue]) aMask |= (1L<<i);
		else aMask &= ~(1L<<i);
	}
	unsigned long theRegValue = [model controlReg] & ~kCtrlTrgEnMask; 
	theRegValue |= (aMask<< kCtrlTrgEnShift);
	[model setControlReg:theRegValue];
}

- (IBAction) inhibitEnableAction:(id)sender;
{
	unsigned long aMask = 0;
	int i;
	for(i=0;i<4;i++){
		if([[inhibitEnableMatrix cellWithTag:i] intValue]) aMask |= (1L<<i);
		else aMask &= ~(1L<<i);
	}
	unsigned long theRegValue = [model controlReg] & ~kCtrlInhEnMask; 
	theRegValue |= (aMask<<kCtrlInhEnShift);
	[model setControlReg:theRegValue];
}

- (IBAction) testPatternEnableAction:(id)sender;
{
	unsigned long aMask       = [[testPatternEnableMatrix selectedCell] tag];
	unsigned long theRegValue = [model controlReg] & ~kCtrlTpEnMask; 
	theRegValue |= (aMask<<kCtrlTpEnEnShift);
	[model setControlReg:theRegValue];
}

- (IBAction) miscCntrlBitsAction:(id)sender;
{
	unsigned long theRegValue = [model controlReg] & ~(kCtrlPPSMask | kCtrlShapeMask | kCtrlRunMask | kCtrlTstSltMask | kCtrlIntEnMask | kCtrlLedOffmask); 
	if([[miscCntrlBitsMatrix cellWithTag:0] intValue])	theRegValue |= kCtrlPPSMask;
	if([[miscCntrlBitsMatrix cellWithTag:1] intValue])	theRegValue |= kCtrlShapeMask;
	if([[miscCntrlBitsMatrix cellWithTag:2] intValue])	theRegValue |= kCtrlRunMask;
	if([[miscCntrlBitsMatrix cellWithTag:3] intValue])	theRegValue |= kCtrlTstSltMask;
	if([[miscCntrlBitsMatrix cellWithTag:4] intValue])	theRegValue |= kCtrlIntEnMask;
	if([[miscCntrlBitsMatrix cellWithTag:5] intValue])	theRegValue |= kCtrlLedOffmask;

	[model setControlReg:theRegValue];
}

//----------------------------------



- (IBAction) dumpPageStatus:(id)sender
{
	if([[NSApp currentEvent] clickCount] >=2){
		//int pageIndex = [sender selectedRow]*32 + [sender selectedColumn];
		@try {
			//[model dumpTriggerRAM:pageIndex];
		}
		@catch(NSException* localException) {
			NSLog(@"Exception doing SLT dump trigger RAM page\n");
			NSRunAlertPanel([localException name], @"%@\nSLT%d dump trigger RAM failed", @"OK", nil, nil,
							localException,[model stationNumber]);
		}
	}
}

- (IBAction) pollNowAction:(id)sender
{
	[model readAllStatus];
}

- (IBAction) pollRateAction:(id)sender
{
    [model setPollingInterval:[[pollRatePopup selectedItem] tag]];
}

- (IBAction) interruptMaskAction:(id)sender
{
	unsigned long aMaskValue = 0;
	int i;
	for(i=0;i<9;i++){
		if([[interruptMaskMatrix cellWithTag:i] intValue]) aMaskValue |= (1L<<i);
		else aMaskValue &= ~(1L<<i);
	}
	[model setInterruptMask:aMaskValue];	
}

- (IBAction) nextPageDelayAction:(id)sender
{
	[model setNextPageDelay:100-[sender intValue]];	
}

- (IBAction) pageSizeAction:(id)sender
{
	[model setPageSize:[sender intValue]];	
}

- (IBAction) displayTriggerAction:(id)sender
{
	[model setDisplayTrigger:[sender intValue]];	
}

- (IBAction) usePBusSimAction:(id)sender
{
    NSLog(@"PbusSim action\n");
	//	[model setPBusSim:[sender intValue]];
}

- (IBAction) displayEventLoopAction:(id)sender
{
	[model setDisplayEventLoop:[sender intValue]];	
}


- (IBAction) initBoardAction:(id)sender
{
	@try {
		[self endEditing];
		[model initBoard];
		NSLog(@"SLT%d initialized\n",[model stationNumber]);
	}
	@catch(NSException* localException) {
		NSLog(@"Exception SLT init\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d InitBoard failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) readStatus:(id)sender
{
	[model readStatusReg];
	[model readPageManagerReg];
}

- (IBAction) reportAllAction:(id)sender
{
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	@try {
		[model printStatusReg];
		[model printControlReg];
		[model printPageManagerReg];
		NSLogFont(aFont,@"--------------------------------------\n");
		NSLogFont(aFont,@"Dead Time  : %lld\n",[model readDeadTime]);
		NSLogFont(aFont,@"Veto Time  : %lld\n",[model readVetoTime]);
		NSLogFont(aFont,@"Run Time   : %lld\n",[model readRunTime]);
		NSLogFont(aFont,@"Seconds    : %d\n",  [model readSecondsCounter]);
		unsigned long value = [model readSubSecondsCounter];
		unsigned long v1 = value & 0x3FF;
		unsigned long v2 = (value >>10) & 0x3FF;
		NSLogFont(aFont,@"sub Seconds: %d, %d\n",v1,v2);
		//[model printInterruptMask];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading SLT status\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORIpeV4SLTSettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) selectRegisterAction:(id) aSender
{
 NSLog(@"This is: SLTv4: selectRegisterAction\n");
    // Make sure that value has changed.
    if ([aSender indexOfSelectedItem] != [model selectedRegIndex]){
	    [[model undoManager] setActionName:@"Select Register"]; // Set undo name
	    [model setSelectedRegIndex:[aSender indexOfSelectedItem]]; // set new value
		[self settingsLockChanged:nil];
    }
}

- (IBAction) writeValueAction:(id) aSender
{
	[self endEditing];
    // Make sure that value has changed.
    if ([aSender intValue] != [model writeValue]){
		[[model undoManager] setActionName:@"Set Write Value"]; // Set undo name.
		[model setWriteValue:[aSender intValue]]; // Set new value
    }
}

- (IBAction) readRegAction: (id) sender
{
	int index = [registerPopUp indexOfSelectedItem];
	@try {
		unsigned long value = [model readReg:index];
		NSLog(@"SLT reg: %@ value: 0x%x\n",[model getRegisterName:index],value);
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading SLT reg: %@\n",[model getRegisterName:index]);
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}
- (IBAction) writeRegAction: (id) sender
{
	[self endEditing];
	int index = [registerPopUp indexOfSelectedItem];
	@try {
		[model writeReg:index value:[model writeValue]];
		NSLog(@"wrote 0x%x to SLT reg: %@ \n",[model writeValue],[model getRegisterName:index]);
	}
	@catch(NSException* localException) {
		NSLog(@"Exception writing SLT reg: %@\n",[model getRegisterName:index]);
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) hwVersionAction: (id) sender
{
	@try {
		[model readHwVersion];
		NSLog(@"%d Project:%d Doc:%d Implementation:%d\n",[model fullID], [model projectVersion], [model documentVersion], [model implementation]);

	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading SLT HW Model Version\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) deadTimeAction: (id) sender
{
	@try {
		NSLog(@"%@ Dead Time: %lld\n",[model fullID],[model readDeadTime]);
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading SLT Dead Time\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) vetoTimeAction: (id) sender
{
	@try {
		NSLog(@"%@ Veto Time: %lld\n",[model fullID],[model readVetoTime]);
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading SLT Veto Time\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) runTimeAction: (id) sender
{
	@try {
		NSLog(@"%@ Run Time: %lld\n",[model fullID],[model readRunTime]);
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading SLT Run Time\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) secondsAction: (id) sender
{
	@try {
		NSLog(@"%@ Seconds: %d\n",[model fullID],[model readSecondsCounter]);
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading SLT Seconds Counter\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) subSecondsAction: (id) sender
{
	@try {
		unsigned long value = [model readSubSecondsCounter];
		unsigned long v1 = value & 0x3FF;
		unsigned long v2 = (value >>10) & 0x3FF;
		NSLog(@"%@ Sub Seconds: %d, %d\n",[model fullID],v1,v2);
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading SLT SubSeconds Counter\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}


- (IBAction) resetHWAction: (id) pSender
{
	@try {
		[model hw_config];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading SLT HW Reset\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) pulserAmpAction: (id) sender
{
	[model setPulserAmp:[sender floatValue]];
}

- (IBAction) pulserDelayAction: (id) sender
{
	[model setPulserDelay:[sender floatValue]];
}

- (IBAction) loadPulserAction: (id) sender
{
	@try {
		//[model loadPulserValues];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception loading SLT pulser values\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d load pulser failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) resetPageManagerAction:(id)sender
{
	@try {
		[model writePageManagerReset];
		NSLog(@"SLT: Manual Reset Page Manager\n");

	}
	@catch(NSException* localException) {
		NSLog(@"Exception doing SLT release pages\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d release pages failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) writeSetInhibitAction:(id)sender
{
	@try { 
		[model writeSetInhibit]; 
		NSLog(@"SLT: Manual Set Inhibit\n");
	}
	@catch(NSException* localException) {
		NSLog(@"Exception doing SLT Set SW Inhibit pages\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d set SW inhibiit failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) writeClrInhibit:(id)sender
{
	@try { 
		[model writeClrInhibit]; 
		NSLog(@"SLT: Manual Clr Inhibit\n");
	}
	@catch(NSException* localException) {
		NSLog(@"Exception doing SLT Release SW Inhibit pages\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d release SW inhibiit failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) writeSWTrigAction:(id)sender
{
	@try { 
		[model writeSwTrigger]; 
		NSLog(@"SLT: Manual SW Trigger\n");
	}
	@catch(NSException* localException) {
		NSLog(@"Exception doing SLT Software trigger\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d software trigger failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}


- (IBAction) definePatternFileAction:(id)sender
{
    NSString* startDir = NSHomeDirectory(); //default to home
    if([model patternFilePath]){
        startDir = [[model patternFilePath] stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Load Pattern File"];
    [openPanel beginSheetForDirectory:startDir
                                 file:nil
                                types:nil
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(loadPatternPanelDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
	
}

- (IBAction) loadPatternFile:(id)sender
{
	//[model loadPatternFile];
}

- (IBAction) calibrateAction:(id)sender
{
    NSBeginAlertSheet(@"Threshold Calibration",
                      @"Cancel",
                      @"Yes/Do Calibrate",
                      nil,[self window],
                      self,
                      @selector(calibrationSheetDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"Really run threshold calibration for ALL FLTs?\n This will change ALL thresholds on ALL cards.");
}


@end

@implementation ORIpeV4SLTController (private)
-(void)loadPatternPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        NSString* fileName = [[sheet filenames] objectAtIndex:0];
        [model setPatternFilePath:fileName];
    }
}

- (void) calibrationSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{
    if(returnCode == NSAlertAlternateReturn){
		@try {
			[model autoCalibrate];
		}
		@catch(NSException* localException) {
		}
    }    
}

@end


