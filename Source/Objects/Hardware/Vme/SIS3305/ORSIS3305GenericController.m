//-------------------------------------------------------------------------
//  ORSIS3302Controller.h
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

#pragma mark ***Imported Files
#import <Cocoa/Cocoa.h>
#import "ORSIS3305GenericController.h"
#import "ORRateGroup.h"
#import "ORRate.h"
#import "ORTimeRate.h"
#import "ORRate.h"
#import "OHexFormatter.h"
#import "ORTimeLinePlot.h"
#import "ORPlotView.h"
#import "ORTimeAxis.h"
#import "ORCompositePlotView.h"
#import "ORValueBarGroupView.h"

@implementation ORSIS3305GenericController

-(id)init
{
    self = [super initWithWindowNibName:@"SIS3305Generic"];
    
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) awakeFromNib
{
	
    settingSize     = NSMakeSize(850,520);
    rateSize		= NSMakeSize(790,300);
    
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
	
	
    NSString* key = [NSString stringWithFormat: @"orca.SIS3305%d.selectedtab",[model slot]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
			
	OHexFormatter *numberFormatter = [[[OHexFormatter alloc] init] autorelease];
	
	NSNumberFormatter *rateFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	[rateFormatter setFormat:@"##0.0;0;-##0.0"];
	
	int i;
	for(i=0;i<8;i++){
		NSCell* theCell = [thresholdMatrix cellAtRow:i column:0];
		[theCell setFormatter:numberFormatter];
	}
	for(i=0;i<8;i++){
		NSCell* theCell = [rateTextFields cellAtRow:i column:0];
		[theCell setFormatter:rateFormatter];
	}
		
	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
	[timeRatePlot addPlot: aPlot];
	[(ORTimeAxis*)[timeRatePlot xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
	[aPlot release];

	[rate0 setNumber:8 height:10 spacing:5];

	
	[super awakeFromNib];
	
}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
	
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORVmeCardSlotChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(baseAddressChanged:)
                         name : ORVmeIOCardBaseAddressChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORSIS3305GenericSettingsLockChanged
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(rateGroupChanged:)
                         name : ORSIS3305GenericRateGroupChanged
                       object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(totalRateChanged:)
						 name : ORRateGroupTotalRateChangedNotification
					   object : nil];
	
    //a fake action for the scale objects
    [notifyCenter addObserver : self
                     selector : @selector(scaleAction:)
                         name : ORAxisRangeChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(miscAttributesChanged:)
						 name : ORMiscAttributesChanged
					   object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(updateTimePlot:)
                         name : ORRateAverageChangedNotification
                       object : [[model waveFormRateGroup]timeRate]];
    
    [notifyCenter addObserver : self
                     selector : @selector(integrationChanged:)
                         name : ORRateGroupIntegrationChangedNotification
                       object : nil];

	
    [notifyCenter addObserver : self
                     selector : @selector(gtChanged:)
                         name : ORSIS3305GenericGtChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(trapFilterTriggerChanged:)
                         name : ORSIS3305GenericTrapFilterTriggerChanged
                       object : model];	
    
    [notifyCenter addObserver : self
                     selector : @selector(thresholdChanged:)
                         name : ORSIS3305GenericThresholdChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(clockSourceChanged:)
                         name : ORSIS3305GenericClockSourceChanged
						object: model];
        
	
	[notifyCenter addObserver : self
                     selector : @selector(pulseLengthChanged:)
                         name : ORSIS3305GenericPulseLengthChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(sumGChanged:)
                         name : ORSIS3305GenericSumGChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(peakingTimeChanged:)
                         name : ORSIS3305GenericPeakingTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(dacOffsetChanged:)
                         name : ORSIS3305GenericDacOffsetChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(sampleLengthChanged:)
                         name : ORSIS3305GenericSampleLengthChanged
						object: model];


    [notifyCenter addObserver : self
                     selector : @selector(preTriggerDelayChanged:)
                         name : ORSIS3305GenericPreTriggerDelayChanged
						object: model];

	
	[self registerRates];


    [notifyCenter addObserver : self
                     selector : @selector(firmwareVersionChanged:)
                         name : ORSIS3305GenericFirmwareVersionChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(stopAtEventLengthChanged:)
                         name : ORSIS3305GenericStopAtEventChanged
						object: model];    
    
    [notifyCenter addObserver : self
                     selector : @selector(enablePageWrapChanged:)
                         name : ORSIS3305GenericEnablePageWrapChanged
						object: model];    
    
    [notifyCenter addObserver : self
                     selector : @selector(pageWrapSizeChanged:)
                         name : ORSIS3305GenericPageWrapSizeChanged
						object: model];    
    
    [notifyCenter addObserver : self
                     selector : @selector(testDataEnableChanged:)
                         name : ORSIS3305GenericTestDataEnableChanged
						object: model];    

    [notifyCenter addObserver : self
                     selector : @selector(testDataTypeChanged:)
                         name : ORSIS3305GenericTestDataTypeChanged
						object: model];    
    
    [notifyCenter addObserver : self
                     selector : @selector(averagingChanged:)
                         name : ORSIS3305GenericAveragingChanged
						object: model];    
    
    // Trigger/Lemo configuration
    
    [notifyCenter addObserver : self
                     selector : @selector(startDelayChanged:)
                         name : ORSIS3305GenericStartDelayChanged
						object: model];    

    [notifyCenter addObserver : self
                     selector : @selector(stopDelayChanged:)
                         name : ORSIS3305GenericStopDelayChanged
						object: model];    
    
    [notifyCenter addObserver : self
                     selector : @selector(maxEventsChanged:)
                         name : ORSIS3305GenericMaxEventsChanged
						object: model];    
    
    [notifyCenter addObserver : self
                     selector : @selector(lemoTimestampClearChanged:)
                         name : ORSIS3305GenericLemoTimestampChanged
						object: model];    

    [notifyCenter addObserver : self
                     selector : @selector(lemoStartStopChanged:)
                         name : ORSIS3305GenericLemoStartStopChanged
						object: model];        

    
    [notifyCenter addObserver : self
                     selector : @selector(internalTrigStartChanged:)
                         name : ORSIS3305GenericInternalTrigStartChanged
						object: model];    

    [notifyCenter addObserver : self
                     selector : @selector(internalTrigStopChanged:)
                         name : ORSIS3305GenericInternalTrigStopChanged
						object: model];        
    
    [notifyCenter addObserver : self
                     selector : @selector(multiEventModeChanged:)
                         name : ORSIS3305GenericMultiEventModeChanged
						object: model];        
    
    [notifyCenter addObserver : self
                     selector : @selector(autostartModeChanged:)
                         name : ORSIS3305GenericAutostartModeChanged
						object: model];        
    


}

- (void) registerRates
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter removeObserver:self name:ORRateChangedNotification object:nil];
    
    NSEnumerator* e = [[[model waveFormRateGroup] rates] objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
		
        [notifyCenter removeObserver:self name:ORRateChangedNotification object:obj];
		
        [notifyCenter addObserver : self
                         selector : @selector(waveFormRateChanged:)
                             name : ORRateChangedNotification
                           object : obj];
    }
}


