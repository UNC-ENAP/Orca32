//--------------------------------------------------------------------------------
// CLASS:		ORCaen775Model
// Purpose:		Handles hardware interface for those commands specific to the 775.
// Author:		Jan M. Wouters
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
#import "ORCaen775Model.h"


// Address information for this unit.
#define k775DefaultBaseAddress 		0xa00000
#define k775DefaultAddressModifier 	0x39

NSString* ORCaen775ModelModelTypeChanged = @"ORCaen775ModelModelTypeChanged";
NSString* ORCaen775ModelOnlineMaskChanged = @"ORCaen775ModelOnlineMaskChanged";

// Define all the registers available to this unit.
static RegisterNamesStruct reg[kNumRegisters] = {
{@"Output Buffer",		true,	true, 	true,	0x0000,		kReadOnly,	kD32},
{@"FirmWare Revision",	false,	false, 	false,	0x1000,		kReadOnly,	kD16},
{@"Geo Address",		false,	false, 	false,	0x1002,		kReadWrite,	kD16},
{@"MCST CBLT Address",	false,	false, 	true,	0x1004,		kReadWrite,	kD16},
{@"Bit Set 1",			false,	true, 	true,	0x1006,		kReadWrite,	kD16},
{@"Bit Clear 1",		false,	true, 	true,	0x1008,		kReadWrite,	kD16},
{@"Interrup Level",		false,	true, 	true,	0x100A,		kReadWrite,	kD16},
{@"Interrup Vector",	false,	true, 	true,	0x100C,		kReadWrite,	kD16},
{@"Status Register 1",	false,	true, 	true,	0x100E,		kReadOnly,	kD16},
{@"Control Register 1",	false,	true, 	true,	0x1010,		kReadWrite,	kD16},
{@"ADER High",			false,	false, 	true,	0x1012,		kReadWrite,	kD16},
{@"ADER Low",			false,	false, 	true,	0x1014,		kReadWrite,	kD16},
{@"Single Shot Reset",	false,	false, 	false,	0x1016,		kWriteOnly,	kD16},
{@"MCST CBLT Ctrl",		false,	false, 	true,	0x101A,		kReadWrite,	kD16},
{@"Event Trigger Reg",	false,	true, 	true,	0x1020,		kReadWrite,	kD16},
{@"Status Register 2",	false,	true, 	true,	0x1022,		kReadOnly,	kD16},
{@"Event Counter L",	true,	true, 	true,	0x1024,		kReadOnly,	kD16},
{@"Event Counter H",	true,	true, 	true,	0x1026,		kReadOnly,	kD16},
{@"Increment Event",	false,	false, 	false,	0x1028,		kWriteOnly,	kD16},
{@"Increment Offset",	false,	false, 	false,	0x102A,		kWriteOnly,	kD16},
{@"Load Test Register",	false,	false, 	false,	0x102C,		kReadWrite,	kD16},
{@"FCLR Window",		false,	true, 	true,	0x102E,		kReadWrite,	kD16},
{@"Bit Set 2",			false,	true, 	true,	0x1032,		kReadWrite,	kD16},
{@"Bit Clear 2",		false,	true, 	true,	0x1034,		kWriteOnly,	kD16},
{@"W Mem Test Address",	false,	true, 	true,	0x1036,		kWriteOnly,	kD16},
{@"Mem Test Word High",	false,	true, 	true,	0x1038,		kWriteOnly,	kD16},
{@"Mem Test Word Low",	false,	false, 	false,	0x103A,		kWriteOnly,	kD16},
{@"Crate Select",		false,	true, 	true,	0x103C,		kReadWrite,	kD16},
{@"Test Event Write",	false,	false, 	false,	0x103E,		kWriteOnly,	kD16},
{@"Event Counter Reset",false,	false, 	false,	0x1040,		kWriteOnly,	kD16},
{@"Full Scale Range",	false,	true, 	true,	0x1060,		kReadWrite,	kD16},
{@"R Test Address",		false,	true, 	true,	0x1064,		kWriteOnly,	kD16},
{@"SW Comm",			false,	false, 	false,	0x1068,		kWriteOnly,	kD16},
{@"ADD",				false,	false, 	false,	0x1070,		kReadOnly,	kD16},
{@"BADD",				false,	false, 	false,	0x1072,		kReadOnly,	kD16},
{@"Thresholds",			false,	false, 	false,	0x1080,		kReadWrite,	kD16},
};


@implementation ORCaen775Model

#pragma mark ���Initialization
//--------------------------------------------------------------------------------
/*!\method  init
* \brief	Called first time class is initialized.  Used to set basic
*			default values first time object is created.
* \param	aDocument			- The initialization document.
* \note	
*/
//--------------------------------------------------------------------------------
- (id) init //designated initializer
{
    self = [super init];
	[[self undoManager] disableUndoRegistration];
	
    [self setBaseAddress: k775DefaultBaseAddress];
    [self setAddressModifier: k775DefaultAddressModifier];
	
	[[self undoManager] enableUndoRegistration];
    
    return self;
}

#pragma mark ***Accessors

- (int) modelType
{
    return modelType;
}

