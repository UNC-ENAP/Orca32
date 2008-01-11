//-------------------------------------------------------------------------
//  ORGretina4Model.h
//
//  Created by Mark A. Howe on Wednesday 02/07/2007.
//  Copyright (c) 2007 CENPA. University of Washington. All rights reserved.
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "ORGretina4Model.h"
#import "ORDataTypeAssigner.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORVmeCrateModel.h"
#import "ORRateGroup.h"
#import "ORTimer.h"
#import "VME_HW_Definitions.h"

NSString* ORGretina4ModelNoiseFloorIntegrationTimeChanged = @"ORGretina4ModelNoiseFloorIntegrationTimeChanged";
NSString* ORGretina4ModelNoiseFloorOffsetChanged = @"ORGretina4ModelNoiseFloorOffsetChanged";
NSString* ORGretina4CardInfoUpdated				= @"ORGretina4CardInfoUpdated";
NSString* ORGretina4RateGroupChangedNotification= @"ORGretina4RateGroupChangedNotification";
NSString* ORGretina4SettingsLock				= @"ORGretina4SettingsLock";
NSString* ORGretina4NoiseFloorChanged			= @"ORGretina4NoiseFloorChanged";
NSString* ORGretina4ModelFIFOCheckChanged		= @"ORGretina4ModelFIFOCheckChanged";

NSString* ORGretina4ModelEnabledChanged			= @"ORGretina4ModelEnabledChanged";
NSString* ORGretina4ModelCFDEnabledChanged		= @"ORGretina4ModelCFDEnabledChanged";
NSString* ORGretina4ModelPoleZeroEnabledChanged	= @"ORGretina4ModelPoleZeroEnabledChanged";
NSString* ORGretina4ModelDebugChanged			= @"ORGretina4ModelDebugChanged";
NSString* ORGretina4ModelPileUpChanged			= @"ORGretina4ModelPileUpChanged";
NSString* ORGretina4ModelPolarityChanged		= @"ORGretina4ModelPolarityChanged";
NSString* ORGretina4ModelTriggerModeChanged		= @"ORGretina4ModelTriggerModeChanged";
NSString* ORGretina4ModelLEDThresholdChanged	= @"ORGretina4ModelLEDThresholdChanged";
NSString* ORGretina4ModelCFDDelayChanged		= @"ORGretina4ModelCFDDelayChanged";
NSString* ORGretina4ModelCFDFractionChanged		= @"ORGretina4ModelCFDFractionChanged";
NSString* ORGretina4ModelCFDThresholdChanged	= @"ORGretina4ModelCFDThresholdChanged";
NSString* ORGretina4ModelDataDelayChanged		= @"ORGretina4ModelDataDelayChanged";
NSString* ORGretina4ModelDataLengthChanged		= @"ORGretina4ModelDataLengthChanged";


@implementation ORGretina4Model
#pragma mark ���Static Declarations
//offsets from the base address
static unsigned long register_offsets[kNumberOfGretina4Registers] = {
    0x00,  //[0] board ID
    0x04,  //[1] Programming done
    0x08,  //[2] External Window
    0x0C,  //[3] Pileup Window
    0x10,  //[4] Noise Window
    0x14,  //[5] Extrn trigger sliding length
    0x18,  //[6] Collection time
    0x1C,  //[7] Integration time
    0x20,  //[8] Hardware Status
    0x40,  //[9] Control/Status
    0x80,  //[10] LED Threshold
    0xC0,  //[11] CFD Parameters
    0x100, //[12] Raw data sliding length
    0x140, //[13] Raw data window length
    0x400, //[14] DAC
	0x480, //[15] Slave Front bus status
    0x484, //[16] Channel Zero time stamp LSB
    0x488, //[17] Channel Zero time stamp MSB
    0x48C, //[18] Slave Front Bus Send Box 18 - 1
    0x4D4, //[19] Slave Front bus register 0 - 10
    0x500, //[20] Master Logic Status
    0x504, //[21] SlowData CCLED timers
    0x508, //[22] DeltaT155_DeltaT255 (3)
    0x514, //[23] SnapShot 
    0x518, //[24] XTAL ID 
    0x51C, //[25] Length of Time to get Hit Pattern 
    0x520, //[26] Front Side Bus Register
    0x524, //[27] FrontBus Registers 0-10
	0x780, //[28] Debug data buffer address
	0x784, //[29] Debug data buffer data
	0x788, //[30] LED flag window
	0x800, //[31] Aux io read
	0x804, //[32] Aux io write
	0x808, //[33] Aux io config
	0x820, //[34] FB_Read
	0x824, //[35] FB_Write
	0x828, //[36] FB_Config
	0x840, //[37] SD_Read
	0x844, //[38] SD_Write
	0x848, //[39] SD_Config
	0x84C, //[40] Adc config
	0x860, //[41] self trigger enable
	0x864, //[42] self trigger period
	0x868, //[43] self trigger count
};

enum {
    kExternalWindowIndex,
    kPileUpWindowIndex,
    kNoiseWindowIndex,
    kExtTrigLengthIndex,
    kCollectionTimeIndex,
    kIntegrationTimeIndex
};

static struct {
    NSString*	name;
    NSString*	units;
    unsigned long	regOffset;
    unsigned short	mask; 
    unsigned short	initialValue;
    float		ratio; //conversion constants
} cardConstants[kNumGretina4CardParams] = {
    {@"External Window",	@"us",	0x08,	0x7FF,	0x190, 4./(float)0x190},
    {@"Pileup Window",		@"us",	0x0C,	0x7FF,	0x0400,	10./(float)0x400},
    {@"Noise Window",		@"ns",	0x10,	0x07F,	0x0040,	640./(float)0x40},
    {@"Ext Trigger Length", @"us",	0x14,	0x7FF,	0x0190,	4.0/(float)0x190},
    {@"Collection Time",	@"us",	0x18,	0x01FF,	0x01C2,	4.5/(float)0x1C2},
    {@"Integration Time",	@"us",	0x1C,	0x01FF,	0x01C2,	4.5/(float)0x1C2},
};


