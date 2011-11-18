//
//  ORLabJackUE9Model.m
//  Orca
//
//  Created by Mark Howe on Fri Nov 11,2011.
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Physics and Department sponsored in part by the United States 
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
#import "ORLabJackUE9Model.h"
#import "ORUSBInterface.h"
#import "NSNotifications+Extensions.h"
#import "ORDataTypeAssigner.h"

NSString* ORLabJackUE9ModelDeviceSerialNumberChanged = @"ORLabJackUE9ModelDeviceSerialNumberChanged";
NSString* ORLabJackUE9ModelInvolvedInProcessChanged = @"ORLabJackUE9ModelInvolvedInProcessChanged";
NSString* ORLabJackUE9ModelAOut1Changed			= @"ORLabJackUE9ModelAOut1Changed";
NSString* ORLabJackUE9ModelAOut0Changed			= @"ORLabJackUE9ModelAOut0Changed";
NSString* ORLabJackUE9ShipDataChanged				= @"ORLabJackUE9ShipDataChanged";
NSString* ORLabJackUE9DigitalOutputEnabledChanged	= @"ORLabJackUE9DigitalOutputEnabledChanged";
NSString* ORLabJackUE9CounterChanged				= @"ORLabJackUE9CounterChanged";
NSString* ORLabJackUE9SerialNumberChanged			= @"ORLabJackUE9SerialNumberChanged";
NSString* ORLabJackUE9USBInterfaceChanged			= @"ORLabJackUE9USBInterfaceChanged";
NSString* ORLabJackUE9USBInConnection				= @"ORLabJackUE9USBInConnection";
NSString* ORLabJackUE9USBNextConnection			= @"ORLabJackUE9USBNextConnection";
NSString* ORLabJackUE9Lock							= @"ORLabJackUE9Lock";
NSString* ORLabJackUE9ChannelNameChanged			= @"ORLabJackUE9ChannelNameChanged";
NSString* ORLabJackUE9ChannelUnitChanged			= @"ORLabJackUE9ChannelUnitChanged";
NSString* ORLabJackUE9AdcChanged					= @"ORLabJackUE9AdcChanged";
NSString* ORLabJackUE9GainChanged					= @"ORLabJackUE9GainChanged";
NSString* ORLabJackUE9DoNameChanged				= @"ORLabJackUE9DoNameChanged";
NSString* ORLabJackUE9IoNameChanged				= @"ORLabJackUE9IoNameChanged";
NSString* ORLabJackUE9DoDirectionChanged			= @"ORLabJackUE9DoDirectionChanged";
NSString* ORLabJackUE9IoDirectionChanged			= @"ORLabJackUE9IoDirectionChanged";
NSString* ORLabJackUE9DoValueOutChanged			= @"ORLabJackUE9DoValueOutChanged";
NSString* ORLabJackUE9IoValueOutChanged			= @"ORLabJackUE9IoValueOutChanged";
NSString* ORLabJackUE9DoValueInChanged				= @"ORLabJackUE9DoValueInChanged";
NSString* ORLabJackUE9IoValueInChanged				= @"ORLabJackUE9IoValueInChanged";
NSString* ORLabJackUE9PollTimeChanged				= @"ORLabJackUE9PollTimeChanged";
NSString* ORLabJackUE9HiLimitChanged				= @"ORLabJackUE9HiLimitChanged";
NSString* ORLabJackUE9LowLimitChanged				= @"ORLabJackUE9LowLimitChanged";
NSString* ORLabJackUE9AdcDiffChanged				= @"ORLabJackUE9AdcDiffChanged";
NSString* ORLabJackUE9SlopeChanged					= @"ORLabJackUE9SlopeChanged";
NSString* ORLabJackUE9InterceptChanged				= @"ORLabJackUE9InterceptChanged";
NSString* ORLabJackUE9MinValueChanged				= @"ORLabJackUE9MinValueChanged";
NSString* ORLabJackUE9MaxValueChanged				= @"ORLabJackUE9MaxValueChanged";

#define kLabJackUE9U12DriverPath @"/System/Library/Extensions/LabJackUE9U12.kext"
@interface ORLabJackUE9Model (private)
- (void) readPipeThread;
- (void) firstWrite;
- (void) writeData:(unsigned char*) data;
- (void) pollHardware;
- (void) sendIoControl;
- (void) readAdcValues;
- (void) addCurrentState:(NSMutableDictionary*)dictionary cArray:(int*)anArray forKey:(NSString*)aKey;
- (void) normalChecksum:(unsigned char*)b len:(int)n;
- (void) extendedChecksum:(unsigned char*)b len:(int)n;
- (unsigned char) normalChecksum8:(unsigned char*)b len:(int)n;
- (unsigned short) extendedChecksum16:(unsigned char*)b len:(int) n;
- (unsigned char) extendedChecksum8:(unsigned char*) b;
@end

#define kLabJackUE9DataSize 17

