//-------------------------------------------------------------------------
//  ORSIS3316Controller.h
//  Orca
//
//  Created by Mark A. Howe on Wednesday 9/30/08.
//  Copyright (c) 2015 CENPA. University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolinaponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ***Imported Files
#import <Cocoa/Cocoa.h>
#import "ORSIS3316Controller.h"
#import "ORRateGroup.h"
#import "ORRate.h"
#import "ORValueBarGroupView.h"
#import "ORPlot.h"
#import "ORPlotView.h"
#import "ORTimeLinePlot.h"
#import "ORTimeAxis.h"
#import "ORTimeRate.h"
#import "ORRate.h"
#import "OHexFormatter.h"
#import "ORCompositePlotView.h"

@implementation ORSIS3316Controller

- (id)init
{
    self = [super initWithWindowNibName:@"SIS3316"];
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) awakeFromNib
{
    settingSize     = NSMakeSize(865,860);
    rateSize		= NSMakeSize(790,300);
    
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
	
	
    NSString* key = [NSString stringWithFormat: @"orca.SIS3316%d.selectedtab",[model slot]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
			
	OHexFormatter *numberFormatter = [[[OHexFormatter alloc] init] autorelease];
	
	NSNumberFormatter *rateFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	[rateFormatter setFormat:@"##0.0;0;-##0.0"];
	
	int i;
	for(i=0;i<kNumSIS3316Channels;i++){
        [[thresholdMatrix           cellAtRow:i column:0] setFormatter:numberFormatter];
        [[heTrigThresholdMatrix     cellAtRow:i column:0] setFormatter:numberFormatter];
		[[rateTextFields            cellAtRow:i column:0] setFormatter:rateFormatter];
        
        [[enabledMatrix             cellAtRow:i column:0] setTag:i];
        [[histogramsEnabledMatrix   cellAtRow:i column:0] setTag:i];
        [[pileupEnabledMatrix       cellAtRow:i column:0] setTag:i];
        [[clrHistogramWithTSMatrix  cellAtRow:i column:0] setTag:i];
        [[writeHitsIntoEventMemoryMatrix   cellAtRow:i column:0] setTag:i];
        [[thresholdMatrix           cellAtRow:i column:0] setTag:i];
        [[heSuppressTrigModeMatrix  cellAtRow:i column:0] setTag:i];
        [[cfdControlMatrix          cellAtRow:i column:0] setTag:i];
        [[heTrigThresholdMatrix     cellAtRow:i column:0] setTag:i];
        [[intTrigOutPulseBitsMatrix cellAtRow:i column:0] setTag:i];
        [[energyDividerMatrix       cellAtRow:i column:0] setTag:i];
        [[energySubtractorMatrix    cellAtRow:i column:0] setTag:i];
        [[tauFactorMatrix           cellAtRow:i column:0] setTag:i];
        [[gapTimeMatrix             cellAtRow:i column:0] setTag:i];
        [[peakingTimeMatrix         cellAtRow:i column:0] setTag:i];
	}  
    for(i=0;i<kNumSIS3316Groups;i++){
        [[activeTrigGateWindowLenMatrix cellAtRow:i column:0] setFormatter:numberFormatter];
        [[activeTrigGateWindowLenMatrix cellAtRow:i column:0] setTag:i];
        [[preTriggerDelayMatrix cellAtRow:i column:0] setFormatter:numberFormatter];
        [[preTriggerDelayMatrix cellAtRow:i column:0] setTag:i];
        [[accGate1LenMatrix     cellAtRow:i column:0] setTag:i];
        [[accGate1StartMatrix   cellAtRow:i column:0] setTag:i];
        [[accGate2LenMatrix     cellAtRow:i column:0] setTag:i];
        [[accGate2StartMatrix   cellAtRow:i column:0] setTag:i];
        [[accGate3LenMatrix     cellAtRow:i column:0] setTag:i];
        [[accGate3StartMatrix   cellAtRow:i column:0] setTag:i];
        [[accGate4LenMatrix     cellAtRow:i column:0] setTag:i];
        [[accGate4StartMatrix   cellAtRow:i column:0] setTag:i];
        [[accGate5LenMatrix     cellAtRow:i column:0] setTag:i];
        [[accGate5StartMatrix   cellAtRow:i column:0] setTag:i];
        [[accGate6LenMatrix     cellAtRow:i column:0] setTag:i];
        [[accGate6StartMatrix   cellAtRow:i column:0] setTag:i];
        [[accGate7LenMatrix     cellAtRow:i column:0] setTag:i];
        [[accGate7StartMatrix   cellAtRow:i column:0] setTag:i];
        [[accGate8LenMatrix     cellAtRow:i column:0] setTag:i];
        [[accGate8StartMatrix   cellAtRow:i column:0] setTag:i];
        [[rawDataBufferLenMatrix     cellAtRow:i column:0] setTag:i];
        [[rawDataBufferStartMatrix   cellAtRow:i column:0] setTag:i];
   }

	ORTimeLinePlot* aPlot1 = [[ORTimeLinePlot alloc] initWithTag:8 andDataSource:self];
	[timeRatePlot addPlot: aPlot1];
	[(ORTimeAxis*)[timeRatePlot xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
	[aPlot1 release];
	
	[rate0 setNumber:8 height:10 spacing:5];
	
	[super awakeFromNib];
}

#pragma mark •••Notifications
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
                         name : ORRunStatusChangedNotification  //kControlStatusReg? 6.1?
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORSIS3316SettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(rateGroupChanged:)
                         name : ORSIS3316RateGroupChangedNotification
                       object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(totalRateChanged:)
						 name : ORRateGroupTotalRateChangedNotification
					   object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(enabledChanged:)
                         name : ORSIS3316EnabledChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(heSuppressTrigModeChanged:)
                         name : ORSIS3316HeSuppressTrigModeChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(thresholdChanged:)
                         name : ORSIS3316ThresholdChanged
                       object : model];

  
    [notifyCenter addObserver : self
                     selector : @selector(cfdControlBitsChanged:)
                         name : ORSIS3316CfdControlBitsChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(peakingTimeChanged:)
                         name : ORSIS3316PeakingTimeChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(energyDividerChanged:)
                         name : ORSIS3316EnergyDividerChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(energySubtractorChanged:)
                         name : ORSIS3316EnergySubtractorChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(histogramsEnabledChanged:)
                         name : ORSIS3316HistogramsEnabledChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(pileupEnabledChanged:)
                         name : ORSIS3316PileUpEnabledChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(clrHistogramWithTSChanged:)
                         name : ORSIS3316ClrHistogramWithTSChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(writeHitsIntoEventMemoryChanged:)
                         name : ORSIS3316WriteHitsIntoEventMemoryChanged
                       object : model];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(tauFactorChanged:)
                         name : ORSIS3316TauFactorChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(gapTimeChanged:)
                         name : ORSIS3316GapTimeChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(heTrigThresholdChanged:)
                         name : ORSIS3316HeTrigThresholdChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(trigBothEdgesChanged:)
                         name : ORSIS3316TrigBothEdgesChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(intHeTrigOutPulseChanged:)
                         name : ORSIS3316IntHeTrigOutPulseChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(intTrigOutPulseBitsChanged:)
                         name : ORSIS3316IntTrigOutPulseBitsChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(activeTrigGateWindowLenChanged:)
                         name : ORSIS3316ActiveTrigGateWindowLenChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(preTriggerDelayChanged:)
                         name : ORSIS3316PreTriggerDelayChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(rawDataBufferLenChanged:)
                         name : ORSIS3316RawDataBufferLenChanged
                        object: model];
    [notifyCenter addObserver : self
                     selector : @selector(rawDataBufferStartChanged:)
                         name : ORSIS3316RawDataBufferStartChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(accGate1LenChanged:)
                         name : ORSIS3316AccGate1LenChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(accGate1StartChanged:)
                         name : ORSIS3316AccGate1StartChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(accGate2LenChanged:)
                         name : ORSIS3316AccGate2LenChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(accGate2StartChanged:)
                         name : ORSIS3316AccGate2StartChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(accGate3LenChanged:)
                         name : ORSIS3316AccGate3LenChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(accGate3StartChanged:)
                         name : ORSIS3316AccGate3StartChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(accGate4LenChanged:)
                         name : ORSIS3316AccGate4LenChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(accGate4StartChanged:)
                         name : ORSIS3316AccGate4StartChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(accGate5LenChanged:)
                         name : ORSIS3316AccGate5LenChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(accGate5StartChanged:)
                         name : ORSIS3316AccGate5StartChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(accGate6LenChanged:)
                         name : ORSIS3316AccGate6LenChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(accGate6StartChanged:)
                         name : ORSIS3316AccGate6StartChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(accGate7LenChanged:)
                         name : ORSIS3316AccGate7LenChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(accGate7StartChanged:)
                         name : ORSIS3316AccGate7StartChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(accGate8LenChanged:)
                         name : ORSIS3316AccGate8LenChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(accGate8StartChanged:)
                         name : ORSIS3316AccGate8StartChanged
                       object : model];
    
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
                     selector : @selector(pageSizeChanged:)
                         name : ORSIS3316PageSizeChanged
						object: model];
	
    [self registerRates];
    [notifyCenter addObserver : self
                     selector : @selector(stopDelayChanged:)
                         name : ORSIS3316StopDelayChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(clockSourceChanged:)
                         name : ORSIS3316ClockSourceChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(startDelayChanged:)
                         name : ORSIS3316StartDelayChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(stopDelayChanged:)
                         name : ORSIS3316StopDelayChanged
						object: model];
			
	
    [notifyCenter addObserver : self
                     selector : @selector(stopTriggerChanged:)
                         name : ORSIS3316StopTriggerChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(eventConfigChanged:)
                         name : ORSIS3316EventConfigChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(csrChanged:)
                         name : ORSIS3316CSRRegChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(acqChanged:)
                         name : ORSIS3316AcqRegChanged
						object: model];
			
    [notifyCenter addObserver : self
                     selector : @selector(moduleIDChanged:)
                         name : ORSIS3316IDChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(hwVersionChanged:)
                         name : ORSIS3316HWVersionChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(temperatureChanged:)
                         name : ORSIS3316TemperatureChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORSIS3316SerialNumberChanged
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
    [self enabledChanged:nil];
    [self heSuppressTrigModeChanged:nil];
	[self thresholdChanged:nil];
    [self cfdControlBitsChanged:nil];
 
    [self histogramsEnabledChanged:nil];
    [self pileupEnabledChanged:nil];
    [self clrHistogramWithTSChanged:nil];
    [self writeHitsIntoEventMemoryChanged:nil];
    
    [self energyDividerChanged:nil];
    [self energySubtractorChanged:nil];
    [self tauFactorChanged:nil];
    [self gapTimeChanged:nil];
    [self peakingTimeChanged:nil];
    [self heTrigThresholdChanged:nil];
    [self trigBothEdgesChanged:nil];
    [self intHeTrigOutPulseChanged:nil];
    [self intTrigOutPulseBitsChanged:nil];
    [self activeTrigGateWindowLenChanged:nil];
    [self preTriggerDelayChanged:nil];
    [self rawDataBufferLenChanged:nil];
    [self rawDataBufferStartChanged:nil];

    [self accGate1LenChanged:nil];
    [self accGate1StartChanged:nil];
    [self accGate2LenChanged:nil];
    [self accGate2StartChanged:nil];
    [self accGate3LenChanged:nil];
    [self accGate3StartChanged:nil];
    [self accGate4LenChanged:nil];
    [self accGate4StartChanged:nil];
    [self accGate5LenChanged:nil];
    [self accGate5StartChanged:nil];
    [self accGate6LenChanged:nil];
    [self accGate6StartChanged:nil];
    [self accGate7LenChanged:nil];
    [self accGate7StartChanged:nil];
    [self accGate8LenChanged:nil];
    [self accGate8StartChanged:nil];

    [self rateGroupChanged:nil];
    [self integrationChanged:nil];
    [self miscAttributesChanged:nil];
    [self totalRateChanged:nil];
    [self updateTimePlot:nil];
    [self waveFormRateChanged:nil];
	[self pageSizeChanged:nil];
	[self stopDelayChanged:nil];
	[self clockSourceChanged:nil];
	[self startDelayChanged:nil];
	[self stopDelayChanged:nil];
	[self randomClockChanged:nil];
	[self stopTriggerChanged:nil];
	
	[self eventConfigChanged:nil];
	[self csrChanged:nil];
	[self acqChanged:nil];
	[self moduleIDChanged:nil];
    [self hwVersionChanged:nil];
    [self serialNumberChanged:nil];
    
    [self setUpdatedOnce]; //<<--Must be last to ensure all fields are updated on first load
}