#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self initParams];
    [self setAddressModifier:0x09];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc 
{
    [waveFormRateGroup release];
    [cardInfo release];
	[fifoFullAlarm clearAlarm];
	[fifoFullAlarm release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Gretina4Card"]];	
}

- (void) makeMainController
{
    [self linkToController:@"ORGretina4Controller"];
}

- (Class) guardianClass
{
	return NSClassFromString(@"ORVme64CrateModel");
}

#pragma mark ***Accessors

- (float) noiseFloorIntegrationTime
{
    return noiseFloorIntegrationTime;
}

- (void) setNoiseFloorIntegrationTime:(float)aNoiseFloorIntegrationTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNoiseFloorIntegrationTime:noiseFloorIntegrationTime];

    if(aNoiseFloorIntegrationTime<.01)aNoiseFloorIntegrationTime = .01;
	else if(aNoiseFloorIntegrationTime>5)aNoiseFloorIntegrationTime = 5;
	
    noiseFloorIntegrationTime = aNoiseFloorIntegrationTime;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelNoiseFloorIntegrationTimeChanged object:self];
}

- (int) fifoState
{
    return fifoState;
}

- (void) setFifoState:(int)aFifoState
{
    fifoState = aFifoState;
}

- (int) noiseFloorOffset
{
    return noiseFloorOffset;
}

- (void) setNoiseFloorOffset:(int)aNoiseFloorOffset
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNoiseFloorOffset:noiseFloorOffset];
    
    noiseFloorOffset = aNoiseFloorOffset;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelNoiseFloorOffsetChanged object:self];
}

- (ORRateGroup*) waveFormRateGroup
{
    return waveFormRateGroup;
}
- (void) setWaveFormRateGroup:(ORRateGroup*)newRateGroup
{
    [newRateGroup retain];
    [waveFormRateGroup release];
    waveFormRateGroup = newRateGroup;
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORGretina4RateGroupChangedNotification
                      object:self];    
}

- (BOOL) noiseFloorRunning
{
	return noiseFloorRunning;
}

- (id) rateObject:(int)channel
{
    return [waveFormRateGroup rateObject:channel];
}

- (void) initParams
{

	int i;
	for(i=0;i<kNumGretina4Channels;i++){
		enabled[i]			= YES;
		debug[i]			= NO;
		pileUp[i]			= NO;
        cfdEnabled[i]		= NO;
		poleZeroEnabled[i]	= NO;
		polarity[i]			= 0x3;
		triggerMode[i]		= 0x0;
		ledThreshold[i]		= 0x1FFFF;
		cfdDelay[i]			= 0x3f;
		cfdFraction[i]		= 0x0;
		cfdThreshold[i]		= 0x10;
		dataDelay[i]		= 0x1C2;
		dataLength[i]		= 0x3FF;
	}
	
    if(!cardInfo){
        cardInfo = [[NSMutableArray array] retain];
        int i;
        for(i=0;i<kNumGretina4CardParams;i++){
            [cardInfo addObject:[NSNumber numberWithInt:cardConstants[i].initialValue]];
        }
    }	
}

- (void) cardInfo:(int)index setObject:(id)aValue
{	
    [[[self undoManager] prepareWithInvocationTarget:self] cardInfo:index setObject:[self cardInfo:index]];
    [cardInfo replaceObjectAtIndex:index withObject:aValue];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4CardInfoUpdated object:self];
}

- (id) rawCardValue:(int)index value:(id)aValue 
{	
    float theValue = [aValue floatValue];
    unsigned short theRawValue = theValue / cardConstants[index].ratio;
    return [NSNumber numberWithInt: theRawValue & cardConstants[index].mask];
}

- (id) convertedCardValue:(int)index
{	
    int theValue  = [[cardInfo objectAtIndex:index] intValue];
    float theConvertedValue = theValue * cardConstants[index].ratio;
    return [NSNumber numberWithFloat: theConvertedValue];
}


- (id) cardInfo:(int)index
{
    return [cardInfo objectAtIndex:index];
}


- (void) setRateIntegrationTime:(double)newIntegrationTime
{
	//we this here so we have undo/redo on the rate object.
    [[[self undoManager] prepareWithInvocationTarget:self] setRateIntegrationTime:[waveFormRateGroup integrationTime]];
    [waveFormRateGroup setIntegrationTime:newIntegrationTime];
}

#pragma mark ���Rates
- (unsigned long) getCounter:(int)counterTag forGroup:(int)groupTag
{
	if(groupTag == 0){
		if(counterTag>=0 && counterTag<kNumGretina4Channels){
			return waveFormCount[counterTag];
		}	
		else return 0;
	}
	else return 0;
}
#pragma mark ���specific accessors
- (void) setExternalWindow:(int)aValue { [self cardInfo:kExternalWindowIndex  setObject:[NSNumber numberWithInt:aValue]]; }
- (void) setPileUpWindow:(int)aValue   { [self cardInfo:kPileUpWindowIndex    setObject:[NSNumber numberWithInt:aValue]]; }
- (void) setNoiseWindow:(int)aValue    { [self cardInfo:kNoiseWindowIndex		setObject:[NSNumber numberWithInt:aValue]]; }
- (void) setExtTrigLength:(int)aValue  { [self cardInfo:kExtTrigLengthIndex   setObject:[NSNumber numberWithInt:aValue]]; }
- (void) setCollectionTime:(int)aValue { [self cardInfo:kCollectionTimeIndex  setObject:[NSNumber numberWithInt:aValue]]; }
- (void) setIntegratonTime:(int)aValue { [self cardInfo:kIntegrationTimeIndex setObject:[NSNumber numberWithInt:aValue]]; }

- (int) externalWindow   { return [[self cardInfo:kExternalWindowIndex] intValue]; }
- (int) pileUpWindow	 { return [[self cardInfo:kPileUpWindowIndex] intValue]; }
- (int) noiseWindow		 { return [[self cardInfo:kNoiseWindowIndex] intValue]; }
- (int) extTrigLength    { return [[self cardInfo:kExtTrigLengthIndex] intValue]; }
- (int) collectionTime   { return [[self cardInfo:kCollectionTimeIndex] intValue]; }
- (int) integrationTime  { return [[self cardInfo:kIntegrationTimeIndex] intValue]; }