- (void) updateWindow
{
    [super updateWindow];
    [self baseAddressChanged:nil];
    [self slotChanged:nil];
    [self settingsLockChanged:nil];
	[self gtChanged:nil];
	[self trapFilterTriggerChanged:nil];    
	[self thresholdChanged:nil];
	[self dacOffsetChanged:nil];
	[self sumGChanged:nil];
	[self peakingTimeChanged:nil];
	[self pulseLengthChanged:nil];
	[self preTriggerDelayChanged:nil];
	
    [self rateGroupChanged:nil];
    [self integrationChanged:nil];
    [self miscAttributesChanged:nil];
    [self totalRateChanged:nil];
    [self updateTimePlot:nil];
    [self waveFormRateChanged:nil];
	
    // Buffer
    [self sampleLengthChanged:nil];
    [self averagingChanged:nil];
    [self stopAtEventLengthChanged:nil];
    [self enablePageWrapChanged:nil];
    [self pageWrapSizeChanged:nil];
    [self testDataEnableChanged:nil];
    [self testDataTypeChanged:nil];

    // Trigger/Lemo configuration
    [self startDelayChanged:nil];
    [self stopDelayChanged:nil];
    [self maxEventsChanged:nil];
    [self lemoTimestampClearChanged:nil];
    [self lemoStartStopChanged:nil];
    [self internalTrigStartChanged:nil];
    [self internalTrigStopChanged:nil];
    [self multiEventModeChanged:nil];
    [self autostartModeChanged:nil];


	
	[self firmwareVersionChanged:nil];
	[self clockSourceChanged:nil];
}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Interface Management

