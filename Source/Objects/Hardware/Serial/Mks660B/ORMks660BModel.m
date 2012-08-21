//--------------------------------------------------------
// ORMks660BModel
// Created by Mark Howe on Wednesday, April 25, 2012
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2012 University of North Carolina. All rights reserved.
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

#pragma mark •••Imported Files

#import "ORMks660BModel.h"
#import "ORSerialPort.h"
#import "ORSerialPortAdditions.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORTimeRate.h"

#pragma mark •••External Strings
NSString* ORMks660BModelLowAlarmChanged		= @"ORMks660BModelLowAlarmChanged";
NSString* ORMks660BModelHighLimitChanged	= @"ORMks660BModelHighLimitChanged";
NSString* ORMks660BModelHighAlarmChanged	= @"ORMks660BModelHighAlarmChanged";
NSString* ORMks660BModelFullScaleRBChanged	= @"ORMks660BModelFullScaleRBChanged";
NSString* ORMks660BModelCalibrationNumberChanged = @"ORMks660BModelCalibrationNumberChanged";
NSString* ORMks660BModelLowHysteresisChanged	 = @"ORMks660BModelLowHysteresisChanged";
NSString* ORMks660BModelHighHysteresisChanged	 = @"ORMks660BModelHighHysteresisChanged";
NSString* ORMks660BModelDecimalPtPositionChanged = @"ORMks660BModelDecimalPtPositionChanged";
NSString* ORMks660BShipPressuresChanged		= @"ORMks660BShipPressuresChanged";
NSString* ORMks660BPollTimeChanged			= @"ORMks660BPollTimeChanged";
NSString* ORMks660BPressureChanged			= @"ORMks660BPressureChanged";
NSString* ORMks660BLowSetPointChanged       = @"ORMks660BLowSetPointChanged";
NSString* ORMks660BHighSetPointChanged      = @"ORMks660BHighSetPointChanged";
NSString* ORMks660BInvolvedInProcessChanged = @"ORMks660BInvolvedInProcessChanged";

NSString* ORMks660BLock = @"ORMks660BLock";

@interface ORMks660BModel (private)
- (void) processOneCommandFromQueue;
- (void) process_response:(NSString*)theResponse;
- (BOOL) decodeLowSetPoint:(NSString*)theResponse;
- (BOOL) decodeHighSetPoint:(NSString*)theResponse;
- (BOOL) decodePressure:(NSString*)theResponse;
- (BOOL) decodeFullScale:(NSString*)theResponse;
- (BOOL) decodeHysteresis:(NSString*)theResponse;
@end

@implementation ORMks660BModel

- (void) dealloc
{
    [buffer release];
	[timeRates release];
	[super dealloc];
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"Mks660B.tif"]];
}

- (void) makeMainController
{
	[self linkToController:@"ORMks660BController"];
}

- (NSString*) helpURL
{
	return nil;
}

- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian
{
	return [super acceptsGuardian:aGuardian] || [aGuardian isMemberOfClass:NSClassFromString(@"ORMJDVacuumModel")];
}

- (void) dataReceived:(NSNotification*)note
{
    if([[note userInfo] objectForKey:@"serialPort"] == serialPort){
		[self cancelTimeout];
        NSString* theString = [[[[NSString alloc] initWithData:[[note userInfo] objectForKey:@"data"] 
												      encoding:NSASCIIStringEncoding] autorelease] uppercaseString];

		//the serial port may break the data up into small chunks, so we have to accumulate the chunks until
		//we get a full piece.
        theString = [[theString componentsSeparatedByString:@"\n"] componentsJoinedByString:@""];
        if(!buffer)buffer = [[NSMutableString string] retain];
        [buffer appendString:theString];					
        do {
            NSRange lineRange = [buffer rangeOfString:@"\r"];
            if(lineRange.location!= NSNotFound){
                NSMutableString* theResponse = [[[buffer substringToIndex:lineRange.location+1] mutableCopy] autorelease];
                [buffer deleteCharactersInRange:NSMakeRange(0,lineRange.location+1)];      //take the cmd out of the buffer
				
				[self process_response:theResponse];
    
				[self setLastRequest:nil];			 //clear the last request
				[self processOneCommandFromQueue];	 //do the next command in the queue
            }
        } while([buffer rangeOfString:@"\r\n"].location!= NSNotFound);
	}
}


