//--------------------------------------------------------------------------------
/*!\class	ORCaen775Model
 * \brief	Handles all access to CAEN CV775 TDC module.
 * \methods
 *			\li \b 			- Constructor
 *			\li \b 
 * \note
 * \author	Jan M. Wouters
 * \history	2002-02-25 (mh) - Original
 *			2002-11-18 (jmw) - Modified for ORCA.
 *			2003-07-01 (jmw) - Rewritten for new CAEN base class.
 */
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

#import "ORCaenCardModel.h"

// Declaration of constants for module.
enum {
	kOutputBuffer,
	kFirmWareRevision,
	kGeoAddress,
	kMCST_CBLTAddress,
	kBitSet1,
	kBitClear1,
	kInterrupLevel,
	kInterrupVector,
	kStatusRegister1,
	kControlRegister1,
	kADERHigh,
	kADERLow,
	kSingleShotReset,
	kMCST_CBLTCtrl,
	kEventTriggerReg,
	kStatusRegister2,
	kEventCounterL,
	kEventCounterH,
	kIncrementEvent,
	kIncrementOffset,
	kLoadTestRegister,
	kFCLRWindow,
	kBitSet2,
	kBitClear2,
	kWMemTestAddress,
	kMemTestWord_High,
	kMemTestWord_Low,
	kCrateSelect,
	kTestEventWrite,
	kEventCounterReset,
	kFullScaleRange,
	kRTestAddress,
	kSWComm,
	kADD,
	kBADD,
	kThresholds,
	kNumRegisters
};


// Size of output buffer
#define kTDCOutputBufferSize 0x0FFC + 0x0004

// Class definition
@interface ORCaen775Model : ORCaenCardModel
{
}


#pragma mark ���Accessors

#pragma mark ���Register - General routines
- (short) 			getNumberRegisters;
- (unsigned long) 	getBufferOffset;
- (unsigned short) 	getDataBufferSize;
- (unsigned long) 	getThresholdOffset;
- (short) 			getStatusRegisterIndex: (short) aRegister;
- (short)			getThresholdIndex;
- (short)			getOutputBufferIndex;

#pragma mark ***Register - Register specific routines
- (NSString*) 		getRegisterName: (short) anIndex;
- (unsigned long) 	getAddressOffset: (short) anIndex;
- (short)  			getAccessType: (short) anIndex;
- (short)  			getAccessSize: (short) anIndex;
- (BOOL)  			dataReset: (short) anIndex;
- (BOOL)  			swReset: (short) anIndex;
- (BOOL)  			hwReset: (short) anIndex;

@end

//the decoder concrete decoder class
@interface ORCaen775DecoderForCAEN : ORCaenDataDecoder
{}
- (NSString*) identifier;
@end