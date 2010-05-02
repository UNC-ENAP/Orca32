//--------------------------------------------------------
// ORKJL2200IonGaugeController
// Created by Mark  A. Howe on Thurs Apr 22 2010
// Copyright (c) 2010 University of North Caroline. All rights reserved.
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

#import "ORKJL2200IonGaugeController.h"
#import "ORKJL2200IonGaugeModel.h"
#import "ORPlotView.h"
#import "ORTimeLinePlot.h"
#import "ORTimeAxis.h"
#import "ORSerialPortList.h"
#import "ORSerialPort.h"
#import "ORTimeRate.h"
#import "BiStateView.h"

@interface ORKJL2200IonGaugeController (private)
- (void) populatePortListPopup;
@end

@implementation ORKJL2200IonGaugeController

#pragma mark ***Initialization

- (id) init
{
	self = [super initWithWindowNibName:@"KJL2200IonGauge"];
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
    [(ORAxis*)[plotter0 yScale] setRngLow:0.0 withHigh:300.];
	[(ORAxis*)[plotter0 yScale] setRngLimitsLow:-300.0 withHigh:500 withMinRng:4];

    [(ORAxis*)[plotter0 xScale] setRngLow:0.0 withHigh:10000];
	[(ORAxis*)[plotter0 xScale] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];

	ORTimeLinePlot* aPlot;
	aPlot= [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
	[plotter0 addPlot: aPlot];
	[(ORTimeAxis*)[plotter0 xScale] setStartTime: [[NSDate date] timeIntervalSince1970]];
	[aPlot release];
	
	[super awakeFromNib];
}
- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"KJL2200 (%d)",[model uniqueIdNumber]]];
}

#pragma mark ***Notifications

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
                         name : ORKJL2200IonGaugeLock
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(portNameChanged:)
                         name : ORKJL2200IonGaugePortNameChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(portStateChanged:)
                         name : ORSerialPortStateChanged
                       object : nil];
                                              
    [notifyCenter addObserver : self
                     selector : @selector(pollTimeChanged:)
                         name : ORKJL2200IonGaugePollTimeChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(shipPressureChanged:)
                         name : ORKJL2200IonGaugeShipPressureChanged
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
                     selector : @selector(pressureChanged:)
                         name : ORKJL2200IonGaugePressureChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(setPointChanged:)
                         name : ORKJL2200IonGaugeModelSetPointChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(sensitivityChanged:)
                         name : ORKJL2200IonGaugeModelSensitivityChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(emissionCurrentChanged:)
                         name : ORKJL2200IonGaugeModelEmissionCurrentChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(degasTimeChanged:)
                         name : ORKJL2200IonGaugeModelDegasTimeChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(stateMaskChanged:)
                         name : ORKJL2200IonGaugeModelStateMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pressureScaleChanged:)
                         name : ORKJL2200IonGaugeModelPressureScaleChanged
						object: model];
	
}

- (void) updateWindow
{
    [super updateWindow];
    [self lockChanged:nil];
    [self portStateChanged:nil];
    [self portNameChanged:nil];
	[self pollTimeChanged:nil];
	[self shipPressureChanged:nil];
	[self updateTimePlot:nil];
    [self miscAttributesChanged:nil];
	[self pressureChanged:nil];
	[self setPointChanged:nil];
	[self sensitivityChanged:nil];
	[self emissionCurrentChanged:nil];
	[self degasTimeChanged:nil];
	[self stateMaskChanged:nil];
	[self pressureScaleChanged:nil];
}

- (void) pressureScaleChanged:(NSNotification*)aNote
{
	[pressureScalePU selectItemAtIndex: [model pressureScale]];
	[plotter0 setNeedsDisplay:YES];
}

- (void) stateMaskChanged:(NSNotification*)aNote
{
	unsigned short aMask = [model stateMask];
	[setPoint1State setState:aMask & kKJL2200SetPoint1Mask];
	[setPoint2State setState:aMask & kKJL2200SetPoint2Mask];
	[setPoint3State setState:aMask & kKJL2200SetPoint3Mask];
	[setPoint4State setState:aMask & kKJL2200SetPoint4Mask];
	BOOL degassOn = aMask & kKJL2200DegasOnMask;
	BOOL isOn     = aMask & kKJL2200IonGaugeOnMask;
	[degasOnField setStringValue:degassOn?@"Degas":@""];
	[onOffButton setTitle:isOn?@"Turn Off":@"Turn On"];
	[degasButton setTitle:isOn?@"Turn Degas Off":@"Turn Degas On"];
	
	[[setPointLabelMatrix cellWithTag:0] setStringValue:aMask & kKJL2200SetPoint1Mask ? @"S1":@""];
	[[setPointLabelMatrix cellWithTag:1] setStringValue:aMask & kKJL2200SetPoint2Mask ? @"S2":@""];
	[[setPointLabelMatrix cellWithTag:2] setStringValue:aMask & kKJL2200SetPoint3Mask ? @"S3":@""];
	[[setPointLabelMatrix cellWithTag:3] setStringValue:aMask & kKJL2200SetPoint4Mask ? @"S4":@""];
	
	[self pressureChanged:nil];
}

- (void) degasTimeChanged:(NSNotification*)aNote
{
	[degasTimeField setFloatValue: [model degasTime]];
}

