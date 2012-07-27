//--------------------------------------------------------
// ORSerialPortWithQueueModel.m
// Created by Mark  A. Howe on Wed 4/15/2009
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

#import "ORSerialPortWithQueueModel.h"
#import "ORSafeQueue.h"
#import "ORSerialPort.h"
#import "ORAlarm.h"

#pragma mark •••External Strings
NSString* ORSerialPortWithQueueModelIsValidChanged			= @"ORSerialPortWithQueueModelIsValidChanged";
NSString* ORSerialPortWithQueueModelPortClosedAfterTimeout	= @"ORSerialPortWithQueueModelPortClosedAfterTimeout";

@implementation ORSerialPortWithQueueModel

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	[cmdQueue release];
	[lastRequest release];
	[timeoutAlarm clearAlarm];
	[timeoutAlarm release];
	[super dealloc];
}

#pragma mark •••Accessors
- (id) lastRequest
{
	return lastRequest;
}

- (void) setLastRequest:(id)aCmd
{
	[aCmd retain];
	[lastRequest release];
	lastRequest = aCmd;    
}

- (BOOL) isValid
{
	if([serialPort isOpen] && isValid) return YES;
	else return NO;
}

- (void) setIsValid:(BOOL)aState
{
	if(isValid!=aState){
		isValid = aState;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORSerialPortWithQueueModelIsValidChanged object:self];		
	}
	
	if(isValid){
		timeoutCount=0;
		[self clearTimeoutAlarm];
	}
}

#pragma mark •••Cmd Handling
- (id) nextCmd
{
	return [cmdQueue dequeue];
}

- (void) enqueueCmd:(id)aCmd
{
    if([serialPort isOpen]){ 
		if(!cmdQueue)cmdQueue = [[ORSafeQueue alloc] init];
		[cmdQueue enqueue:aCmd];	
	}
}

- (void) cancelTimeout
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
}

- (void) startTimeout:(int)aDelay
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	[self performSelector:@selector(timeout) withObject:nil afterDelay:aDelay];
}
- (void) openPort:(BOOL)aState
{
	if(!aState){
		[self cancelTimeout];
		[self setIsValid:NO];
		[cmdQueue removeAllObjects];
		[self setLastRequest:nil];
		[self clearTimeoutAlarm];
	}
	
	[super openPort:aState];
}

- (void) timeout
{
	timeoutCount++;
	if(timeoutCount>10){
		[self postTimeoutAlarm];
	}
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	NSLogError(@"command timeout",[self fullID],nil);
	[self setIsValid:NO];
	[cmdQueue removeAllObjects];
	[self setLastRequest:nil];
	if([serialPort isOpen]){
		[self recoverFromTimeout];
	}
}

- (void) recoverFromTimeout
{
}

- (void) clearTimeoutAlarm
{
	[timeoutAlarm clearAlarm];
	[timeoutAlarm release];
	timeoutAlarm = nil;
}

- (void) postTimeoutAlarm
{
	if(!timeoutAlarm){
		NSString* alarmName = [NSString stringWithFormat:@"%@ Serial Port Timeout",[self fullID]];
		timeoutAlarm = [[ORAlarm alloc] initWithName:alarmName severity:kHardwareAlarm];
		[timeoutAlarm setSticky:NO];
		[timeoutAlarm setHelpString:@"The serial port is not working. The port was closed. Acknowledging this alarm will clear it. You will need to reopen the serial port to try again."];
		[serialPort close];
		[cmdQueue removeAllObjects];
		[self setLastRequest:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORSerialPortWithQueueModelPortClosedAfterTimeout object:self];		
	}
	[timeoutAlarm postAlarm];
}

@end