@implementation ORLabJackUE9Model
- (id)init
{
	self = [super init];
	int i;
	for(i=0;i<8;i++){
		lowLimit[i] = -10;
		hiLimit[i]  = 10;
		minValue[i] = -10;
		maxValue[i]  = 10;
		//default to range from -10 to +10 over adc range of 0 to 4095
		slope[i] = 20./4095.;
		intercept[i] = -10;
	}
		
	return self;	
}

- (void) dealloc 
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	int i;
	for(i=0;i<8;i++)	[channelName[i] release];
	for(i=0;i<8;i++)	[channelUnit[i] release];
	for(i=0;i<16;i++)	[ioName[i] release];
	for(i=0;i<4;i++)	[doName[i] release];
    [serialNumber release];
	[super dealloc];
}

- (void) makeConnectors
{
	ORConnector* connectorObj1 = [[ ORConnector alloc ] 
								  initAt: NSMakePoint( 0, [self frame].size.height-20 )
								  withGuardian: self];
	[[ self connectors ] setObject: connectorObj1 forKey: ORLabJackUE9USBInConnection ];
	[ connectorObj1 setConnectorType: 'USBI' ];
	[ connectorObj1 addRestrictedConnectionType: 'USBO' ]; //can only connect to usb outputs
	[connectorObj1 setOffColor:[NSColor yellowColor]];
	[ connectorObj1 release ];
	
	ORConnector* connectorObj2 = [[ ORConnector alloc ] 
								  initAt: NSMakePoint( [self frame].size.width-kConnectorSize, 10 )
								  withGuardian: self];
	[[ self connectors ] setObject: connectorObj2 forKey: ORLabJackUE9USBNextConnection ];
	[ connectorObj2 setConnectorType: 'USBO' ];
	[ connectorObj2 addRestrictedConnectionType: 'USBI' ]; //can only connect to usb inputs
	[connectorObj2 setOffColor:[NSColor yellowColor]];
	[ connectorObj2 release ];
}

- (void) makeMainController
{
    [self linkToController:@"ORLabJackUE9Controller"];
}

- (NSString*) helpURL
{
	return @"USB/LabJackUE9.html";
}

- (void) connectionChanged
{
	[[self objectConnectedTo:ORLabJackUE9USBNextConnection] connectionChanged];
}

- (void) setGuardian:(id)aGuardian
{
	[super setGuardian:aGuardian];

}

-(void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
	NSImage* aCachedImage = [NSImage imageNamed:@"LabJackUE9"];
    if(!usbInterface){
		NSSize theIconSize = [aCachedImage size];
		NSPoint theOffset = NSZeroPoint;
		
		NSImage* i = [[NSImage alloc] initWithSize:theIconSize];
		[i lockFocus];
		
		[aCachedImage compositeToPoint:theOffset operation:NSCompositeCopy];
		
		if(!usbInterface || ![self getUSBController]){
			NSBezierPath* path = [NSBezierPath bezierPath];
			[path moveToPoint:NSMakePoint(20,10)];
			[path lineToPoint:NSMakePoint(40,30)];
			[path moveToPoint:NSMakePoint(40,10)];
			[path lineToPoint:NSMakePoint(20,30)];
			[path setLineWidth:3];
			[[NSColor redColor] set];
			[path stroke];
		}    
		
		[i unlockFocus];
		
		[self setImage:i];
		[i release];
    }
	else {
		[ self setImage: aCachedImage];
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORForceRedraw object: self];
}

- (NSString*) title 
{
	return [NSString stringWithFormat:@"LabJackUE9 (Serial# %@)",[usbInterface serialNumber]];
}

- (unsigned long) vendorID
{
	return 0x0CD5;
}

- (unsigned long) productID
{
	return 0x0009;	//LabJackUE9 ID
}

- (id) getUSBController
{
	id obj = [self objectConnectedTo:ORLabJackUE9USBInConnection];
	id cont =  [ obj getUSBController ];
	return cont;
}

#pragma mark ***Accessors

- (unsigned long) deviceSerialNumber
{
    return deviceSerialNumber;
}

- (void) setDeviceSerialNumber:(unsigned long)aDeviceSerialNumber
{
    deviceSerialNumber = aDeviceSerialNumber;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9ModelDeviceSerialNumberChanged object:self];
}

- (BOOL) involvedInProcess
{
    return involvedInProcess;
}

- (void) setInvolvedInProcess:(BOOL)aInvolvedInProcess
{
    involvedInProcess = aInvolvedInProcess;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9ModelInvolvedInProcessChanged object:self];
}

- (unsigned short) aOut1
{
    return aOut1;
}

- (void) setAOut1:(unsigned short)aValue
{
	if(aValue>1023)aValue=1023;
    [[[self undoManager] prepareWithInvocationTarget:self] setAOut1:aOut1];
    aOut1 = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9ModelAOut1Changed object:self];
}

- (void) setAOut0Voltage:(float)aValue
{
	[self setAOut0:aValue*255./5.1];
}

- (void) setAOut1Voltage:(float)aValue
{
	[self setAOut1:aValue*255./5.1];
}
		 
- (unsigned short) aOut0
{
    return aOut0;
}

