//
//  ORDetectorRamper.m
//  Orca
//
//  Created by Mark Howe on Friday May 25,2012
//  Copyright (c) 2012 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORDetectorRamper.h"
#import "ORAlarm.h"

NSString* ORDetectorRamperStepWaitChanged				= @"ORDetectorRamperStepWaitChanged";
NSString* ORDetectorRamperLowVoltageWaitChanged			= @"ORDetectorRamperLowVoltageWaitChanged";
NSString* ORDetectorRamperLowVoltageThresholdChanged	= @"ORDetectorRamperLowVoltageThresholdChanged";
NSString* ORDetectorRamperLowVoltageStepChanged			= @"ORDetectorRamperLowVoltageStepChanged";
NSString* ORDetectorRamperMaxVoltageChanged				= @"ORDetectorRamperMaxVoltageChanged";
NSString* ORDetectorRamperMinVoltageChanged				= @"ORDetectorRamperMinVoltageChanged";
NSString* ORDetectorRamperVoltageStepChanged			= @"ORDetectorRamperVoltageStepChanged";
NSString* ORDetectorRamperEnabledChanged				= @"ORDetectorRamperEnabledChanged";
NSString* ORDetectorRamperStateChanged					= @"ORDetectorRamperStateChanged";
NSString* ORDetectorRamperRunningChanged				= @"ORDetectorRamperRunningChanged";

@interface ORDetectorRamper (private)
- (void) setRunning:(BOOL)aValue;
- (void) execute;
- (void) setState:(int)aValue;
@end

@implementation ORDetectorRamper

@synthesize delegate, channel, stepWait, lowVoltageThreshold, enabled, state;
@synthesize voltageStep, lowVoltageWait, lowVoltageStep, maxVoltage, minVoltage;
@synthesize lastStepWaitTime, running, target, lastVoltageWaitTime;

#define kTolerance				2 //Volts

#define kDetRamperIdle                  0
#define kDetRamperStartRamp				1
#define kDetRamperEmergencyOff			2
#define kDetRamperStepWaitForVoltage	3
#define kDetRamperStepToNextVoltage		4
#define kDetRamperStepWait              5
#define kDetRamperDone                  6
#define kDetRamperNoChangeError         7


- (id) initWithDelegate:(OrcaObject*)aDelegate channel:(int)aChannel
{
	self = [super init];
	if([aDelegate respondsToSelector:@selector(hwGoal:)]  &&
	   [aDelegate respondsToSelector:@selector(voltage:)] &&
	   [aDelegate respondsToSelector:@selector(isOn:)]){
			self.delegate = aDelegate;
	}
	self.channel = aChannel;
	return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	self.lastStepWaitTime = nil;
	self.lastVoltageWaitTime = nil;
	[rampFailedAlarm clearAlarm];
	[rampFailedAlarm release];
	[super dealloc];
}

- (NSUndoManager*) undoManager
{
    return [[NSApp delegate] undoManager];
}

- (void) setStepWait:(short)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStepWait:stepWait];
	stepWait = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperStepWaitChanged object:delegate];
}

- (void) setLowVoltageWait:(short)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLowVoltageWait:lowVoltageWait];
	lowVoltageWait = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperLowVoltageWaitChanged object:delegate];
}

- (void) setLowVoltageThreshold:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLowVoltageThreshold:lowVoltageThreshold];
	lowVoltageThreshold = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperLowVoltageThresholdChanged object:delegate];
}

- (void) setLowVoltageStep:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLowVoltageStep:lowVoltageStep];
	lowVoltageStep = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperLowVoltageStepChanged object:delegate];
}

- (void) setMaxVoltage:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMaxVoltage:maxVoltage];
	maxVoltage = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperMaxVoltageChanged object:delegate];
}

- (void) setMinVoltage:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMinVoltage:minVoltage];
	minVoltage = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperMinVoltageChanged object:delegate];
}

- (void) setVoltageStep:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVoltageStep:voltageStep];
	voltageStep = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperVoltageStepChanged object:delegate];
}

- (void) setEnabled:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnabled:enabled];
	enabled = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperEnabledChanged object:delegate];
}