- (void) setEnabled:(short)chan withValue:(short)aValue		
{ 
    [[[self undoManager] prepareWithInvocationTarget:self] setEnabled:chan withValue:enabled[chan]];
	enabled[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelEnabledChanged object:self];
}

- (void) setCFDEnabled:(short)chan withValue:(short)aValue		
{ 
    [[[self undoManager] prepareWithInvocationTarget:self] setCFDEnabled:chan withValue:cfdEnabled[chan]];
	cfdEnabled[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelCFDEnabledChanged object:self];
}

- (void) setPoleZeroEnabled:(short)chan withValue:(short)aValue		
{ 
    [[[self undoManager] prepareWithInvocationTarget:self] setPoleZeroEnabled:chan withValue:poleZeroEnabled[chan]];
	poleZeroEnabled[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelPoleZeroEnabledChanged object:self];
}

- (void) setDebug:(short)chan withValue:(short)aValue	
{ 
    [[[self undoManager] prepareWithInvocationTarget:self] setDebug:chan withValue:debug[chan]];
	debug[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelDebugChanged object:self];
}

- (void) setPileUp:(short)chan withValue:(short)aValue		
{ 
    [[[self undoManager] prepareWithInvocationTarget:self] setPileUp:chan withValue:pileUp[chan]];
	pileUp[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelPileUpChanged object:self];
}

- (void) setPolarity:(short)chan withValue:(int)aValue		
{
	if(aValue<0)aValue=0;
	else if(aValue>0x3)aValue= 0x3;
    [[[self undoManager] prepareWithInvocationTarget:self] setPolarity:chan withValue:polarity[chan]];
	polarity[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelPolarityChanged object:self];
}

- (void) setTriggerMode:(short)chan withValue:(int)aValue	
{ 
	if(aValue<0)aValue=0;
	else if(aValue>0x3)aValue= 0x3;
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerMode:chan withValue:triggerMode[chan]];
	triggerMode[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelTriggerModeChanged object:self];
}

- (void) setLEDThreshold:(short)chan withValue:(int)aValue 
{ 
	if(aValue<0)aValue=0;
	else if(aValue>0x1FFFF)aValue = 0x1FFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setLEDThreshold:chan withValue:ledThreshold[chan]];
	ledThreshold[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelLEDThresholdChanged object:self];
}

- (void) setCFDDelay:(short)chan withValue:(int)aValue		
{
	if(aValue<0)aValue=0;
	else if(aValue>0x3F)aValue = 0x3F;
    [[[self undoManager] prepareWithInvocationTarget:self] setCFDDelay:chan withValue:cfdDelay[chan]];
	cfdDelay[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelCFDDelayChanged object:self];
}

- (void) setCFDFraction:(short)chan withValue:(int)aValue	
{ 
	if(aValue<0)aValue=0;
	else if(aValue>0x11)aValue = 0x11;
    [[[self undoManager] prepareWithInvocationTarget:self] setCFDFraction:chan withValue:cfdFraction[chan]];
	cfdFraction[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelCFDFractionChanged object:self];
}

- (void) setCFDThreshold:(short)chan withValue:(int)aValue  
{
	if(aValue<0)aValue=0;
	else if(aValue>0x1F)aValue = 0x1F;
    [[[self undoManager] prepareWithInvocationTarget:self] setCFDThreshold:chan withValue:cfdThreshold[chan]];
	cfdThreshold[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelCFDThresholdChanged object:self];
}

- (void) setDataDelay:(short)chan withValue:(int)aValue     
{
	if(aValue<0)aValue=0;
	else if(aValue>0x7FF)aValue = 0x7FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setDataDelay:chan withValue:dataDelay[chan]];
	dataDelay[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelDataDelayChanged object:self];
}

- (void) setDataLength:(short)chan withValue:(int)aValue    
{
	if(aValue<0x0)aValue=0x0;
	else if(aValue>0x3FF)aValue = 0x3FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setDataLength:chan withValue:dataLength[chan]];
	dataLength[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelDataLengthChanged object:self];
}

- (int) enabled:(short)chan			{ return enabled[chan]; }
- (int) cfdEnabled:(short)chan		{ return cfdEnabled[chan]; }
- (int) poleZeroEnabled:(short)chan	{ return poleZeroEnabled[chan]; }
- (int) debug:(short)chan			{ return debug[chan]; }
- (int) pileUp:(short)chan			{ return pileUp[chan];}
- (int) polarity:(short)chan		{ return polarity[chan];}
- (int) triggerMode:(short)chan		{ return triggerMode[chan];}
- (int) ledThreshold:(short)chan	{ return ledThreshold[chan]; }
- (int) cfdDelay:(short)chan		{ return cfdDelay[chan]; }
- (int) cfdFraction:(short)chan		{ return cfdFraction[chan]; }
- (int) cfdThreshold:(short)chan	{ return cfdThreshold[chan]; }
- (int) dataDelay:(short)chan		{ return dataDelay[chan]; }
- (int) dataLength:(short)chan		{ return dataLength[chan]; }


- (float) cfdDelayConverted:(short)chan		{ return cfdDelay[chan]*630./(float)0x3F; }		//convert to ns
- (float) cfdThresholdConverted:(short)chan	{ return cfdThreshold[chan]*160./(float)0x10; }	//convert to kev
- (float) dataDelayConverted:(short)chan	{ return dataDelay[chan]*4.5/(float)0x01C2; }	//convert to µs
- (float) dataLengthConverted:(short)chan	{ return dataLength[chan]*10.0; }               //convert to ns

- (void) setCFDDelayConverted:(short)chan withValue:(float)aValue
{
	[self setCFDDelay:chan withValue:aValue*0x3F/630.];		//ns -> raw
}
	
- (void) setCFDThresholdConverted:(short)chan withValue:(float)aValue
{
	[self setCFDThreshold:chan withValue:aValue*0x10/160.];		//kev -> raw
}