- (void) setAOut0:(unsigned short)aValue
{
	if(aValue>1023)aValue=1023;
    [[[self undoManager] prepareWithInvocationTarget:self] setAOut0:aOut0];
    aOut0 = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9ModelAOut0Changed object:self];
}

- (float) slope:(int)i
{
	if(i>=0 && i<8)return slope[i];
	else return 20./4095.;
}

- (void) setSlope:(int)i withValue:(float)aValue
{
	if(i>=0 && i<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setSlope:i withValue:slope[i]];
		
		slope[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9SlopeChanged object:self userInfo:userInfo];
		
	}
}

- (float) intercept:(int)i
{
	if(i>=0 && i<8)return intercept[i];
	else return -10;
}

- (void) setIntercept:(int)i withValue:(float)aValue
{
	if(i>=0 && i<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setIntercept:i withValue:intercept[i]];
		
		intercept[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9InterceptChanged object:self userInfo:userInfo];
		
	}
}

- (float) lowLimit:(int)i
{
	if(i>=0 && i<8)return lowLimit[i];
	else return 0;
}

- (void) setLowLimit:(int)i withValue:(float)aValue
{
	if(i>=0 && i<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setLowLimit:i withValue:lowLimit[i]];
		
		lowLimit[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9LowLimitChanged object:self userInfo:userInfo];
		
	}
}

- (float) hiLimit:(int)i
{
	if(i>=0 && i<8)return hiLimit[i];
	else return 0;
}

- (void) setHiLimit:(int)i withValue:(float)aValue
{
	if(i>=0 && i<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setHiLimit:i withValue:lowLimit[i]];
		
		hiLimit[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9HiLimitChanged object:self userInfo:userInfo];
		
	}
}

- (float) minValue:(int)i
{
	if(i>=0 && i<8)return minValue[i];
	else return 0;
}

- (void) setMinValue:(int)i withValue:(float)aValue
{
	if(i>=0 && i<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setMinValue:i withValue:minValue[i]];
		
		minValue[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9MinValueChanged object:self userInfo:userInfo];
		
	}
}
- (float) maxValue:(int)i
{
	if(i>=0 && i<8)return maxValue[i];
	else return 0;
}

- (void) setMaxValue:(int)i withValue:(float)aValue
{
	if(i>=0 && i<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setMaxValue:i withValue:maxValue[i]];
		
		maxValue[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9MaxValueChanged object:self userInfo:userInfo];
		
	}
}


- (BOOL) shipData
{
    return shipData;
}

- (void) setShipData:(BOOL)aShipData
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipData:shipData];
    shipData = aShipData;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9ShipDataChanged object:self];
}

- (int) pollTime
{
    return pollTime;
}

- (void) setPollTime:(int)aPollTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollTime:pollTime];
    pollTime = aPollTime;
	[self pollHardware];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9PollTimeChanged object:self];
}

- (BOOL) digitalOutputEnabled
{
    return digitalOutputEnabled;
}

- (void) setDigitalOutputEnabled:(BOOL)aDigitalOutputEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDigitalOutputEnabled:digitalOutputEnabled];
    digitalOutputEnabled = aDigitalOutputEnabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9DigitalOutputEnabledChanged object:self];
}

- (unsigned long) counter
{
    return counter;
}

- (void) setCounter:(unsigned long)aCounter
{
    counter = aCounter;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9CounterChanged object:self];
}

- (NSString*) channelName:(int)i
{
	if(i>=0 && i<8){
		if([channelName[i] length])return channelName[i];
		else return [NSString stringWithFormat:@"Chan %d",i];
	}
	else return @"";
}

- (void) setChannel:(int)i name:(NSString*)aName
{
	if(i>=0 && i<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setChannel:i name:channelName[i]];
		
		[channelName[i] autorelease];
		channelName[i] = [aName copy]; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9ChannelNameChanged object:self userInfo:userInfo];
		
	}
}

- (NSString*) channelUnit:(int)i
{
	if(i>=0 && i<8){
		if([channelUnit[i] length])return channelUnit[i];
		else return @"V";
	}
	else return @"";
}

- (void) setChannel:(int)i unit:(NSString*)aName
{
	if(i>=0 && i<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setChannel:i unit:channelUnit[i]];
		
		[channelUnit[i] autorelease];
		channelUnit[i] = [aName copy]; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9ChannelUnitChanged object:self userInfo:userInfo];
		
	}
}



- (NSString*) ioName:(int)i
{
	if(i>=0 && i<4){
		if([ioName[i] length])return ioName[i];
		else return [NSString stringWithFormat:@"IO%d",i];
	}
	else return @"";
}

- (void) setIo:(int)i name:(NSString*)aName
{
	if(i>=0 && i<4){
		[[[self undoManager] prepareWithInvocationTarget:self] setIo:i name:ioName[i]];
		
		[ioName[i] autorelease];
		ioName[i] = [aName copy]; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9IoNameChanged object:self userInfo:userInfo];
		
	}
}

- (NSString*) doName:(int)i
{
	if(i>=0 && i<16){
		if([doName[i] length])return doName[i];
		else return [NSString stringWithFormat:@"DO%d",i];
	}
	else return @"";
}