- (void) setTarget:(int)aTarget    
{
    if(aTarget > maxVoltage)      target = maxVoltage;
    else if(aTarget < minVoltage) target = minVoltage;
    else                          target = aTarget;
}

- (BOOL) atIntermediateGoal
{
	int v1 = [delegate hwGoal:channel];
	int v2 = [delegate voltage:channel];
	int diff = abs(v2 - v1);
	return diff < kTolerance;
}

- (BOOL) atTarget
{
	return abs([delegate voltage:channel] - target) < kTolerance;
}

- (int) stepSize
{
    if([delegate voltage:channel]<lowVoltageThreshold)return lowVoltageStep;
    else return voltageStep;
}

- (short) timeToWait
{
    if([delegate voltage:channel]<lowVoltageThreshold)return lowVoltageWait;
    else return stepWait;    
}

- (int) nextVoltage
{
	int currentVoltage = [delegate voltage:channel];
    if(currentVoltage <= target){
        return MIN(maxVoltage,MIN(currentVoltage+[self stepSize],target));  
    }
    else {
       return MAX(minVoltage,MAX(currentVoltage-[self stepSize],target));
    }
}

- (void) startRamping
{
	if(![self atTarget]){
		if(!running) {
			if([delegate isOn:channel]){
				[NSObject cancelPreviousPerformRequestsWithTarget:self];
				self.running = YES;
				self.state = kDetRamperStartRamp;
				[self performSelector:@selector(execute) withObject:nil afterDelay:1.0];
			}
			else NSLog(@"%@ channel %d not on. HV ramp not started.\n",[delegate fullID],channel);
		}
		else NSLog(@"%@ HV already ramping.\n",[delegate fullID]);
	}
	else NSLog(@"%@ HV already at %.2f.\n",[delegate fullID],[delegate voltage:channel]);

}

- (void) emergencyOff
{
	if([delegate isOn:channel]){
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
		self.running = YES;
		self.state = kDetRamperEmergencyOff;
		[self performSelector:@selector(execute) withObject:nil afterDelay:1.0];
	}
    else NSLog(@"%@ channel %d not on. EmergencyOff not executed.\n",[delegate fullID],channel);
}