- (void) shipPressureValues
{
    if([[ORGlobal sharedGlobal] runInProgress]){
		
		unsigned long data[4];
		data[0] = dataId | 4;
		data[1] = (([self decimalPtPosition]&0xf)<<16) | ([self uniqueIdNumber]&0xfff);

		union {
			float asFloat;
			unsigned long asLong;
		}theData;
		
		theData.asFloat = pressure;
		data[2] = theData.asLong;			
		data[3] = timeMeasured;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
															object:[NSData dataWithBytes:data length:sizeof(long)*4]];
	}
}

#pragma mark •••Accessors
- (BOOL) involvedInProcess
{
    return involvedInProcess;
}

- (void) setInvolvedInProcess:(BOOL)aInvolvedInProcess
{
    involvedInProcess = aInvolvedInProcess;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMks660BInvolvedInProcessChanged object:self];
}

- (float) lowAlarm
{
    return lowAlarm;
}

- (void) setLowAlarm:(float)aLowAlarm
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLowAlarm:lowAlarm];
    lowAlarm = aLowAlarm;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMks660BModelLowAlarmChanged object:self];
}

- (float) highLimit
{
    return highLimit;
}

- (void) setHighLimit:(float)aHighLimit
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHighLimit:highLimit];
    highLimit = aHighLimit;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMks660BModelHighLimitChanged object:self];
}

- (float) highAlarm
{
    return highAlarm;
}

- (void) setHighAlarm:(float)aHighAlarm
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHighAlarm:highAlarm];
    highAlarm = aHighAlarm;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMks660BModelHighAlarmChanged object:self];
}

- (int) fullScaleRB
{
    return fullScaleRB;
}

- (void) setFullScaleRB:(int)aFullScaleRB
{
    fullScaleRB = aFullScaleRB;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMks660BModelFullScaleRBChanged object:self];
}

- (int) calibrationNumber
{
    return calibrationNumber;
}

- (void) setCalibrationNumber:(int)aCalibrationNumber
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCalibrationNumber:calibrationNumber];
    calibrationNumber = aCalibrationNumber;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMks660BModelCalibrationNumberChanged object:self];
}

- (int) lowHysteresis
{
    return lowHysteresis;
}

- (void) setLowHysteresis:(int)aLowHysteresis
{
	if(aLowHysteresis<0)aLowHysteresis=0;
	else if(aLowHysteresis>99)aLowHysteresis=99;
    [[[self undoManager] prepareWithInvocationTarget:self] setLowHysteresis:lowHysteresis];
    lowHysteresis = aLowHysteresis;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMks660BModelLowHysteresisChanged object:self];
}

- (int) highHysteresis
{
	
    return highHysteresis;
}

- (void) setHighHysteresis:(int)aHighHysteresis
{
	if(aHighHysteresis<0)aHighHysteresis=0;
	else if(aHighHysteresis>99)aHighHysteresis=99;
    [[[self undoManager] prepareWithInvocationTarget:self] setHighHysteresis:highHysteresis];
    highHysteresis = aHighHysteresis;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMks660BModelHighHysteresisChanged object:self];
}

- (int) decimalPtPosition
{
	if(decimalPtPosition<1)			return 0;
	else if(decimalPtPosition>5)	return 4;
    return decimalPtPosition;
}

- (void) setDecimalPtPosition:(int)aDecimalPtPosition
{
	if(aDecimalPtPosition<1)		aDecimalPtPosition=0;
	else if(aDecimalPtPosition>5)	aDecimalPtPosition=4;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setDecimalPtPosition:decimalPtPosition];
    decimalPtPosition = aDecimalPtPosition;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMks660BModelDecimalPtPositionChanged object:self];
}

- (ORTimeRate*)timeRate
{
	return timeRates;
}

- (BOOL) shipPressures
{
    return shipPressures;
}

- (void) setShipPressures:(BOOL)aShipPressures
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipPressures:shipPressures];
    shipPressures = aShipPressures;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMks660BShipPressuresChanged object:self];
}

- (int) pollTime
{
    return pollTime;
}

- (void) setPollTime:(int)aPollTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollTime:pollTime];
    pollTime = aPollTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMks660BPollTimeChanged object:self];

	if(pollTime){
		[self performSelector:@selector(pollHardware) withObject:nil afterDelay:2];
	}
	else {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollHardware) object:nil];
	}
}