- (void) setDo:(int)i name:(NSString*)aName
{
	if(i>=0 && i<16){
		[[[self undoManager] prepareWithInvocationTarget:self] setDo:i name:doName[i]];
		
		[doName[i] autorelease];
		doName[i] = [aName copy]; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9DoNameChanged object:self userInfo:userInfo];
		
	}
}

- (int) adc:(int)i
{
	unsigned short result = 0;
	@synchronized(self){
		if(i>=0 && i<8){
			result =  adc[i];
		}
	}
	return result;
}

- (void) setAdc:(int)i withValue:(int)aValue
{
	@synchronized(self){
		if(i>=0 && i<8){
			adc[i] = aValue; 
			
			NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
			[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
			
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackUE9AdcChanged object:self userInfo:userInfo];
		}	
	}
}
- (int) gain:(int)i
{
	unsigned short result = 0;
	@synchronized(self){
		if(i>=0 && i<4){
			result =  gain[i];
		}
	}
	return result;
}

- (void) setGain:(int)i withValue:(int)aValue
{
	@synchronized(self){
		if(i>=0 && i<4){
			[[[self undoManager] prepareWithInvocationTarget:self] setGain:i withValue:gain[i]];
			gain[i] = aValue; 
			
			NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
			[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
			
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackUE9GainChanged object:self userInfo:userInfo];
		}	
	}
}

- (unsigned short) adcDiff
{
	return adcDiff;
}

- (void) setAdcDiff:(unsigned short)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAdcDiff:adcDiff];
    adcDiff = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9AdcDiffChanged object:self];
	
}

- (void) setAdcDiffBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = adcDiff;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setAdcDiff:aMask];
}

- (unsigned short) doDirection
{
    return doDirection;
}

- (void) setDoDirection:(unsigned short)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDoDirection:doDirection];
    doDirection = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9DoDirectionChanged object:self];
}


- (void) setDoDirectionBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = doDirection;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setDoDirection:aMask];
	//ORAdcInfoProviding protocol requirement
	//[self postAdcInfoProvidingValueChanged];
}

- (unsigned short) ioDirection
{
    return ioDirection;
}

- (void) setIoDirection:(unsigned short)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIoDirection:ioDirection];
    ioDirection = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9IoDirectionChanged object:self];
}

- (void) setIoDirectionBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = ioDirection;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setIoDirection:aMask];
	//ORAdcInfoProviding protocol requirement
	//[self postAdcInfoProvidingValueChanged];
}


- (unsigned short) doValueOut
{
    return doValueOut;
}

- (void) setDoValueOut:(unsigned short)aMask
{
	@synchronized(self){
		[[[self undoManager] prepareWithInvocationTarget:self] setDoValueOut:doValueOut];
		doValueOut = aMask;
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackUE9DoValueOutChanged object:self];
	}
}

- (void) setDoValueOutBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = doValueOut;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setDoValueOut:aMask];
	//ORAdcInfoProviding protocol requirement
	//[self postAdcInfoProvidingValueChanged];
}

- (unsigned short) ioValueOut
{
    return ioValueOut;
}

- (void) setIoValueOut:(unsigned short)aMask
{
	@synchronized(self){
		[[[self undoManager] prepareWithInvocationTarget:self] setIoValueOut:ioValueOut];
		ioValueOut = aMask;
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackUE9IoValueOutChanged object:self];
	}
}

- (void) setIoValueOutBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = ioValueOut;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setIoValueOut:aMask];
	//ORAdcInfoProviding protocol requirement
	//[self postAdcInfoProvidingValueChanged];
}

- (unsigned short) ioValueIn
{
    return ioValueIn;
}

- (void) setIoValueIn:(unsigned short)aMask
{
	@synchronized(self){
		ioValueIn = aMask;
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackUE9IoValueInChanged object:self];
	}
}

- (void) setIoValueInBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = ioValueIn;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setIoValueIn:aMask];
	//ORAdcInfoProviding protocol requirement
	//[self postAdcInfoProvidingValueChanged];
}

- (NSString*) ioInString:(int)i
{
	if(ioDirection & (1L<<i) ) return (ioValueIn & 1L<<i) ? @"Hi":@"Lo";
	else						 return @"";
}

- (NSColor*) ioInColor:(int)i
{
	if(ioDirection & (1L<<i) ) return (ioValueIn & 1L<<i) ? 
		[NSColor colorWithCalibratedRed:0 green:.8 blue:0 alpha:1.0] :
		[NSColor colorWithCalibratedRed:.8 green:0 blue:0 alpha:1.0];
	else						 return [NSColor blackColor];
}

- (NSColor*) doInColor:(int)i
{
	if(doDirection & (1L<<i) ) return (doValueIn & 1L<<i) ? 
		[NSColor colorWithCalibratedRed:0 green:.8 blue:0 alpha:1.0] :
		[NSColor colorWithCalibratedRed:.8 green:0 blue:0 alpha:1.0];
	else						 return [NSColor blackColor];
}

- (unsigned short) doValueIn
{
    return doValueIn;
}

