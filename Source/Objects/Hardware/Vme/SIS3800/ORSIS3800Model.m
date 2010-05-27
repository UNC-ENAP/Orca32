//-------------------------------------------------------------------------
//  ORSIS3800Model.h
//
//  Created by Mark A. Howe on Wednesday 9/30/08.
//  Copyright (c) 2008 CENPA. University of Washington. All rights reserved.
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
#import "ORSIS3800Model.h"
#import "ORDataTypeAssigner.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORVmeCrateModel.h"
#import "ORTimer.h"
#import "VME_HW_Definitions.h"

NSString* ORSIS3800ModelIsCountingChanged			 = @"ORSIS3800ModelIsCountingChanged";
NSString* ORSIS3800ModelSyncWithRunChanged			 = @"ORSIS3800ModelSyncWithRunChanged";
NSString* ORSIS3800ModelClearOnRunStartChanged		 = @"ORSIS3800ModelClearOnRunStartChanged";
NSString* ORSIS3800ModelEnableReferencePulserChanged = @"ORSIS3800ModelEnableReferencePulserChanged";
NSString* ORSIS3800ModelEnableInputTestModeChanged	 = @"ORSIS3800ModelEnableInputTestModeChanged";
NSString* ORSIS3800ModelEnable25MHzPulsesChanged	 = @"ORSIS3800ModelEnable25MHzPulsesChanged";
NSString* ORSIS3800ModelLemoInModeChanged			 = @"ORSIS3800ModelLemoInModeChanged";
NSString* ORSIS3800ModelCountEnableMaskChanged		 = @"ORSIS3800ModelCountEnableMaskChanged";
NSString* ORSIS3800SettingsLock						 = @"ORSIS3800SettingsLock";
NSString* ORSIS3800ModelIDChanged					 = @"ORSIS3800ModelIDChanged";
NSString* ORSIS3800CountersChanged					 = @"ORSIS3800CountersChanged";
NSString* ORSIS3800ModelOverFlowMaskChanged			 = @"ORSIS3800ModelOverFlowMaskChanged";
NSString* ORSIS3800PollTimeChanged					 = @"ORSIS3800PollTimeChanged";

//general register offsets
#define kControlStatus				0x00	
#define kModuleIDReg				0x04	
#define kSelectiveCountDisable		0x0C
#define kClearAllCounters			0x20
#define kClockShadowReg				0x24
#define kGlobalCountEnable			0x28
#define kGlobalCountDisable			0x2C
#define kBroadcastClearAllCounters	0x30
#define kBroadcastClockShadowReg	0x34
#define kBroadcastCountEnable		0x38
#define kBroadcastCountDisable		0x3C
#define kClear1_8					0x40
#define kClear9_16					0x44
#define kClear17_24					0x48
#define kClear25_32					0x4C
#define kEnableReferencePulserChan1 0x50
#define kDisableReferencePulserChan1 0x54
#define kGlobalReset				0x60
#define kTestPulse					0x68
#define kClearCounter0				0x100 //start address for 32 channels
#define kClearOverflowBitCounter0	0x180 //start address for 32 channels
#define kReadShadowReg				0x200 //start address for 32 channels
#define kReadCounter				0x280 //start address for 32 channels
#define kReadAndClearAllCounters	0x300 //start address for 32 channels
#define kOverflowReg1_8				0x380 
#define kOverflowReg9_16			0x3A0 
#define kOverflowReg17_24			0x3C0 
#define kOverflowReg25_32			0x3E0 

//bits in the status reg
#define kStatusUserLED				(1L<<0)
#define kStatusIRQForSoftwareTest	(1L<<1)
#define kStatusInputModeBit0		(1L<<2)
#define kStatusInputModeBit1		(1L<<3)
#define kStatus25MHzTestPulses		(1L<<4)
#define kStatusInputTestMode		(1L<<5)
#define kStatusBroadcastMode		(1L<<6)
#define kStatusBoadcastHandShake	(1L<<7)
#define kStatusEnableRefPulser		(1L<<13)
#define kStatusGeneralOverFlowBit	(1L<<14)
#define kStatusGlobalCountEnable	(1L<<15)
#define kStatusVMEIRQEnableSrc0		(1L<<20)
#define kStatusVMEIRQEnableSrc1		(1L<<21)
#define kStatusVMEIRQEnableSrc2		(1L<<22)
#define kStatusInternalVMEIRQ		(1L<<26)
#define kStatusVMEIRQ				(1L<<27)
#define kStatusVMEIRQsource0_OF		(1L<<28)
#define kStatusVMEIRQsource1_ExtClk	(1L<<29)
#define kStatusVMEIRQsource2_Test	(1L<<30)