- (void) setDataDelayConverted:(short)chan withValue:(float)aValue;
{
	[self setDataDelay:chan withValue:aValue*0x01C2/4.5];		//µs -> raw
} 
 
- (void) setDataLengthConverted:(short)chan withValue:(float)aValue
{
	[self setDataLength:chan withValue:aValue/10.0];		//ns -> raw
}  

#pragma mark ���Hardware Access
- (unsigned long) baseAddress
{
	return (([self slot]+1)&0x1f)<<20;
}

- (short) readBoardID
{
    unsigned long theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_offsets[kBoardID]
                        numToRead:1
                        withAddMod:[self addressModifier]
                        usingAddSpace:0x01];
    return theValue & 0xffff;
}

- (void) resetDCM
{
    unsigned long theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_offsets[kSDConfig]
                        numToRead:1
                        withAddMod:[self addressModifier]
                        usingAddSpace:0x01];
    
    /* To reset the DCM, assert bit 9 of this register. */
    theValue |= 0x200;
    
    [[self adapter] writeLongBlock:&theValue
                        atAddress:[self baseAddress] + register_offsets[kSDConfig]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                        usingAddSpace:0x01];
    /* OK, that should do it. */
}

- (void) resetBoard
{
    /* First disable all channels. This does not affect the model state,
       just the board state. */
    int i;
    for(i=0;i<kNumGretina4Channels;i++){
        [self writeControlReg:i enabled:NO];
    }

    /* Then reset the DCM clock. (This will also reset the serdes.) */
    [self resetDCM];
    
    /* Finally, initialize the serdes. */
    [self initSerDes];
}

- (void) initSerDes
{
    unsigned long theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_offsets[kHardwareStatus]
                        numToRead:1
                        withAddMod:[self addressModifier]
                        usingAddSpace:0x01];
                        
    if ((theValue & 0x7) == 0x7) return;
    theValue = 0x22;
    /* First we set to loop back mode so the SD can lock. */
    [[self adapter] writeLongBlock:&theValue
                        atAddress:[self baseAddress] + register_offsets[kSDConfig]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                        usingAddSpace:0x01];

    
    while(1) {
        /* Wait for the SD and DCM to lock */
        [[self adapter] readLongBlock:&theValue
                            atAddress:[self baseAddress] + register_offsets[kHardwareStatus]
                            numToRead:1
                            withAddMod:[self addressModifier]
                            usingAddSpace:0x01];
                    
        if ((theValue & 0x7) == 0x7) break;
    }
    theValue = 0x02;
    [[self adapter] writeLongBlock:&theValue
                            atAddress:[self baseAddress] + register_offsets[kSDConfig]
                            numToWrite:1
                            withAddMod:[self addressModifier]
                            usingAddSpace:0x01];    
}

- (void) initBoard
{
    [self initSerDes];
    //write the card level params
    int i;
    for(i=0;i<kNumGretina4CardParams;i++){
        unsigned long theValue = [[cardInfo objectAtIndex:i] longValue];
        [[self adapter] writeLongBlock:&theValue
                             atAddress:[self baseAddress] + cardConstants[i].regOffset
                            numToWrite:1
                            withAddMod:[self addressModifier]
                         usingAddSpace:0x01];
    }
    //write the channel level params
    for(i=0;i<kNumGretina4Channels;i++){
        [self writeControlReg:i enabled:YES];
        [self writeLEDThreshold:i];
        [self writeCFDParameters:i];
        [self writeRawDataSlidingLength:i];
        [self writeRawDataWindowLength:i];
    }
    
}

- (unsigned long) readControlReg:(int)channel
{
    unsigned long theValue = 0 ;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_offsets[kControlStatus] + 4*channel
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    return theValue;
}