#pragma mark •••Interface Management

- (void) enabledChanged:(NSNotification*)aNote  //bools and possibly more changed like this
{
    short i;
    for(i=0;i<kNumSIS3316Channels;i++){
        [[enabledMatrix cellWithTag:i] setState:[model enabled:i]];
    }
}

- (void) histogramsEnabledChanged:(NSNotification*)aNote        { [self updateBOOLMatrix:histogramsEnabledMatrix        getter:@selector(histogramsEnabled:)]; }
- (void) pileupEnabledChanged:(NSNotification*)aNote            { [self updateBOOLMatrix:pileupEnabledMatrix            getter:@selector(pileupEnabled:)]; }
- (void) clrHistogramWithTSChanged:(NSNotification*)aNote       { [self updateBOOLMatrix:clrHistogramWithTSMatrix       getter:@selector(clrHistogramsWithTS:)]; }
- (void) writeHitsIntoEventMemoryChanged:(NSNotification*)aNote { [self updateBOOLMatrix:writeHitsIntoEventMemoryMatrix getter:@selector(writeHitsToEventMemory:)]; }

- (void) heSuppressTrigModeChanged:(NSNotification*)aNote { [self updateBOOLMatrix:heSuppressTrigModeMatrix getter:@selector(heSuppressTriggerMask:)]; }
- (void) thresholdChanged:(NSNotification*)aNote          { [self updateValueMatrix:thresholdMatrix         getter:@selector(threshold:)]; }
- (void) cfdControlBitsChanged:(NSNotification*)aNote     { [self updatePUMatrix:cfdControlMatrix           getter:@selector(cfdControlBits:)]; }