//bits in the control reg
#define kSwitchUserLEDOn			(1L<<0)
#define kSetIRQTest					(1L<<1)
#define kSetInputModeBit0			(1L<<2)
#define kSetInputModeBit1			(1L<<3)
#define kEnable25MHzTestPulses		(1L<<4)
#define kEnableInputTestMode		(1L<<5)
#define kEnableBroadcastMode		(1L<<6)
#define kEnableBoadcastHandShake	(1L<<7)
#define kSwitchUserLEDOff			(1L<<8)
#define kClearIRQTestSource2		(1L<<9)
#define kClearInputModeBit0			(1L<<10)
#define kClearInputModeBit1			(1L<<11)
#define kDisable25MHzTestPulses		(1L<<12)
#define kDisableIputTestMode		(1L<<13)
#define kDisableBroadcastMode		(1L<<14)
#define kDisableBoadcastHandShake	(1L<<15)
#define kEnableIRQSource0			(1L<<20)
#define kEnableIRQSource1			(1L<<21)
#define kEnableIRQSource2			(1L<<22)
#define kDisableIRQSource0			(1L<<28)
#define kDisableIRQSource1			(1L<<29)
#define kDisableIRQSource2			(1L<<30)


#define kSIS3800DataLen (7+32)

@interface ORSIS3800Model (private)
- (void) shipData;
- (void) logTime;
@end

@implementation ORSIS3800Model

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setAddressModifier:0x09];
    [self setBaseAddress:0x38383800];
	[self setDefaults];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc 
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"SIS3800Card"]];	
}

- (void) makeMainController
{
    [self linkToController:@"ORSIS3800Controller"];
}

//- (NSString*) helpURL
//{
//	return @"VME/SIS330x.html";
//}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x0E4);
}

#pragma mark ***Accessors

- (BOOL) isCounting
{
    return isCounting;
}

- (void) setIsCounting:(BOOL)aState
{
	if(aState != isCounting){
		isCounting = aState;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3800ModelIsCountingChanged object:self];
	}
}

- (BOOL) syncWithRun
{
    return syncWithRun;
}

- (void) setSyncWithRun:(BOOL)aSyncWithRun
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSyncWithRun:syncWithRun];
    syncWithRun = aSyncWithRun;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3800ModelSyncWithRunChanged object:self];
}

- (BOOL) clearOnRunStart
{
    return clearOnRunStart;
}

- (void) setClearOnRunStart:(BOOL)aClearOnRunStart
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClearOnRunStart:clearOnRunStart];
    clearOnRunStart = aClearOnRunStart;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3800ModelClearOnRunStartChanged object:self];
}

- (float) convertedPollTime
{
	//if you change this you have to change the popup in the dialog as well
	float convertedPollTime[8] = {0,.5,1,2,5,10,20,60};
	if(pollTime>=0 && pollTime<8){
		return convertedPollTime[pollTime];
	}
	else return 0.0;
}

- (int) pollTime
{
    return pollTime;
}

- (void) setPollTime:(int)aPollTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollTime:pollTime];
    pollTime = aPollTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3800PollTimeChanged object:self];
	
	if(pollTime){
		[self performSelector:@selector(timeToPoll) withObject:nil afterDelay:0];
	}
	else {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeToPoll) object:nil];
	}
}

- (void) timeToPoll
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeToPoll) object:nil];
	[self readCounts:NO];
	[self shipData];
	
	[self performSelector:@selector(timeToPoll) withObject:nil afterDelay:[self convertedPollTime]];
}

- (BOOL) enableReferencePulser
{
    return enableReferencePulser;
}

- (void) setEnableReferencePulser:(BOOL)aEnableReferencePulser
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnableReferencePulser:enableReferencePulser];
    enableReferencePulser = aEnableReferencePulser;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3800ModelEnableReferencePulserChanged object:self];
}

- (BOOL) enableInputTestMode
{
    return enableInputTestMode;
}

- (void) setEnableInputTestMode:(BOOL)aEnableInputTestMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnableInputTestMode:enableInputTestMode];
    enableInputTestMode = aEnableInputTestMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3800ModelEnableInputTestModeChanged object:self];
}

- (BOOL) enable25MHzPulses
{
    return enable25MHzPulses;
}