- (void) emissionCurrentChanged:(NSNotification*)aNote
{
	[emissionCurrentField setFloatValue: [model emissionCurrent]];
}

- (void) sensitivityChanged:(NSNotification*)aNote
{
	[sensitivityField setIntValue: [model sensitivity]];
}

- (void) setPointChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<4;i++){
		[[setPointMatrix cellWithTag:i] setStringValue: [NSString stringWithFormat:@"%.2E",[model setPoint:i]]];
	}
}

- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [plotter0 xScale]){
		[model setMiscAttributes:[(ORAxis*)[plotter0 xScale]attributes] forKey:@"XAttributes0"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter0 yScale]){
		[model setMiscAttributes:[(ORAxis*)[plotter0 yScale]attributes] forKey:@"YAttributes0"];
	};

}

- (void) miscAttributesChanged:(NSNotification*)aNote
{

	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"XAttributes0"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes0"];
		if(attrib){
			[(ORAxis*)[plotter0 xScale] setAttributes:attrib];
			[plotter0 setNeedsDisplay:YES];
			[(ORAxis*)[plotter0 xScale] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"YAttributes0"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes0"];
		if(attrib){
			[(ORAxis*)[plotter0 yScale] setAttributes:attrib];
			[plotter0 setNeedsDisplay:YES];
			[(ORAxis*)[plotter0 yScale] setNeedsDisplay:YES];
		}
	}
}

- (void) updateTimePlot:(NSNotification*)aNote
{
	if(!aNote || ([aNote object] == [model timeRate])){
		[plotter0 setNeedsDisplay:YES];
	}
}

- (void) shipPressureChanged:(NSNotification*)aNote
{
	[shipPressureButton setIntValue: [model shipPressure]];
	[shippingStateField setStringValue:[model shipPressure]?@"Shipping Enabled":@""];
}

- (void) pressureChanged:(NSNotification*)aNote
{
	if([model stateMask] & kKJL2200IonGaugeOnMask){
		[pressureField setStringValue:[NSString stringWithFormat:@"%.1E",[model pressure]]];
	}
	else {
		[pressureField setStringValue:@"OFF"];
	}
	unsigned long t = [model timeMeasured];
	NSCalendarDate* theDate;
	if(t){
		theDate = [NSCalendarDate dateWithTimeIntervalSince1970:t];
		[theDate setCalendarFormat:@"%m/%d %H:%M:%S"];
		[timeField setObjectValue:theDate];
	}
	else [timeField setObjectValue:@"--"];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORKJL2200IonGaugeLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNotification
{

    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORKJL2200IonGaugeLock];
    BOOL locked = [gSecurity isLocked:ORKJL2200IonGaugeLock];

    [lockButton setState: locked];

    [portListPopup setEnabled:!locked];
    [openPortButton setEnabled:!locked];
    [pollTimePopup setEnabled:!locked];
    [shipPressureButton setEnabled:!locked];
    [degasButton setEnabled:!locked];
    [onOffButton setEnabled:!locked];
	
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:ORKJL2200IonGaugeLock])s = @"Not in Maintenance Run.";
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


#pragma mark ***Actions
- (void) pressureScaleAction:(id)sender
{
	[model setPressureScale:[sender indexOfSelectedItem]];	
}
- (IBAction) readNowAction:(id)sender
{
	[model pollPressure];
}

- (IBAction) degasTimeAction:(id)sender
{
	[model setDegasTime:[sender floatValue]];	
}

- (IBAction) emissionCurrentAction:(id)sender
{
	[model setEmissionCurrent:[sender floatValue]];	
}

- (IBAction) sensitivityAction:(id)sender
{
	[model setSensitivity:[sender intValue]];	
}

- (IBAction) shipPressureAction:(id)sender
{
	[model setShipPressure:[sender intValue]];	
}

- (IBAction) initBoard:(id)sender
{
	[model initBoard];	
}
- (IBAction) toggleIonGauge:(id)sender
{
	if([model stateMask] & kKJL2200IonGaugeOnMask) [model turnOff];	
	else [model turnOn];
}

- (IBAction) toggleDegass:(id)sender
{
	if([model stateMask] & kKJL2200DegasOnMask) [model turnDegasOff];	
	else [model turnDegasOn];
}

- (IBAction) setPointAction:(id)sender
{
	NSString* s = [[sender selectedCell] stringValue];
	s = [s stringByReplacingOccurrencesOfString:@"-" withString:@"E-"];
	s = [s stringByReplacingOccurrencesOfString:@"EE-" withString:@"E-"];
	float theValue = [s floatValue];
	[model setSetPoint:[[sender selectedCell] tag] withValue:theValue];	
}


- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORKJL2200IonGaugeLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) portListAction:(id) sender
{
    [model setPortName: [portListPopup titleOfSelectedItem]];
}

- (IBAction) openPortAction:(id)sender
{
    [model openPort:![[model serialPort] isOpen]];
}

- (IBAction) pollTimeAction:(id)sender
{
	[model setPollTime:[[sender selectedItem] tag]];
}

#pragma mark •••Data Source
- (int) numberPointsInPlot:(id)aPlotter
{
	return [[model timeRate] count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
	int count = [[model timeRate] count];
	int index = count-i-1;
	*xValue = [[model timeRate] timeSampledAtIndex:index];
	*yValue = [[model timeRate] valueAtIndex:index];
}

@end

@implementation ORKJL2200IonGaugeController (private)

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

