//
//  ORHPMotionNodeController.m
//  Orca
//
//  Created by Mark Howe on Fri Apr 24, 2009.
//  Copyright (c) 2009 CENPA, University of Washington. All rights reserved.
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

#import "ORMotionNodeController.h"
#import "ORMotionNodeModel.h"
#import "ORSerialPortController.h"
#import "ORSerialPort.h"
#import "ORPlotter1D.h"
#import "ORAxis.h"

@implementation ORMotionNodeController
- (id) init
{
    self = [ super initWithWindowNibName: @"MotionNode" ];
    return self;
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    	
	[notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORMotionNodeModelLock
						object: nil];
		
    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORMotionNodeModelSerialNumberChanged
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(versionChanged:)
                         name : ORMotionNodeModelVersionChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(isAccelOnlyChanged:)
                         name : ORMotionNodeModelIsAccelOnlyChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(packetLengthChanged:)
                         name : ORMotionNodeModelPacketLengthChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(traceIndexChanged:)
                         name : ORMotionNodeModelTraceIndexChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(nodeRunningChanged:)
                         name : ORMotionNodeModelNodeRunningChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(portStateChanged:)
                         name : ORSerialPortStateChanged
                       object : [model serialPort]];
	
    [notifyCenter addObserver : self
                     selector : @selector(temperatureChanged:)
                         name : ORMotionNodeModelTemperatureChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(dispayComponentsChanged:)
                         name : ORMotionNodeModelDisplayComponentsChanged
						object: model];
	
}

- (void) awakeFromNib
{
	[[tracePlot xScale] setRngLow:0 withHigh:kModeNodeTraceLength];
	[[tracePlot xScale] setRngLimitsLow:0 withHigh:kModeNodeTraceLength withMinRng:kModeNodeTraceLength];

	[[tracePlot yScale]  setInteger:NO];
	[[tracePlot yScale]  setRngDefaultsLow:-2 withHigh:2];
	[[tracePlot yScale] setRngLow:-2 withHigh:2];
	[[tracePlot yScale] setRngLimitsLow:-2 withHigh:2 withMinRng:.02];
	[super awakeFromNib];
}

- (void) updateWindow
{
    [ super updateWindow ];
	[self serialNumberChanged:nil];
	[self versionChanged:nil];
	[self isAccelOnlyChanged:nil];
	[self packetLengthChanged:nil];
	[self traceIndexChanged:nil];
	[self nodeRunningChanged:nil];
    [self lockChanged:nil];
	[self temperatureChanged:nil];
	[self dispayComponentsChanged:nil];
}

- (void) dispayComponentsChanged:(NSNotification*)aNote
{
	[displayComponentsMatrix selectCellWithTag: [model displayComponents]];
	[tracePlot setNeedsDisplay:YES];
}

- (void) temperatureChanged:(NSNotification*)aNote
{
	[temperatureField setFloatValue: [model temperature]];
}

- (void) portStateChanged:(NSNotification*)aNotification
{
	[self updateButtons];
}	
	
- (void) nodeRunningChanged:(NSNotification*)aNote
{
	if([model nodeVersion] == 0){
		[nodeRunningField setObjectValue: [model nodeRunning]?@"FLUSHING":@"NO"];
	}
	else {
		[nodeRunningField setObjectValue: [model nodeRunning]?@"YES":@"NO"];
	}
	[self updateButtons];
}

- (void) traceIndexChanged:(NSNotification*)aNote
{
	[tracePlot setNeedsDisplay:YES];
}

- (void) packetLengthChanged:(NSNotification*)aNote
{
	[packetLengthField setIntValue: [model packetLength]];
}

- (void) isAccelOnlyChanged:(NSNotification*)aNote
{
	[isAccelOnlyField setStringValue: [model isAccelOnly]?@"Acc":@"Full"];
}

- (void) versionChanged:(NSNotification*)aNote
{
	[versionField setIntValue: [model nodeVersion]];
	[self updateButtons];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORMotionNodeModelLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) updateButtons
{
    BOOL locked		= [gSecurity isLocked:ORMotionNodeModelLock];
	BOOL portOpen	= [[model serialPort] isOpen];
	BOOL nodeRunning = [model nodeRunning];
	BOOL nodeValid = ([model nodeVersion] != 0);
    [lockButton setState: locked];
	[startButton setEnabled: portOpen && !locked && !nodeRunning && nodeValid];
	[stopButton setEnabled: portOpen && !locked && nodeRunning && nodeValid];
	
	[serialPortController updateButtons:locked];
}

- (void) lockChanged:(NSNotification*)aNote
{
	[self updateButtons];
}

- (void) serialNumberChanged:(NSNotification*)aNote
{
	[[self window] setTitle:[model title]];
}

- (BOOL) portLocked
{
	return [gSecurity isLocked:ORMotionNodeModelLock];
}

#pragma mark •••Actions
- (IBAction) displayComponentsAction:(id)sender
{
	[model setDisplayComponents:[[displayComponentsMatrix selectedCell] tag]];
	if([model displayComponents]){
		[xLabel setStringValue:@"Ax"];
		[yLabel setStringValue:@"Ay"];
		[zLabel setStringValue:@"Az"];
	}
	else {
		[xLabel setStringValue:@"1-Total"];
		[yLabel setStringValue:@""];
		[zLabel setStringValue:@""];
	}
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORMotionNodeModelLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) readOnboardMemory:(id)sender
{
	[model readOnboardMemory];
}
- (IBAction) readConnect:(id)sender
{
	[model readConnect];
}
- (IBAction) start:(id)sender
{
	[model startDevice];
}
- (IBAction) stop:(id)sender
{
	[model stopDevice];
}

- (int)	numberOfDataSetsInPlot:(id)aPlotter
{
	return 4;
}

- (int)	numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
	if([model displayComponents]){
		if(set == 3) return 0;
		else return kModeNodeTraceLength;
	}
	else {
		if(set < 3) return 0;
		else return kModeNodeTraceLength;

	}
}

- (float)  	plotter:(id) aPlotter dataSet:(int)set dataValue:(int) i 
{
	if(set == 0)		return [model axAt:i];
	else if(set == 1)	return [model ayAt:i];
	else if(set == 2)	return [model azAt:i];
	else if(set == 3)	return [model totalxyzAt:i];
	return 0;
}

@end

