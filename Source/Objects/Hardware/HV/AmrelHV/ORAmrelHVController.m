//
//  ORAmrelHVController.m
//  Orca
//
//  Created by Mark Howe on Thursday, Aug 20,2009
//  Copyright (c) 2009 Univerisy of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the Univerisy of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the Univerisy of North 
//Carolina reserve all rights in the program. Neither the authors,
//Univerisy of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORAmrelHVController.h"
#import "ORAmrelHVModel.h"
#import "ORSerialPortList.h"
#import "ORSerialPort.h"

@interface ORAmrelHVController (private)
- (void) populatePortListPopup;
@end

@implementation ORAmrelHVController
- (id) init
{
    self = [ super initWithWindowNibName: @"AmrelHV" ];
    return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (void) awakeFromNib
{
    [self populatePortListPopup];

    oneChannelSize	= NSMakeSize(523,400);
    twoChannelSize	= NSMakeSize(523,636);
		
	[super awakeFromNib];
}

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
						 name : ORAmrelHVLock
						object: nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(setVoltageChanged:)
						 name : ORAmrelHVSetVoltageChanged
						object: model];
	
	[notifyCenter addObserver : self
					 selector : @selector(actVoltageChanged:)
						 name : ORAmrelHVActVoltageChanged
						object: model];
	
	[notifyCenter addObserver : self
					 selector : @selector(pollTimeChanged:)
						 name : ORAmrelHVPollTimeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(actCurrentChanged:)
                         name : ORAmrelHVActCurrentChanged
						object: model];	
	
    [notifyCenter addObserver : self
                     selector : @selector(portNameChanged:)
                         name : ORAmrelHVModelPortNameChanged
                        object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(portStateChanged:)
                         name : ORSerialPortStateChanged
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(numberOfChannelsChanged:)
                         name : ORAmrelHVModelNumberOfChannelsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(outputStateChanged:)
                         name : ORAmrelHVModelOutputStateChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(rampRateChanged:)
                         name : ORAmrelHVModelRampRateChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(rampEnabledChanged:)
                         name : ORAmrelHVModelRampEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(rampStateChanged:)
                         name : ORAmrelHVModelRampStateChanged
						object: model];
    [notifyCenter addObserver : self
                     selector : @selector(timedOut:)
                         name : ORAmrelHVModelTimeout
						object: model];
}

- (void) updateWindow
{
    [ super updateWindow ];
    [self lockChanged:nil];
	[self portStateChanged:nil];
    [self portNameChanged:nil];
	[self setVoltageChanged:nil];
	[self actVoltageChanged:nil];
	[self actCurrentChanged:nil];
	[self pollTimeChanged:nil];
	[self numberOfChannelsChanged:nil];
	[self outputStateChanged:nil];
	[self polarityChanged:nil];
	[self rampRateChanged:nil];
	[self rampEnabledChanged:nil];
	[self rampStateChanged:nil];
	[self updateButtons];
}

- (void) timedOut:(NSNotification*)aNote
{
	[timeoutField setStringValue:@"Time Out"];
}

- (void) rampStateChanged:(NSNotification*)aNote
{
	[rampStateAField setIntValue: [model rampState:0]];
	[rampStateBField setIntValue: [model rampState:1]];
	if(aNote) {
		[self updateChannelButtons:0];
		[self updateChannelButtons:1];
	}
}

- (void) rampEnabledChanged:(NSNotification*)aNote
{
	[rampEnabledACB setIntValue: [model rampEnabled:0]];
	[rampEnabledBCB setIntValue: [model rampEnabled:1]];
	if(aNote)[self updateButtons];
}

- (void) outputStateChanged:(NSNotification*)aNote
{
	if([model outputState:0])	[hvPowerAField setStringValue:@"On"];
	else						[hvPowerAField setStringValue:@"Off"];
	
	if([model outputState:1])	[hvPowerBField setStringValue:@"On"];
	else						[hvPowerBField setStringValue:@"Off"];
	
	[self performSelector:@selector(updateChannels) withObject:nil afterDelay:0];
	[self performSelector:@selector(updateButtons) withObject:nil afterDelay:0];
}

- (void) numberOfChannelsChanged:(NSNotification*)aNote
{
	[numberOfChannelsPU selectItemAtIndex: [model numberOfChannels]-1];
	[self adjustWindowSize];
}