- (void) energyDividerChanged:(NSNotification*)aNote      { [self updateValueMatrix:energyDividerMatrix     getter:@selector(energyDivider:)]; }
- (void) energySubtractorChanged:(NSNotification*)aNote   { [self updateValueMatrix:energySubtractorMatrix  getter:@selector(energySubtractor:)]; }

- (void) tauFactorChanged:(NSNotification*)aNote          { [self updateValueMatrix:tauFactorMatrix         getter:@selector(tauFactor:)]; }
- (void) gapTimeChanged:(NSNotification*)aNote            { [self updateValueMatrix:gapTimeMatrix           getter:@selector(gapTime:)]; }
- (void) peakingTimeChanged:(NSNotification*)aNote        { [self updateValueMatrix:peakingTimeMatrix       getter:@selector(peakingTime:)]; }
- (void) heTrigThresholdChanged:(NSNotification*)aNote    { [self updateValueMatrix:heTrigThresholdMatrix   getter:@selector(heTrigThreshold:)]; }
- (void) trigBothEdgesChanged:(NSNotification*)aNote      { [self updateBOOLMatrix:trigBothEdgesMatrix      getter:@selector(trigBothEdgesMask:)]; }
- (void) intHeTrigOutPulseChanged:(NSNotification*)aNote  { [self updateBOOLMatrix:intHeTrigOutPulseMatrix  getter:@selector(intHeTrigOutPulseMask:)]; }
- (void) intTrigOutPulseBitsChanged:(NSNotification*)aNote{ [self updatePUMatrix:intTrigOutPulseBitsMatrix  getter:@selector(intTrigOutPulseBit:)]; }
- (void) activeTrigGateWindowLenChanged:(NSNotification*)aNote  {[self updateValueMatrix:activeTrigGateWindowLenMatrix getter:@selector(activeTrigGateWindowLen:)];}
- (void) preTriggerDelayChanged:(NSNotification*)aNote    { [self updateValueMatrix:preTriggerDelayMatrix   getter:@selector(preTriggerDelay:)];}