- (void) setEnable25MHzPulses:(BOOL)aEnable25MHzPulses
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnable25MHzPulses:enable25MHzPulses];
    enable25MHzPulses = aEnable25MHzPulses;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3800ModelEnable25MHzPulsesChanged object:self];
}

- (int) lemoInMode
{
    return lemoInMode;
}

- (void) setLemoInMode:(int)aLemoInMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoInMode:lemoInMode];
    lemoInMode = aLemoInMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3800ModelLemoInModeChanged object:self];
}

- (unsigned long) counts:(int)i
{
	if(i>=0 && i<32)return counts[i];
	else return 0;
}

- (unsigned long) countEnableMask { return countEnableMask; }
- (void) setCountEnableMask:(unsigned long)aCountEnableMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCountEnableMask:countEnableMask];
    countEnableMask = aCountEnableMask;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3800ModelCountEnableMaskChanged object:self];
}

- (BOOL) countEnabled:(short)chan { return countEnableMask & (1<<chan); }
- (void) setCountEnabled:(short)chan withValue:(BOOL)aValue		
{ 
	NSLog(@"setting %d to %d\n",chan,aValue);
	unsigned long aMask = countEnableMask;
	if(aValue)aMask |= (1L<<chan);
	else aMask &= ~(1L<<chan);
	[self setCountEnableMask:aMask];
}

- (unsigned long) overFlowMask { return overFlowMask; }
- (void) setOverFlowMask:(unsigned long)aMask
{
    overFlowMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3800ModelOverFlowMaskChanged object:self];
}

- (void) setDefaults
{
	int i;
	for(i=0;i<32;i++){
		[self setCountEnabled:i withValue:YES];
	}
}

- (unsigned short) moduleID;
{
	return moduleID;
}

#pragma mark •••Hardware Access
- (void) readModuleID:(BOOL)verbose
{	
	unsigned long result = 0;
	[[self adapter] readLongBlock:&result
                         atAddress:[self baseAddress] + kModuleIDReg
                        numToRead:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	moduleID = result >> 16;
	unsigned short version = (result >> 12) & 0xf;
	if(verbose)NSLog(@"SIS3800 ID: %x  Version:%x\n",moduleID,version);
	
	[self readStatusRegister];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3800ModelIDChanged object:self];
}