- (void) setDoValueIn:(unsigned short)aMask
{
	@synchronized(self){
		doValueIn = aMask;
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackUE9DoValueInChanged object:self];
	}
}

- (void) setDoValueInBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = doValueIn;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setDoValueIn:aMask];
	//ORAdcInfoProviding protocol requirement
	//[self postAdcInfoProvidingValueChanged];
}

- (NSString*) doInString:(int)i
{
	if(doDirection & (1L<<i) ) return (doValueIn & 1L<<i) ? @"Hi":@"Lo";
	else						 return @"";
}

- (NSString*) serialNumber
{
    return serialNumber;
}

- (void) setSerialNumber:(NSString*)aSerialNumber
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSerialNumber:serialNumber];
    
    [serialNumber autorelease];
    serialNumber = [aSerialNumber copy];    
	
	
	if(!serialNumber){
		[[self getUSBController] releaseInterfaceFor:self];
	}
	else {
		[[self getUSBController] claimInterfaceWithSerialNumber:serialNumber for:self];
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9SerialNumberChanged object:self];
}

- (void) interfaceAdded:(NSNotification*)aNote
{
	[self checkDevices];
}

- (void) interfaceRemoved:(NSNotification*)aNote
{
}

- (void) setUsbInterface:(ORUSBInterface*)anInterface;
{
	//we don't need this since we are using libusb, but a stub is needed to conform to the usbuser protocol.
}

- (NSString*) usbInterfaceDescription
{
	if(usbInterface)return [usbInterface description];
	else return @"?";
}

- (void) registerWithUSB:(id)usb
{
	[usb registerForUSBNotifications:self];
}

- (void) checkDevices
{
	int numUE9s = LJUSB_GetDevCount(UE9_PRODUCT_ID);
	NSLog(@"Number of LabJackkUE9 devices: %d\n",numUE9s);
	HANDLE devHandles[256];
	UINT productIds[256];
	LJUSB_OpenAllDevices(devHandles,productIds,256);
	int i;
	for(i=0;i<256;i++){
		if(productIds[i] == 0x9){
			NSLog(@"Device Handle: %d Product ID: %d\n",devHandles[i],productIds[i]);
		}
	}
}

- (NSString*) hwName
{
	if(usbInterface)return [usbInterface deviceName];
	else return @"?";
}

- (void) makeUSBClaim:(NSString*)aSerialNumber
{
}

- (void) resetCounter
{
	doResetOfCounter = YES;
	[self sendIoControl];
}


#pragma mark ***HW Access
- (void) queryAll
{
	if(!queue){
		queue = [[NSOperationQueue alloc] init];
		[queue setMaxConcurrentOperationCount:1]; //can only do one at a time
	}	
	if ([[queue operations] count] == 0) {
		ORLabJackUE9Query* anOp = [[ORLabJackUE9Query alloc] initWithDelegate:self];
		[queue addOperation:anOp];
		[anOp release];
		led = !led;
	}
}

#pragma mark ***Data Records
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId   = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anOtherDevice
{
    [self setDataId:[anOtherDevice dataId]];
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"LabJackUE9"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORLabJackUE9DecoderForIOData",@"decoder",
								 [NSNumber numberWithLong:dataId],   @"dataId",
								 [NSNumber numberWithBool:NO],       @"variable",
								 [NSNumber numberWithLong:kLabJackUE9DataSize],       @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Temperatures"];
    
    return dataDictionary;
}

- (unsigned long) timeMeasured
{
	return timeMeasured;
}


- (void) shipIOData
{
    if([[ORGlobal sharedGlobal] runInProgress]){
		
		unsigned long data[kLabJackUE9DataSize];
		data[0] = dataId | kLabJackUE9DataSize;
		data[1] = ((adcDiff & 0xf) << 16) | ([self uniqueIdNumber] & 0x0000fffff);
		
		union {
			float asFloat;
			unsigned long asLong;
		} theData;
		
		int index = 2;
		int i;
		for(i=0;i<8;i++){
			theData.asFloat = [self convertedValue:i];
			data[index] = theData.asLong;
			index++;
		}
		data[index++] = counter;
		data[index++] = ((ioDirection & 0xF) << 16) | (doDirection & 0xFFFF);
		data[index++] = ((ioValueOut  & 0xF) << 16) | (doValueOut & 0xFFFF);
		data[index++] = ((ioValueIn   & 0xF) << 16) | (doValueIn & 0xFFFF);
	
		data[index++] = timeMeasured;
		data[index++] = 0; //spares
		data[index++] = 0;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
															object:[NSData dataWithBytes:data length:sizeof(long)*kLabJackUE9DataSize]];
	}
}
#pragma mark •••Bit Processing Protocol
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
            [self queryAll]; 
            if(shipData){
                [self shipIOData]; 
            }
            readOnce = YES;
        }
		@catch(NSException* localException) { 
			//catch this here to prevent it from falling thru, but nothing to do.
        }
		
		//grab the bit pattern at the start of the cycle. it
		//will not be changed during the cycle.
		processInputValue = (doValueIn | (ioValueIn & 0xf)<<16) & (~doDirection | (~ioDirection & 0xf)<<16);
		processOutputMask = (doDirection | (ioDirection & 0xf)<<16);
		
    }
}