- (void) accGate1LenChanged:  (NSNotification*)aNote      { [self updateValueMatrix:accGate1LenMatrix        getter:@selector(accGate1Len:)];}
- (void) accGate1StartChanged:(NSNotification*)aNote      { [self updateValueMatrix:accGate1StartMatrix      getter:@selector(accGate1Start:)];}
- (void) accGate2LenChanged:  (NSNotification*)aNote      { [self updateValueMatrix:accGate2LenMatrix        getter:@selector(accGate2Len:)];}
- (void) accGate2StartChanged:(NSNotification*)aNote      { [self updateValueMatrix:accGate2StartMatrix      getter:@selector(accGate2Start:)];}
- (void) accGate3LenChanged:  (NSNotification*)aNote      { [self updateValueMatrix:accGate3LenMatrix        getter:@selector(accGate3Len:)];}
- (void) accGate3StartChanged:(NSNotification*)aNote      { [self updateValueMatrix:accGate3StartMatrix      getter:@selector(accGate3Start:)];}
- (void) accGate4LenChanged:  (NSNotification*)aNote      { [self updateValueMatrix:accGate4LenMatrix        getter:@selector(accGate4Len:)];}
- (void) accGate4StartChanged:(NSNotification*)aNote      { [self updateValueMatrix:accGate4StartMatrix      getter:@selector(accGate4Start:)];}
- (void) accGate5LenChanged:  (NSNotification*)aNote      { [self updateValueMatrix:accGate5LenMatrix        getter:@selector(accGate5Len:)];}
- (void) accGate5StartChanged:(NSNotification*)aNote      { [self updateValueMatrix:accGate5StartMatrix      getter:@selector(accGate5Start:)];}
- (void) accGate6LenChanged:  (NSNotification*)aNote      { [self updateValueMatrix:accGate6LenMatrix        getter:@selector(accGate6Len:)];}
- (void) accGate6StartChanged:(NSNotification*)aNote      { [self updateValueMatrix:accGate6StartMatrix      getter:@selector(accGate6Start:)];}
- (void) accGate7LenChanged:  (NSNotification*)aNote      { [self updateValueMatrix:accGate7LenMatrix        getter:@selector(accGate7Len:)];}
- (void) accGate7StartChanged:(NSNotification*)aNote      { [self updateValueMatrix:accGate7StartMatrix      getter:@selector(accGate7Start:)];}
- (void) accGate8LenChanged:  (NSNotification*)aNote      { [self updateValueMatrix:accGate8LenMatrix        getter:@selector(accGate8Len:)];}
- (void) accGate8StartChanged:(NSNotification*)aNote      { [self updateValueMatrix:accGate8StartMatrix      getter:@selector(accGate8Start:)];}
- (void) rawDataBufferLenChanged:  (NSNotification*)aNote { [self updateValueMatrix:rawDataBufferLenMatrix   getter:@selector(rawDataBufferLen:)];}
- (void) rawDataBufferStartChanged:(NSNotification*)aNote { [self updateValueMatrix:rawDataBufferStartMatrix getter:@selector(rawDataBufferStart:)];}

