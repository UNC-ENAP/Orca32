//
//  ORHPPulserModel.h
//  Orca
//
//  Created by Mark Howe on Tue May 13 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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
#import "ORGpibDeviceModel.h"
#import "ORDataTaker.h"

// Structure used to describe characteristics of hardware register.
typedef struct HPPulserCustomWaveformStruct {
	NSString*       waveformName;
	NSString*       storageName;
	bool			tryToStore;
} HPPulserCustomWaveformStruct; 

#define kCalibrationWidth 	7.8  //can't set exactly to 8 because of a bug in the HP pulser
#define kCalibrationVoltage 	750
#define kCalibrationBurstRate 	3.0 

#define kPadSize 100

@class ORDataPacket;

@interface ORHPPulserModel : ORGpibDeviceModel {
	NSMutableData*  waveform;
	float           voltage;
	float           burstRate;
	float           totalWidth;
	int             selectedWaveform;
	NSString*       fileName;
	int             downloadIndex;
	BOOL            loading;
    int             triggerSource;
	BOOL			enableRandom;
	float			minTime;
	float			maxTime;
	unsigned long	randomCount;
	unsigned long   pulserDataId;
	int				savedTriggerSource;
    BOOL			lockGUI;
    BOOL			negativePulse;
	
	enum {
    kSquareWave1,
    kSingleSinWave1,
	kSingleSinWave2,
    kSquareWave2,
    kDoubleSinWave,
    kLogCalibrationWaveform,
	kLogCalibWave2,
	kLogCalibWave4,
	kDoubleLogamp,
	kTripleLogamp,
	kLogCalibWaveAdjust,
	kGaussian,
	kPinDiode,
    kWaveformFromFile,
    kNumWaveforms   //must be last
    } volatileWaveformConsts;
	
	enum {
	kNumBuiltInTypes = 6
	} numBuiltInTypes;
	
	enum {
	kMaxNumWaveformPoints = 16000
	} maxNumWaveformPoints;
    
	enum {
    kInternalTrigger,
    kExternalTrigger,
    kSoftwareTrigger 
    } triggerTypes;
}

#pragma mark ***Initialization
- (id) 		init;
- (void) 	dealloc;
- (void)	setUpImage;
- (void)	makeMainController;
- (void) registerNotificationObservers;
- (void) runStatusChanged:(NSNotification*)aNotification;
- (void) downloadStarted:(NSNotification*)aNotification;
- (void) downloadFinished:(NSNotification*)aNotification;
- (void) waveFormWasSent;
- (void) updateLoadProgress;

#pragma mark •••Accessors
- (BOOL) negativePulse;
- (void) setNegativePulse:(BOOL)aNegativePulse;
- (BOOL) lockGUI;
- (void) setLockGUI:(BOOL)aLockGUI;
- (NSString *) fileName;
- (void)  setFileName:(NSString *)newFileName;

- (int)	  selectedWaveform;
- (void)  setSelectedWaveform:(int)newSelectedWaveform;
- (NSMutableData*) waveform;
- (void)  setWaveform:(NSMutableData* )newWaveform;
- (float) voltage;
- (void)  setVoltage:(float)aValue;
- (float) burstRate;
- (void)  setBurstRate:(float)aValue;
- (float) totalWidth;
- (void)  setTotalWidth:(float)aValue;

- (int)	 triggerSource;
- (void) setTriggerSource:(short)aValue;

- (int)  downloadIndex;
- (void) stopDownload;
- (BOOL) loading;
- (BOOL) enableRandom;
- (void) setEnableRandom:(BOOL)aNewEnableRandom;
- (float) minTime;
- (void) setMinTime:(float)aNewMinTime;
- (float) maxTime;
- (void) setMaxTime:(float)aNewMaxTime;
- (unsigned long) randomCount;
- (void) setRandomCount:(unsigned long)aNewRandomCount;
- (unsigned long)   pulserDataId;
- (void)   setPulserDataId:(unsigned long)aValue;
- (id)  dialogLock;

#pragma mark •••Hardware Access
- (NSString*) readIDString;
- (void) resetAndClear;
- (void) systemTest;
- (void) logSystemResponse;
- (void) writeVoltage:(unsigned short)value;
- (void) writeBurstRate:(float)rate;
- (void) writeTotalWidth:(float)width;
- (void) writeBurstMode:(BOOL)value;
- (void) writeBurstCount:(int)value;
- (void) writeTriggerSource:(short)value;
- (void) downloadWaveform;
- (void) downloadWaveformWorker;
- (void) copyWaveformWorker;
- (void) outputWaveformParams;

#pragma mark •••NonVolatile Memory Management
- (void) loadFromVolativeMemory;
- (void) loadFromNonVolativeMemory;
- (BOOL) isWaveformInNonVolatileMemory;
- (void) emptyVolatileMemory;
- (NSArray*) getLoadedWaveforms;

- (NSDictionary*) dataRecordDescription;
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;

#pragma mark •••Waveform Building
- (void) insert:(unsigned short) numPoints value:(float) theValue;
- (void) insertNegativeFullSineWave:(unsigned short)numPoints amplitude:(float) theAmplitude phase:(float) thePhase;
- (void) insertGaussian:(unsigned short)numPoints amplitude:(float) theAmplitude;
- (void) insertPinDiode:(unsigned short)numPoints amplitude:(float) theAmplitude;
- (void) normalizeWaveform;
- (unsigned short) numPoints;
- (void) trigger;

#pragma mark •••Helpers
- (void) buildWave;
- (BOOL) inCustomList:(NSString*)aName;
- (BOOL) inBuiltInList:(NSString*)aName;
- (float) calculateFreq:(float)width;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)aDecoder;
- (void)encodeWithCoder:(NSCoder*)anEncoder;
- (void)loadMemento:(NSCoder*)decoder;
- (void)saveMemento:(NSCoder*)anEncoder;
- (NSData*) memento;
- (void) restoreFromMemento:(NSData*)aMemento;

@end

extern NSString* ORHPPulserModelNegativePulseChanged;
extern NSString* ORHPPulserModelLockGUIChanged;
extern NSString* ORHPPulserVoltageChangedNotification;
extern NSString* ORHPPulserBurstRateChangedNotification;
extern NSString* ORHPPulserTotalWidthChangedNotification;
extern NSString* ORHPPulserSelectedWaveformChangedNotification;
extern NSString* ORHPPulserWaveformLoadStartedNotification;
extern NSString* ORHPPulserWaveformLoadProgressingNotification;
extern NSString* ORHPPulserWaveformLoadFinishedNotification;
extern NSString* ORHPPulserWaveformLoadingNonVoltileNotification;
extern NSString* ORHPPulserWaveformLoadingVoltileNotification;
extern NSString* ORHPPulserTriggerModeChangedNotification;
extern NSString* ORHPPulserEnableRandomChangedNotification;
extern NSString* ORHPPulserMinTimeChangedNotification;
extern NSString* ORHPPulserMaxTimeChangedNotification;
extern NSString* ORHPPulserRandomCountChangedNotification;