- (void) endProcessCycle
{
	readOnce = NO;
	//don't use the setter so the undo manager is bypassed
	doValueOut = processOutputValue & 0xFFFF;
	ioValueOut = (processOutputValue >> 16) & 0xF;
}

- (BOOL) processValue:(int)channel
{
	return (processInputValue & (1L<<channel)) > 0;
}

- (void) setProcessOutput:(int)channel value:(int)value
{
	processOutputMask |= (1L<<channel);
	if(value)	processOutputValue |= (1L<<channel);
	else		processOutputValue &= ~(1L<<channel);
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"LabJackUE9,%d",[self uniqueIdNumber]];
}

- (NSString*) processingTitle
{
    return [self identifier];
}

- (double) convertedValue:(int)aChan
{
	double volts = 20.0/4095.*adc[aChan] - 10.;
	if(aChan>=0 && aChan<8)return slope[aChan] * volts + intercept[aChan];
	else return 0;
}

- (double) maxValueForChan:(int)aChan
{
	return maxValue[aChan];
}

- (double) minValueForChan:(int)aChan
{
	return minValue[aChan];
}

- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit channel:(int)channel
{
	@synchronized(self){
		if(channel>=0 && channel<8){
			*theLowLimit = lowLimit[channel];
			*theHighLimit =  hiLimit[channel];
		}
		else {
			*theLowLimit = -10;
			*theHighLimit = 10;
		}
	}		
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setAOut1:[decoder decodeIntForKey:@"aOut1"]];
    [self setAOut0:[decoder decodeIntForKey:@"aOut0"]];
    [self setShipData:[decoder decodeBoolForKey:@"shipData"]];
    [self setDigitalOutputEnabled:[decoder decodeBoolForKey:@"digitalOutputEnabled"]];
    [self setSerialNumber:	[decoder decodeObjectForKey:@"serialNumber"]];
	int i;
	for(i=0;i<8;i++) {
		
		NSString* aName = [decoder decodeObjectForKey:[NSString stringWithFormat:@"channelName%d",i]];
		if(aName)[self setChannel:i name:aName];
		else	 [self setChannel:i name:[NSString stringWithFormat:@"Chan %d",i]];
		
		NSString* aUnit = [decoder decodeObjectForKey:[NSString stringWithFormat:@"channelUnit%d",i]];
		if(aUnit)[self setChannel:i unit:aName];
		else	 [self setChannel:i unit:@"V"];
		
		[self setMinValue:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"minValue%d",i]]];
		[self setMaxValue:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"maxValue%d",i]]];
		[self setLowLimit:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"lowLimit%d",i]]];
		[self setHiLimit:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"hiLimit%d",i]]];
		[self setSlope:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"slope%d",i]]];
		[self setIntercept:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"intercept%d",i]]];
	}
	
	for(i=0;i<16;i++) {
		NSString* aName = [decoder decodeObjectForKey:[NSString stringWithFormat:@"DO%d",i]];
		if(aName)[self setDo:i name:aName];
		else [self setDo:i name:[NSString stringWithFormat:@"DO%d",i]];
	}
	
	for(i=0;i<4;i++) {
		NSString* aName = [decoder decodeObjectForKey:[NSString stringWithFormat:@"IO%d",i]];
		if(aName)[self setIo:i name:aName];
		else [self setIo:i name:[NSString stringWithFormat:@"IO%d",i]];
		[self setGain:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"gain%d",i]]];
	}
	[self setAdcDiff:	[decoder decodeIntForKey:@"adcDiff"]];
	[self setDoDirection:	[decoder decodeIntForKey:@"doDirection"]];
	[self setIoDirection:	[decoder decodeIntForKey:@"ioDirection"]];
    [self setPollTime:		[decoder decodeIntForKey:@"pollTime"]];

    [[self undoManager] enableUndoRegistration];    
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:aOut1 forKey:@"aOut1"];
    [encoder encodeInt:aOut0 forKey:@"aOut0"];
    [encoder encodeBool:shipData forKey:@"shipData"];
    [encoder encodeInt:pollTime forKey:@"pollTime"];
    [encoder encodeBool:digitalOutputEnabled forKey:@"digitalOutputEnabled"];
    [encoder encodeObject:serialNumber	forKey: @"serialNumber"];
	int i;
	for(i=0;i<8;i++) {
		[encoder encodeObject:channelUnit[i] forKey:[NSString stringWithFormat:@"unitName%d",i]];
		[encoder encodeObject:channelName[i] forKey:[NSString stringWithFormat:@"channelName%d",i]];
		[encoder encodeFloat:lowLimit[i] forKey:[NSString stringWithFormat:@"lowLimit%d",i]];
		[encoder encodeFloat:hiLimit[i] forKey:[NSString stringWithFormat:@"hiLimit%d",i]];
		[encoder encodeFloat:slope[i] forKey:[NSString stringWithFormat:@"slope%d",i]];
		[encoder encodeFloat:intercept[i] forKey:[NSString stringWithFormat:@"intercept%d",i]];
		[encoder encodeFloat:minValue[i] forKey:[NSString stringWithFormat:@"minValue%d",i]];
		[encoder encodeFloat:maxValue[i] forKey:[NSString stringWithFormat:@"maxValue%d",i]];
	}
	
	for(i=0;i<16;i++) {
		[encoder encodeObject:doName[i] forKey:[NSString stringWithFormat:@"DO%d",i]];
	}
	for(i=0;i<4;i++) {
		[encoder encodeObject:ioName[i] forKey:[NSString stringWithFormat:@"IO%d",i]];
		[encoder encodeInt:gain[i] forKey:[NSString stringWithFormat:@"gain%d",i]];
	}

    [encoder encodeInt:adcDiff		forKey:@"adcDiff"];
    [encoder encodeInt:doDirection	forKey:@"doDirection"];
    [encoder encodeInt:ioDirection	forKey:@"ioDirection"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	
	[self addCurrentState:objDictionary cArray:gain forKey:@"Gain"];
    [objDictionary setObject:[NSNumber numberWithInt:adcDiff] forKey:@"AdcDiffMask"];
	
    return objDictionary;
}
- (void) readSerialNumber
{
	
}
@end