- (void) csrChanged:(NSNotification*)aNote
{
	[[csrMatrix cellWithTag:0] setIntValue:[model enableTriggerOutput]];
	[[csrMatrix cellWithTag:1] setIntValue:[model invertTrigger]];
	[[csrMatrix cellWithTag:2] setIntValue:[model activateTriggerOnArmed]];
	[[csrMatrix cellWithTag:3] setIntValue:[model enableInternalRouting]];
	[[csrMatrix cellWithTag:4] setIntValue:[model bankFullTo1]];
	[[csrMatrix cellWithTag:5] setIntValue:[model bankFullTo2]];
	[[csrMatrix cellWithTag:7] setIntValue:[model bankFullTo3]];
}

- (void) acqChanged:(NSNotification*)aNote
{
	[[acqMatrix cellWithTag:0] setIntValue:[model bankSwitchMode]];
	[[acqMatrix cellWithTag:1] setIntValue:[model autoStart]];
	[[acqMatrix cellWithTag:2] setIntValue:[model multiEventMode]];
	[[acqMatrix cellWithTag:3] setIntValue:[model multiplexerMode]];
	[[acqMatrix cellWithTag:4] setIntValue:[model lemoStartStop]];
	[[acqMatrix cellWithTag:5] setIntValue:[model p2StartStop]];
	[[acqMatrix cellWithTag:6] setIntValue:[model gateMode]];
	[stopDelayEnabledButton setIntValue: [model stopDelayEnabled]];
}

- (void) moduleIDChanged:(NSNotification*)aNote
{
	unsigned short moduleID = [model moduleID];
	if(moduleID) [moduleIDField setStringValue:[NSString stringWithFormat:@"%x",moduleID]];
	else		 [moduleIDField setStringValue:@"---"];
    
    NSString* revision = [model revision];
    if(revision) [revisionField setStringValue:revision];
    else		 [revisionField setStringValue:@"---"];
    
    if( [model majorRevision] == 0x20)   [gammaRevisionField setStringValue:@"Gamma Revision"];
    else                            [gammaRevisionField setStringValue:@""];

}

- (void) hwVersionChanged: (NSNotification*)aNote
{
    unsigned short readHWVersion = [model hwVersion];
    if(readHWVersion) [hwVersionField setStringValue: [NSString stringWithFormat:@"%x",readHWVersion]];
}

- (void) serialNumberChanged: (NSNotification*)aNote
{
    unsigned short readSerialNumber = [model serialNumber];
    if(readSerialNumber) [serialNumberField setStringValue:[NSString stringWithFormat:@"%x",readSerialNumber]];
    else [serialNumberField setStringValue:@""];
}

