//
//  ORXL3Model.h
//  Orca
//
//  Created by Mark Howe on Tue, Apr 30, 2008.
//  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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
#import "ORSNOCard.h"
#import "XL3_Cmds.h"
#import "ORDataTaker.h"
#import "VME_eCPU_Config.h"

typedef struct  {
	NSString*	regName;
	unsigned long	address;
} Xl3RegNamesStruct; 

enum {
	kXl3SelectReg,
	kXl3DataAvailReg,
	kXl3CsReg,
	kXl3MaskReg,
	kXl3ClockReg,
	kXl3HvRelayReg,
	kXl3XilinxReg,
	kXl3TestReg,
	kXl3HvCsReg,
	kXl3HvSetPointReg,
	kXl3HvVoltageReg,
	kXl3HvCurrentReg,
	kXl3VmReg,
	kXl3VrReg,
	kXl3NumRegisters //must be last
};

@class XL3_Link;
@class ORCommandList;

@interface ORXL3Model : ORSNOCard <ORDataTaker>
{
	XL3_Link*       xl3Link;
	unsigned long	xl3MegaBundleDataId;
	unsigned long	cmosRateDataId;
	short           selectedRegister;
	BOOL            basicOpsRunning;
	BOOL            autoIncrement;	
	unsigned short	repeatDelay;
	short           repeatOpCount;
	BOOL            doReadOp;
	unsigned long   workingCount;
	unsigned long   writeValue;
	unsigned int    xl3Mode;
	unsigned long   slotMask;
	BOOL            xl3ModeRunning;
	unsigned long   xl3RWAddressValue;
    unsigned long   xl3RWDataValue;
	NSMutableDictionary* xl3OpsRunning;
	unsigned long   xl3PedestalMask;
    unsigned long   xl3ChargeInjMask;
    unsigned char   xl3ChargeInjCharge;
    unsigned short  pollXl3Time;
    BOOL            isPollingXl3;
    BOOL            isPollingCMOSRates;
    unsigned short  pollCMOSRatesMask;
    BOOL            isPollingPMTCurrents;
    unsigned short  pollPMTCurrentsMask;
    BOOL            isPollingFECVoltages;
    unsigned short  pollFECVoltagesMask;
    BOOL            isPollingXl3Voltages;
    BOOL            isPollingHVSupply;
    BOOL            isPollingXl3WithRun;
    BOOL            isPollingVerbose;
    BOOL            isPollingForced;
    NSString*       pollStatus;
    NSThread*       pollThread;
    NSMutableDictionary* pollDict;
    
    unsigned long long  relayMask;
    NSString* relayStatus;
    BOOL hvASwitch;
    BOOL hvBSwitch;
}

@property (assign)	unsigned long   xl3ChargeInjMask;
@property (assign)	unsigned char   xl3ChargeInjCharge;
@property (assign)	unsigned short  pollXl3Time;
@property (assign)	BOOL            isPollingXl3;
@property (assign)	BOOL            isPollingCMOSRates;
@property (assign)	unsigned short  pollCMOSRatesMask;
@property (assign)	BOOL            isPollingPMTCurrents;
@property (assign)	unsigned short  pollPMTCurrentsMask;
@property (assign)	BOOL            isPollingFECVoltages;
@property (assign)	unsigned short  pollFECVoltagesMask;
@property (assign)	BOOL            isPollingXl3Voltages;
@property (assign)	BOOL            isPollingHVSupply;
@property (assign)  BOOL            isPollingXl3WithRun;
@property (assign)  BOOL            isPollingVerbose;
@property (copy)    NSString*       pollStatus;
@property (readonly, nonatomic) NSMutableDictionary* pollDict;
@property (assign)  BOOL            isPollingForced;

@property (assign) unsigned long long relayMask;
@property (copy) NSString* relayStatus;
@property (assign) BOOL hvASwitch;
@property (assign) BOOL hvBSwitch;

#pragma mark •••Initialization
- (id)   init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (void) wakeUp;
- (void) sleep;

