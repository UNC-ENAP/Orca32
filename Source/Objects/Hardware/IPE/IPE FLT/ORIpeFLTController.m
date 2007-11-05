//
//  ORIpeFLTController.m
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


#pragma mark ���Imported Files
#import "ORIpeFLTController.h"
#import "ORIpeFLTModel.h"
#import "ORIpeFLTDefs.h"
#import "ORFireWireInterface.h"
#import "ORPlotter1D.h"
#import "ORValueBar.h"
#import "ORAxis.h"
#import "ORTimeRate.h"

@implementation ORIpeFLTController

#pragma mark ���Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"IpeFLT"];
    
    return self;
}

#pragma mark ���Initialization
- (void) dealloc
{
	[rateFormatter release];
	[blankView release];
    [super dealloc];
}

- (void) awakeFromNib
{
    [super awakeFromNib];

    settingSize			= NSMakeSize(546,670);
    rateSize			= NSMakeSize(430,650);
    testSize			= NSMakeSize(400,400);

	rateFormatter = [[NSNumberFormatter alloc] init];
	[rateFormatter setFormat:@"##0.00"];
	[totalHitRateField setFormatter:rateFormatter];

    blankView = [[NSView alloc] init];
    
    NSString* key = [NSString stringWithFormat: @"orca.ORIpeFLT%d.selectedtab",[model stationNumber]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];

	ORValueBar* bar = rate0;
	do {
		[bar setBackgroundColor:[NSColor whiteColor]];
		[bar setBarColor:[NSColor greenColor]];
		bar = [bar chainedView];
	}while(bar!=nil);
	
	[totalRate setBackgroundColor:[NSColor whiteColor]];
	[totalRate setBarColor:[NSColor greenColor]];


    [self updateWindow];
}

#pragma mark ���Accessors

#pragma mark ���Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORIpeFLTSettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORIpeCardSlotChangedNotification
					   object : model];


    [notifyCenter addObserver : self
                     selector : @selector(modeChanged:)
                         name : ORIpeFLTModelModeChanged
                       object : model];
					   
    [notifyCenter addObserver : self
					 selector : @selector(thresholdChanged:)
						 name : ORIpeFLTModelThresholdChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(gainChanged:)
						 name : ORIpeFLTModelGainChanged
					   object : model];

   [notifyCenter addObserver : self
					 selector : @selector(triggerEnabledChanged:)
						 name : ORIpeFLTModelTriggerEnabledChanged
					   object : model];

   [notifyCenter addObserver : self
					 selector : @selector(hitRateEnabledChanged:)
						 name : ORIpeFLTModelHitRateEnabledChanged
					   object : model];

   [notifyCenter addObserver : self
					 selector : @selector(triggersEnabledArrayChanged:)
						 name : ORIpeFLTModelTriggersEnabledChanged
					   object : model];

   [notifyCenter addObserver : self
					 selector : @selector(hitRatesEnabledArrayChanged:)
						 name : ORIpeFLTModelHitRatesArrayChanged
					   object : model];


    [notifyCenter addObserver : self
					 selector : @selector(gainArrayChanged:)
						 name : ORIpeFLTModelGainsChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(thresholdArrayChanged:)
						 name : ORIpeFLTModelThresholdsChanged
					   object : model];
					   
    [notifyCenter addObserver : self
					 selector : @selector(hitRateLengthChanged:)
						 name : ORIpeFLTModelHitRateLengthChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(hitRateChanged:)
						 name : ORIpeFLTModelHitRateChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(scaleAction:)
						 name : ORAxisRangeChangedNotification
					   object : nil];

    [notifyCenter addObserver : self
					 selector : @selector(miscAttributesChanged:)
						 name : ORMiscAttributesChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(totalRateChanged:)
						 name : ORRateAverageChangedNotification
					   object : [model totalRate]];

    [notifyCenter addObserver : self
                     selector : @selector(testEnabledArrayChanged:)
                         name : ORIpeFLTModelTestEnabledArrayChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(testStatusArrayChanged:)
                         name : ORIpeFLTModelTestStatusArrayChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(updateWindow)
                         name : ORIpeFLTModelTestsRunningChanged
                       object : model];


    [notifyCenter addObserver : self
                     selector : @selector(testParamChanged:)
                         name : ORIpeFLTModelTestParamChanged
                       object : model];

    [notifyCenter addObserver : self
					 selector : @selector(readoutPagesChanged:)
						 name : ORIpeFLTModelReadoutPagesChanged
					   object : model];


    [notifyCenter addObserver : self
                     selector : @selector(interruptMaskChanged:)
                         name : ORIpeFLTModelInterruptMaskChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(ledOffChanged:)
                         name : ORIpeFLTModelLedOffChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(thresholdOffsetChanged:)
                         name : ORIpeFLTModelThresholdOffsetChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(coinTimeChanged:)
                         name : ORIpeFLTModelCoinTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(integrationTimeChanged:)
                         name : ORIpeFLTModelIntegrationTimeChanged
						object: model];

}

