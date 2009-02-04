//--------------------------------------------------------
// ORPacController
// Created by Mark  A. Howe on Tue Jan 6, 2009
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2005 CENPA, University of Washington. All rights reserved.
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

#import "ORPacController.h"
#import "ORPacModel.h"
#import "ORPlotter1D.h"
#import "ORAxis.h"
#import "ORSerialPortList.h"
#import "ORSerialPort.h"
#import "ORTimeRate.h"
#import "OHexFormatter.h"

@interface ORPacController (private)
- (void) populatePortListPopup;
@end

@implementation ORPacController

#pragma mark •••Initialization

- (id) init
{
	self = [super initWithWindowNibName:@"Pac"];
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) awakeFromNib
{
    [self populatePortListPopup];
    [[plotter0 yScale] setRngLow:0.0 withHigh:1000.];
	[[plotter0 yScale] setRngLimitsLow:0.0 withHigh:100000 withMinRng:10];
	[plotter0 setDrawWithGradient:YES];

    [[plotter0 xScale] setRngLow:0.0 withHigh:10000];
	[[plotter0 xScale] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];

	OHexFormatter *numberFormatter = [[[OHexFormatter alloc] init] autorelease];
	int i;
	for(i=0;i<8;i++){
		NSCell* theCell = [adcMatrix cellAtRow:i column:0];
		[theCell setFormatter:numberFormatter];
	}
	
	[super awakeFromNib];
}

#pragma mark •••Notifications

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORPacLock
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(portNameChanged:)
                         name : ORPacModelPortNameChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(portStateChanged:)
                         name : ORSerialPortStateChanged
                       object : nil];
                                              
    [notifyCenter addObserver : self
                     selector : @selector(adcChanged:)
                         name : ORPacModelAdcChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(pollTimeChanged:)
                         name : ORPacModelPollTimeChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(shipAdcsChanged:)
                         name : ORPacModelShipAdcsChanged
						object: model];

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
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(portDMaskChanged:)
						 name : ORPacModelPortDMaskChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(dacChanged:)
						 name : ORPacModelDacChanged
					   object : model];
	
		
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"Power and Control (Unit %d)",[model uniqueIdNumber]]];
}

- (void) updateWindow
{
    [super updateWindow];
    [self lockChanged:nil];
    [self portStateChanged:nil];
    [self portNameChanged:nil];
	[self adcChanged:nil];
	[self dacChanged:nil];
	[self pollTimeChanged:nil];
	[self portDMaskChanged:nil];
	[self shipAdcsChanged:nil];
	[self updateTimePlot:nil];
    [self miscAttributesChanged:nil];
}

- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [plotter0 xScale]){
		[model setMiscAttributes:[[plotter0 xScale]attributes] forKey:@"XAttributes0"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter0 yScale]){
		[model setMiscAttributes:[[plotter0 yScale]attributes] forKey:@"YAttributes0"];
	};

}

- (void) miscAttributesChanged:(NSNotification*)aNote
{

	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"XAttributes0"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes0"];
		if(attrib){
			[[plotter0 xScale] setAttributes:attrib];
			[plotter0 setNeedsDisplay:YES];
			[[plotter0 xScale] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"YAttributes0"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes0"];
		if(attrib){
			[[plotter0 yScale] setAttributes:attrib];
			[plotter0 setNeedsDisplay:YES];
			[[plotter0 yScale] setNeedsDisplay:YES];
		}
	}

}

- (void) updateTimePlot:(NSNotification*)aNote
{
	if(!aNote || ([aNote object] == [model timeRate:0])){
		[plotter0 setNeedsDisplay:YES];
	}
}

- (void) portDMaskChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<8;i++){
		[[portDMatrix cellWithTag:i] setIntValue: [model portDBit:i]];
	}
}

- (void) shipAdcsChanged:(NSNotification*)aNote
{
	[shipAdcsButton setIntValue: [model shipAdcs]];
}

- (void) adcChanged:(NSNotification*)aNote
{
	if(aNote){
		int index = [[[aNote userInfo] objectForKey:@"Index"] intValue];
		[self loadAdcTimeValuesForIndex:index];
	}
	else {
		int i;
		for(i=0;i<8;i++){
			[self loadAdcTimeValuesForIndex:i];
		}
	}
}

- (void) dacChanged:(NSNotification*)aNote
{
	if(aNote){
		int index = [[[aNote userInfo] objectForKey:@"Index"] intValue];
		[[dacMatrix cellWithTag:index] setIntValue:[model dac:index]];
	}
	else {
		int i;
		for(i=0;i<8;i++){
			[[dacMatrix cellWithTag:i] setIntValue:[model dac:i]];
		}
	}
}