- (int) lowSetPoint:(int)index
{
    if(index>=0 && index<2)return lowSetPoint[index];
	else return 0;
}

- (void) setLowSetPoint:(int)index withValue:(int)aValue;
{
    if(index>=0 && index<2){
		[[[self undoManager] prepareWithInvocationTarget:self] setLowSetPoint:index withValue:lowSetPoint[index]];
		lowSetPoint[index] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORMks660BLowSetPointChanged object:self];
        
	}
}

- (int) highSetPoint:(int)index
{
    if(index>=0 && index<2)return highSetPoint[index];
	else return 0.0;
}

- (void) setHighSetPoint:(int)index withValue:(int)aValue;
{
    if(index>=0 && index<2){
		[[[self undoManager] prepareWithInvocationTarget:self] setHighSetPoint:index withValue:highSetPoint[index]];
		highSetPoint[index] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORMks660BHighSetPointChanged object:self];
	}
}

- (unsigned long) timeMeasured
{
	return timeMeasured;
}

- (float) pressure
{
	return pressure;
}

- (void) setPressure:(float)aValue
{
	pressure = aValue;
	//get the time(UT!)
	time_t	ut_Time;
	time(&ut_Time);
	timeMeasured = ut_Time;

	if(timeRates == nil) timeRates = [[ORTimeRate alloc] init];
	[timeRates addDataToTimeAverage:pressure];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMks660BPressureChanged object:self];
}

- (NSString*) lastRequest
{
	return lastRequest;
}

- (void) setLastRequest:(NSString*)aRequest
{
	[lastRequest autorelease];
	lastRequest = [aRequest copy];    
}

- (void) setUpPort
{
	[serialPort setSpeed:9600];
	[serialPort setParityNone];
	[serialPort setStopBits2:NO];
	[serialPort setDataBits:8];
	[serialPort commitChanges];
}
 

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	[self setLowAlarm:			[decoder decodeFloatForKey:@"lowAlarm"]];
	[self setHighLimit:			[decoder decodeFloatForKey:	 @"highLimit"]];
	[self setHighAlarm:			[decoder decodeFloatForKey:	 @"highAlarm"]];
	[self setCalibrationNumber:	[decoder decodeIntForKey:	 @"calibrationNumber"]];
	[self setLowHysteresis:		[decoder decodeIntForKey:	 @"lowHysteresis"]];
	[self setHighHysteresis:	[decoder decodeIntForKey:	 @"highHysteresis"]];
	[self setDecimalPtPosition:	[decoder decodeIntForKey:	 @"decimalPtPosition"]];
	[self setShipPressures:		[decoder decodeBoolForKey:	 @"shipPressures"]];
	[self setPollTime:			[decoder decodeIntForKey:	 @"pollTime"]];
	
	int i;
	for(i=0;i<2;i++){
		[self setLowSetPoint:i   withValue:	[decoder decodeIntForKey: [NSString stringWithFormat:@"lowSetPoint%d",i]]];
		[self setHighSetPoint:i  withValue: [decoder decodeIntForKey: [NSString stringWithFormat:@"highSetPoint%d",i]]];
	}
	
	[[self undoManager] enableUndoRegistration];
	timeRates = [[ORTimeRate alloc] init];

	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeFloat:lowAlarm			forKey:@"lowAlarm"];
	[encoder encodeFloat:highLimit			forKey:@"highLimit"];
	[encoder encodeFloat:highAlarm			forKey:@"highAlarm"];
	[encoder encodeInt:calibrationNumber	forKey:@"calibrationNumber"];
	[encoder encodeInt:lowHysteresis		forKey:@"lowHysteresis"];
	[encoder encodeInt:highHysteresis		forKey:@"highHysteresis"];
	[encoder encodeInt:decimalPtPosition	forKey:@"decimalPtPosition"];
	[encoder encodeBool:shipPressures		forKey: @"shipPressures"];
    [encoder encodeInt: pollTime			forKey: @"pollTime"];
	int i;
	for(i=0;i<2;i++){
		[encoder encodeInt:lowSetPoint[i]	forKey: [NSString stringWithFormat:@"lowSetPoint%d",i]];
		[encoder encodeInt:highSetPoint[i]  forKey: [NSString stringWithFormat:@"highSetPoint%d",i]];
	}
}

