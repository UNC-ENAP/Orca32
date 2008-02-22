//
//  ORIP320Model.cp
//  Orca
//
//  Created by Mark Howe on Mon Feb 10 2003.
//  Copyright � 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ���Imported Files
#import "ORIP320Model.h"
#import "ORIPCarrierModel.h"
#import "ORVmeCrateModel.h"
#include "VME_HW_Definitions.h"
#import "ORDataTypeAssigner.h"

#import "ORIP320Channel.h"

#pragma mark ���Notification Strings
NSString* ORIP320ModelDisplayRawChanged = @"ORIP320ModelDisplayRawChanged";
NSString* ORIP320GainChangedNotification 		= @"ORIP320GainChangedNotification";
NSString* ORIP320ModeChangedNotification 		= @"ORIP320ModeChangedNotification";
NSString* ORIP320AdcValueChangedNotification 		= @"ORIP320AdcValueChangedNotification";

NSString* ORIP320WriteValueChangedNotification		= @"IP320 WriteValue Changed Notification";
NSString* ORIP320ReadMaskChangedNotification 		= @"IP320 ReadMask Changed Notification";
NSString* ORIP320ReadValueChangedNotification		= @"IP320 ReadValue Changed Notification";
NSString* ORIP320PollingStateChangedNotification	= @"ORIP320PollingStateChangedNotification";

static struct {
    NSString* regName;
    unsigned long addressOffset;
}reg[kNum320Registers]={
	{@"Control Reg",  0x0000},
	{@"Convert Cmd",  0x0010},
	{@"ADC Data Reg", 0x0020},		
};

@interface ORIP320Model (private)
- (void) _setUpPolling;
- (void) _pollAllChannels;
@end

@implementation ORIP320Model

#pragma mark ���Initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setChanObjs:[NSMutableArray array]];
    int i=0;
    for(i=0;i<kNumIP320Channels;i++){
        [chanObjs addObject:[[[ORIP320Channel alloc] initWithAdc:self channel:i]autorelease]];
    }
    [[self undoManager] enableUndoRegistration];
    return self;
}

-(void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [chanObjs release];
    [super dealloc];
}

- (void) wakeUp
{
    if(![self aWake]){
        [self _setUpPolling];
    }
    [super wakeUp];
}

- (void) sleep
{
    [super sleep];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"IP320"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORIP320Controller"];
}



#pragma mark ���Accessors

- (BOOL) displayRaw
{
    return displayRaw;
}

- (void) setDisplayRaw:(BOOL)aDisplayRaw
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDisplayRaw:displayRaw];
    
    displayRaw = aDisplayRaw;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORIP320ModelDisplayRawChanged object:self];
}
// ===========================================================
// - chanObjs:
// ===========================================================
- (NSMutableArray *)chanObjs {
    return chanObjs; 
}

// ===========================================================
// - setChanObjs:
// ===========================================================
- (void)setChanObjs:(NSMutableArray *)aChanArray {
    [aChanArray retain];
    [chanObjs release];
    chanObjs = aChanArray;
}


- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}

- (void) setPollingState:(NSTimeInterval)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollingState:pollingState];
    
    pollingState = aState;
    
    [self performSelector:@selector(_setUpPolling) withObject:nil afterDelay:0.5];
    
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORIP320PollingStateChangedNotification
                      object: self];
    
}

- (void) postNotification:(NSNotification*)aNote
{
	[[NSNotificationCenter defaultCenter] postNotification:aNote];
}

- (NSTimeInterval)	pollingState
{
    return pollingState;
}
- (BOOL) hasBeenPolled 
{ 
    return hasBeenPolled;
}

#pragma mark ���Hardware Access
- (unsigned long) getRegisterAddress:(short) aRegister
{
    int ip = [self slotConv];
    return [guardian baseAddress] + ip*0x100 + reg[aRegister].addressOffset;
}

- (unsigned long) getAddressOffset:(short) anIndex
{
    return reg[anIndex].addressOffset;
}

- (NSString*) getRegisterName:(short) anIndex
{
    return reg[anIndex].regName;
}

- (short) getNumRegisters;
{
    return kNum320Registers;
}

- (void) loadConstants:(unsigned short)aChannel
{
    ORIP320Channel* chanObj = [chanObjs objectAtIndex:aChannel];
    unsigned short aMask = 0;
    aMask |= (aChannel%20 & kChan_mask);//bits 0-5
	aMask |= [chanObj gain] << 6;       //bits 6-7
	aMask |= [chanObj mode] << 8;       //bits 8-9
        
	[[guardian adapter] writeWordBlock:&aMask
								 atAddress:[self getRegisterAddress:kControlReg]
								numToWrite:1L
								withAddMod:[guardian addressModifier]
							 usingAddSpace:kAccessRemoteIO];
}