- (void) eventConfigChanged:(NSNotification*)aNote
{
	[[eventConfigMatrix cellWithTag:0] setIntValue:[model pageWrap]];
	[[eventConfigMatrix cellWithTag:1] setIntValue:[model gateChaining]];
}

- (void) stopTriggerChanged:(NSNotification*)aNote
{
	[stopTriggerButton setIntValue: [model stopTrigger]];
}

- (void) randomClockChanged:(NSNotification*)aNote
{
	[randomClockButton setIntValue: [model randomClock]];
}

- (void) clockSourceChanged:(NSNotification*)aNote
{
	[clockSourcePU selectItemAtIndex: [model clockSource]];
}

- (void) startDelayChanged:(NSNotification*)aNote
{
	[startDelayField setIntValue: [model startDelay]];
}

- (void) stopDelayChanged:(NSNotification*)aNote
{
	[stopDelayField setIntValue: [model stopDelay]];
}

- (void) pageSizeChanged:(NSNotification*)aNote
{
	[pageSizePU selectItemWithTag: [model pageSize]];
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

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORSIS3316SettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORSIS3316SettingsLock];
    BOOL locked = [gSecurity isLocked:ORSIS3316SettingsLock];
    
    [settingLockButton          setState: locked];
    [addressText                setEnabled:!locked && !runInProgress];
    [initButton                 setEnabled:!lockedOrRunningMaintenance];
	[enabledMatrix              setEnabled:!lockedOrRunningMaintenance];
	[heSuppressTrigModeMatrix   setEnabled:!lockedOrRunningMaintenance];
	[thresholdMatrix            setEnabled:!lockedOrRunningMaintenance];
    
	[checkEventButton           setEnabled:!locked && !runInProgress];
	[testMemoryButton           setEnabled:!locked && !runInProgress];
	
	[csrMatrix                  setEnabled:!locked && !runInProgress];
	[acqMatrix                  setEnabled:!locked && !runInProgress];
	[eventConfigMatrix          setEnabled:!locked && !runInProgress];
	[stopTriggerButton          setEnabled:!lockedOrRunningMaintenance];
	[randomClockButton          setEnabled:!lockedOrRunningMaintenance];
	[stopDelayEnabledButton     setEnabled:!lockedOrRunningMaintenance];
	[startDelayField            setEnabled:!lockedOrRunningMaintenance];
	[clockSourcePU              setEnabled:!lockedOrRunningMaintenance];
	[stopDelayField             setEnabled:!lockedOrRunningMaintenance];
	[pageSizePU                 setEnabled:!locked && !runInProgress];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"SIS3316 Card (Slot %d)",[model slot]]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
    [slotField setIntValue: [model slot]];
    [[self window] setTitle:[NSString stringWithFormat:@"SIS3316 Card (Slot %d)",[model slot]]];
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