- (void) setModelType:(int)aModelType
{
    [[[self undoManager] prepareWithInvocationTarget:self] setModelType:modelType];
    
    modelType = aModelType;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen775ModelModelTypeChanged object:self];
}
- (unsigned long)onlineMask {
	
    return onlineMask;
}

- (void)setOnlineMask:(unsigned long)anOnlineMask 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOnlineMask:[self onlineMask]];
    onlineMask = anOnlineMask;	    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen775ModelOnlineMaskChanged object:self];
}

- (BOOL)onlineMaskBit:(int)bit
{
	return onlineMask&(1<<bit);
}

- (void) setOnlineMaskBit:(int)bit withValue:(BOOL)aValue
{
	unsigned long aMask = onlineMask;
	if(aValue)aMask |= (1<<bit);
	else      aMask &= ~(1<<bit);
	[self setOnlineMask:aMask];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"775Card"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORCaen775Controller"];
}

- (NSString*) helpURL
{
	return @"VME/V775.html";
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x1080);
}

#pragma mark ���Register - General routines
- (short) getNumberRegisters
{
	return kNumRegisters;
}

- (unsigned long) getBufferOffset
{
	return reg[kOutputBuffer].addressOffset;
}

- (unsigned short) getDataBufferSize
{
	return kTDCOutputBufferSize;
}

- (int) numberOfChannels
{
	if([self modelType] == kModel775) return 32;
	else							  return 16;
}

- (unsigned long) getThresholdOffset
{
	return reg[kThresholds].addressOffset;
}

- (short) getStatusRegisterIndex: (short) aRegister
{
    if ( aRegister == 1 ) return kStatusRegister1;
    else return kStatusRegister2;
}

- (short) getThresholdIndex
{
    return( kThresholds );
}

- (short) getOutputBufferIndex
{
    return( kOutputBuffer );
}


#pragma mark ***Register - Register specific routines
- (NSString*) getRegisterName: (short) anIndex
{
	return reg[anIndex].regName;
}

- (unsigned long) getAddressOffset: (short) anIndex
{
    return( reg[anIndex].addressOffset );
}

- (short) getAccessType: (short) anIndex
{
	return reg[anIndex].accessType;
}

- (short) getAccessSize: (short) anIndex
{
	return reg[anIndex].size;
}

- (BOOL) dataReset: (short) anIndex
{
	return reg[anIndex].dataReset;
}

- (BOOL) swReset: (short) anIndex
{
	return reg[anIndex].softwareReset;
}

- (BOOL) hwReset: (short) anIndex
{
	return reg[anIndex].hwReset;
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"CAEN 775 (Slot %d) ",[self slot]];
}

- (unsigned short) threshold:(unsigned short) aChnl
{
	return [super threshold:aChnl] & 0xFF;
}

- (void) writeThresholds
{
	int i;
	int n = (modelType==kModel775?32:16);
	for(i=0;i<n;i++){
		int kill = ((onlineMask & (1<<i))!=0)?0x0:0x100;
		unsigned short aValue = [self threshold:i] | kill;
		[[self adapter] writeWordBlock:&aValue
							 atAddress:[self baseAddress] + [self getThresholdOffset] + (i * 4)
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
	}
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	NSString* decoderName;
	if(modelType == kModel775){
		decoderName = @"ORCAEN775DecoderForTdc";
	}
	else {
		decoderName = @"ORCAEN775NDecoderForTdc";
	}
	NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 decoderName,								@"decoder",
								 [NSNumber numberWithLong:dataId],           @"dataId",
								 [NSNumber numberWithBool:YES],              @"variable",
								 [NSNumber numberWithLong:-1],               @"length",
								 nil];
	
    [dataDictionary setObject:aDictionary forKey:@"Tdc"];
    return dataDictionary;
}
#pragma mark ***DataTaker
- (void) runTaskStarted: (ORDataPacket*) aDataPacket userInfo:(id)userInfo
{
    [super runTaskStarted:aDataPacket userInfo:userInfo];
    
    // Clear unit
    [self write: kBitSet2 sendValue: kClearData];				// Clear data, 
    [self write: kBitClear2 sendValue: kClearData];			// Clear "Clear data" bit of status reg.
    [self write: kEventCounterReset sendValue: 0x0000];	// Clear event counter
    
    // Set options
    
    // Set thresholds in unit
    [self writeThresholds];
    
}

- (void) runTaskStopped: (ORDataPacket*) aDataPacket userInfo:(id)userInfo
{
    [super runTaskStopped:aDataPacket userInfo:userInfo];
}


#pragma mark ���Archival
- (id) initWithCoder: (NSCoder*) aDecoder
{
    self = [super initWithCoder: aDecoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setModelType:[aDecoder decodeIntForKey:@"modelType"]];
   	[self setOnlineMask:[aDecoder decodeInt32ForKey:@"onlineMask"]];
 
    [[self undoManager] enableUndoRegistration];
    return self;
}


- (void) encodeWithCoder: (NSCoder*) anEncoder
{
    [super encodeWithCoder: anEncoder];
	[anEncoder encodeInt:modelType forKey:@"modelType"];
	[anEncoder encodeInt32:onlineMask forKey:@"onlineMask"];
}

@end

@implementation ORCaen775DecoderForCAEN : ORCaenDataDecoder
- (NSString*) identifier
{
    return @"CAEN 775 TDC";
}
@end