- (void) readStatusRegister
{		
	unsigned long aMask = 0;
	[[self adapter] readLongBlock:&aMask
                         atAddress:[self baseAddress] + kControlStatus
                        numToRead:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	[self setIsCounting: (aMask & kStatusGlobalCountEnable)==kStatusGlobalCountEnable ];
}

- (void) writeControlRegister
{
	unsigned long aMask = 0x0;
	aMask |= 
	((lemoInMode & 0x3) << 2)			|  //the '1' bits set the mode bits
	((~lemoInMode & 0x3) << 10)			|  //the '0' bits set the mode clr bits
	((enable25MHzPulses & 0x1) << 4)	|
	((~enable25MHzPulses & 0x1) << 12)	|
	((enableInputTestMode & 0x1) << 5)	|
	((~enableInputTestMode & 0x1) << 13);
			  
	[[self adapter] writeLongBlock:&aMask
                         atAddress:[self baseAddress] + kControlStatus
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) setLed:(BOOL)state
{
	unsigned long aValue;
	if(state)	aValue = kSwitchUserLEDOn;
	else		aValue = kSwitchUserLEDOff;
	
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kControlStatus
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) initBoard
{  
	[self reset];
	[self writeControlRegister];
	[self writeCountEnableMask];
	[self readStatusRegister];
	[self enableReferencePulser:enableReferencePulser];
}

- (void) readCounts:(BOOL)clear
{
	//To ensure synchronicity to 5ns read the first scaler from 0x300 and the rest from the shadow registers
	unsigned long aValue = 0;
	[[self adapter] readLongBlock:&aValue
						atAddress:[self baseAddress] + (clear ? kReadAndClearAllCounters : kReadCounter)
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	counts[0] = aValue;
	int i;
	for(i=1;i<32;i++){
		[[self adapter] readLongBlock:&aValue
							atAddress:[self baseAddress] + kReadShadowReg + (4*i)
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];
		counts[i] = aValue;
	}
	[self readOverFlowRegisters];
	
	[self logTime];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3800CountersChanged object:self];

}

- (void) readOverFlowRegisters
{
	unsigned long aMask = 0;
	unsigned long aValue = 0;
	[[self adapter] readLongBlock:&aValue
						atAddress:[self baseAddress] + kOverflowReg1_8
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	aMask |= (aValue&0xff000000)>>24;
	
	[[self adapter] readLongBlock:&aValue
						atAddress:[self baseAddress] + kOverflowReg9_16
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	aMask |= (aValue & 0xff000000)<<16;
	
	[[self adapter] readLongBlock:&aValue
						atAddress:[self baseAddress] + kOverflowReg17_24
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	aMask |= (aValue & 0xff000000)<<8;
	
	[[self adapter] readLongBlock:&aValue
						atAddress:[self baseAddress] + kOverflowReg25_32
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	aMask |= (aValue & 0xff000000);
	
	[self setOverFlowMask:aMask];
}

- (void) clearCounter:(int)i
{
	unsigned long aValue;
	if(i>=0 && i<32){
		[[self adapter] writeLongBlock:&aValue
							atAddress:[self baseAddress] + kClearCounter0 + (4*i)
							numToWrite:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];
		counts[i] = 0;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3800CountersChanged object:self];	
}


- (void) writeCountEnableMask
{
	unsigned long aValue = ~countEnableMask;
	[[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress] + kSelectiveCountDisable
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void) clearOverFlowCounter:(int)i
{
	unsigned long aValue;
	if(i>=0 && i<32){
		[[self adapter] writeLongBlock:&aValue
							 atAddress:[self baseAddress] + kClearOverflowBitCounter0 + (4*i)
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
	}
	[self readOverFlowRegisters];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3800CountersChanged object:self];	
}

- (void) clearAll
{
	unsigned long aValue = 0;
	[[self adapter] writeLongBlock:&aValue
					atAddress:[self baseAddress] + kClearAllCounters
					numToWrite:1
					withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	int i;
	for(i=0;i<32;i++){
		counts[i] = 0;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3800CountersChanged object:self];	
}

- (void) clearCounterGroup:(int)group
{
	switch(group){
		case 0: [self clearCounterGroup0]; break;
		case 1: [self clearCounterGroup1]; break;
		case 2: [self clearCounterGroup2]; break;
		case 3: [self clearCounterGroup3]; break;
	}
}

- (void) clearCounterGroup0
{
	unsigned long aValue = 0;
	[[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress] + kClear1_8
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	int i;
	for(i=0;i<8;i++)counts[i] = 0;
		
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3800CountersChanged object:self];	
}

- (void) clearCounterGroup1
{
	unsigned long aValue = 0;
	[[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress] + kClear9_16
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	int i;
	for(i=8;i<16;i++)counts[i] = 0;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3800CountersChanged object:self];	
}

- (void) clearCounterGroup2
{
	unsigned long aValue = 0;
	[[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress] + kClear17_24
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	int i;
	for(i=16;i<24;i++)counts[i] = 0;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3800CountersChanged object:self];	
}

- (void) clearCounterGroup3
{
	unsigned long aValue = 0;
	[[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress] + kClear25_32
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	int i;
	for(i=24;i<32;i++)counts[i] = 0;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3800CountersChanged object:self];	
}

- (void) enableReferencePulser:(BOOL)state
{
	unsigned long aValue = 0;
	[[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress] + (state?kEnableReferencePulserChan1:kDisableReferencePulserChan1)
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3800CountersChanged object:self];	
}

- (void) generateTestPulse
{
	unsigned long aValue = 0;
	[[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress] + kTestPulse
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3800CountersChanged object:self];	
}

#pragma mark •••Data Taker
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm]; //short form preferred
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORSIS3800DecoderForCounts",				@"decoder",
								 [NSNumber numberWithLong:dataId],			@"dataId",
								 [NSNumber numberWithBool:NO],				@"variable",
								 [NSNumber numberWithLong:kSIS3800DataLen],	@"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Counts"];
    
    return dataDictionary;
}

#pragma mark •••HW Wizard

- (int) numberOfChannels
{
    return kNumSIS3800Channels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Enable Counters"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setCountEnabled:withValue:) getMethod:@selector(countEnabled:)];
    [a addObject:p];	
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setName:@"Init"];
    [p setSetMethodSelector:@selector(initBoard)];
    [a addObject:p];
    
    return a;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORVmeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card" className:@"ORSIS3800Model"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORSIS3800Model"]];
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    id obj = [cardDictionary objectForKey:param];
    if(obj)return obj;
    else return [[cardDictionary objectForKey:param] objectAtIndex:aChannel];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	[objDictionary setObject:[NSNumber numberWithLong:countEnableMask] forKey:@"countEnableMask"];
	
    return objDictionary;
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORSIS3800Model"];    
    
    //cache some stuff
  	if(!moduleID)[self readModuleID:NO];
	lastTimeMeasured = 0;
	[self reset];
    [self initBoard];
	if([self clearOnRunStart]){
		[self clearAll];
	}
	if([self syncWithRun]){
		[self startCounting];
	}
	[self setLed:YES];
	isRunning = NO;
}

//**************************************************************************************
// Function:	TakeData
// Description: Read data from a card
//**************************************************************************************
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	if([self syncWithRun]){
		[self stopCounting];
	}
	[self setLed:NO];
}

//this is the data structure for the new SBCs (i.e. VX704 from Concurrent)
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id				= kSIS3800; //should be unique
	configStruct->card_info[index].hw_mask[0]				= dataId; //better be unique
	configStruct->card_info[index].slot						= [self slot];
	configStruct->card_info[index].crate					= [self crateNumber];
	configStruct->card_info[index].add_mod					= [self addressModifier];
	configStruct->card_info[index].base_add					= [self baseAddress];
	configStruct->card_info[index].deviceSpecificData[0]	= moduleID;
	configStruct->card_info[index].num_Trigger_Indexes		= 0;
	
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	
	return index+1;
}