- (void) writeControlReg:(int)chan enabled:(BOOL)forceEnable
{
 
    BOOL startStop;
    if(forceEnable)	startStop= enabled[chan];
    else			startStop = NO;
	
    unsigned long theValue = (poleZeroEnabled[chan] << 13) | (cfdEnabled[chan] << 12) | (polarity[chan] << 10) 
        | (triggerMode[chan] << 3) | (pileUp[chan] << 2) | (debug[chan] << 1) | startStop;
    [[self adapter] writeLongBlock:&theValue
                         atAddress:[self baseAddress] + register_offsets[kControlStatus] + 4*chan
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    unsigned long readBackValue = [self readControlReg:chan];
    if((readBackValue & 0xC1F) != (theValue & 0xC1F)){
        NSLogColor([NSColor redColor],@"Channel %d status reg readback != writeValue (0x%x != 0x%x)\n",chan,readBackValue & 0xC1F,theValue & 0xC1F);
    }
}

- (void) writeLEDThreshold:(int)channel
{    
    [[self adapter] writeLongBlock:&ledThreshold[channel]
                         atAddress:[self baseAddress] + register_offsets[kLEDThreshold] + 4*channel
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}

- (void) writeCFDParameters:(int)channel
{    
    unsigned long theValue = ((cfdDelay[channel] & 0x3F) << 7) | ((cfdFraction[channel] & 0x3) << 5) | (cfdThreshold[channel]);
    [[self adapter] writeLongBlock:&theValue
                         atAddress:[self baseAddress] + register_offsets[kCFDParameters] + 4*channel
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}

- (void) writeRawDataSlidingLength:(int)channel
{    
    unsigned long theValue = (unsigned long)dataDelay[channel];
    [[self adapter] writeLongBlock:&theValue
                         atAddress:[self baseAddress] + register_offsets[kRawDataSlidingLength] + 4*channel
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}

- (void) writeRawDataWindowLength:(int)channel
{    
	unsigned long aValue = dataLength[channel];
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + register_offsets[kRawDataWindowLength] + 4*channel
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}


- (unsigned short) readFifoState
{
    unsigned long theValue = 0 ;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_offsets[kProgrammingDone]
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    if((theValue & kGretina4FIFOEmpty)!=0)		return kEmpty;
    else if((theValue & kGretina4FIFOAllFull)!=0)		return kFull;
    else if((theValue & kGretina4FIFOAlmostFull)!=0)	return kAlmostFull;
    else if((theValue & kGretina4FIFOAlmostEmpty)!=0)	return kAlmostEmpty;
    else						return kHalfFull;
}

- (unsigned long) readFIFO:(unsigned long)index
{
    unsigned long theValue = 0 ;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress]*0x100 + (4*index)
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return theValue;
}

- (void) writeFIFO:(unsigned long)index value:(unsigned long)aValue
{
    [[self adapter] writeLongBlock:&aValue
                         atAddress:([self baseAddress]*0x100) + (4*index)
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (int) clearFIFO
{
	int count = 0;
	NSDate* startDate = [NSDate date];
    fifoStateAddress  = [self baseAddress] + register_offsets[kProgrammingDone];
    fifoAddress       = [self baseAddress] + 0x1000;
	theController     = [self adapter];
	unsigned long  dataDump[0xffff];
	BOOL error		  = NO;
    while(1){
		unsigned long val;
		//read the fifo state
		[theController readLongBlock:&val
						   atAddress:fifoStateAddress
						   numToRead:1
						  withAddMod:[self addressModifier]
					   usingAddSpace:0x01];
		if((val & kGretina4FIFOEmpty) == 0){
			//read the first longword which should be the packet separator: 0xAAAAAAAA
			unsigned long theValue;
			[theController readLongBlock:&theValue 
							   atAddress:fifoAddress 
							   numToRead:1 
							  withAddMod:[self addressModifier] 
						   usingAddSpace:0x01];
			
			if(theValue==0xAAAAAAAA){
				//read the first word of actual data so we know how much to read
				[theController readLongBlock:&theValue 
								   atAddress:fifoAddress 
								   numToRead:1 
								  withAddMod:[self addressModifier] 
							   usingAddSpace:0x01];
																		
				[theController readLongBlock:dataDump 
							  atAddress:fifoAddress 
							numToRead:((theValue & 0xffff0000)>>16)-1  //number longs left to read
							 withAddMod:[self addressModifier] 
						  usingAddSpace:0x01];
				count++;
			}
			else {
				error = YES;
				break;
			}
		}
		else break;

		if([[NSDate date] timeIntervalSinceDate:startDate] > 10){
			error = YES;
			break;
		}
    }

	if(error){
		NSLog(@"Unable to clear FIFO on Gretina4 card (slot %d)\n",[self slot]);
		[NSException raise:@"Gretina card Error" format:@"unable to clear FIFO on Gretina4 card (slot %d)",[self slot]];
	}
	
	return count;
}

- (void) findNoiseFloors
{
	if(noiseFloorRunning){
		noiseFloorRunning = NO;
	}
	else {
		noiseFloorState = 0;
		noiseFloorRunning = YES;
		[self performSelector:@selector(stepNoiseFloor) withObject:self afterDelay:0];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4NoiseFloorChanged object:self];
}

- (void) stepNoiseFloor
{
	[[self undoManager] disableUndoRegistration];
  
    NS_DURING
		unsigned long val;

		switch(noiseFloorState){
			case 0: //init
				//disable all channels
				[self initBoard];
				int i;
				for(i=0;i<kNumGretina4Channels;i++){
					oldEnabled[i] = [self enabled:i];
					[self setEnabled:i withValue:NO];
					[self writeControlReg:i enabled:NO];
					oldLEDThreshold[i] = [self ledThreshold:i];
					[self setLEDThreshold:i withValue:0x7fff];
					newLEDThreshold[i] = 0x7fff;
				}
				noiseFloorWorkingChannel = -1;
				//find first channel
				for(i=0;i<kNumGretina4Channels;i++){
					if(oldEnabled[i]){
						noiseFloorWorkingChannel = i;
						break;
					}
				}
				if(noiseFloorWorkingChannel>=0){
					noiseFloorLow			= 0;
					noiseFloorHigh		= 0x7FFF;
					noiseFloorTestValue	= 0x7FFF/2;              //Initial probe position
					[self setLEDThreshold:noiseFloorWorkingChannel withValue:noiseFloorHigh];
					[self writeLEDThreshold:noiseFloorWorkingChannel];
					[self setEnabled:noiseFloorWorkingChannel withValue:YES];
					[self writeControlReg:noiseFloorWorkingChannel enabled:YES];
					[self clearFIFO];
					noiseFloorState = 1;
				}
				else {
					noiseFloorState = 2; //nothing to do
				}
			break;
			
			case 1:
				if(noiseFloorLow <= noiseFloorHigh) {
					[self setLEDThreshold:noiseFloorWorkingChannel withValue:noiseFloorTestValue];
					[self writeLEDThreshold:noiseFloorWorkingChannel];
					noiseFloorState = 2;	//go check for data
				}
				else {
					newLEDThreshold[noiseFloorWorkingChannel] = noiseFloorTestValue + noiseFloorOffset;
					[self setEnabled:noiseFloorWorkingChannel withValue:NO];
					[self writeControlReg:noiseFloorWorkingChannel enabled:NO];
					[self setLEDThreshold:noiseFloorWorkingChannel withValue:0x7fff];
					[self writeLEDThreshold:noiseFloorWorkingChannel];
					noiseFloorState = 3;	//done with this channel
				}
			break;
			
			case 2:
				//read the fifo state
				[[self adapter] readLongBlock:&val
									   atAddress:[self baseAddress] + register_offsets[kProgrammingDone]
									   numToRead:1
									  withAddMod:[self addressModifier]
								   usingAddSpace:0x01];

				if((val & kGretina4FIFOEmpty) == 0){
					//there's some data in fifo so we're too low with the threshold
					[self setLEDThreshold:noiseFloorWorkingChannel withValue:0x7fff];
					[self writeLEDThreshold:noiseFloorWorkingChannel];
					[self clearFIFO];
					noiseFloorLow = noiseFloorTestValue + 1;
				}
				else noiseFloorHigh = noiseFloorTestValue - 1;										//no data so continue lowering threshold
				noiseFloorTestValue = noiseFloorLow+((noiseFloorHigh-noiseFloorLow)/2);     //Next probe position.
				noiseFloorState = 1;	//continue with this channel
			break;
			
			case 3:
				//go to next channel
				noiseFloorLow		= 0;
				noiseFloorHigh		= 0x7FFF;
				noiseFloorTestValue	= 0x7FFF/2;              //Initial probe position
				//find first channel
				int startChan = noiseFloorWorkingChannel+1;
				noiseFloorWorkingChannel = -1;
				for(i=startChan;i<kNumGretina4Channels;i++){
					if(oldEnabled[i]){
						noiseFloorWorkingChannel = i;
						break;
					}
				}
				if(noiseFloorWorkingChannel >= startChan){
					[self setEnabled:noiseFloorWorkingChannel withValue:YES];
					[self writeControlReg:noiseFloorWorkingChannel enabled:YES];
					noiseFloorState = 1;
				}
				else {
					noiseFloorState = 4;
				}
			break;
							
			case 4: //finish up	
				//load new results
				for(i=0;i<kNumGretina4Channels;i++){
					[self setEnabled:i withValue:oldEnabled[i]];
					[self setLEDThreshold:i withValue:newLEDThreshold[i]];
				}
				[self initBoard];
				noiseFloorRunning = NO;
			break;
		}
		if(noiseFloorRunning){
			[self performSelector:@selector(stepNoiseFloor) withObject:self afterDelay:noiseFloorIntegrationTime];
		}
		else {
			[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4NoiseFloorChanged object:self];
		}
    NS_HANDLER
        int i;
        for(i=0;i<kNumGretina4Channels;i++){
            [self setEnabled:i withValue:oldEnabled[i]];
            [self setLEDThreshold:i withValue:oldLEDThreshold[i]];
        }
		NSLog(@"Gretina4 LED threshold finder quit because of exception\n");
    NS_ENDHANDLER
	[[self undoManager] enableUndoRegistration];
}


#pragma mark ���Data Taker
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
        @"ORGretina4WaveformDecoder",             @"decoder",
        [NSNumber numberWithLong:dataId],        @"dataId",
        [NSNumber numberWithBool:YES],           @"variable",
        [NSNumber numberWithLong:-1],			 @"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"Gretina4"];
    
    return dataDictionary;
}


#pragma mark ���HW Wizard
-(BOOL) hasParmetersToRamp
{
	return YES;
}
- (int) numberOfChannels
{
    return kNumGretina4Channels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"External Window"];
    [p setFormat:@"##0" upperLimit:0x7ff lowerLimit:0 stepSize:1 units:cardConstants[kExternalWindowIndex].units];
    [p setSetMethod:@selector(setExternalWindow:) getMethod:@selector(externalWindow)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Pileup Window"];
    [p setFormat:@"##0" upperLimit:0x7ff lowerLimit:0 stepSize:1 units:cardConstants[kPileUpWindowIndex].units];
    [p setSetMethod:@selector(setPileUpWindow:) getMethod:@selector(pileUpWindow)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Noise Window"];
    [p setFormat:@"##0" upperLimit:0x3f lowerLimit:0 stepSize:1 units:cardConstants[kNoiseWindowIndex].units];
    [p setSetMethod:@selector(setNoiseWindow:) getMethod:@selector(noiseWindow)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Ext Trig Length"];
    [p setFormat:@"##0" upperLimit:0x7ff lowerLimit:0 stepSize:1 units:cardConstants[kExtTrigLengthIndex].units];
    [p setSetMethod:@selector(setExtTrigLength:) getMethod:@selector(extTrigLength)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Collection Time"];
    [p setFormat:@"##0" upperLimit:0xff lowerLimit:0 stepSize:1 units:cardConstants[kCollectionTimeIndex].units];
    [p setSetMethod:@selector(setCollectionTime:) getMethod:@selector(collectionTime)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Integration Time"];
    [p setFormat:@"##0" upperLimit:0xff lowerLimit:0 stepSize:1 units:cardConstants[kIntegrationTimeIndex].units];
    [p setSetMethod:@selector(setIntegrationTime:) getMethod:@selector(integrationTime)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Polarity"];
    [p setFormat:@"##0" upperLimit:3 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setPolarity:withValue:) getMethod:@selector(polarity:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Trigger Mode"];
    [p setFormat:@"##0" upperLimit:3 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setTriggerMode:withValue:) getMethod:@selector(triggerMode:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Pile Up"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setPileUp:withValue:) getMethod:@selector(pileUp:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Enabled"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setEnable:withValue:) getMethod:@selector(enable:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Debug Mode"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setDebug:withValue:) getMethod:@selector(debug:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"LED Threshold"];
    [p setFormat:@"##0" upperLimit:0x1ffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setLEDThreshold:withValue:) getMethod:@selector(ledThreshold:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"CFD Delay"];
    [p setFormat:@"##0" upperLimit:630 lowerLimit:0 stepSize:1 units:@"ns"];
    [p setSetMethod:@selector(setCFDDelayConverted:withValue:) getMethod:@selector(cfdDelayConverted:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"CFD Fraction"];
    [p setFormat:@"##0" upperLimit:0x3 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setCFDFraction:withValue:) getMethod:@selector(cfdFraction:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"CFD Threshold"];
    [p setFormat:@"##0.0" upperLimit:160 lowerLimit:0 stepSize:1 units:@"Kev"];
	[p setCanBeRamped:YES];
    [p setSetMethod:@selector(setCFDThresholdConverted:withValue:) getMethod:@selector(cfdThresholdConverted:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Data Delay"];
    [p setFormat:@"##0.00" upperLimit:4.5 lowerLimit:0 stepSize:.01 units:@"us"];
    [p setSetMethod:@selector(setDataDelayConverted:withValue:) getMethod:@selector(dataDelayConverted:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Data Length"];
    [p setFormat:@"##0" upperLimit:0x3FF lowerLimit:1 stepSize:1 units:@"ns"];
    [p setSetMethod:@selector(setDataLengthConverted:withValue:) getMethod:@selector(dataLengthConverted:)];
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
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card" className:@"ORGretina4Model"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORGretina4Model"]];
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
 	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    
    id obj = [cardDictionary objectForKey:param];
    if(obj)return obj;
    else return [[cardDictionary objectForKey:param] objectAtIndex:aChannel];
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORGretina4Model"];    
    
    //cache some stuff
    location        = (([self crateNumber]&0x0000000f)<<21) | (([self slot]& 0x0000001f)<<16);
    theController   = [self adapter];
    fifoAddress     = [self baseAddress] + 0x1000;
    fifoStateAddress= [self baseAddress] + register_offsets[kProgrammingDone];
    
    short i;
    for(i=0;i<kNumGretina4Channels;i++){
        [self writeControlReg:i enabled:NO];
    }
    [self clearFIFO];
    dataBuffer = (unsigned long*)malloc(0xffff * sizeof(long));
    [self startRates];
    
    [self initBoard];
    
	[self performSelector:@selector(checkFifoAlarm) withObject:nil afterDelay:1];
}

//**************************************************************************************
// Function:	TakeData
// Description: Read data from a card
//**************************************************************************************
-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    isRunning = YES;
    NSString* errorLocation = @"";
    NS_DURING
        unsigned long val;
        //read the fifo state
        [theController readLongBlock:&val
                           atAddress:fifoStateAddress
                           numToRead:1
                          withAddMod:[self addressModifier]
                       usingAddSpace:0x01];
        fifoState = val;			
        if((val & kGretina4FIFOEmpty) == 0){
            unsigned long numLongs = 0;
            dataBuffer[numLongs++] = dataId | 0; //we'll fill in the length later
            dataBuffer[numLongs++] = location;
            
            //read the first longword which should be the packet separator: 0xAAAAAAAA
            unsigned long theValue;
            [theController readLongBlock:&theValue 
                               atAddress:fifoAddress 
                               numToRead:1 
                              withAddMod:[self addressModifier] 
                           usingAddSpace:0x01];
            
            if(theValue==0xAAAAAAAA){
                
                //read the first word of actual data so we know how much to read
                [theController readLongBlock:&theValue 
                                   atAddress:fifoAddress 
                                   numToRead:1 
                                  withAddMod:[self addressModifier] 
                               usingAddSpace:0x01];
                
                dataBuffer[numLongs++] = theValue;
                
                ++waveFormCount[theValue & 0x7];  //grab the channel and inc the count
                
                unsigned long numLongsLeft  = ((theValue & 0xffff0000)>>16)-1;
                
                [theController readLong:&dataBuffer[numLongs] 
                              atAddress:fifoAddress 
                            timesToRead:numLongsLeft 
                             withAddMod:[self addressModifier] 
                          usingAddSpace:0x01];
                          
                long totalNumLongs = (numLongs + numLongsLeft);
                dataBuffer[0] |= totalNumLongs; //see, we did fill it in...
                [aDataPacket addLongsToFrameBuffer:dataBuffer length:totalNumLongs];
            }
            else {
                //oops... really bad -- the buffer read is out of sequence -- dump it all
                [self clearFIFO];
                NSLogError(@"Gretina4",[NSString stringWithFormat:@"slot %d",[self slot]],@"Packet Sequence Error -- FIFO flushed",nil);
            }
        }
    
    NS_HANDLER
        NSLogError(@"",@"Gretina4 Card Error",errorLocation,nil);
        [self incExceptionCount];
        [localException raise];
    NS_ENDHANDLER
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    isRunning = NO;
    [waveFormRateGroup stop];
    //stop all channels
    short i;
    for(i=0;i<kNumGretina4Channels;i++){					
		waveFormCount[i] = 0;
        [self writeControlReg:i enabled:NO];
    }
    free(dataBuffer);
}

- (void) checkFifoAlarm
{
	if(((fifoState & kGretina4FIFOAlmostFull) != 0) && isRunning){
		fifoEmptyCount = 0;
		if(!fifoFullAlarm){
			NSString* alarmName = [NSString stringWithFormat:@"FIFO Almost Full Gretina4 (slot %d)",[self slot]];
			fifoFullAlarm = [[ORAlarm alloc] initWithName:alarmName severity:kDataFlowAlarm];
			[fifoFullAlarm setSticky:YES];
			[fifoFullAlarm setHelpString:@"The rate is too high. Adjust the LED Threshold accordingly."];
			[fifoFullAlarm postAlarm];
		}
	}
	else {
		fifoEmptyCount++;
		if(fifoEmptyCount>=5){
			[fifoFullAlarm clearAlarm];
			[fifoFullAlarm release];
			fifoFullAlarm = nil;
		}
	}
	if(isRunning){
		[self performSelector:@selector(checkFifoAlarm) withObject:nil afterDelay:1.5];
	}
	else {
		[fifoFullAlarm clearAlarm];
		[fifoFullAlarm release];
		fifoFullAlarm = nil;
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelFIFOCheckChanged object:self];
}

- (void) reset
{
}


- (BOOL) bumpRateFromDecodeStage:(short)channel
{
    if(isRunning)return NO;
    
    ++waveFormCount[channel];
    return YES;
}

- (unsigned long) waveFormCount:(int)aChannel
{
    return waveFormCount[aChannel];
}

-(void) startRates
{
    [self clearWaveFormCounts];
    [waveFormRateGroup start:self];
}

- (void) clearWaveFormCounts
{
    int i;
    for(i=0;i<kNumGretina4Channels;i++){
        waveFormCount[i]=0;
    }
}

- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{

    /* The current hardware specific data is:               *
     *                                                      *
     * 0: FIFO state address                                *
     * 1: FIFO empty state mask                             *
     * 2: FIFO address                                      *
     * 3: FIFO address AM                                   *
     * 4: FIFO size                                         */
    
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id	= kGretina; //should be unique
	configStruct->card_info[index].hw_mask[0] 	= dataId; //better be unique
	configStruct->card_info[index].slot			= [self slot];
	configStruct->card_info[index].crate		= [self crateNumber];
	configStruct->card_info[index].add_mod		= [self addressModifier];
	configStruct->card_info[index].base_add		= [self baseAddress];
	configStruct->card_info[index].deviceSpecificData[0]	= [self baseAddress] + register_offsets[kProgrammingDone]; //fifoStateAddress
    configStruct->card_info[index].deviceSpecificData[1]	= kGretina4FIFOEmpty; // fifoEmptyMask
    configStruct->card_info[index].deviceSpecificData[2]	= [self baseAddress] + 0x1000; // fifoAddress
    configStruct->card_info[index].deviceSpecificData[3]	= 0x0B; // fifoAM
    configStruct->card_info[index].deviceSpecificData[4]	= 0x1FFFF; // size of FIFO
	configStruct->card_info[index].num_Trigger_Indexes		= 0;
	
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	
	return index+1;
}

#pragma mark ���Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setNoiseFloorIntegrationTime:[decoder decodeFloatForKey:@"NoiseFloorIntegrationTime"]];
    [self setNoiseFloorOffset:[decoder decodeIntForKey:@"NoiseFloorOffset"]];
    cardInfo = [[decoder decodeObjectForKey:@"cardInfo"] retain];
    
    
    [self setWaveFormRateGroup:[decoder decodeObjectForKey:@"waveFormRateGroup"]];
    
    if(!waveFormRateGroup){
        [self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:kNumGretina4Channels groupTag:0] autorelease]];
        [waveFormRateGroup setIntegrationTime:5];
    }
    [waveFormRateGroup resetRates];
    [waveFormRateGroup calcRates];
	
	int i;
	for(i=0;i<kNumGretina4Channels;i++){
		[self setEnabled:i withValue:[decoder decodeIntForKey:[@"enabled" stringByAppendingFormat:@"%d",i]]];
		[self setDebug:i withValue:[decoder decodeIntForKey:[@"debug" stringByAppendingFormat:@"%d",i]]];
		[self setPileUp:i withValue:[decoder decodeIntForKey:[@"pileUp" stringByAppendingFormat:@"%d",i]]];
		[self setPolarity:i withValue:[decoder decodeIntForKey:[@"polarity" stringByAppendingFormat:@"%d",i]]];
		[self setTriggerMode:i withValue:[decoder decodeIntForKey:[@"triggerMode" stringByAppendingFormat:@"%d",i]]];
		[self setLEDThreshold:i withValue:[decoder decodeIntForKey:[@"ledThreshold" stringByAppendingFormat:@"%d",i]]];
		[self setCFDThreshold:i withValue:[decoder decodeIntForKey:[@"cfdThreshold" stringByAppendingFormat:@"%d",i]]];
		[self setCFDDelay:i withValue:[decoder decodeIntForKey:[@"cfdDelay" stringByAppendingFormat:@"%d",i]]];
		[self setCFDFraction:i withValue:[decoder decodeIntForKey:[@"cfdFraction" stringByAppendingFormat:@"%d",i]]];
		[self setDataDelay:i withValue:[decoder decodeIntForKey:[@"dataDelay" stringByAppendingFormat:@"%d",i]]];
		[self setDataLength:i withValue:[decoder decodeIntForKey:[@"dataLength" stringByAppendingFormat:@"%d",i]]];
	}
	      
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeFloat:noiseFloorIntegrationTime forKey:@"NoiseFloorIntegrationTime"];
    [encoder encodeInt:noiseFloorOffset forKey:@"NoiseFloorOffset"];
    [encoder encodeObject:cardInfo forKey:@"cardInfo"];
    [encoder encodeObject:waveFormRateGroup forKey:@"waveFormRateGroup"];
	int i;
 	for(i=0;i<kNumGretina4Channels;i++){
		[encoder encodeInt:enabled[i] forKey:[@"enabled" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:debug[i] forKey:[@"debug" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:pileUp[i] forKey:[@"pileUp" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:polarity[i] forKey:[@"polarity" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:triggerMode[i] forKey:[@"triggerMode" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:cfdFraction[i] forKey:[@"cfdFraction" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:cfdDelay[i] forKey:[@"cfdDelay" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:cfdThreshold[i] forKey:[@"cfdThreshold" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:ledThreshold[i] forKey:[@"ledThreshold" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:dataDelay[i] forKey:[@"dataDelay" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:dataLength[i] forKey:[@"dataLength" stringByAppendingFormat:@"%d",i]];
	}

 }

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    short i;
    for(i=0;i<kNumGretina4CardParams;i++){
        [objDictionary setObject:[self cardInfo:i] forKey:cardConstants[i].name];
    }  
	[self addCurrentState:objDictionary cArray:enabled forKey:@"Enabled"];
	[self addCurrentState:objDictionary cArray:debug forKey:@"Debug Mode"];
	[self addCurrentState:objDictionary cArray:pileUp forKey:@"Pile Up"];
	[self addCurrentState:objDictionary cArray:polarity forKey:@"Polarity"];
	[self addCurrentState:objDictionary cArray:triggerMode forKey:@"Trigger Mode"];
	[self addCurrentState:objDictionary cArray:cfdDelay forKey:@"CFD Delay"];
	[self addCurrentState:objDictionary cArray:cfdFraction forKey:@"CFD Fraction"];
	[self addCurrentState:objDictionary cArray:cfdThreshold forKey:@"CFD Threshold"];
	[self addCurrentState:objDictionary cArray:dataDelay forKey:@"Data Delay"];
	[self addCurrentState:objDictionary cArray:dataLength forKey:@"Data Length"];
    
    NSMutableArray* ar = [NSMutableArray array];
	for(i=0;i<kNumGretina4Channels;i++){
		[ar addObject:[NSNumber numberWithLong:ledThreshold[i]]];
	}
    [objDictionary setObject:ar forKey:@"LED Threshold"];
	
	
    return objDictionary;
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary cArray:(short*)anArray forKey:(NSString*)aKey
{
	NSMutableArray* ar = [NSMutableArray array];
	int i;
	for(i=0;i<kNumGretina4Channels;i++){
		[ar addObject:[NSNumber numberWithShort:*anArray]];
		anArray++;
	}
	[dictionary setObject:ar forKey:aKey];
}


@end
