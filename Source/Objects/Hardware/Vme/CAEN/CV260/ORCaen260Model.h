/*
 *  ORCaen260Model.h
 *  Orca
 *
 *  Created by Mark Howe on 12/7/07.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
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

#pragma mark •••Imported Files

#import "ORCaenCardModel.h"
#import "VME_eCPU_Config.h"
#import "SBC_Config.h"

#define 	kNumCaen260Channels 		16

#pragma mark •••Register Definitions
enum {
	kVersion,
	kModualType,
	kFixedCode,
	kInterruptJumpers,
	kScalerIncrease,
	kInhibitReset,
	kInhibitSet,
	kClear,
	kCounter0,
	kCounter1,
	kCounter2,
	kCounter3,
	kCounter4,
	kCounter5,
	kCounter6,
	kCounter7,
	kCounter8,
	kCounter9,
	kCounter10,
	kCounter11,
	kCounter12,
	kCounter13,
	kCounter14,
	kCounter15,
	kClearVMEInterrupt,
	kDisableVMEInterrupt,
	kEnableVMEInterrupt,
	kInterruptLevel,
	kInterruptVector,
	kNumberOfV260Registers			//must be last
};

#pragma mark •••Forward Declarations
@class ORRateGroup;

@interface ORCaen260Model :  ORCaenCardModel
{
    @private
		BOOL			pollRunning;
        unsigned short	enabledMask;
		unsigned long	scalerValue[kNumCaen260Channels];
		NSTimeInterval	pollingState;
		BOOL			shipRecords;
		time_t			lastReadTime;
}

#pragma mark •••Initialization
- (id) init; 
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark •••Accessors
- (BOOL) shipRecords;
- (void) setShipRecords:(BOOL)aShipRecords;
- (unsigned long) scalerValue:(int)index;
- (void) setScalerValue:(unsigned long)aValue index:(int)index;
- (unsigned short) enabledMask;
- (void) setEnabledMask:(unsigned short)aEnabledMask;
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherCaen260;
- (void) setPollingState:(NSTimeInterval)aState;
- (NSTimeInterval) pollingState;

#pragma mark •••Hardware Access
- (unsigned short) 	readBoardVersion;
- (unsigned short) 	readFixedCode;
- (void)			setInhibit;
- (void)			resetInhibit;
- (void)			clearScalers;
- (void)			readScalers;

#pragma mark •••Data Header
- (NSDictionary*) dataRecordDescription;

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

#pragma mark •••External String Definitions
extern NSString* ORCaen260ModelEnabledMaskChanged;
extern NSString* ORCaen260ModelScalerValueChanged;
extern NSString* ORCaen260ModelPollingStateChanged;
extern NSString* ORCaen260ModelShipRecordsChanged;