#pragma mark ••• Commands
- (void) addCmdToQueue:(NSString*)aCmd waitForResponse:(BOOL)waitForResponse
{
    if([serialPort isOpen]){ 
		ORMks660BCmd* cmdObj  = [[[ORMks660BCmd alloc] init] autorelease];
		cmdObj.cmd = aCmd;
		cmdObj.waitForResponse = waitForResponse;
		
		[self enqueueCmd:cmdObj];
		if(!lastRequest){
			[self processOneCommandFromQueue];
		}
	}
}

- (void) writeZeroDisplay
{
	[self addCmdToQueue:@"Z" waitForResponse:NO];
}

- (void) writeFullScale
{
	[self addCmdToQueue:@"F" waitForResponse:NO];
}

- (void) writeCalibrationNumber
{
	[self addCmdToQueue:[NSString stringWithFormat:@"S%05d",calibrationNumber] waitForResponse:NO];
}

- (void) writeDecimalPtPosition
{
	[self addCmdToQueue:[NSString stringWithFormat:@"D%d",decimalPtPosition+1] waitForResponse:NO];
}

- (void) writeSetPoints
{
	[self addCmdToQueue:[NSString stringWithFormat:@"P1%@%05d",highSetPoint[0]>=0?@"+":@"-",abs(highSetPoint[0])] waitForResponse:NO];
	[self addCmdToQueue:@"++Delay" waitForResponse:YES];
	[self addCmdToQueue:@"R1" waitForResponse:YES];

	[self addCmdToQueue:[NSString stringWithFormat:@"P2%@%05d",lowSetPoint[0]>=0?@"+":@"-",abs(lowSetPoint[0])] waitForResponse:NO];
	[self addCmdToQueue:@"++Delay" waitForResponse:YES];
    [self addCmdToQueue:@"R2" waitForResponse:YES];
 
	[self addCmdToQueue:[NSString stringWithFormat:@"P3%@%05d",highSetPoint[1]>=0?@"+":@"-",abs(highSetPoint[1])] waitForResponse:NO];
	[self addCmdToQueue:@"++Delay" waitForResponse:YES];
    [self addCmdToQueue:@"R3" waitForResponse:YES];

	[self addCmdToQueue:[NSString stringWithFormat:@"P4%@%05d",lowSetPoint[1]>=0?@"+":@"-",abs(lowSetPoint[1])] waitForResponse:NO];
	[self addCmdToQueue:@"++Delay" waitForResponse:YES];
    [self addCmdToQueue:@"R4" waitForResponse:YES];
}

- (void) writeHysteresis
{
	[self addCmdToQueue:[NSString stringWithFormat:@"H1%02d",highHysteresis] waitForResponse:NO];
	[self addCmdToQueue:@"++Delay" waitForResponse:YES];
    [self addCmdToQueue:@"R6" waitForResponse:YES];
	
	[self addCmdToQueue:[NSString stringWithFormat:@"H2%02d",lowHysteresis] waitForResponse:NO];
	[self addCmdToQueue:@"++Delay" waitForResponse:YES];
	[self addCmdToQueue:@"R7" waitForResponse:YES];
	
	[self readHysteresis];
}

- (void) readPressure
{
	[self addCmdToQueue:@"R5" waitForResponse:YES];
	[self addCmdToQueue:@"R8" waitForResponse:YES];
	[self addCmdToQueue:@"++ShipRecords" waitForResponse:NO];
}

- (void) readFullScale
{
	[self addCmdToQueue:@"R8" waitForResponse:YES];
}

- (void) readDecimalPtPosition
{
	[self addCmdToQueue:@"R9" waitForResponse:YES];
}

- (void) readSetPoints
{
    [self addCmdToQueue:@"R1" waitForResponse:YES];
	[self addCmdToQueue:@"R2" waitForResponse:YES];
    [self addCmdToQueue:@"R3" waitForResponse:YES];
    [self addCmdToQueue:@"R4" waitForResponse:YES];
}

- (void) readHysteresis
{
    [self addCmdToQueue:@"R6" waitForResponse:YES];
	[self addCmdToQueue:@"R7" waitForResponse:YES];
}

- (void) initHardware
{
	[self writeDecimalPtPosition];
	[self addCmdToQueue:@"++Delay" waitForResponse:YES];
	[self writeHysteresis];
	[self writeSetPoints];
}

- (void) readAndCompare
{
	[self readSetPoints];
}

- (void) readAndLoad
{
	[self addCmdToQueue:@"++StartDialogLoad" waitForResponse:NO];	
	[self readAndCompare];
	[self addCmdToQueue:@"++EndDialogLoad" waitForResponse:NO];	
}


