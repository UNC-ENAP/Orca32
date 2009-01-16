//-------------------------------------------------------------------------
//  ORSIS3300Model.h
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "ORVmeIOCard.h";
#import "ORDataTaker.h";
#import "ORHWWizard.h";
#import "SBC_Config.h"

@class ORRateGroup;
@class ORAlarm;

#define kNumSIS3300Channels			8 

@interface ORSIS3300Model : ORVmeIOCard <ORDataTaker,ORHWWizard,ORHWRamping>
{
  @private
    int				pageSize;
 	
 	
    BOOL			stopTrigger;
    BOOL			pageWrap;
    BOOL			gateChaining;

	//control status reg
    BOOL enableTriggerOutput;
    BOOL invertTrigger;
    BOOL activateTriggerOnArmed;
    BOOL enableInternalRouting;
    BOOL bankFullTo1;
    BOOL bankFullTo2;
    BOOL bankFullTo3;	
	
	//Acquisition control reg
	BOOL bankSwitchMode;
    BOOL autoStart;
    BOOL multiEventMode;
	BOOL lemoStartStop;
    BOOL p2StartStop;
    BOOL gateMode;
    BOOL multiplexerMode;

	//clocks and delays (Acquistion control reg)
    BOOL stopDelayEnabled;
    BOOL startDelayEnabled;
    BOOL randomClock;
	int	 clockSource;
    int	 startDelay;
    int	 stopDelay;
	
	unsigned long   dataId;

	long			enabledMask;
	long			ltGtMask;
	NSMutableArray* thresholds;
	
	ORRateGroup*	waveFormRateGroup;
	unsigned long 	waveFormCount[kNumSIS3300Channels];
	BOOL isRunning;
	unsigned long*  dataBuffer;

	//cach to speed takedata
	unsigned long location;
	id theController;
	unsigned long fifoAddress;
	unsigned long fifoStateAddress;
	BOOL firstTime;
	int currentBank;
	int adcValue[8][512];
}

- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark ***Accessors
//CSR bits
- (BOOL) bankFullTo3;
- (void) setBankFullTo3:(BOOL)aBankFullTo3;
- (BOOL) bankFullTo2;
- (void) setBankFullTo2:(BOOL)aBankFullTo2;
- (BOOL) bankFullTo1;
- (void) setBankFullTo1:(BOOL)aBankFullTo1;
- (BOOL) enableInternalRouting;
- (void) setEnableInternalRouting:(BOOL)aEnableInternalRouting;
- (BOOL) activateTriggerOnArmed;
- (void) setActivateTriggerOnArmed:(BOOL)aActivateTriggerOnArmed;
- (BOOL) invertTrigger;
- (void) setInvertTrigger:(BOOL)aInvertTrigger;
- (BOOL) enableTriggerOutput;
- (void) setEnableTriggerOutput:(BOOL)aEnableTriggerOutput;

//Acquisition control reg
- (BOOL) bankSwitchMode;
- (void) setBankSwitchMode:(BOOL)aBankSwitchMode;
- (BOOL) autoStart;
- (void) setAutoStart:(BOOL)aAutoStart;
- (BOOL) multiEventMode;
- (void) setMultiEventMode:(BOOL)aMultiEventMode;
- (BOOL) multiplexerMode;
- (void) setMultiplexerMode:(BOOL)aMultiplexerMode;
- (BOOL) lemoStartStop;
- (void) setLemoStartStop:(BOOL)aLemoStartStop;
- (BOOL) p2StartStop;
- (void) setP2StartStop:(BOOL)aP2StartStop;
- (BOOL) gateMode;
- (void) setGateMode:(BOOL)aGateMode;

//clocks and delays (Acquistion control reg)
- (BOOL) startDelayEnabled;
- (void) setStartDelayEnabled:(BOOL)aStartDelayEnabled;
- (BOOL) stopDelayEnabled;
- (void) setStopDelayEnabled:(BOOL)aStopDelayEnabled;
- (BOOL) randomClock;
- (void) setRandomClock:(BOOL)aRandomClock;
- (int) clockSource;
- (void) setClockSource:(int)aClockSource;

//event configuration
- (BOOL) pageWrap;
- (void) setPageWrap:(BOOL)aPageWrap;
- (BOOL) gateChaining;
- (void) setGateChaining:(BOOL)aState;


- (BOOL) stopTrigger;
- (void) setStopTrigger:(BOOL)aStopTrigger;
- (int) stopDelay;
- (void) setStopDelay:(int)aStopDelay;
- (int) startDelay;
- (void) setStartDelay:(int)aStartDelay;
- (int) pageSize;
- (void) setPageSize:(int)aPageSize;