- (void) loadAdcTimeValuesForIndex:(int)index
{
	[[adcMatrix cellWithTag:index] setIntValue:[model adc:index]];
	[[adc1Matrix cellWithTag:index] setIntValue:[model adc:index]];
	unsigned long t = [model timeMeasured:index];
	NSCalendarDate* theDate;
	if(t){
		theDate = [NSCalendarDate dateWithTimeIntervalSince1970:t];
		[theDate setCalendarFormat:@"%m/%d %H:%M:%S"];
		[[timeMatrix cellWithTag:index] setObjectValue:theDate];
	}
	else [[timeMatrix cellWithTag:index] setObjectValue:@"--"];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORPacLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNotification
{

    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORPacLock];
    BOOL locked = [gSecurity isLocked:ORPacLock];

    [lockButton setState: locked];

    [portListPopup setEnabled:!locked];
    [openPortButton setEnabled:!locked];
    [pollTimePopup setEnabled:!locked];
    [shipAdcsButton setEnabled:!locked];
    [portDMatrix setEnabled:!locked];
    [dacMatrix setEnabled:!locked];
    [readDacButton setEnabled:!locked];
    [writeDacButton setEnabled:!locked];
    [readAdcsButton setEnabled:!locked];
    [portDButton setEnabled:!locked];
    [setLcmEnaButton setEnabled:!locked];
    [clrLcmEnaButton setEnabled:!locked];
	
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:ORPacLock])s = @"Not in Maintenance Run.";
    }
    [lockDocField setStringValue:s];

}

- (void) portStateChanged:(NSNotification*)aNotification
{
    if(aNotification == nil || [aNotification object] == [model serialPort]){
        if([model serialPort]){
            [openPortButton setEnabled:YES];

            if([[model serialPort] isOpen]){
                [openPortButton setTitle:@"Close"];
                [portStateField setTextColor:[NSColor colorWithCalibratedRed:0.0 green:.8 blue:0.0 alpha:1.0]];
                [portStateField setStringValue:@"Open"];
            }
            else {
                [openPortButton setTitle:@"Open"];
                [portStateField setStringValue:@"Closed"];
                [portStateField setTextColor:[NSColor redColor]];
            }
        }
        else {
            [openPortButton setEnabled:NO];
            [portStateField setTextColor:[NSColor blackColor]];
            [portStateField setStringValue:@"---"];
            [openPortButton setTitle:@"---"];
        }
    }
}

- (void) pollTimeChanged:(NSNotification*)aNotification
{
	[pollTimePopup selectItemWithTag:[model pollTime]];
}

- (void) portNameChanged:(NSNotification*)aNotification
{
    NSString* portName = [model portName];
    
	NSEnumerator *enumerator = [ORSerialPortList portEnumerator];
	ORSerialPort *aPort;

    [portListPopup selectItemAtIndex:0]; //the default
    while (aPort = [enumerator nextObject]) {
        if([portName isEqualToString:[aPort name]]){
            [portListPopup selectItemWithTitle:portName];
            break;
        }
	}  
    [self portStateChanged:nil];
}


#pragma mark •••Actions
- (IBAction) readDacAction:(id)sender
{
	[model readDacs];
}

- (IBAction) setLcmEnaAction:(id)sender
{
	[model setLcmEna];
}

- (IBAction) clrLcmEnaAction:(id)sender
{
	[model clrLcmEna];
}

- (IBAction) writeDacAction:(id)sender
{
	[model readDacs];
}

- (IBAction) dacAction:(id)sender
{
	[model setDac:[[sender selectedCell] tag] value:[sender intValue]];
}

- (IBAction) shipAdcsAction:(id)sender
{
	[model setShipAdcs:[sender intValue]];	
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORPacLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) portListAction:(id) sender
{
    [model setPortName: [portListPopup titleOfSelectedItem]];
}

- (IBAction) openPortAction:(id)sender
{
    [model openPort:![[model serialPort] isOpen]];
}

- (IBAction) readAdcsAction:(id)sender
{
	[model readAdcs];
}

- (IBAction) pollTimeAction:(id)sender
{
	[model setPollTime:[[sender selectedItem] tag]];
}
- (IBAction) portDAction:(id)sender
{
	unsigned char mask = 0;
	int i;
	for(i=0;i<8;i++){
		if([[portDMatrix cellWithTag:i] intValue])mask |= (1<<i);
	}
	[model setPortDMask:mask];
}

- (IBAction) writePortDAction:(id) sender
{
	[model writePortD];
}

#pragma mark •••Data Source
- (BOOL) willSupplyColors
{
	return YES;
}

- (NSColor*) colorForDataSet:(int)set
{
	if(set==0)return [NSColor redColor];
	else if(set==1)return [NSColor orangeColor];
	else return [NSColor blackColor];
}


- (int) numberOfDataSetsInPlot:(id)aPlotter
{
    return 2;
}

- (int)	numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
	if(aPlotter == plotter0) return [[model timeRate:set] count];
	else return 0;
}

- (float)  	plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x 
{
	if(aPlotter == plotter0){
		int count = [[model timeRate:set] count];
		return [[model timeRate:set] valueAtIndex:count-x-1];
	}
	else return 0;
}

- (unsigned long)  	secondsPerUnit:(id) aPlotter
{
	return [[model timeRate:0] sampleTime]; //all should be the same, just return value for rate 0
}

@end

@implementation ORPacController (private)

- (void) populatePortListPopup
{
	NSEnumerator *enumerator = [ORSerialPortList portEnumerator];
	ORSerialPort *aPort;
    [portListPopup removeAllItems];
    [portListPopup addItemWithTitle:@"--"];

	while (aPort = [enumerator nextObject]) {
        [portListPopup addItemWithTitle:[aPort name]];
	}    
}
@end