#pragma mark •••Data Records
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherMks660B
{
    [self setDataId:[anotherMks660B dataId]];
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"Mks660BModel"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORMks660BDecoderForPressure",     @"decoder",
        [NSNumber numberWithLong:dataId],   @"dataId",
        [NSNumber numberWithBool:NO],       @"variable",
        [NSNumber numberWithLong:4],        @"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"Pressures"];
    
    return dataDictionary;
}

- (void) recoverFromTimeout
{
	//there was a timout on the serial line, try again.
	[self pollHardware];
}

- (void) pollHardware
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollHardware) object:nil];
	
	[self readPressure];
		
	if(pollTime!=0){
		[self performSelector:@selector(pollHardware) withObject:nil afterDelay:pollTime];
	}
}
#pragma mark •••Adc Processing Protocol
- (void) processIsStarting
{
	//we will control the polling loop
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollHardware) object:nil];
    readOnce = NO;
	[self setInvolvedInProcess:YES];
}

- (void) processIsStopping
{
	//return control to the normal loop
	[self setPollTime:pollTime];
	[self setInvolvedInProcess:NO];
}

//note that everything called by these routines MUST be threadsafe
- (void) startProcessCycle
{    
    if(!readOnce){
        @try { 
			[self performSelectorOnMainThread:@selector(readPressure) withObject:nil waitUntilDone:NO]; 
			if(shipPressures) [self performSelectorOnMainThread:@selector(shipPressures) withObject:nil waitUntilDone:NO];
            readOnce = YES;
        }
		@catch(NSException* localException) { 
			//catch this here to prevent it from falling thru, but nothing to do.
        }
    }
}

- (void) endProcessCycle
{
	readOnce = NO;
}

- (NSString*) identifier
{
	NSString* s;
 	@synchronized(self){
		s= [NSString stringWithFormat:@"MKS660,%lu",[self uniqueIdNumber]];
	}
	return s;
}

- (NSString*) processingTitle
{
	NSString* s;
 	@synchronized(self){
		s= [self identifier];
	}
	return s;
}

- (double) convertedValue:(int)aChan
{
	double theValue = 0;
	@synchronized(self){
		theValue = [self pressure];
	}
	return theValue;
}

- (double) maxValueForChan:(int)aChan
{
	return highLimit;
}

- (double) minValueForChan:(int)aChan
{
	return 0;
}

- (void) getAlarmRangeLow:(double*)theLowAlarm high:(double*)theHighAlarm channel:(int)aChan
{
	@synchronized(self){
		*theLowAlarm  = lowAlarm;
		*theHighAlarm = highAlarm;
	}		
}

- (BOOL) processValue:(int)channel
{
	return NO;
}

- (void) setProcessOutput:(int)channel value:(int)value
{
    //nothing to do
}


@end

@implementation ORMks660BModel (private)


- (void) clearDelay
{
	delay = NO;
	[self processOneCommandFromQueue];
}

- (void) processOneCommandFromQueue
{
	if(delay)return;
	
	ORMks660BCmd* cmdObj = [self nextCmd];
	if(cmdObj){
		NSString* aCmd = cmdObj.cmd;
		if([aCmd isEqualToString:@"++Delay"]){
			delay = YES;
			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(clearDelay) object:nil];
			[self performSelector:@selector(clearDelay) withObject:nil afterDelay:.1];
		}
		else if([aCmd isEqualToString:@"++ShipRecords"]){
			if(shipPressures) [self shipPressureValues];
			[self processOneCommandFromQueue];
		}
		else if([aCmd isEqualToString:@"++StartDialogLoad"]){
			loadDialog = YES;
		}
		else if([aCmd isEqualToString:@"++EndDialogLoad"]){
			loadDialog = NO;
		}
		else {
			if(cmdObj.waitForResponse) {
				[self startTimeout:3];
				[self setLastRequest:aCmd];
			}
			else [self setLastRequest:nil];
			if(![aCmd hasSuffix:@"\r\n"]) aCmd = [aCmd stringByAppendingString:@"\r\n"];
			[serialPort writeString:aCmd];
			if(!lastRequest){
				[self processOneCommandFromQueue];
			}
		}
	}
}