#pragma mark ���Interface Management

- (void) integrationTimeChanged:(NSNotification*)aNote
{
	[integrationTimeField setIntValue: [model integrationTime]];
}

- (void) coinTimeChanged:(NSNotification*)aNote
{
	[coinTimeField setIntValue: [model coinTime]];
}


- (void) thresholdOffsetChanged:(NSNotification*)aNote
{
	[thresholdOffsetField setIntValue: [model thresholdOffset]];
}

- (void) ledOffChanged:(NSNotification*)aNote
{
	[ledOffField setStringValue: ![model ledOff]?@"Led On":@""];
}

- (void) interruptMaskChanged:(NSNotification*)aNote
{
	[interruptMaskField setIntValue: [model interruptMask]];
}

- (void) updateWindow
{
    [super updateWindow];
    [self slotChanged:nil];
    [self settingsLockChanged:nil];
	[self modeChanged:nil];
	[self gainArrayChanged:nil];
	[self thresholdArrayChanged:nil];
	[self triggersEnabledArrayChanged:nil];
	[self hitRatesEnabledArrayChanged:nil];
	[self hitRateLengthChanged:nil];
	[self hitRateChanged:nil];
    [self updateTimePlot:nil];
    [self totalRateChanged:nil];
	[self scaleAction:nil];
    [self testEnabledArrayChanged:nil];
	[self testStatusArrayChanged:nil];
	[self testParamChanged:nil];
    [self miscAttributesChanged:nil];
	[self readoutPagesChanged:nil];	
	[self interruptMaskChanged:nil];
	[self ledOffChanged:nil];
	[self thresholdOffsetChanged:nil];
	[self integrationTimeChanged:nil];
	[self coinTimeChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORIpeFLTSettingsLock to:secure];
    [settingLockButton setEnabled:secure];	
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORIpeFLTSettingsLock];
	BOOL isRunning = [gOrcaGlobals runInProgress];
    BOOL locked = [gSecurity isLocked:ORIpeFLTSettingsLock];
	BOOL testsAreRunning = [model testsRunning];
	BOOL testingOrRunning = testsAreRunning | runInProgress;
    

    [testEnabledMatrix setEnabled:!locked && !testingOrRunning];
    [settingLockButton setState: locked];
	[integrationTimeField setEnabled:!lockedOrRunningMaintenance];
	[coinTimeField setEnabled:!lockedOrRunningMaintenance];
	[initBoardButton setEnabled:!lockedOrRunningMaintenance];
	[reportButton setEnabled:!lockedOrRunningMaintenance];
	[modeButton setEnabled:!lockedOrRunningMaintenance];
	[resetButton setEnabled:!lockedOrRunningMaintenance];
    [gainTextFields setEnabled:!lockedOrRunningMaintenance];
    [thresholdTextFields setEnabled:!lockedOrRunningMaintenance];
    [triggerEnabledCBs setEnabled:!lockedOrRunningMaintenance];
    [hitRateEnabledCBs setEnabled:!lockedOrRunningMaintenance];

	[versionButton setEnabled:!isRunning];
	[testButton setEnabled:!isRunning];
	[statusButton setEnabled:!isRunning];

    [hitRateLengthPU setEnabled:!lockedOrRunningMaintenance];
    [hitRateAllButton setEnabled:!lockedOrRunningMaintenance];
    [hitRateNoneButton setEnabled:!lockedOrRunningMaintenance];
	
	[readoutPagesField setEnabled:!lockedOrRunningMaintenance]; // ak, 2.7.07

	if(testsAreRunning){
		[testButton setEnabled: YES];
		[testButton setTitle: @"Stop"];
	}
    else {
		[testButton setEnabled: !runInProgress];	
		[testButton setTitle: @"Test"];
	}
}