- (void) stopRamping
{
	self.state = kDetRamperDone;
	self.running = NO;
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (NSString*) stateString
{
	if(!enabled)return @"--";
	else switch(state){
		case kDetRamperIdle:                return @"Idle";
		case kDetRamperStartRamp:           return @"Starting";
		case kDetRamperEmergencyOff:        return @"EmergencyOff";
		case kDetRamperStepWaitForVoltage:  return @"Waiting on Voltage";
		case kDetRamperStepToNextVoltage:   return @"Stepping";
		case kDetRamperStepWait:            return @"Waiting at Step";
		case kDetRamperDone:                return @"Done";    
		case kDetRamperNoChangeError:       return @"Ramp Failed";    
		default:                            return @"?";
	}
}

- (NSString*) hwGoalString
{
	if(!enabled)return @"--";
	else switch(state){
		case kDetRamperIdle:                return @"Idle";
		case kDetRamperStartRamp:           return @"Starting";
		case kDetRamperEmergencyOff:        return @"EmergencyOff";
		case kDetRamperStepWaitForVoltage:  return [NSString stringWithFormat:@"Waiting for %d",[delegate hwGoal:channel]];
		case kDetRamperStepToNextVoltage:   return @"Stepping";
		case kDetRamperStepWait:            return [NSString stringWithFormat:@"Waiting at %d",[delegate hwGoal:channel]];
		case kDetRamperDone:                return @"At Target";    
		case kDetRamperNoChangeError:       return @"Failed";    
		default:                            return @"?";
	}
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
			
	[self setChannel:				[decoder decodeIntForKey: @"channel"]];
	[self setStepWait:				[decoder decodeIntForKey: @"stepWait"]];
    [self setLowVoltageWait:		[decoder decodeIntForKey: @"lowVoltageWait"]];
    [self setLowVoltageThreshold:	[decoder decodeIntForKey: @"lowVoltageThreshold"]];
    [self setLowVoltageStep:		[decoder decodeIntForKey: @"lowVoltageStep"]];
    [self setMaxVoltage:			[decoder decodeIntForKey: @"maxVoltage"]];
    [self setMinVoltage:			[decoder decodeIntForKey: @"minVoltage"]];
    [self setVoltageStep:			[decoder decodeIntForKey: @"voltageStep"]];
    [self setEnabled:				[decoder decodeBoolForKey:@"enabled"]];
	
 	[[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{	
	[encoder encodeInt:channel              forKey:@"channel"];
	[encoder encodeInt:stepWait             forKey:@"stepWait"];
	[encoder encodeInt:lowVoltageWait		forKey:@"lowVoltageWait"];
	[encoder encodeInt:lowVoltageThreshold	forKey:@"lowVoltageThreshold"];
	[encoder encodeInt:lowVoltageStep		forKey:@"lowVoltageStep"];
	[encoder encodeInt:maxVoltage			forKey:@"maxVoltage"];
	[encoder encodeInt:minVoltage			forKey:@"minVoltage"];
	[encoder encodeInt:voltageStep			forKey:@"voltageStep"];
	[encoder encodeBool:enabled				forKey:@"enabled"];
}
@end

@implementation ORDetectorRamper (private)

- (void) execute
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	if(!enabled)                 return;	//must be enabled
	if(![delegate isOn:channel]) return;	//channel must be on
	
	[self performSelector:@selector(execute) withObject:nil afterDelay:1.0];
			
	switch (state) {
			
		case kDetRamperStartRamp:
            self.target = [delegate target:channel];
            self.state  = kDetRamperStepToNextVoltage;
        break;
			
		case kDetRamperEmergencyOff:
            self.target = 0;
            self.state  = kDetRamperStepToNextVoltage;			
		break;
												
		case kDetRamperStepToNextVoltage:
            if([self atTarget])                self.state = kDetRamperDone;
			else {
				[delegate setHwGoal:channel withValue:[self nextVoltage]];
				[delegate writeVoltage:channel];
				self.state = kDetRamperStepWaitForVoltage;	
			}
        break;
            
        case kDetRamperStepWaitForVoltage:
			if(lastVoltageWaitTime) {
				if([[NSDate date] timeIntervalSinceDate:lastVoltageWaitTime] >= 60){
					NSLog(@"%@ channel %d not ramping.\n",[delegate fullID],channel);
					self.state = kDetRamperNoChangeError;
				}
				else {
					if([self atTarget])                self.state = kDetRamperDone;
					else if([self atIntermediateGoal]) self.state = kDetRamperStepWait;
				}
			}
			else {
				self.lastVoltageWaitTime = [NSDate date];
                [self execute];
			}
        break;

        case kDetRamperStepWait:
			if(lastStepWaitTime) {
				if([[NSDate date] timeIntervalSinceDate:lastStepWaitTime] >= [self timeToWait]){
					self.lastStepWaitTime = nil;
					self.state	          = kDetRamperStepToNextVoltage;
				}
			}
            else {
                self.lastStepWaitTime = [NSDate date];
                [self execute];
            }
        break;
            
		case kDetRamperDone:
			self.running = NO;
			[NSObject cancelPreviousPerformRequestsWithTarget:self];
        break;
			
		case kDetRamperNoChangeError:
			self.running = NO;
			
			if(!rampFailedAlarm){
				NSString* s = [NSString stringWithFormat:@"%@,%d Ramp Failed",[delegate fullID],channel];
				rampFailedAlarm = [[ORAlarm alloc] initWithName:s severity:3];
				[rampFailedAlarm setSticky:NO];
				[rampFailedAlarm setHelpString:@"There was no change in the HV voltage during ramping. The ramping process was flagged as failed. Check the channel manually. Acknowledge the alarm to clear it."];
			}                      
			[rampFailedAlarm setAcknowledged:NO];
			[rampFailedAlarm postAlarm];
			
			[NSObject cancelPreviousPerformRequestsWithTarget:self];
		break;
	}
}

- (void) setRunning:(BOOL)aValue
{
	running = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperRunningChanged object:delegate];
}

- (void) setState:(int)aValue
{
	state = aValue;
	
	//reset timers as needed.
	if(state == kDetRamperStepWait)					self.lastStepWaitTime = nil;
	else if(state == kDetRamperStepWaitForVoltage)	self.lastVoltageWaitTime = nil;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperStateChanged object:delegate];
}
@end