- (void) rampRateChanged:(NSNotification*)aNote
{
	[rampRateAField setFloatValue:[model rampRate:0]];
	[rampRateBField setFloatValue:[model rampRate:1]];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
}

- (void) portStateChanged:(NSNotification*)aNote
{
    if(aNote == nil || [aNote object] == [model serialPort]){
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
		if(aNote)[self updateButtons];
    }
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

- (void) setVoltageChanged:(NSNotification*)aNote
{
	[setVoltageAField setFloatValue:[model voltage:0]];
	[setVoltageBField setFloatValue:[model voltage:1]];
}

- (void) actVoltageChanged:(NSNotification*)aNote
{
	[actVoltageAField setFloatValue:[model actVoltage:0]];
	[actVoltageBField setFloatValue:[model actVoltage:1]];
	[self updateChannelButtons:0];
	[self updateChannelButtons:1];
}

- (void) polarityChanged:(NSNotification*)aNote
{
	[polarityAPU selectItemAtIndex:[model polarity:0]];
	[polarityBPU selectItemAtIndex:[model polarity:1]];
}

- (void) actCurrentChanged:(NSNotification*)aNote
{
	[actCurrentAField setFloatValue:[model actCurrent:0]];
	[actCurrentBField setFloatValue:[model actCurrent:1]];
}

- (void)adjustWindowSize
{
    switch([model numberOfChannels]){
        case  1: [self resizeWindowToSize:oneChannelSize];    break;
		case  2: [self resizeWindowToSize:twoChannelSize];	  break;
    }
}


- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORAmrelHVLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNotification
{
	[self updateButtons];
}

- (void) pollTimeChanged:(NSNotification*)aNote
{
	[pollTimePopup selectItemWithTag: [model pollTime]];
	if([model pollTime])[pollingProgress startAnimation:self];
	else [pollingProgress stopAnimation:self];
}

#pragma mark •••Notifications

- (void) updateButtons
{
    //BOOL runInProgress  = [gOrcaGlobals runInProgress];
    BOOL locked			= [gSecurity isLocked:ORAmrelHVLock];
    BOOL portOpen		= [[model serialPort] isOpen];

    [lockButton setState: locked];
	
	if([model channelIsValid:0]){
		[pollTimePopup		setEnabled: !locked && portOpen];
		[pollNowButton		setEnabled: !locked && portOpen];
		[polarityAPU		setEnabled: !locked && portOpen];
		[setVoltageAField	setEnabled: !locked && portOpen];
		[maxCurrentAField	setEnabled: !locked && portOpen];
		[loadValuesAButton	setEnabled: !locked && portOpen];
		[rampRateAField		setEnabled: !locked && portOpen && [model rampEnabled:0]];
		if([model rampEnabled:0])[setVoltageLabelA setStringValue:@"Ramp To:"];
		else					 [setVoltageLabelA setStringValue:@"Set To:"];
		if([model outputState:0]) [hvPowerAButton setTitle:@"Turn Off"];
		else					  [hvPowerAButton setTitle:@"Turn On"];
		[self updateChannelButtons:0];
	}
	
	if([model channelIsValid:1]){
		[polarityBPU		setEnabled: !locked && portOpen];
		[setVoltageBField	setEnabled: !locked && portOpen];
		[maxCurrentBField	setEnabled: !locked && portOpen];
		[loadValuesBButton	setEnabled: !locked && portOpen];
		[rampRateBField		setEnabled: !locked && portOpen && [model rampEnabled:1]];
		if([model rampEnabled:1])[setVoltageLabelB setStringValue:@"Ramp To:"];
		else					 [setVoltageLabelB setStringValue:@"Set To:"];
		if([model outputState:1]) [hvPowerBButton setTitle:@"Turn Off"];
		else					  [hvPowerBButton setTitle:@"Turn On"];
		[self updateChannelButtons:1];
	}
	
	[moduleIDButton		setEnabled: !locked && portOpen];
	[syncButton 	    setEnabled: !locked && portOpen];
}

- (void) updateChannels
{
	[self updateChannelButtons:0];
	[self updateChannelButtons:1];
}

- (void) updateChannelButtons:(int)i
{
	BOOL locked				= [gSecurity isLocked:ORAmrelHVLock];
	BOOL portOpen			= [[model serialPort] isOpen];
	BOOL OKForPowerEnable	= !locked && portOpen;
	
	if([model channelIsValid:i]){
		if([model outputState:i]){
			//power is on. power can only be turned off if act voltage low
			OKForPowerEnable &= ([model actVoltage:i]<1);
		}
		NSImageView* theImageView = ((i==0) ? hvStateAImage:hvStateBImage);
		if(![model outputState:i])[theImageView setImage:nil];
		else {
			if([model rampState:i] == kAmrelHVNotRamping){
				if([model actVoltage:i]<1) {
					[theImageView setImage:nil];
				}
				else if([model actVoltage:i]>1 && [model actVoltage:i]<99){
					[theImageView setImage:[NSImage imageNamed:@"lowVoltage"]];
				}
				else {
					[theImageView setImage:[NSImage imageNamed:@"highVoltage"]];
				}
			}
			else if([model rampState:i] == kAmrelHVRampingUp){
				[theImageView setImage:[NSImage imageNamed:@"upRamp"]];
			}
			else if([model rampState:i] == kAmrelHVRampingDn){
				[theImageView setImage:[NSImage imageNamed:@"downRamp"]];
			}
		}
		NSButton* powerButton = (i==0?hvPowerAButton:hvPowerBButton);
		[powerButton setEnabled: OKForPowerEnable];
		
		if(i==0){
			[stopAButton		setEnabled: !locked && portOpen && [model rampState:0]!=kAmrelHVNotRamping];
			[rampEnabledACB		setEnabled: !locked && portOpen && [model rampState:1]==kAmrelHVNotRamping];
			[panicAButton		setEnabled: !locked && portOpen && ([model actVoltage:0]>0)];
		}
		else if(i==1){
			[stopBButton		setEnabled: !locked && portOpen && [model rampState:1]!=kAmrelHVNotRamping];
			[rampEnabledBCB		setEnabled: !locked && portOpen && [model rampState:1]==kAmrelHVNotRamping];
			[panicBButton		setEnabled: !locked && portOpen && ([model actVoltage:1]>0)];
		}
	}

	[systemPanicBButton setEnabled: !locked && portOpen && ([model actVoltage:0]>0) || [model actVoltage:1]>0];
		
}

- (NSString*) windowNibName
{
	return @"AmrelHV";
}

- (NSString*) rampItemNibFileName
{
	//subclasses can specify a differant RampItem nib file if needed.
	return @"HVRampItem";
}

#pragma mark •••Actions
- (IBAction) rampEnabledAction:(id)sender
{
	[model setRampEnabled:[sender tag] withValue:[sender intValue]];	
}

- (IBAction) rateRateAction:(id)sender
{
	[model setRampRate:[sender tag] withValue:[sender intValue]];	
}

- (IBAction) numberOfChannelsAction:(id)sender
{
	[model setNumberOfChannels:[sender indexOfSelectedItem]+1];	
}

- (IBAction) polarityAction:(id)sender
{
	[model setPolarity:[sender tag] withValue:[sender indexOfSelectedItem]];	
}

- (IBAction) setVoltageAction:(id)sender
{
	[model setVoltage:[sender tag] withValue:[sender floatValue]];
}

- (IBAction) pollTimeAction:(id)sender
{
	[model setPollTime:[[sender selectedItem] tag]];	
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORAmrelHVLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) loadAllValues:(id)sender
{
	[self endEditing];
	[model loadHardware:[sender tag]];
}

- (IBAction) stopRampAction:(id)sender
{
	[model stopRamp:[sender tag]];
}

- (IBAction) panicAction:(id)sender
{
	[model panicToZero:[sender tag]];
}

- (IBAction) systemPanicAction:(id)sender
{
	[model panicToZero:0xFFFF];
}

- (IBAction) portListAction:(id) sender
{
    [model setPortName: [portListPopup titleOfSelectedItem]];
}

- (IBAction) openPortAction:(id)sender
{
    [model openPort:![[model serialPort] isOpen]];
}

- (IBAction) hwPowerAction:(id)sender
{
	[self endEditing];
    [model setOutputState:[sender tag] withValue:![model outputState:[sender tag]]];
	[model loadHardware:[sender tag]];
}

- (IBAction) pollNowAction:(id)sender
{
	[model getAllValues];
}

- (IBAction) moduleIDAction:(id)sender
{
	[model getID];
}

- (IBAction) syncAction:(id)sender
{
	[model syncDialog];

}

@end

@implementation ORAmrelHVController (private)

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