#pragma mark •••Accessors
- (NSString*) shortName;
- (id) controllerCard;
- (void) setSlot:(int)aSlot;
- (XL3_Link*) xl3Link;
- (void) setXl3Link:(XL3_Link*) aXl3Link;
- (void) setGuardian:(id)aGuardian;
- (short) getNumberRegisters;
- (NSString*) getRegisterName:(short) anIndex;
- (unsigned long) getRegisterAddress: (short) anIndex;
- (BOOL) basicOpsRunning;
- (void) setBasicOpsRunning:(BOOL)aBasicOpsRunning;
- (BOOL) compositeXl3ModeRunning;
- (void) setCompositeXl3ModeRunning:(BOOL)aCompositeXl3ModeRunning;
- (unsigned long) slotMask;
- (void) setSlotMask:(unsigned long)aSlotMask;
- (BOOL) autoIncrement;
- (void) setAutoIncrement:(BOOL)aAutoIncrement;
- (unsigned short) repeatDelay;
- (void) setRepeatDelay:(unsigned short)aRepeatDelay;
- (short) repeatOpCount;
- (void) setRepeatOpCount:(short)aRepeatCount;
- (unsigned long) writeValue;
- (void) setWriteValue:(unsigned long)aWriteValue;
- (unsigned int) xl3Mode;
- (void) setXl3Mode:(unsigned int)aXl3Mode;
- (BOOL) xl3ModeRunning;
- (void) setXl3ModeRunning:(BOOL)anXl3ModeRunning;
- (unsigned long) xl3RWAddressValue;
- (void) setXl3RWAddressValue:(unsigned long)anXl3RWAddressValue;
- (unsigned long) xl3RWDataValue;
- (void) setXl3RWDataValue:(unsigned long)anXl3RWDataValue;
- (BOOL) xl3OpsRunningForKey:(id)aKey;
- (void) setXl3OpsRunning:(BOOL)anXl3OpsRunning forKey:(id)aKey;
- (unsigned long) xl3PedestalMask;
- (void) setXl3PedestalMask:(unsigned long)anXl3PedestalMask;

- (int) selectedRegister;
- (void) setSelectedRegister:(int)aSelectedRegister;
- (NSString*) xl3LockName;
- (NSComparisonResult) XL3NumberCompare:(id)aCard;

#pragma mark •••DB Helpers
- (void) synthesizeDefaultsIntoBundle:(mb_t*)aBundle forSLot:(unsigned short)aSlot;
- (void) byteSwapBundle:(mb_t*)aBundle;
- (void) synthesizeFECIntoBundle:(mb_t*)aBundle forSLot:(unsigned short)aSlot;

#pragma mark •••DataTaker
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherObj;
@property unsigned long xl3MegaBundleDataId;
@property unsigned long cmosRateDataId;
- (NSDictionary*) dataRecordDescription;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (int) load_eCPU_HW_Config_Structure:(VME_crate_config*)configStruct index:(int)index;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

#pragma mark •••Hardware Access
- (void) selectCards:(unsigned long) selectBits;
- (void) deselectCards;
- (void) select:(ORSNOCard*) aCard;
- (void) writeHardwareRegister:(unsigned long) anAddress value:(unsigned long) aValue;
- (unsigned long) readHardwareRegister:(unsigned long) regAddress;
- (void) writeHardwareMemory:(unsigned long) memAddress value:(unsigned long) aValue;
- (unsigned long) readHardwareMemory:(unsigned long) memAddress;
- (void) writeXL3Register:(short)aRegister value:(unsigned long)aValue;
- (unsigned long) readXL3Register:(short)aRegister;

- (void) initCrateWithXilinx:(BOOL)aXilinxFlag autoInit:(BOOL)anAutoInitFlag;

#pragma mark •••Basic Ops
- (void) readBasicOps;
- (void) writeBasicOps;
- (void) stopBasicOps;
- (void) reportStatus;

#pragma mark •••Composite
- (void) deselectComposite;
- (void) writeXl3Mode;
- (void) compositeXl3RW;
- (void) compositeQuit;
- (void) compositeSetPedestal;
- (unsigned short) getBoardIDForSlot:(unsigned short)aSlot chip:(unsigned short)aChip;
- (void) getBoardIDs;
- (void) compositeResetCrate;
- (void) compositeResetCrateAndXilinX;
- (void) compositeResetFIFOAndSequencer;
- (void) compositeResetXL3StateMachine;
- (void) compositeEnableChargeInjection;
- (void) reset;
- (void) enableChargeInjectionForSlot:(unsigned short)aSlot channelMask:(unsigned long)aChannelMask;

#pragma mark •••HV
- (void) readCMOSCountWithArgs:(check_total_count_args_t*)aSlot counts:(check_total_count_results_t*)aCounts;
- (void) readCMOSCountForSlot:(unsigned short)aSlot withChannelMask:(unsigned long)aChannelMask;
- (void) readCMOSCount;

- (void) readCMOSRateWithArgs:(read_cmos_rate_args_t*)aArgs rates:(read_cmos_rate_results_t*)aRates;
- (void) readCMOSRateForSlot:(unsigned short)aSlot withChannelMask:(unsigned long)aChannelMask withDelay:(unsigned long)aDelay;
- (void) readCMOSRateWithDelay:(unsigned long)aDelay;

