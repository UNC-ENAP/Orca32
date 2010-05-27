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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "ORVmeIOCard.h"
#import "ORDataTaker.h"
#import "ORHWWizard.h"
#import "SBC_Config.h"

@class ORRateGroup;
@class ORAlarm;

#define kNumSIS3800Channels			32 

@interface ORSIS3800Model : ORVmeIOCard <ORDataTaker,ORHWWizard>
{
  @private
	int				pollTime;
	BOOL			isRunning;
 	unsigned short	moduleID;
	unsigned long   dataId;
	unsigned long	counts[32];
	unsigned long   timeMeasured;
	unsigned long   lastTimeMeasured;
    unsigned long	countEnableMask;
    unsigned long	overFlowMask;
	
    int lemoInMode;
    BOOL enable25MHzPulses;
    BOOL enableInputTestMode;
    BOOL enableReferencePulser;
    BOOL clearOnRunStart;
    BOOL syncWithRun;
    BOOL isCounting;
}

- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark ***Accessors
- (BOOL) isCounting;
- (void) setIsCounting:(BOOL)aIsCounting;
- (BOOL) syncWithRun;
- (void) setSyncWithRun:(BOOL)aSyncWithRun;
- (BOOL) clearOnRunStart;
- (void) setClearOnRunStart:(BOOL)aClearOnRunStart;
- (float) convertedPollTime;
- (int) pollTime;
- (void) setPollTime:(int)aPollTime;
- (BOOL) enableReferencePulser;
- (void) setEnableReferencePulser:(BOOL)aEnableReferencePulser;
- (BOOL) enableInputTestMode;
- (void) setEnableInputTestMode:(BOOL)aEnableInputTestMode;
- (BOOL) enable25MHzPulses;
- (void) setEnable25MHzPulses:(BOOL)aEnable25MHzPulses;
- (int) lemoInMode;
- (void) setLemoInMode:(int)aLemoInMode;
- (unsigned long) counts:(int)i;
- (unsigned long) countEnableMask;
- (void) setCountEnableMask:(unsigned long)aCountEnableMask;
- (BOOL) countEnabled:(short)chan;
- (void) setCountEnabled:(short)chan withValue:(BOOL)aValue;	
- (unsigned long) overFlowMask;
- (void) setOverFlowMask:(unsigned long)aMask;


- (void) setDefaults;
- (unsigned short) moduleID;

#pragma mark •••Hardware Access
- (void) initBoard;
- (void) readModuleID:(BOOL)verbose;
- (void) readStatusRegister;
- (void) writeControlRegister;
- (void) setLed:(BOOL)state;
- (void) startCounting;
- (void) stopCounting;
- (void) readCounts:(BOOL)clear;
- (void) clearAll;
- (void) clearCounter:(int)i;
- (void) clearCounterGroup:(int)group;
- (void) clearCounterGroup0;
- (void) clearCounterGroup1;
- (void) clearCounterGroup2;
- (void) clearCounterGroup3;
- (void) enableReferencePulser:(BOOL)state;
- (void) generateTestPulse;
- (void) clearOverFlowCounter:(int)i;
- (void) readOverFlowRegisters;
- (void) timeToPoll;

#pragma mark •••Data Taker
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (NSDictionary*) dataRecordDescription;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;

#pragma mark •••HW Wizard
- (int) numberOfChannels;
- (NSArray*) wizardParameters;
- (NSArray*) wizardSelections;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORSIS3800ModelIsCountingChanged;
extern NSString* ORSIS3800ModelSyncWithRunChanged;
extern NSString* ORSIS3800ModelClearOnRunStartChanged;
extern NSString* ORSIS3800ModelEnableReferencePulserChanged;
extern NSString* ORSIS3800ModelEnableInputTestModeChanged;
extern NSString* ORSIS3800ModelEnable25MHzPulsesChanged;
extern NSString* ORSIS3800ModelLemoInModeChanged;
extern NSString* ORSIS3800ModelCountEnableMaskChanged;
extern NSString* ORSIS3800SettingsLock;
extern NSString* ORSIS3800ModelIDChanged;
extern NSString* ORSIS3800CountersChanged;
extern NSString* ORSIS3800ModelOverFlowMaskChanged;
extern NSString* ORSIS3800PollTimeChanged;

