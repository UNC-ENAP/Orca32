//--------------------------------------------------------
// ORTPG256AController
//  Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
//  Created by Mark Howe on Mon Apr 16 2012.
//  Copyright 2012  University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
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

#import "ORTPG256AController.h"
#import "ORTPG256AModel.h"
#import "ORTimeLinePlot.h"
#import "ORCompositePlotView.h"
#import "ORTimeAxis.h"
#import "ORSerialPortList.h"
#import "ORSerialPort.h"
#import "ORTimeRate.h"

@interface ORTPG256AController (private)
- (void) populatePortListPopup;
@end

@implementation ORTPG256AController

#pragma mark ***Initialization

- (id) init
{
	self = [super initWithWindowNibName:@"TPG256A"];
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
    [[plotter0 yAxis] setRngLow:0.0 withHigh:1000.];
	[[plotter0 yAxis] setRngLimitsLow:0.0 withHigh:100000 withMinRng:10];

    [[plotter0 xAxis] setRngLow:0.0 withHigh:10000];
	[[plotter0 xAxis] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];

	
	int i;
	for(i=0;i<6;i++){
		ORTimeLinePlot* aPlot;
		aPlot= [[ORTimeLinePlot alloc] initWithTag:i andDataSource:self];
		[plotter0 addPlot: aPlot];
		[aPlot setLineColor:[self colorForDataSet:i]];
		[aPlot setName:[NSString stringWithFormat:@"P%d",i]];
		[(ORTimeAxis*)[plotter0 xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
		[aPlot release];
	}
	[plotter0 setShowLegend:YES];
	[super awakeFromNib];
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
                         name : ORTPG256ALock
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(portNameChanged:)
                         name : ORTPG256AModelPortNameChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(portStateChanged:)
                         name : ORSerialPortStateChanged
                       object : nil];
                                              
    [notifyCenter addObserver : self
                     selector : @selector(pressureChanged:)
                         name : ORTPG256APressureChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(pollTimeChanged:)
                         name : ORTPG256AModelPollTimeChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(shipPressuresChanged:)
                         name : ORTPG256AModelShipPressuresChanged
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
                     selector : @selector(pressureScaleChanged:)
                         name : ORTPG256AModelPressureScaleChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(highLimitChanged:)
                         name : ORTPG256AModelHighLimitChanged
						object: model];	
	
    [notifyCenter addObserver : self
                     selector : @selector(highAlarmChanged:)
                         name : ORTPG256AModelHighAlarmChanged
						object: model];	
	
    [notifyCenter addObserver : self
                     selector : @selector(unitsChanged:)
                         name : ORTPG256AModelUnitsChanged
						object: model];

}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"TPG256A (Unit %d)",[model uniqueIdNumber]]];
}

- (void) updateWindow
{
    [super updateWindow];
    [self lockChanged:nil];
    [self portStateChanged:nil];
    [self portNameChanged:nil];
	[self pressureChanged:nil];
	[self pollTimeChanged:nil];
	[self shipPressuresChanged:nil];
	[self updateTimePlot:nil];
    [self miscAttributesChanged:nil];
	[self pressureScaleChanged:nil];
	[self highLimitChanged:nil];
	[self highAlarmChanged:nil];
	[self unitsChanged:nil];
}

- (void) unitsChanged:(NSNotification*)aNote
{
	[unitsPU selectItemAtIndex: [(ORTPG256AModel*)model units]];
}

- (void) highLimitChanged:(NSNotification*)aNote
{
	[processLimitTableView reloadData];
}

- (void) highAlarmChanged:(NSNotification*)aNote
{
	[processLimitTableView reloadData];
}


- (void) pressureScaleChanged:(NSNotification*)aNote
{
	[pressureScalePU selectItemAtIndex: [model pressureScale]];
	[plotter0 setNeedsDisplay:YES];
}

- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [plotter0 xAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter0 xAxis]attributes] forKey:@"XAttributes0"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter0 yAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter0 yAxis]attributes] forKey:@"YAttributes0"];
	};

}

- (void) miscAttributesChanged:(NSNotification*)aNote
{

	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"XAttributes0"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes0"];
		if(attrib){
			[(ORAxis*)[plotter0 xAxis] setAttributes:attrib];
			[plotter0 setNeedsDisplay:YES];
			[[plotter0 xAxis] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"YAttributes0"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes0"];
		if(attrib){
			[(ORAxis*)[plotter0 yAxis] setAttributes:attrib];
			[plotter0 setNeedsDisplay:YES];
			[[plotter0 yAxis] setNeedsDisplay:YES];
		}
	}

}

- (void) updateTimePlot:(NSNotification*)aNote
{
	if(!aNote || ([aNote object] == [model timeRate:0])){
		[plotter0 setNeedsDisplay:YES];
	}
}

- (void) shipPressuresChanged:(NSNotification*)aNote
{
	[shipPressuresButton setIntValue: [model shipPressures]];
}

- (void) pressureChanged:(NSNotification*)aNote
{
	[pressureTableView reloadData];
}


- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORTPG256ALock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNotification
{

    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORTPG256ALock];
    BOOL locked = [gSecurity isLocked:ORTPG256ALock];

    [lockButton setState: locked];

    [portListPopup	setEnabled:!locked];
    [openPortButton setEnabled:!locked];
    [pollTimePopup	setEnabled:!locked];
    [unitsPU		setEnabled:!locked];
    [shipPressuresButton setEnabled:!locked];
    
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:ORTPG256ALock])s = @"Not in Maintenance Run.";
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