- (unsigned short) readAdcChannel:(unsigned short)aChannel
{
    
	int changeCount = 0;
	unsigned short value = 0;
	@synchronized(self) {
		NSString* errorLocation = @"";
		NS_DURING
			
			errorLocation = @"Control Reg Setup";
			[self loadConstants:aChannel];
			
			unsigned short modifier = [guardian addressModifier];
			errorLocation = @"Converion Start";
			unsigned short dummyValue = 0xFFFF;
			id cachedController = [guardian adapter];
			[cachedController writeWordBlock:&dummyValue
									 atAddress:[self getRegisterAddress:kConvertCmd]
									numToWrite:1L
									withAddMod:modifier
								 usingAddSpace:kAccessRemoteIO];
			
			errorLocation = @"Adc Read";
			[cachedController readWordBlock:(unsigned short*)&value
									atAddress:[self getRegisterAddress:kADCDataReg]
									numToRead:1L
								   withAddMod:modifier
								usingAddSpace:kAccessRemoteIO];
			
			//the value needs to be shifted by 3 bits after the read. That's how is comes off the card....
			if([[chanObjs objectAtIndex:aChannel] setChannelValue:(value>>3) & 0x0fff])changeCount++;
			
		NS_HANDLER
			NSLogError(@"",[NSString stringWithFormat:@"IP320 %d,%@",[self slot],[self identifier]],errorLocation,nil);
			[NSException raise:[NSString stringWithFormat:@"IP320 Read Adc Channel %d Failed",aChannel] format:@"Error Location: %@",errorLocation];
		NS_ENDHANDLER
		if(changeCount){
			[self performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:ORIP320AdcValueChangedNotification object:self] waitUntilDone:NO];
		}
	}
    return value;
}

- (void) readAllAdcChannels
{
	@synchronized(self) {
		short chan;
		for(chan=0;chan<kNumIP320Channels;chan++){
			if([[chanObjs objectAtIndex:chan] readEnabled]){
				if(chan>=20){
					if([[chanObjs objectAtIndex:chan-20] mode] == 0x1){
						//only read chans above 20 if chans below 20 are not diff. mode
						[self readAdcChannel:chan];
					}
				}
				else [self readAdcChannel:chan];
			}
		}
		valuesReadyToShip = YES;	
	}
}

- (void) _pollAllChannels
{
    NS_DURING 
        [self readAllAdcChannels];    
    NS_HANDLER 
	//catch this here to prevent it from falling thru, but nothing to do.
	NS_ENDHANDLER
        
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	if(pollingState!=0){
		[self performSelector:@selector(_pollAllChannels) withObject:nil afterDelay:pollingState];
	}
}

- (void) enablePollAll:(BOOL)state
{
    short chan;
    for(chan=0;chan<kNumIP320Channels;chan++){
        [[chanObjs objectAtIndex:chan] setObject:[NSNumber numberWithBool:state] forKey:k320ChannelReadEnabled];
    }
}

- (void) enableAlarmAll:(BOOL)state
{
    short chan;
    for(chan=0;chan<kNumIP320Channels;chan++){
        [[chanObjs objectAtIndex:chan] setObject:[NSNumber numberWithBool:state] forKey:k320ChannelAlarmEnabled];
    }
}


#pragma mark ���Polling
- (void) _setUpPolling
{
    if(pollingState!=0){        
        NSLog(@"Polling IP320,%d,%d,%d  every %.0f seconds.\n",[self crateNumber],[self slot],[self slotConv],pollingState);
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(_pollAllChannels) withObject:self afterDelay:pollingState];
        [self _pollAllChannels];
    }
    else {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        NSLog(@"Not Polling IP320,%d,%d,%d\n",[self crateNumber],[self slot],[self slotConv]);
    }
}

#pragma mark ���Archival
static NSString* kORIP320chanObjs   = @"kORIP320chanObjs";
static NSString *kORIP320PollingState   = @"kORIP320PollingState";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	    
    [[self undoManager] disableUndoRegistration];
    [self setDisplayRaw:[decoder decodeBoolForKey:@"ORIP320ModelDisplayRaw"]];
    [self setChanObjs:[decoder decodeObjectForKey:kORIP320chanObjs]];
    [self setPollingState:[decoder decodeIntForKey:kORIP320PollingState]];
    [[self undoManager] enableUndoRegistration];
    
    
    if(chanObjs == nil){
        [self setChanObjs:[NSMutableArray array]];
        int i;
        for(i=0;i<kNumIP320Channels;i++){
            [chanObjs addObject:[[[ORIP320Channel alloc] initWithAdc:self channel:i]autorelease]];
        }
    }
	[chanObjs makeObjectsPerformSelector:@selector(setAdcCard:) withObject:self];
	   	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:displayRaw forKey:@"ORIP320ModelDisplayRaw"];
    [encoder encodeObject:chanObjs forKey:kORIP320chanObjs];
    [encoder encodeInt:[self pollingState] forKey:kORIP320PollingState];
}

#pragma mark ���Bit Processing Protocol
- (void)processIsStarting
{
}

- (void)processIsStopping
{
}
//note that everything called by these routines MUST be threadsafe
- (void) startProcessCycle
{
    [self readAllAdcChannels];
}

- (void) endProcessCycle
{
    //nothing to do
}

- (int) processValue:(int)channel
{
	return 0;
}