- (void) process_response:(NSString*)theResponse
{	
	[self setIsValid:YES];

	if(!lastRequest)return;
	
	int lastRequestNumber = [[lastRequest substringFromIndex:1] intValue];
	
	switch(lastRequestNumber){
		case 1: [self decodeHighSetPoint:theResponse];		break;
		case 2: [self decodeLowSetPoint:theResponse];		break;
		case 3: [self decodeHighSetPoint:theResponse];		break;
		case 4: [self decodeLowSetPoint:theResponse];		break;
		case 5: [self decodePressure:theResponse];			break;
		case 6: [self decodeHysteresis:theResponse];	break;
		case 7: [self decodeHysteresis:theResponse];		break;
		case 8: [self decodeFullScale:theResponse];			break;
	}
}

- (BOOL) decodeLowSetPoint:(NSString*)theResponse
{
	if([theResponse hasPrefix:@"P"]){
		int index = [[theResponse substringWithRange:NSMakeRange(1,1)] intValue];
		if(index==2 || index==4){
			float scaleFactor = powf(10.,4-decimalPtPosition);
			float theValue = [[theResponse substringFromIndex:2] floatValue];
			int i = 0;
			if(index == 4) i = 1;
			if(loadDialog){
				[self setLowSetPoint:i withValue:theValue * scaleFactor];
				return YES;
			}
			if(fabs(lowSetPoint[i]/scaleFactor - theValue) < 0.001)return YES;
			else NSLogColor([NSColor redColor], @"MKS660B (%d) LowSetPoint[%d] ReadBack mismatch (%.4f != %.4f)\n",[self uniqueIdNumber],i+1,lowSetPoint[i]/scaleFactor,theValue);
		}
		else return NO;
    }
	return NO;	
}

- (BOOL) decodeHighSetPoint:(NSString*)theResponse
{
	if([theResponse hasPrefix:@"P"]){
		int index = [[theResponse substringWithRange:NSMakeRange(1,1)] intValue];
		if(index==1 || index==3){
			float scaleFactor = powf(10.,4-decimalPtPosition);
			float theValue = [[theResponse substringFromIndex:2] floatValue];
			int i = 0;
			if(index == 3) i = 1;
			if(loadDialog){
				[self setHighSetPoint:i withValue:theValue * scaleFactor];
				return YES;
			}
			if(fabs(highSetPoint[i]/scaleFactor - theValue) < 0.001)return YES;
			else NSLogColor([NSColor redColor], @"MKS660B (%d) HighSetPoint[%d] ReadBack mismatch (%.4f != %.4f)\n",[self uniqueIdNumber],i+1,highSetPoint[i]/scaleFactor,theValue);
		}
		else return NO;
    }
	return NO;	
}


- (BOOL) decodeFullScale:(NSString*)theResponse
{
	if([theResponse hasPrefix:@"S"]){
		int theValue = [[theResponse substringFromIndex:1] intValue];
		[self setFullScaleRB:theValue];
	}
	return YES;	
}

- (BOOL) decodePressure:(NSString*)theResponse
{
    if([theResponse hasPrefix:@"P"]){
		float theValue = [[theResponse substringFromIndex:1] floatValue];
		[self setPressure:theValue];
		return YES;
	}
	return NO;
}

- (BOOL) decodeHysteresis:(NSString*)theResponse
{
	if([theResponse hasPrefix:@"H"]){
		int index = [[theResponse substringWithRange:NSMakeRange(1,1)] intValue];
		if(index==1 || index==2){
			int theValue = [[theResponse substringFromIndex:2] intValue];
			if(loadDialog){
				if(index==1) [self setHighHysteresis:theValue];
				else		 [self setLowHysteresis:theValue];
				return YES;
			}
			if(index==1){
				if(fabs(highHysteresis - theValue) == 0)return YES;
				else NSLogColor([NSColor redColor], @"MKS660B (%d) HighHysteresis ReadBack mismatch (%d != %d)\n",[self uniqueIdNumber],highHysteresis,theValue);
			}
			else {
				if(fabs(lowHysteresis - theValue) == 0)return YES;
				else NSLogColor([NSColor redColor], @"MKS660B (%d) LowHysteresis ReadBack mismatch (%d != %d)\n",[self uniqueIdNumber],lowHysteresis,theValue);
			}
		}
	}
	return NO;
}
@end

@implementation ORMks660BCmd
@synthesize cmd,waitForResponse;
- (void) dealloc
{
	self.cmd		 = nil;
	[super dealloc];
}
@end