- (void) unitsAction:(id)sender
{
	[model setUnits:[sender indexOfSelectedItem]];	
	[model sendUnits];
}

- (void) pressureScaleAction:(id)sender
{
	[model setPressureScale:[sender indexOfSelectedItem]];	
}

- (void) shipPressuresAction:(id)sender
{
	[model setShipPressures:[sender intValue]];	
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORTPG256ALock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) portListAction:(id) sender
{
    [model setPortName: [portListPopup titleOfSelectedItem]];
}

- (IBAction) openPortAction:(id)sender
{
    [model openPort:![[model serialPort] isOpen]];
}

- (IBAction) readPressuresAction:(id)sender
{
	[model readPressures];
}

- (IBAction) pollTimeAction:(id)sender
{
	[model setPollTime:[[sender selectedItem] tag]];
}


#pragma mark •••Plotter Data Source

- (NSColor*) colorForDataSet:(int)set
{
	if(set==0)      return [NSColor redColor];
	else if(set==1) return [NSColor orangeColor];
	else if(set==2) return [NSColor blueColor];
	else if(set==3) return [NSColor greenColor];
	else if(set==4) return [NSColor blackColor];
	else if(set==5) return [NSColor purpleColor];
	else            return [NSColor blackColor];
}

- (int) numberPointsInPlot:(id)aPlotter
{
	int set = [aPlotter tag];
	return [[model timeRate:set] count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
	int set = [aPlotter tag];
	int count = [[model timeRate:set] count];
	int index = count-i-1;
	*xValue = [[model timeRate:set] timeSampledAtIndex:index];
	*yValue = [[model timeRate:set] valueAtIndex:index] * [model pressureScaleValue];
}

#pragma mark •••Table Data Source
- (int) numberOfRowsInTableView:(NSTableView *)aTableView
{
	return 6;
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
	if(aTableView == pressureTableView){
		if(rowIndex < 6){
			if([[aTableColumn identifier] isEqualToString:@"channel"]){
				return [NSNumber numberWithInt:rowIndex];
			}
			else if([[aTableColumn identifier] isEqualToString:@"pressure"]){
				return [self pressureValuesForIndex:rowIndex];
			}
			else if([[aTableColumn identifier] isEqualToString:@"time"]){
				unsigned long theTime = [model timeMeasured:rowIndex];
				NSCalendarDate* theDate;
				if(theTime){
					theDate = [NSCalendarDate dateWithTimeIntervalSince1970:theTime];
					[theDate setCalendarFormat:@"%m/%d %H:%M:%S"];
					return theDate;
				}
				else return @"--";
			}
			else return @"";
		}
		else return @"";
	}
	else if(aTableView == processLimitTableView){
		if([[aTableColumn identifier] isEqualToString:@"channel"]){
			return [NSNumber numberWithInt:rowIndex];
		}
		else if([[aTableColumn identifier] isEqualToString:@"hiLimit"]){
			return [NSString stringWithFormat:@"%.2E",[model highLimit:rowIndex]];
		}
		else if([[aTableColumn identifier] isEqualToString:@"lowLimit"]){
			return [NSString stringWithFormat:@"%.2E",[model lowLimit:rowIndex]];
		}
		else if([[aTableColumn identifier] isEqualToString:@"lowAlarm"]){
			return [NSString stringWithFormat:@"%.2E",[model lowAlarm:rowIndex]];
		}
		else if([[aTableColumn identifier] isEqualToString:@"hiAlarm"]){
			return [NSString stringWithFormat:@"%.2E",[model highAlarm:rowIndex]];
		}
		else return @"";
	}
	else return @"";	
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if(anObject == nil)return;
    
	if(aTableView == processLimitTableView){
		
        if([[aTableColumn identifier] isEqualToString:@"Channel"]) return;
		
        if([[aTableColumn identifier] isEqualToString:@"hiLimit"]){
			[model setHighLimit:rowIndex value:[anObject doubleValue]];
		}
        else if([[aTableColumn identifier] isEqualToString:@"lowLimit"]){
			[model setLowLimit:rowIndex value:[anObject doubleValue]];		
		}
        else if([[aTableColumn identifier] isEqualToString:@"lowAlarm"]){
			[model setLowAlarm:rowIndex value:[anObject doubleValue]];			
		}
        else if([[aTableColumn identifier] isEqualToString:@"hiAlarm"]){
			[model setHighAlarm:rowIndex value:[anObject doubleValue]];				
		}
    }
}

- (NSString*) pressureValuesForIndex:(int)index
{
	int state = [model measurementState:index];
	if(state == kTPG256AMeasurementOK){
		return [NSString stringWithFormat:@"%.2E",[model pressure:index]];
	}
	else if(state == kTPG256AMeasurementUnderRange)	 return @"UnderRange";
	else if(state == kTPG256AMeasurementOverRange)	 return @"OverRange";
	else if(state == kTPG256AMeasurementSensorError) return @"Error";
	else if(state == kTPG256AMeasurementSensorOff)	 return @"OFF";
	else if(state == kTPG256AMeasurementNoSensor)	 return @"No Sensor";
	else if(state == kTPG256AMeasurementIDError)	 return @"ID Err";
	else											 return @"--";
}

@end

@implementation ORTPG256AController (private)
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