- (void) testParamChanged:(NSNotification*)aNotification
{
	[[testParamsMatrix cellWithTag:0] setIntValue:[model startChan]];
	[[testParamsMatrix cellWithTag:1] setIntValue:[model endChan]];
	[[testParamsMatrix cellWithTag:2] setIntValue:[model page]];	
}


- (void) testEnabledArrayChanged:(NSNotification*)aNotification
{
	int i;
	for(i=0;i<kNumIpeFLTTests;i++){
		[[testEnabledMatrix cellWithTag:i] setIntValue:[model testEnabled:i]];
	}    
}

- (void) testStatusArrayChanged:(NSNotification*)aNotification
{
	int i;
	for(i=0;i<kNumIpeFLTTests;i++){
		[[testStatusMatrix cellWithTag:i] setStringValue:[model testStatus:i]];
	}
}


- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [rate0 xScale]){
		[model setMiscAttributes:[[rate0 xScale]attributes] forKey:@"RateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [totalRate xScale]){
		[model setMiscAttributes:[[totalRate xScale]attributes] forKey:@"TotalRateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [timeRatePlot xScale]){
		[model setMiscAttributes:[[timeRatePlot xScale]attributes] forKey:@"TimeRateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [timeRatePlot yScale]){
		[model setMiscAttributes:[[timeRatePlot yScale]attributes] forKey:@"TimeRateYAttributes"];
	};
	
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{
	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"RateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"RateXAttributes"];
		if(attrib){
			[[rate0 xScale] setAttributes:attrib];
			[rate0 setNeedsDisplay:YES];
			[[rate0 xScale] setNeedsDisplay:YES];
			[rateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TotalRateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TotalRateXAttributes"];
		if(attrib){
			[[totalRate xScale] setAttributes:attrib];
			[totalRate setNeedsDisplay:YES];
			[[totalRate xScale] setNeedsDisplay:YES];
			[totalRateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TimeRateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TimeRateXAttributes"];
		if(attrib){
			[[timeRatePlot xScale] setAttributes:attrib];
			[timeRatePlot setNeedsDisplay:YES];
			[[timeRatePlot xScale] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TimeRateYAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TimeRateYAttributes"];
		if(attrib){
			[[timeRatePlot yScale] setAttributes:attrib];
			[timeRatePlot setNeedsDisplay:YES];
			[[timeRatePlot yScale] setNeedsDisplay:YES];
			[timeRateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
}


- (void) updateTimePlot:(NSNotification*)aNote
{
	//if(!aNote || ([aNote object] == [[model adcRateGroup]timeRate])){
	//	[timeRatePlot setNeedsDisplay:YES];
	//}
}


- (void) gainChanged:(NSNotification*)aNotification
{
	int chan = [[[aNotification userInfo] objectForKey:ORIpeFLTChan] intValue];
	[[gainTextFields cellWithTag:chan] setIntValue: [model gain:chan]];
}

- (void) triggerEnabledChanged:(NSNotification*)aNotification
{
	int chan = [[[aNotification userInfo] objectForKey:ORIpeFLTChan] intValue];
	[[triggerEnabledCBs cellWithTag:chan] setState: [model triggerEnabled:chan]];
}

- (void) hitRateEnabledChanged:(NSNotification*)aNotification
{
	int chan = [[[aNotification userInfo] objectForKey:ORIpeFLTChan] intValue];
	[[hitRateEnabledCBs cellWithTag:chan] setState: [model hitRateEnabled:chan]];
}

- (void) thresholdChanged:(NSNotification*)aNotification
{
	int chan = [[[aNotification userInfo] objectForKey:ORIpeFLTChan] intValue];
	[[thresholdTextFields cellWithTag:chan] setIntValue: [model threshold:chan]];
}


- (void) slotChanged:(NSNotification*)aNotification
{
	// Set title of FLT configuration window, ak 15.6.07
	[[self window] setTitle:[NSString stringWithFormat:@"IPE-DAQ-V3 FLT Card (Slot %d)",[model stationNumber]]];
}

- (void) gainArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kNumFLTChannels;chan++){
		[[gainTextFields cellWithTag:chan] setIntValue: [model gain:chan]];

	}	
}

- (void) thresholdArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kNumFLTChannels;chan++){
		[[thresholdTextFields cellWithTag:chan] setIntValue: [model threshold:chan]];
	}
}

- (void) triggersEnabledArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kNumFLTChannels;chan++){
		[[triggerEnabledCBs cellWithTag:chan] setIntValue: [model triggerEnabled:chan]];

	}
}

- (void) hitRatesEnabledArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kNumFLTChannels;chan++){
		[[hitRateEnabledCBs cellWithTag:chan] setIntValue: [model hitRateEnabled:chan]];

	}
}

- (void) modeChanged:(NSNotification*)aNote
{
	[modeButton selectItemAtIndex:[model fltRunMode]];
	[self settingsLockChanged:nil];	
}

- (void) hitRateLengthChanged:(NSNotification*)aNote
{
	[hitRateLengthPU selectItemWithTag:[model hitRateLength]];
}

- (void) hitRateChanged:(NSNotification*)aNote
{
	int chan;
	for(chan=0;chan<kNumFLTChannels;chan++){
		id theCell = [rateTextFields cellWithTag:chan];
		if([model hitRateOverFlow:chan]){
			[theCell setFormatter: nil];
			[theCell setTextColor:[NSColor redColor]];
			[theCell setObjectValue: @"OverFlow"];
		}
		else {
			[theCell setFormatter: rateFormatter];
			[theCell setTextColor:[NSColor blackColor]];
			[theCell setFloatValue: [model hitRate:chan]];
		}
	}
	[rate0 setNeedsDisplay:YES];
	[totalHitRateField setFloatValue:[model hitRateTotal]];
	[totalRate setNeedsDisplay:YES];
}

- (void) totalRateChanged:(NSNotification*)aNote
{
	if(aNote==nil || [aNote object] == [model totalRate]){
		[timeRatePlot setNeedsDisplay:YES];
	}
}

- (void) readoutPagesChanged:(NSNotification*)aNote
{
	[readoutPagesField setIntValue:[model readoutPages]];
}


- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [[self window] setContentView:blankView];
    switch([tabView indexOfTabViewItem:tabViewItem]){
        case  0: [self resizeWindowToSize:settingSize];     break;
		case  1: [self resizeWindowToSize:rateSize];	    break;
		default: [self resizeWindowToSize:testSize];	    break;
    }
    [[self window] setContentView:totalView];
            
    NSString* key = [NSString stringWithFormat: @"orca.ORIpeFLT%d.selectedtab",[model stationNumber]];
    int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
    
}

#pragma mark ���Actions

- (IBAction) thresholdOffsetAction:(id)sender
{
	[model setThresholdOffset:[sender intValue]];	
}

- (IBAction) interruptMaskAction:(id)sender
{
	[model setInterruptMask:[sender intValue]];	
}


- (IBAction) coinTimeAction:(id)sender
{
	[model setCoinTime:[sender intValue]];
}

- (IBAction) integrationTimeAction:(id)sender
{
	[model setIntegrationTime:[sender intValue]];
}

- (IBAction) testEnabledAction:(id)sender
{
	NSMutableArray* anArray = [NSMutableArray array];
	int i;
	for(i=0;i<kNumIpeFLTTests;i++){
		if([[testEnabledMatrix cellWithTag:i] intValue])[anArray addObject:[NSNumber numberWithBool:YES]];
		else [anArray addObject:[NSNumber numberWithBool:NO]];
	}
	[model setTestEnabledArray:anArray];
}



- (IBAction) readThresholdsGains:(id)sender
{
	NS_DURING
		int i;
		NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
		NSLogFont(aFont,   @"FLT (station %d)\n",[model stationNumber]); // ak, 5.10.07
		NSLogFont(aFont,   @"chan | Gain | Threshold\n");
		NSLogFont(aFont,   @"-----------------------\n");
		for(i=0;i<kNumFLTChannels;i++){
			NSLogFont(aFont,@"%4d | %4d | %4d \n",i,[model readGain:i],[model readThreshold:i]);
			//NSLog(@"%d: %d\n",i,[model readGain:i]);
		}
		NSLogFont(aFont,   @"-----------------------\n");
	NS_HANDLER
		NSLog(@"Exception reading FLT gains and thresholds\n");
        NSRunAlertPanel([localException name], @"%@\nRead of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) writeThresholdsGains:(id)sender
{
	[self endEditing];
	NS_DURING
		[model loadThresholdsAndGains];
	NS_HANDLER
		NSLog(@"Exception writing FLT gains and thresholds\n");
        NSRunAlertPanel([localException name], @"%@\nWrite of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) gainAction:(id)sender
{
	if([sender intValue] != [model gain:[[sender selectedCell] tag]]){
		[[self undoManager] setActionName: @"Set Gain"];
		[model setGain:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) thresholdAction:(id)sender
{
	if([sender intValue] != [model threshold:[[sender selectedCell] tag]]){
		[[self undoManager] setActionName: @"Set Threshold"];
		[model setThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}


- (IBAction) triggerEnableAction:(id)sender
{
	[[self undoManager] setActionName: @"Set TriggerEnabled"];
	[model setTriggerEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) hitRateEnableAction:(id)sender
{
	[[self undoManager] setActionName: @"Set HitRate Enabled"];
	[model setHitRateEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}


- (IBAction) reportButtonAction:(id)sender
{
	[self endEditing];
	NS_DURING
		[model printStatusReg];
		[model printPeriphStatusReg];
		[model printPixelRegs];
		[self readThresholdsGains:sender];
		[model printStatistics];
	NS_HANDLER
		NSLog(@"Exception reading FLT (%d) status\n",[model stationNumber]);
        NSRunAlertPanel([localException name], @"%@\nRead of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) initBoardButtonAction:(id)sender
{
	[self endEditing];
	NS_DURING
		[model initBoard];
	NS_HANDLER
		NSLog(@"Exception intitBoard FLT (%d) status\n",[model stationNumber]);
        NSRunAlertPanel([localException name], @"%@\nWrite of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORIpeFLTSettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) modeAction: (id) sender
{
	[model setFltRunMode:[modeButton indexOfSelectedItem]];
}

- (IBAction) versionAction: (id) sender
{
	NS_DURING
		NSLog(@"FLT %d Revision: %d\n",[model stationNumber],[model readVersion]);
	NS_HANDLER
		NSLog(@"Exception reading FLT HW Model Version\n");
        NSRunAlertPanel([localException name], @"%@\nRead of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) testAction: (id) sender
{
	NS_DURING
		[model runTests];
	NS_HANDLER
		NSLog(@"Exception reading FLT HW Model Test\n");
        NSRunAlertPanel([localException name], @"%@\nFLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}


- (IBAction) resetAction: (id) sender
{
	NS_DURING
		[model reset];
	NS_HANDLER
		NSLog(@"Exception during FLT reset\n");
        NSRunAlertPanel([localException name], @"%@\nFLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) hitRateLengthAction: (id) sender
{
	if([sender indexOfSelectedItem] != [model hitRateLength]){
		[[self undoManager] setActionName: @"Set Hit Rate Length"]; 
		[model setHitRateLength:[[sender selectedItem] tag]];
	}
}

- (IBAction) hitRateAllAction: (id) sender
{
	[model enableAllHitRates:YES];
}

- (IBAction) hitRateNoneAction: (id) sender
{
	[model enableAllHitRates:NO];
}

- (IBAction) enableAllTriggersAction: (id) sender
{
	[model enableAllTriggers:YES];
}

- (IBAction) enableNoTriggersAction: (id) sender
{
	[model enableAllTriggers:NO];
}


- (IBAction) testParamAction: (id) sender
{
	[self endEditing];
	switch([[sender selectedCell] tag]){
		case 0: 	[model setStartChan:[sender intValue]]; break;
		case 1: 	[model setEndChan:[sender intValue]]; break;
		case 2: 	[model setPage:[sender intValue]]; break;
		default: break;
	}
}

- (IBAction) statusAction:(id)sender
{
	NS_DURING
		[model printStatusReg];
	NS_HANDLER
		NSLog(@"Exception during FLT read status\n");
        NSRunAlertPanel([localException name], @"%@\nRead of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) readoutPagesAction: (id) sender
{
	if([sender intValue] != [model readoutPages]){
		[[self undoManager] setActionName: @"Set Readout Pages"]; 
		[model setReadoutPages:[sender intValue]];
	}
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
                      nil,@"Really run threshold calibration? This will change ALL thresholds on this card.");
}


- (void) calibrationSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{
    if(returnCode == NSAlertAlternateReturn){
		[model autoCalibrate];
    }    
}

#pragma mark ���Plot DataSource
- (int)		numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
	return [[model  totalRate]count];
}
- (float)  	plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x 
{
	int count = [[model totalRate]count];
	return [[model totalRate] valueAtIndex:count-x-1];
}

- (unsigned long)  	secondsPerUnit:(id) aPlotter
{
	return [[model totalRate] sampleTime];
}
@end