- (void) readPMTBaseCurrentsWithArgs:(read_pmt_base_currents_args_t*)aArg currents:(read_pmt_base_currents_results_t*)result;
- (void) readPMTBaseCurrentsForSlot:(unsigned short)aSlot withChannelMask:(unsigned long)aChannelMask;
- (void) readPMTBaseCurrents;

- (void) readHVStatus:(hv_readback_results_t*)status;
- (void) readHVStatus;

- (void) setHVRelays:(unsigned long long)relayMask error:(unsigned long*)aError;
- (void) setHVRelays:(unsigned long long)relayMask;
- (void) closeHVRelays;
- (void) openHVRelays;

- (void) setHVSwitchOnForA:(BOOL)aIsOn forB:(BOOL)bIsOn;
- (void) readHVSwitchOnForA:(BOOL*)aIsOn forB:(BOOL*)bIsOn;
- (void) readHVSwitchOn;

- (void) setHVSwitch:(BOOL)aOn forPowerSupply:(unsigned char)sup;


- (void) readHVInterlockGood:(BOOL*)isGood;
- (void) readHVInterlock;
- (void) setHVDacA:(unsigned short)aDac dacB:(unsigned short)bDac;

#pragma mark •••tests
- (void) readVMONForSlot:(unsigned short)aSlot voltages:(vmon_results_t*)aVoltages;
- (void) readVMONForSlot:(unsigned short)aSlot;
- (void) readVMONWithMask:(unsigned short)aSlotMask;
- (void) readVMONXL3:(vmon_xl3_results_t*)aVoltages;
- (void) readVMONXL3;

- (void) pollXl3:(BOOL)forceFlag;

- (void) loadSingleDacForSlot:(unsigned short)aSlot dacNum:(unsigned short)aDacNum dacVal:(unsigned char)aDacVal;
- (void) setVthrDACsForSlot:(unsigned short)aSlot withChannelMask:(unsigned long)aChannelMask dac:(unsigned char)aDac;

- (id) writeHardwareRegisterCmd:(unsigned long) aRegister value:(unsigned long) aBitPattern;
- (id) readHardwareRegisterCmd:(unsigned long) regAddress;
- (void) executeCommandList:(ORCommandList*)aList;
- (id) delayCmd:(unsigned long) milliSeconds;

@end

extern NSString* ORXL3ModelSelectedRegisterChanged;
extern NSString* ORXL3ModelRepeatCountChanged;
extern NSString* ORXL3ModelRepeatDelayChanged;
extern NSString* ORXL3ModelAutoIncrementChanged;
extern NSString* ORXL3ModelBasicOpsRunningChanged;
extern NSString* ORXL3ModelWriteValueChanged;
extern NSString* ORXL3ModelXl3ModeChanged;
extern NSString* ORXL3ModelSlotMaskChanged;
extern NSString* ORXL3ModelXl3ModeRunningChanged;
extern NSString* ORXL3ModelXl3RWAddressValueChanged;
extern NSString* ORXL3ModelXl3RWDataValueChanged;
extern NSString* ORXL3ModelXl3OpsRunningChanged;
extern NSString* ORXL3ModelXl3PedestalMaskChanged;
extern NSString* ORXL3ModelXl3ChargeInjChanged;
extern NSString* ORXL3ModelPollXl3TimeChanged;
extern NSString* ORXL3ModelIsPollingXl3Changed;
extern NSString* ORXL3ModelIsPollingCMOSRatesChanged;
extern NSString* ORXL3ModelPollCMOSRatesMaskChanged;
extern NSString* ORXL3ModelIsPollingPMTCurrentsChanged;
extern NSString* ORXL3ModelPollPMTCurrentsMaskChanged;
extern NSString* ORXL3ModelIsPollingFECVoltagesChanged;
extern NSString* ORXL3ModelPollFECVoltagesMaskChanged;
extern NSString* ORXL3ModelIsPollingXl3VoltagesChanged;
extern NSString* ORXL3ModelIsPollingHVSupplyChanged;
extern NSString* ORXL3ModelIsPollingXl3WithRunChanged;
extern NSString* ORXL3ModelPollStatusChanged;
extern NSString* ORXL3ModelIsPollingVerboseChanged;
extern NSString* ORXL3ModelRelayMaskChanged;
extern NSString* ORXL3ModelRelayStatusChanged;
extern NSString* ORXL3ModelHvStatusChanged;