@implementation ORLabJackUE9Model (private)
- (void) pollHardware
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	if(pollTime == 0 )return;
    [[self undoManager] disableUndoRegistration];
	[self queryAll];
    [[self undoManager] enableUndoRegistration];
	if(pollTime == -1)[self performSelector:@selector(pollHardware) withObject:nil afterDelay:1/200.];
	else [self performSelector:@selector(pollHardware) withObject:nil afterDelay:pollTime];
}


		
- (void) readAdcValues
{
	if(usbInterface && [self getUSBController]){
		unsigned char data[8];
		int group;
		for(group=0;group<2;group++){
			if(adcDiff & (group==0?0x1:0x4)){
				int chan = (group==0?0:2);
				data[0] = ((gain[chan] & 0x7)<<4) | (group==0?0x0:0x2);  //Bits 6-4 PGA, Bits 3-0 MUX 0-1/4-5Diff
				data[1] = ((gain[chan] & 0x7)<<4) | (group==0?0x0:0x2);  //Bits 6-4 PGA, Bits 3-0 MUX Dup
			}
			else {
				data[0] = 0x08 + 0 + (4*group);  //Bits 6-4 PGA, Bits 3-0 MUX first Channel
				data[1] = 0x08 + 1 + (4*group);  //Bits 6-4 PGA, Bits 3-0 MUX second Channel
			}

			if(adcDiff & (group==0?0x2:0x8)){
				int chan = (group==0?1:3);
				data[2] = ((gain[chan] & 0x7)<<4) |(group==0?0x1:0x3);  //Bits 6-4 PGA, Bits 3-0 MUX 2-3/6-7 Diff
				data[3] = ((gain[chan] & 0x7)<<4) |(group==0?0x1:0x3);  //Bits 6-4 PGA, Bits 3-0 MUX Dup
			}
			else {
				data[2] = 0x08 + 2 + (4*group);  //Bits 6-4 PGA, Bits 3-0 MUX third Channel
				data[3] = 0x08 + 3 + (4*group);  //Bits 6-4 PGA, Bits 3-0 MUX four Channel
			}
			
			data[4] = led;			//led state	
			data[5] = 0xC0;
			data[6] = 0x00;			//Don't care
			data[7] = group;		// --- this echos back so we can tell which group to decode.
			[self writeData:data];
		}
	}
}

- (void) sendIoControl
{
	if(usbInterface && [self getUSBController]){
		
		unsigned char data[8];
		data[0] = (doDirection>>8) & 0xFF;					//D15-D8 Direction
		data[1] = doDirection	   & 0xFF;					//D7-D0 Direction
		data[2] = ((doValueOut & ~doDirection) >> 8) & 0xFF;//D15-D8 State
		data[3] =  (doValueOut & ~doDirection) & 0xFF;		//D15-D8 State
		data[4] = (ioDirection<<4) | ((ioValueOut & ~ioDirection) & 0x0F); //I0-I3 Direction and state
		
		//updateDigital, resetCounter,analog out
		unsigned short out0 = [self aOut0];
		unsigned short out1 = [self aOut1];
		data[5] = 0;
		if(digitalOutputEnabled) data[5] |= 0x10;
		data[5] |= (doResetOfCounter&0x1)<<5;
		//apparently the documentation is wrong and this is an 8-bit dac. 255 = 5V.
		//data[5] |= (((out1>>8) & 0x3) | (((out0>>8) & 0x3)<<2));
		data[6] = out0 & 0xFF;
		data[7] = out1 & 0xFF;
		[self writeData:data];
	}
	doResetOfCounter = NO;
}