- (void) firmwareVersionChanged:(NSNotification*)aNote
{
	[firmwareVersionTextField setFloatValue: [model firmwareVersion]];
	[self settingsLockChanged:nil];
}

- (void) clockSourceChanged:(NSNotification*)aNote
{
	[clockSourcePU selectItemAtIndex: [model clockSource]];
}

- (void) gtChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3305Channels;i++){
		[[gtMatrix cellWithTag:i] setState:[model gt:i]];
	}
}
- (void) trapFilterTriggerChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3305Channels;i++){
		[[trapezoidalTriggerMatrix cellWithTag:i] setState:[model useTrapTrigger:i]];
	}
}
- (void) thresholdChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3305Channels;i++){
		//float volts = (0.0003*[model threshold:i])-5.0;
		[[thresholdMatrix cellWithTag:i] setIntValue:[model threshold:i]];
	}
}

- (void) sampleLengthChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3305Channels/2;i++){
		[[sampleLengthMatrix cellWithTag:i] setIntValue:[model sampleLength:i]];
	}
}

- (void) preTriggerDelayChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3305Channels/2;i++){
		[[preTriggerDelayMatrix cellWithTag:i] setIntValue:[model preTriggerDelay:i]];
	}
}

- (void) dacOffsetChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3305Channels;i++){
		[[dacOffsetMatrix cellWithTag:i] setIntValue:[model dacOffset:i]];
	}
}

- (void) pulseLengthChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3305Channels;i++){
		[[pulseLengthMatrix cellWithTag:i] setIntValue:[model pulseLength:i]];
	}
}

- (void) sumGChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3305Channels;i++){
		[[sumGMatrix cellWithTag:i] setIntValue:[model sumG:i]];
	}
}

- (void) peakingTimeChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3305Channels;i++){
		[[peakingTimeMatrix cellWithTag:i] setIntValue:[model peakingTime:i]];
	}
}

- (void) waveFormRateChanged:(NSNotification*)aNote
{
    ORRate* theRateObj = [aNote object];		
    [[rateTextFields cellWithTag:[theRateObj tag]] setFloatValue: [theRateObj rate]];
    [rate0 setNeedsDisplay:YES];
}

- (void) totalRateChanged:(NSNotification*)aNotification
{
	ORRateGroup* theRateObj = [aNotification object];
	if(aNotification == nil || [model waveFormRateGroup] == theRateObj){
		
		[totalRateText setFloatValue: [theRateObj totalRate]];
		[totalRate setNeedsDisplay:YES];
	}
}

- (void) rateGroupChanged:(NSNotification*)aNote
{
    [self registerRates];
}

- (void) averagingChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3305Groups;i++){
		[[averagingMatrix cellAtRow:i column:0] selectItemAtIndex:[model averagingType:i]];
	}
}
- (void) stopAtEventLengthChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3305Groups;i++){
		[[stopAtEventLengthMatrix cellWithTag:i] setState:[model stopEventAtLength:i]];
	}
}
- (void) enablePageWrapChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3305Groups;i++){
		[[enablePageWrapMatrix cellWithTag:i] setState:[model pageWrap:i]];
	}
}
- (void) pageWrapSizeChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3305Groups;i++){
		[[pageWrapSizeMatrix cellAtRow:i column:0] selectItemAtIndex:[model pageWrapSize:i]];
	}
}
- (void) testDataEnableChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3305Groups;i++){
		[[testDataEnableMatrix cellWithTag:i] setState:[model enableTestData:i]];
	}
}
- (void) testDataTypeChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3305Groups;i++){
		[[testDataTypeMatrix cellAtRow:i column:0] selectItemAtIndex:[model testDataType:i]];
	}
}

// Trigger/Lemo configuration
- (void) startDelayChanged:(NSNotification*)aNote
{
    [startDelay setIntValue:[model startDelay]];
}
- (void) stopDelayChanged:(NSNotification*)aNote
{
    [stopDelay setIntValue:[model stopDelay]];
}
- (void) maxEventsChanged:(NSNotification*)aNote
{
    [maxEvents setIntValue:[model maxEvents]];
}
- (void) lemoTimestampClearChanged:(NSNotification*)aNote
{
    [lemoTimestampClearButton setState:[model lemoTimestampEnabled]];
}
- (void) lemoStartStopChanged:(NSNotification*)aNote
{
    [lemoStartStopButton setState:[model lemoStartStopEnabled]];
}
- (void) internalTrigStartChanged:(NSNotification*)aNote
{
    [internalTrigStartButton setState:[model internalTrigStartEnabled]];
}     