- (void) temperatureChanged:(NSNotification*)aNotification
{
    [temperatureField setFloatValue: [model temperature]];
    if ([model temperature] > 50 ) [temperatureField setTextColor: [NSColor redColor] ];
    else                            [temperatureField setTextColor: [NSColor blackColor] ];
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

#pragma mark •••Actions
- (IBAction) baseAddressAction:(id)sender
{
    [model setBaseAddress:[sender intValue]];
}

- (IBAction) histogramsEnabledAction:(id)sender
{
    [model setHistogramsEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}
- (IBAction) pileupEnabledAction:(id)sender
{
    [model setPileupEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}
- (IBAction) clrHistogramsWithTSAction:(id)sender
{
    [model setClrHistogramsWithTS:[[sender selectedCell] tag] withValue:[sender intValue]];
}
- (IBAction) writeHitsIntoEventMemoryAction:(id)sender
{
    [model setWriteHitsToEventMemory:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) enabledAction:(id)sender
{
    int tag =[[sender selectedCell] tag];
    int aValue = [sender intValue];
    [model setEnabledBit:tag withValue:aValue];
}

- (IBAction) heSuppressTrigModeAction:(id)sender
{
    [model setHeSuppressTriggerBit:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) thresholdAction:(id)sender
{
    [model setThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) cfdControlAction:(id)sender
{
    [model setCfdControlBits:[sender selectedRow] withValue:[[sender selectedCell] indexOfSelectedItem]];
}

- (IBAction) peakingTimeAction:(id)sender
{
    [model setPeakingTime:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) energyDividerAction:(id)sender
{
    [model setEnergyDivider:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) energySubtractorAction:(id)sender
{
    [model setEnergySubtractor:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) tauFactorAction:(id)sender
{
    [model setTauFactor:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) gapTimeAction:(id)sender
{
    [model setGapTime:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) heTrigThresholdAction:(id)sender
{
    [model setHeTrigThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) trigBothEdgesAction:(id)sender
{
    [model setTrigBothEdgesBit:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) intHeTrigOutPulseAction:(id)sender
{
    [model setIntHeTrigOutPulseBit:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) intTrigOutPulseBitsAction:(id)sender
{
    [model setIntTrigOutPulseBit:[sender selectedRow] withValue:[[sender selectedCell] indexOfSelectedItem]];
}

- (IBAction) activeTrigGateWindowLenActive:(id)sender
{
    [model setActiveTrigGateWindowLen:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) preTriggerDelayAction:(id)sender
{
    [model setPreTriggerDelay:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) rawDataBufferLenAction:(id)sender
{
    [model setRawDataBufferLen:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) rawDataBufferStartAction:(id)sender
{
    [model setRawDataBufferStart:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) accGate1LenAction:(id)sender
{
    [model setAccGate1Len:[[sender selectedCell] tag] withValue:[sender intValue]];
}
- (IBAction) accGate1StartAction:(id)sender
{
    [model setAccGate1Start:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) accGate2LenAction:(id)sender
{
    [model setAccGate2Len:[[sender selectedCell] tag] withValue:[sender intValue]];
}
- (IBAction) accGate2StartAction:(id)sender
{
    [model setAccGate2Start:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) accGate3LenAction:(id)sender
{
    [model setAccGate3Len:[[sender selectedCell] tag] withValue:[sender intValue]];
}
- (IBAction) accGate3StartAction:(id)sender
{
    [model setAccGate3Start:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) accGate4LenAction:(id)sender
{
    [model setAccGate4Len:[[sender selectedCell] tag] withValue:[sender intValue]];
}
- (IBAction) accGate4StartAction:(id)sender
{
    [model setAccGate4Start:[[sender selectedCell] tag] withValue:[sender intValue]];
}
- (IBAction) accGate5LenAction:(id)sender
{
    [model setAccGate5Len:[[sender selectedCell] tag] withValue:[sender intValue]];
}
- (IBAction) accGate5StartAction:(id)sender
{
    [model setAccGate5Start:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) accGate6LenAction:(id)sender
{
    [model setAccGate6Len:[[sender selectedCell] tag] withValue:[sender intValue]];
}
- (IBAction) accGate6StartAction:(id)sender
{
    [model setAccGate6Start:[[sender selectedCell] tag] withValue:[sender intValue]];
}
- (IBAction) accGate7LenAction:(id)sender
{
    [model setAccGate7Len:[[sender selectedCell] tag] withValue:[sender intValue]];
}
- (IBAction) accGate7StartAction:(id)sender
{
    [model setAccGate7Start:[[sender selectedCell] tag] withValue:[sender intValue]];
}
- (IBAction) accGate8LenAction:(id)sender
{
    [model setAccGate8Len:[[sender selectedCell] tag] withValue:[sender intValue]];
}
- (IBAction) accGate8StartAction:(id)sender
{
    [model setAccGate8Start:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) csrAction:(id)sender
{
	//tags are defined in IB, they have to match here or there will be trouble
	BOOL state = [[sender selectedCell] intValue];
	switch ([[sender selectedCell] tag]) {
		case 0: [model setEnableTriggerOutput:state];		break; 
		case 1: [model setInvertTrigger:state];				break; 
		case 2: [model setActivateTriggerOnArmed:state];	break; 
		case 3: [model setEnableInternalRouting:state];		break; 
		case 4: [model setBankFullTo1:state];				break; 
		case 5: [model setBankFullTo2:state];				break; 
		case 6: [model setBankFullTo3:state];				break; 
		default: break;
	}
}

- (IBAction) acqAction:(id)sender
{
	//tags are defined in IB, they have to match here or there will be trouble
	BOOL state = [[sender selectedCell] intValue];
	switch ([[sender selectedCell] tag]) {
		case 0: [model setBankSwitchMode:state];	break; 
		case 1: [model setAutoStart:state];			break; 
		case 2: [model setMultiEventMode:state];	break; 
		case 3: [model setMultiplexerMode:state];	break; 
		case 4: [model setLemoStartStop:state];		break; 
		case 5: [model setP2StartStop:state];		break; 
		case 6: [model setGateMode:state];			break; 
		case 8: [model setStopDelayEnabled:state];			break;
		default: break;
	}
}

- (IBAction) eventConfigAction:(id)sender
{
	//tags are defined in IB, they have to match here or there will be trouble
	BOOL state = [[sender selectedCell] intValue];
	switch ([[sender selectedCell] tag]) {
		case 0: [model setPageWrap:state];			break; 
		case 1: [model setGateChaining:state];		break; 
		default: break;
	}
}



- (IBAction) testMemoryBankAction:(id)sender;
{
	@try {
		[model testMemory];
	}
	@catch (NSException* localException) {
		NSLog(@"Test of SIS 3300 Memory Bank failed\n");
	}
}
- (IBAction) probeBoardAction:(id)sender;
{
	@try {
        [model readModuleID:YES];
        [model readHWVersion:YES];
        [model readSerialNumber:YES];
        [model readTemperature:YES];
	}
	@catch (NSException* localException) {
		NSLog(@"Probe of SIS 3300 board ID failed\n");
	}
}

- (IBAction) stopTriggerAction:(id)sender
{
	[model setStopTrigger:[sender intValue]];	
}

- (IBAction) randomClockAction:(id)sender
{
	[model setRandomClock:[sender intValue]];	
}


- (IBAction) stopDelayEnabledAction:(id)sender
{
	[model setStopDelayEnabled:[sender intValue]];	
}

- (IBAction) startDelayAction:(id)sender
{
	[model setStartDelay:[sender intValue]];	
}

- (IBAction) clockSourceAction:(id)sender
{
	[model setClockSource:[sender indexOfSelectedItem]];	
}

- (IBAction) stopDelayAction:(id)sender
{
	[model setStopDelay:[sender intValue]];	
}

- (IBAction) pageSizeAction:(id)sender
{
	[model setPageSize:[[sender selectedItem] tag]];	
}


- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORSIS3316SettingsLock to:[sender intValue] forWindow:[self window]];
}


- (IBAction) initBoard:(id)sender
{
    @try {
        [self endEditing];
        [model initBoard];		//initialize and load hardward
        NSLog(@"Initialized SIS3316 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Reset and Init of SIS3316 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed SIS3316 Reset and Init", @"OK", nil, nil,
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
	
    NSString* key = [NSString stringWithFormat: @"orca.ORSIS3316%d.selectedtab",[model slot]];
    int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
}

- (IBAction) writeThresholdsAction:(id)sender
{
    @try {
        [self endEditing];
        [model writeThresholds];
        [model writeHeTrigThresholds];
        [model writeFirTriggerSetup];
    }
	@catch(NSException* localException) {
        NSLog(@"SIS3316 Thresholds write FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nSIS3316 Write FAILED", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) readThresholdsAction:(id)sender
{
    @try {
        [self endEditing];
        [model readThresholds:YES];
        [model readHeTrigThresholds:YES];
    }
	@catch(NSException* localException) {
        NSLog(@"SIS3316 Thresholds read FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nSIS3316 Read FAILED", @"OK", nil, nil,
                        localException);
    }
}
- (IBAction) writeFirTrigSetupsAction:(id)sender
{
    @try {
        [self endEditing];
        [model writeFirTriggerSetup];
    }
    @catch(NSException* localException) {
        NSLog(@"SIS3316 FirTrigSetups write FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nSIS3316 Write FAILED", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) writeHeTrigThresholdsAction:(id)sender
{
    @try {
        [self endEditing];
        [model writeHeTrigThresholds];
    }
    @catch(NSException* localException) {
        NSLog(@"SIS3316 HeTrigThresholds write FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nSIS3316 Write FAILED", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) readHeTrigThresholdsAction:(id)sender
{
    @try {
        [self endEditing];
        [model readThresholds:YES];
    }
    @catch(NSException* localException) {
        NSLog(@"SIS3316 HeTrigThresholds read FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nSIS3316 Read FAILED", @"OK", nil, nil,
                        localException);
    }
}


- (IBAction) checkEvent:(id)sender
{
	[self endEditing];
	//[model testEventRead];
}

#pragma mark •••Data Source
- (double) getBarValue:(int)tag
{
	return [[[[model waveFormRateGroup]rates] objectAtIndex:tag] rate];
}

- (int) numberPointsInPlot:(id)aPlotter
{
    return [[[model waveFormRateGroup] timeRate]count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
{
    int count = [[[model waveFormRateGroup]timeRate] count];
    int index = count-i-1;
    *yValue = [[[model waveFormRateGroup] timeRate] valueAtIndex:index];
    *xValue = [[[model waveFormRateGroup] timeRate] timeSampledAtIndex:index];
}

@end