- (void) reset
{
 	unsigned long aValue = 0; //value doesn't matter 
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kGlobalReset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) startCounting
{
 	unsigned long aValue = 0; //value doesn't matter 
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kGlobalCountEnable
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	[self readStatusRegister];
}

- (void) stopCounting
{
	unsigned long aValue = 0; //value doesn't matter 
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kGlobalCountDisable
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	[self readStatusRegister];
}


#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setSyncWithRun:[decoder decodeBoolForKey:@"syncWithRun"]];
    [self setClearOnRunStart:[decoder decodeBoolForKey:@"clearOnRunStart"]];
    [self setEnableReferencePulser:[decoder decodeBoolForKey:@"enableReferencePulser"]];
    [self setEnableInputTestMode:[decoder decodeBoolForKey:@"enableInputTestMode"]];
    [self setEnable25MHzPulses:[decoder decodeBoolForKey:@"enable25MHzPulses"]];
    [self setLemoInMode:[decoder decodeIntForKey:@"lemoInMode"]];
    [self setPollTime:[decoder decodeIntForKey:@"pollTime"]];
    [self setCountEnableMask:[decoder decodeInt32ForKey:@"countEnableMask"]];

    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:syncWithRun forKey:@"syncWithRun"];
    [encoder encodeBool:clearOnRunStart forKey:@"clearOnRunStart"];
    [encoder encodeBool:enableReferencePulser forKey:@"enableReferencePulser"];
    [encoder encodeBool:enableInputTestMode forKey:@"enableInputTestMode"];
    [encoder encodeBool:enable25MHzPulses forKey:@"enable25MHzPulses"];
    [encoder encodeInt:lemoInMode forKey:@"lemoInMode"];
    [encoder encodeInt:pollTime forKey:@"pollTime"];
    [encoder encodeInt32:countEnableMask forKey:@"countEnableMask"];
}

@end

@implementation ORSIS3800Model (private)
- (void) logTime
{
	time_t	ut_Time;
	time(&ut_Time);
	lastTimeMeasured = timeMeasured;
	timeMeasured = ut_Time;
}

- (void) shipData
{
	if([[ORGlobal sharedGlobal] runInProgress]){
		
		unsigned long data[kSIS3800DataLen];
		data[0] = dataId | kSIS3800DataLen;
		data[1] = (([self crateNumber]&0x0000000f)<<21) | (([self slot]& 0x0000001f)<<16);
		if(moduleID == 3820)data[1] |= 1;
		
		data[2] = timeMeasured;
		data[3] = lastTimeMeasured;
		data[4] = countEnableMask;
		data[5] = overFlowMask;
		
		data[6] =	
			lemoInMode |
			enable25MHzPulses<<3 |
			enableInputTestMode<<4 |
			enableReferencePulser<<5 |
			clearOnRunStart<<6 |
			syncWithRun<<7;
		   
		int i;
		for(i=0;i<32;i++){
			data[7+i] = counts[i];
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
															object:[NSData dataWithBytes:&data length:sizeof(long)*kSIS3800DataLen]];
	}
}

@end