- (void) readPipeThread
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	@try {
		unsigned char data[8];
		int amountRead = [usbInterface readBytes:data length:8 pipe:1];
		if(amountRead == 8){
			if((data[0] & 0x80)){
				//an AIO command
				int adcOffset = (data[1] & 0x1) * 4;
				[self setAdc:0 + adcOffset withValue:(data[2]&0x00f0)<<4 | data[3]];
				[self setAdc:1 + adcOffset withValue:(data[2]&0x000f)<<8 | data[4]];
				[self setAdc:2 + adcOffset withValue:(data[5]&0x00f0)<<4 | data[6]];
				[self setAdc:3 + adcOffset withValue:(data[5]&0x000f)<<8 | data[7]];				
			}
			else if((data[0] & 0xC0) == 0){
				//some digital I/O
				[self setDoValueIn:data[1]<<8 | data[2]];
				[self setIoValueIn:data[3]>>4];
				[self setCounter:(data[4]<<24) | (data[5]<<16) | (data[6]<<8) | data[7] ];
				
				//always this is the last query so timestamp here
				time_t	ut_Time;
				time(&ut_Time);
				timeMeasured = ut_Time;
				
				if(shipData) [self performSelectorOnMainThread:@selector(shipIOData) withObject:nil waitUntilDone:NO];
			}
			else if((data[0] & 0x50) == 0x50){
				unsigned long n = (data[1]<<1) + (data[2]<<8) + (data[3]<<4) + data[4];
				[self setDeviceSerialNumber:n];
			}
		}
	}
	@catch(NSException* e){
	}
	@finally {
		[pool release];
	}
}

- (void) firstWrite
{
//	unsigned char sendBuff[18];
//	sendBuff[1] = (uint8)(0xF8);  //command byte
//	sendBuff[2] = (uint8)(0x06);  //number of data words
//	sendBuff[3] = (uint8)(0x08);  //extended command number
//	int i;
//	for(i = 6; i < 18; i++)sendBuff[i] = (uint8)(0x00);
//	[self extendedChecksum:sendBuff len:18];	[usbInterface writeBytes:sendBuff length:8];
//	[NSThread detachNewThreadSelector: @selector(readPipeThread) toTarget:self withObject: nil];
//	[ORTimer delay:.02];
//[self readSerialNumber];
	
}

- (void) writeData:(unsigned char*) data
{
	[usbInterface writeBytes:data length:8];
	[NSThread detachNewThreadSelector: @selector(readPipeThread) toTarget:self withObject: nil];
	[ORTimer delay:0.03];
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary cArray:(int*)anArray forKey:(NSString*)aKey
{
	NSMutableArray* ar = [NSMutableArray array];
	int i;
	for(i=0;i<4;i++){
		[ar addObject:[NSNumber numberWithShort:*anArray]];
		anArray++;
	}
	[dictionary setObject:ar forKey:aKey];
}

#pragma mark ***Checksum Helpers
- (void) normalChecksum:(unsigned char*)b len:(int)n
{
	b[0]=[self normalChecksum8:b len:n];
}

- (void) extendedChecksum:(unsigned char*)b len:(int)n
{
	unsigned short a;
	a = [self extendedChecksum16:b len:n];
	b[4] = (unsigned char)(a & 0xff);
	b[5] = (unsigned char)((a / 256) & 0xff);
	b[0] = [self extendedChecksum8:b];
}


- (unsigned char) normalChecksum8:(unsigned char*)b len:(int)n
{
	int i;
	unsigned short a, bb;
	
	//Sums bytes 1 to n-1 unsigned to a 2 byte value. Sums quotient and
	//remainder of 256 division.  Again, sums quotient and remainder of
	//256 division.
	for(i = 1, a = 0; i < n; i++){
		a+=(unsigned short)b[i];
	}
	bb = a / 256;
	a = (a - 256 * bb) + bb;
	bb = a / 256;
	
	return (unsigned char)((a-256*bb)+bb);
}


- (unsigned short) extendedChecksum16:(unsigned char*)b len:(int) n
{
	int i, a = 0;
	
	//Sums bytes 6 to n-1 to a unsigned 2 byte value
	for(i = 6; i < n; i++){
		a += (unsigned short)b[i];
	}
	return a;
}


/* Sum bytes 1 to 5. Sum quotient and remainder of 256 division. Again, sum
 quotient and remainder of 256 division. Return result as unsigned char. */
- (unsigned char) extendedChecksum8:(unsigned char*) b
{
	int i, a, bb;
	
	//Sums bytes 1 to 5. Sums quotient and remainder of 256 division. Again, sums 
	//quotient and remainder of 256 division.
	for(i = 1, a = 0; i < 6; i++){
		a+=(unsigned short)b[i];
	}
	bb = a / 256;
	a = (a - 256 * bb) + bb;
	bb = a / 256;
	
	return (unsigned char)((a - 256 * bb) + bb);  
}

@end

@implementation ORLabJackUE9Query
- (id) initWithDelegate:(id)aDelegate
{
	self = [super init];
	delegate = aDelegate;
    return self;
}

- (void) main
{
	@try {
		[delegate readAdcValues];
		[delegate sendIoControl];
	}
	@catch(NSException* e){
	}
}
@end