- (void) setProcessOutput:(int)channel value:(int)value
{
    //nothing to do
}

- (NSString*) processingTitle
{
    return [NSString stringWithFormat:@"%d,%d,%@",[self crateNumber],[guardian slot],[self identifier]];
}

- (double) convertedValue:(int)channel
{
	return [[[chanObjs objectAtIndex:channel] objectForKey:k320ChannelValue] doubleValue];
}

- (double) maxValueForChan:(int)channel
{
	double theMax = 0;
	@synchronized(self){
		theMax =  [[chanObjs objectAtIndex:channel] maxValue];
	}
	return theMax;
}
- (double) minValueForChan:(int)channel
{
	return 0;
}
- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit channel:(int)channel
{
	@synchronized(self){
		*theLowLimit = [[[chanObjs objectAtIndex:channel] objectForKey:k320ChannelLowValue] doubleValue];
		*theHighLimit = [[[chanObjs objectAtIndex:channel] objectForKey:k320ChannelHighValue] doubleValue];
	}		
}

- (unsigned long) lowMask
{
	int i;
	unsigned long aMask = 0;
	for(i=0;i<32;i++){
		if([[chanObjs objectAtIndex:i] readEnabled]){
			aMask |= 1L<<i;
		}
	}
	return aMask;
}

- (unsigned long) highMask
{
	unsigned long aMask = 0;
	int i;
	for(i=0;i<8;i++){
		if([[chanObjs objectAtIndex:i+32] readEnabled]){
			aMask |= 1L<<i;
		}
	}
	return aMask;
}

#pragma mark ���Data Taker


- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	int i;
	for(i=0;i<kNumIP320Channels;i++){
		[objDictionary setObject:[[chanObjs objectAtIndex:i] parameters] forKey:[NSString stringWithFormat:@"chan%d",i]];
	}	
	return objDictionary;
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORSIP320DecoderForADC",						@"decoder",
        [NSNumber numberWithLong:dataId],               @"dataId",
        [NSNumber numberWithBool:YES],                  @"variable",
        [NSNumber numberWithLong:-1],					@"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"IP320"];
    
    return dataDictionary;
}

- (void) appendEventDictionary:(NSMutableDictionary*)anEventDictionary topLevel:(NSMutableDictionary*)topLevel
{
	NSDictionary* aDictionary;
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
							@"Adc",											@"name",
							[NSNumber numberWithLong:dataId],				@"dataId",
							[NSNumber numberWithLong:kNumIP320Channels],	@"maxChannels",
								nil];
		
	[anEventDictionary setObject:aDictionary forKey:@"IP320"];
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	
    if(![[guardian adapter] controllerCard]){
		[NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
	
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORIP320Model"];    
    
    //----------------------------------------------------------------------------------------
    controller = [[guardian adapter] controllerCard]; //cache the controller for alittle bit more speed.
    slotMask   =  (([self crateNumber]&0x01e)<<21) | ([guardian slot]& 0x0000001f)<<16 | ([self slot]&0xf);
	lowMask = [self lowMask];
	highMask = [self highMask];

    [self clearExceptionCount];
}

//**************************************************************************************
// Function:	TakeData
// Description: Read data from a card
//**************************************************************************************
- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm]; //short form preferred
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	if(valuesReadyToShip){
		unsigned long data[23];
		data[1] = slotMask;
		time_t  now;
		time(&now);
		data[2] = now;	//seconds since 1970
		int index = 3;
		int i;
		for(i=0;i<40;i++){
			if([[chanObjs objectAtIndex:i] readEnabled]){
				int val  = [[chanObjs objectAtIndex:i] rawValue];
				data[index++] = (i&0xff)<<16 | val & 0xfff;
			}
		}
		data[0] = dataId | index;
		
		if(index>3){
			[aDataPacket addLongsToFrameBuffer:data length:index];
		}
		valuesReadyToShip = NO;
	}
}


- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
}

- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id = kIP320;		//should be unique
	configStruct->card_info[index].hw_mask[0] = dataId; //better be unique
	configStruct->card_info[index].slot 	 = [guardian slot];
	configStruct->card_info[index].crate 	 = [self crateNumber];
	configStruct->card_info[index].add_mod 	 = [self addressModifier];
	configStruct->card_info[index].base_add  = [self baseAddress];
	configStruct->card_info[index].deviceSpecificData[0] = [self slot];
	configStruct->card_info[index].deviceSpecificData[1] = MAX(1.,(unsigned long)pollingState);
	configStruct->card_info[index].deviceSpecificData[2] = [self lowMask];
	configStruct->card_info[index].deviceSpecificData[3] = [self highMask];
	int i;
	int j = 4;
	for(i=0;i<40;i++) configStruct->card_info[index].deviceSpecificData[j++] = [[chanObjs objectAtIndex:i] gain];		
	for(i=0;i<40;i++) configStruct->card_info[index].deviceSpecificData[j++] = [[chanObjs objectAtIndex:i] mode];		
	
	configStruct->card_info[index].num_Trigger_Indexes = 0;
	
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	
	return index+1;
}

- (void)reset
{
}
@end