- (void) internalTrigStopChanged:(NSNotification*)aNote
{
    [internalTrigStopButton setState:[model internalTrigStopEnabled]];
}     
     
- (void) multiEventModeChanged:(NSNotification*)aNote
{
    [multiEventModeButton setState:[model multiEventModeEnabled]];
}
- (void) autostartModeChanged:(NSNotification*)aNote
{
    [autostartModeButton setState:[model autostartModeEnabled]];
}     

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORSIS3305GenericSettingsLockChanged to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORSIS3305GenericSettingsLockChanged];
    BOOL locked = [gSecurity isLocked:ORSIS3305GenericSettingsLockChanged];
	
	[settingLockButton			setState: locked];
	
    [addressText				setEnabled:!locked && !runInProgress];
    [initButton					setEnabled:!lockedOrRunningMaintenance];
	[briefReportButton			setEnabled:!lockedOrRunningMaintenance];
	[regDumpButton				setEnabled:!lockedOrRunningMaintenance];
	[probeButton				setEnabled:!lockedOrRunningMaintenance];
	
	[preTriggerDelayMatrix			setEnabled:!lockedOrRunningMaintenance];


	[clockSourcePU					setEnabled:!lockedOrRunningMaintenance];

	[gtMatrix						setEnabled:!lockedOrRunningMaintenance];
	[trapezoidalTriggerMatrix       setEnabled:!lockedOrRunningMaintenance];        
	[thresholdMatrix				setEnabled:!lockedOrRunningMaintenance];
	[dacOffsetMatrix				setEnabled:!lockedOrRunningMaintenance];
	[pulseLengthMatrix				setEnabled:!lockedOrRunningMaintenance];
	[sumGMatrix						setEnabled:!lockedOrRunningMaintenance];
	[peakingTimeMatrix				setEnabled:!lockedOrRunningMaintenance];
	[averagingMatrix				setEnabled:!lockedOrRunningMaintenance];	
	[pageWrapSizeMatrix				setEnabled:!lockedOrRunningMaintenance];
	[enablePageWrapMatrix			setEnabled:!lockedOrRunningMaintenance];
	[testDataTypeMatrix				setEnabled:!lockedOrRunningMaintenance];
	[testDataEnableMatrix			setEnabled:!lockedOrRunningMaintenance];
	[stopAtEventLengthMatrix		setEnabled:!lockedOrRunningMaintenance];
    
	[lemoTimestampClearButton		setEnabled:!lockedOrRunningMaintenance];
	[lemoStartStopButton            setEnabled:!lockedOrRunningMaintenance];
	[internalTrigStopButton         setEnabled:!lockedOrRunningMaintenance];    
	[internalTrigStartButton        setEnabled:!lockedOrRunningMaintenance];    
	[multiEventModeButton           setEnabled:!lockedOrRunningMaintenance];    
	[autostartModeButton            setEnabled:!lockedOrRunningMaintenance];        
	[startDelay                     setEnabled:!lockedOrRunningMaintenance];    
	[stopDelay                      setEnabled:!lockedOrRunningMaintenance];        
	[maxEvents                      setEnabled:!lockedOrRunningMaintenance];        
    
	//can't be changed during a run or the card and probably the sbc will be hosed.
	[sampleLengthMatrix				setEnabled:!locked && !runInProgress];
	
	
	
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"SIS3302 Card (Slot %d)",[model slot]]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
    [slotField setIntValue: [model slot]];
    [[self window] setTitle:[NSString stringWithFormat:@"SIS3302 Card (Slot %d)",[model slot]]];
}

- (void) baseAddressChanged:(NSNotification*)aNote
{
    [addressText setIntValue: [model baseAddress]];
}

- (void) integrationChanged:(NSNotification*)aNotification
{
    ORRateGroup* theRateGroup = [aNotification object];
    if(aNotification == nil || [model waveFormRateGroup] == theRateGroup || [aNotification object] == model){
        double dValue = [[model waveFormRateGroup] integrationTime];
        [integrationStepper setDoubleValue:dValue];
        [integrationText setDoubleValue: dValue];
    }
}


- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [rate0 xAxis]){
		[model setMiscAttributes:[[rate0 xAxis]attributes] forKey:@"RateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [totalRate xAxis]){
		[model setMiscAttributes:[[totalRate xAxis]attributes] forKey:@"TotalRateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [timeRatePlot xAxis]){
		[model setMiscAttributes:[(ORAxis*)[timeRatePlot xAxis]attributes] forKey:@"TimeRateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [timeRatePlot yAxis]){
		[model setMiscAttributes:[(ORAxis*)[timeRatePlot yAxis]attributes] forKey:@"TimeRateYAttributes"];
	};
	
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{
	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"RateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"RateXAttributes"];
		if(attrib){
			[[rate0 xAxis] setAttributes:attrib];
			[rate0 setNeedsDisplay:YES];
			[[rate0 xAxis] setNeedsDisplay:YES];
			[rateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TotalRateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TotalRateXAttributes"];
		if(attrib){
			[[totalRate xAxis] setAttributes:attrib];
			[totalRate setNeedsDisplay:YES];
			[[totalRate xAxis] setNeedsDisplay:YES];
			[totalRateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TimeRateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TimeRateXAttributes"];
		if(attrib){
			[(ORAxis*)[timeRatePlot xAxis] setAttributes:attrib];
			[timeRatePlot setNeedsDisplay:YES];
			[[timeRatePlot xAxis] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TimeRateYAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TimeRateYAttributes"];
		if(attrib){
			[(ORAxis*)[timeRatePlot yAxis] setAttributes:attrib];
			[timeRatePlot setNeedsDisplay:YES];
			[[timeRatePlot yAxis] setNeedsDisplay:YES];
			[timeRateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
}

- (void) updateTimePlot:(NSNotification*)aNote
{
    if(!aNote || ([aNote object] == [[model waveFormRateGroup]timeRate])){
        [timeRatePlot setNeedsDisplay:YES];
    }
}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Actions


//hardware actions
- (IBAction) probeBoardAction:(id)sender;
{
	@try {
		[model readModuleID:YES];
	}
	@catch (NSException* localException) {
		NSLog(@"Probe of SIS 3300 board ID failed\n");
        NSRunAlertPanel([localException name], @"%@\nProbe Failed", @"OK", nil, nil,
                        localException);
	}
}

- (IBAction) clockSourceAction:(id)sender
{
	[model setClockSource:[sender indexOfSelectedItem]];	
}

- (IBAction) gtAction:(id)sender
{
	[model setGtBit:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) trapezoidTriggerAction:(id)sender
{
    [model setUseTrapTriggerMask:[[sender selectedCell] tag] withValue:[sender intValue]];
}
- (IBAction) thresholdAction:(id)sender
{
    if([sender intValue] != [model threshold:[[sender selectedCell] tag]]){
		[model setThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) preTriggerDelayAction:(id)sender
{
    if([sender intValue] != [model preTriggerDelay:[[sender selectedCell] tag]]){
		[model setPreTriggerDelay:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) dacOffsetAction:(id)sender
{
    if([sender intValue] != [model dacOffset:[[sender selectedCell] tag]]){
		[model setDacOffset:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) pulseLengthAction:(id)sender
{
    if([sender intValue] != [model pulseLength:[[sender selectedCell] tag]]){
		[model setPulseLength:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) sumGAction:(id)sender
{
    if([sender intValue] != [model sumG:[[sender selectedCell] tag]]){
		[model setSumG:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) peakingTimeAction:(id)sender
{
    if([sender intValue] != [model peakingTime:[[sender selectedCell] tag]]){
		[model setPeakingTime:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

// Buffer
- (IBAction) sampleLengthAction:(id)sender
{
    if([sender intValue] != [model sampleLength:[[sender selectedCell] tag]]){
		[model setSampleLength:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) averagingAction:(id)sender
{
    if([[sender selectedCell] indexOfSelectedItem] != [model averagingType:[sender selectedRow]]){
		[model setAveragingType:[sender selectedRow] withValue:[[sender selectedCell] indexOfSelectedItem]];
	}

}

- (IBAction) stopAtEventLengthAction:(id)sender
{
    [model setStopEventAtLength:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) enablePageWrapAction:(id)sender
{
    [model setPageWrap:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) pageWrapSizeAction:(id)sender
{
    if([[sender selectedCell] indexOfSelectedItem] != [model pageWrapSize:[sender selectedRow]]){
		[model setPageWrapSize:[sender selectedRow] withValue:[[sender selectedCell] indexOfSelectedItem]];
	}
}

- (IBAction) testDataEnableAction:(id)sender
{
    [model setEnableTestData:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) testDataTypeAction:(id)sender
{
    if([[sender selectedCell] indexOfSelectedItem] != [model testDataType:[sender selectedRow]]){
		[model setTestDataType:[sender selectedRow] withValue:[[sender selectedCell] indexOfSelectedItem]];
	}
}


// Trigger/Lemo configuration
- (IBAction) startDelayAction:(id)sender
{
    [model setStartDelay:[sender intValue]];
}
- (IBAction) stopDelayAction:(id)sender
{
    [model setStopDelay:[sender intValue]];
}
- (IBAction) maxEventsAction:(id)sender
{
    [model setMaxEvents:[sender intValue]];
}
- (IBAction) lemoTimestampClearAction:(id)sender
{
    [model setLemoTimestampEnabled:[sender intValue]];    
}
- (IBAction) lemoStartStopAction:(id)sender
{
    [model setLemoStartStopEnabled:[sender intValue]];    
}
- (IBAction) internalTrigStartAction:(id)sender
{
    [model setInternalTrigStartEnabled:[sender intValue]];    
}
- (IBAction) internalTrigStopAction:(id)sender
{
    [model setInternalTrigStopEnabled:[sender intValue]];    
}
- (IBAction) multiEventModeAction:(id)sender
{
    [model setMultiEventModeEnabled:[sender intValue]];    
}
- (IBAction) autostartModeAction:(id)sender
{
    [model setAutostartModeEnabled:[sender intValue]];    
}

- (IBAction) baseAddressAction:(id)sender
{
    if([sender intValue] != [model baseAddress]){
        [model setBaseAddress:[sender intValue]];
    }
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORSIS3305GenericSettingsLockChanged to:[sender intValue] forWindow:[self window]];
}

-(IBAction) initBoard:(id)sender
{
    @try {
        [self endEditing];
        [model initBoard];		//initialize and load hardward
        NSLog(@"Initialized SIS3302 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Reset and Init of SIS3302 FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nFailed SIS3302 Reset and Init", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) integrationAction:(id)sender
{
    [self endEditing];
    if([sender doubleValue] != [[model waveFormRateGroup]integrationTime]){
        [model setRateIntegrationTime:[sender doubleValue]];		
    }
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
		[self resizeWindowToSize:rateSize];
		[[self window] setContentView:tabView];
    }
	
    NSString* key = [NSString stringWithFormat: @"orca.ORSIS3302%d.selectedtab",[model slot]];
    int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
}

- (IBAction) briefReport:(id)sender
{
    @try {
		[self endEditing];
		[model initBoard];
		[model briefReport];
	}
	@catch(NSException* localException) {
        NSLog(@"SIS3302 Report FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nSIS3302 Report FAILED", @"OK", nil, nil,
                        localException);
    }

}

- (IBAction) regDump:(id)sender
{
	BOOL ok = NO;
    @try {
		[self endEditing];
		[model initBoard];
		ok = YES;
	}
	@catch(NSException* localException) {
        NSLog(@"SIS3302 Reg Dump FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nSIS3302 Reg Dump FAILED", @"OK", nil, nil,
                        localException);
    }
	if(ok)[model regDump];
}

- (IBAction)forceTriggerAction:(id)sender
{
    [model forceTrigger];
}

- (IBAction) resetAction:(id)sender
{
    [model reset];
}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Data Source

- (double) getBarValue:(int)tag
{
	
	return [[[[model waveFormRateGroup]rates] objectAtIndex:tag] rate];
}

- (int) numberPointsInPlot:(id)aPlotter
{
	return [[[model waveFormRateGroup]timeRate]count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
{
	int count = [[[model waveFormRateGroup]timeRate] count];
	int index = count-i-1;
	*yValue = [[[model waveFormRateGroup] timeRate]valueAtIndex:index];
	*xValue = [[[model waveFormRateGroup] timeRate]timeSampledAtIndex:index];
}

@end