- (long) enabledMask;
- (BOOL) enabled:(short)chan;
- (void) setEnabledMask:(long)aMask;
- (void) setEnabledBit:(short)chan withValue:(BOOL)aValue;

- (long) ltGtMask;
- (void) setLtGtMask:(long)aMask;
- (BOOL) ltGt:(short)chan;
- (void) setLtGtBit:(short)chan withValue:(BOOL)aValue;


- (void) setThreshold:(short)chan withValue:(int)aValue;
- (int) threshold:(short)chan;
- (NSMutableArray*) thresholds;
- (void) setThresholds:(NSMutableArray*)someThresholds;

- (void) initParams;

- (ORRateGroup*)    waveFormRateGroup;
- (void)			setWaveFormRateGroup:(ORRateGroup*)newRateGroup;
- (id)              rateObject:(int)channel;
- (void)            setRateIntegrationTime:(double)newIntegrationTime;
- (BOOL)			bumpRateFromDecodeStage:(short)channel;

- (int) sampleSize;
- (int) nPages;

#pragma mark •••Hardware Access
- (void) initBoard;
- (void) readModuleID;
- (void) writeControlStatusRegister;
- (void) writeAcquistionRegister;
- (void) writeEventConfigurationRegister;
- (void) writeThresholds:(BOOL)verbose;
- (void) readThresholds:(BOOL)verbose;
- (void) writeStartDelay;
- (void) writeStopDelay;
- (void) setLed:(BOOL)state;
- (void) enableUserOut:(BOOL)state;
- (void) startSampling;
- (void) stopSampling;
- (void) startBankSwitching;
- (void) stopBankSwitching;
- (void) clearBankFullFlag:(int)whichFlag;
- (unsigned long) eventNumberGroup:(int)group bank:(int) bank;
- (void) writeTriggerClearValue:(unsigned long)aValue;
- (void) setMaxNumberEvents:(unsigned long)aValue;
- (unsigned long) eventTriggerGroup:(int)group bank:(int) bank;

- (void) disArm:(int)bank;
- (void) arm:(int)bank;
- (BOOL) bankIsFull:(int)bank;
- (void) writeTriggerSetup;

//some test functions
- (unsigned long) readTriggerEventBank:(int)bank index:(int)index;
- (void) readAddressCounts;

- (void) readAdcValues:(int)i;
- (int) adcValue:(int)chan index:(int)index;

- (unsigned long) acqReg;
- (unsigned long) configReg;
- (void) testMemory;
- (void) testEventRead;

#pragma mark •••Data Taker
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (NSDictionary*) dataRecordDescription;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (unsigned long) waveFormCount:(int)aChannel;
- (void)   startRates;
- (void) clearWaveFormCounts;
- (unsigned long) getCounter:(int)counterTag forGroup:(int)groupTag;
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;

- (void) sampleAdcValues;
- (unsigned long) readGroup:(int)aGroup intoBuffer:(void*)aBuffer;
- (unsigned int) readEventDirectory: (unsigned long) eventDirAddressOffset 
				  bankAddressOffest: (unsigned long) bankAddressOffest
						 intoBuffer: (void*) pBuffer;

#pragma mark •••HW Wizard
- (int) numberOfChannels;
- (NSArray*) wizardParameters;
- (NSArray*) wizardSelections;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;


#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
@end

//CSR
extern NSString* ORSIS3300ModelCSRRegChanged;
extern NSString* ORSIS3300ModelAcqRegChanged;
extern NSString* ORSIS3300ModelEventConfigChanged;

extern NSString* ORSIS3300ModelStopTriggerChanged;
extern NSString* ORSIS3300ModelRandomClockChanged;
extern NSString* ORSIS3300ModelStopDelayChanged;
extern NSString* ORSIS3300ModelStartDelayChanged;
extern NSString* ORSIS3300ModelClockSourceChanged;
extern NSString* ORSIS3300ModelPageSizeChanged;
extern NSString* ORSIS3300ModelEnabledChanged;
extern NSString* ORSIS3300ModelThresholdChanged;
extern NSString* ORSIS3300ModelThresholdArrayChanged;
extern NSString* ORSIS3300ModelLtGtChanged;

extern NSString* ORSIS3300SettingsLock;
extern NSString* ORSIS3300RateGroupChangedNotification;
extern NSString* ORSIS3300ModelSampleDone;
