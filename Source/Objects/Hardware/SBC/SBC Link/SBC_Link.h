//
//  SBC_Link.h
//  OrcaIntel
//
//  Created by Mark Howe on 9/11/07.
//  Copyright 2007 CENPA, University of Washington. All rights reserved.
//
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

#import "SBC_Config.h"
#import "SBC_Cmds.h"
#import "ORGroup.h"

typedef  enum eSBC_CrateStates{
	kIdle,
	kTryToConnect,
	kTryToStartCode,
	kWaitingForStart,
	kReloadCode,
	kWaitingForReload,
	kTryToConnect2,
	kDone,
	kNumStates //must be last
}eSBC_CrateStates;

typedef enum eSBC_ThrottleConsts{
    kShrinkThrottleBy = 50,           // We shrink the throttle by this much
    kAmountInBufferThreshold = 0x1000 // if the amount in the buffer exceeds this
}eSBC_ThrottleConsts;

@class  ORFileMover;
@class  ORCard;
@class ORSafeQueue;

@interface SBC_Link : ORGroup {
	id				delegate;
	ORAlarm*        eCpuDeadAlarm;
	ORAlarm*        eRunFailedAlarm;

	//setttings
	NSString*		IPNumber;
    NSString*		passWord;
    NSString*		userName;
    NSString*		filePath;
    int				portNumber;
	
	ORFileMover*	coreSBCFileMover;
	ORFileMover*	specificHWFileMover;
	NSMutableData*	theDataBuffer;
	unsigned short  missedHeartBeat;
	unsigned long   oldCycleCount;
	BOOL            isRunning;
    BOOL            startedCode;
    NSTimeInterval	updateInterval;
    unsigned long	writeAddress;
    unsigned long	writeValue;
	unsigned long   addressModifier;
	SBC_info_struct runInfo;
	NSDate*			lastQueUpdate;
    BOOL			reloading;
	NSData*			leftOverData;
	BOOL			isConnected;
    NSCalendarDate*	timeConnected;
	int				socketfd;
	int				irqfd;
	int				startCrateState;
	int				waitCount;
	BOOL			tryingTostartCrate;
	int				compilerErrors;
	int				compilerWarnings;
	BOOL			verbose;
	BOOL			forceReload;
    BOOL			initAfterConnect;
	long			payloadSize;
	unsigned long   bytesReceived;
	unsigned long   bytesSent;
	float			byteRateReceived;
	float			byteRateSent;
    int				loadMode;
	unsigned long	throttleCount;
	unsigned long	throttle;
	unsigned int	readWriteType;
	BOOL			doRange;
	unsigned short	range;
	int				infoType;
	NSLock*			socketLock;
	BOOL			irqThreadRunning;
	ORSafeQueue*    lamsToAck;
	BOOL			stopWatchingIRQ;

	NSTask*			pingTask;

	//cbTest varibles
	int				numTestPoints;
	int				cbTestCount;
	long			startBlockSize;
	long			endBlockSize;
	long			deltaBlockSize;
	long			currentBlockSize;
	BOOL			cbTestRunning;
	BOOL			exitCBTest;
	NSDate*			lastInfoUpdate;
	double			totalTime;
	double			totalPayload;
	long			totalMeasurements;
	long			totalRecordsChecked;
	long			totalErrors;
	BOOL			doingProductionTest;
	BOOL			productionSpeedValueValid;
	float			productionSpeed;
	NSPoint         cbPoints[100];
	int				recordSizeHisto[1000];
}

- (id)   initWithDelegate:(ORCard*)anDelegate;
- (void) dealloc;
- (void) wakeUp; 
- (void) sleep ;	

#pragma mark •••Accessors
- (int) slot;
- (NSUndoManager*) undoManager;
- (int) numTestPoints;
- (void) setNumTestPoints:(int)num;
- (int) infoType;
- (void) setInfoType:(int)aType;
- (void) setDelegate:(ORCard*)anDelegate;
- (id) delegate;
- (int) loadMode;
- (void) setLoadMode:(int)aLoadMode;
- (BOOL) initAfterConnect;
- (void) setInitAfterConnect:(BOOL)aInitAfterConnect;
- (BOOL) tryingToStartCrate;
- (void) setTryingToStartCrate:(BOOL)flag;
- (BOOL) verbose;
- (void) setVerbose:(BOOL)flag;
- (BOOL) forceReload;
- (void) setForceReload:(BOOL)flag;
- (BOOL) reloading;
- (void) setReloading:(BOOL)aReloading;
- (void) setCompilerErrors:(int)aValue;
- (int) compilerErrors;
- (void) setCompilerWarnings:(int)aValue;
- (int) compilerWarnings;
- (NSDate*) lastQueUpdate;
- (void) setLastQueUpdate:(NSDate*)aDate;
- (SBC_info_struct) runInfo;
- (unsigned long) writeValue;
- (void) setWriteValue:(unsigned long)aWriteValue;
- (unsigned long) writeAddress;
- (void) setWriteAddress:(unsigned long)aAddress;
- (NSString*) filePath;
- (void) setFilePath:(NSString*)aPath;
- (NSString*) userName;
- (void) setUserName:(NSString*)aUserName;
- (NSString*) passWord;
- (void) setPassWord:(NSString*)aPassWord;
- (int) portNumber;
- (BOOL) isConnected;
- (void) setIsConnected:(BOOL)aNewIsConnected;
- (NSCalendarDate*) timeConnected;
- (void) setTimeConnected:(NSCalendarDate*)newTimeConnected;
- (void) setPortNumber:(int)aPort;
- (NSString*) IPNumber;
- (void) setIPNumber:(NSString*)aIPNumber;
- (unsigned short) range;
- (void) setRange:(unsigned short)aRange;
- (BOOL) doRange;
- (void) setDoRange:(BOOL)aDoRange;
- (unsigned int) readWriteType;
- (void) setReadWriteType:(unsigned int)aValue;
- (unsigned long) addressModifier;
- (void) setAddressModifier:(unsigned long)aValue;
- (long) payloadSize;
- (void) setPayloadSize:(long)aValue;


- (void) calculateRates;
- (void) setByteRateSent:(float)aRate;
- (float)byteRateSent;
- (void) setByteRateReceived:(float)aRate;
- (float)byteRateReceived;

- (void) fileMoverIsDone:(NSNotification*)aNote;

- (void) tasksCompleted:(id)sender;

- (int) connectToPort:(unsigned short) aPort;
- (void) getRunInfoBlock;
- (void) reloadClient;
- (void) killCrate;
- (void) taskData:(NSString*)text;
- (void) taskFinished:(NSTask*)aTask;
- (void) toggleCrate;
- (void) startCrate;
- (void) stopCrate;
- (void) startCrateCode;
- (void) connect;
- (void) disconnect;
- (NSString*) crateProcessState;

- (void) tellClientToStartRun;
- (void) tellClientToStopRun;

- (void) sendCommand:(long)aCmd withOptions:(SBC_CmdOptionStruct*)optionBlock expectResponse:(BOOL)askForResponse;
- (void) sendPayloadSize:(long)aSize;

- (void) readLongBlock:(long*) buffer
			 atAddress:(unsigned long) anAddress
			 numToRead:(unsigned int) numberLongs;

- (void) writeLongBlock:(long*) buffer
			 atAddress:(unsigned long) anAddress
			 numToRead:(unsigned int)  numberLongs;

- (void) readLongBlock:(unsigned long *) readAddress
			 atAddress:(unsigned int) vmeAddress
			 numToRead:(unsigned int) numberLongs
			withAddMod:(unsigned short) anAddressModifier
		 usingAddSpace:(unsigned short) anAddressSpace;

- (void) writeLongBlock:(unsigned long *) writeAddress
			  atAddress:(unsigned int) vmeAddress
			 numToWrite:(unsigned int) numberLongs
			 withAddMod:(unsigned short) anAddressModifier
		  usingAddSpace:(unsigned short) anAddressSpace;

- (void) readByteBlock:(unsigned char *) readAddress
			 atAddress:(unsigned int) vmeAddress
			 numToRead:(unsigned int) numberBytes
			withAddMod:(unsigned short) anAddressModifier
		 usingAddSpace:(unsigned short) anAddressSpace;

- (void) writeByteBlock:(unsigned char *) writeAddress
			  atAddress:(unsigned int) vmeAddress
			 numToWrite:(unsigned int) numberBytes
			 withAddMod:(unsigned short) anAddressModifier
		  usingAddSpace:(unsigned short) anAddressSpace;

- (void) readWordBlock:(unsigned short *) readAddress
			 atAddress:(unsigned int) vmeAddress
			 numToRead:(unsigned int) numberWords
			withAddMod:(unsigned short) anAddressModifier
		 usingAddSpace:(unsigned short) anAddressSpace;

- (void) writeWordBlock:(unsigned short *) writeAddress
			  atAddress:(unsigned int) vmeAddress
			 numToWrite:(unsigned int) numberWords
			 withAddMod:(unsigned short) anAddressModifier
		  usingAddSpace:(unsigned short) anAddressSpace;


- (void) send:(SBC_Packet*)aSendPacket receive:(SBC_Packet*)aReceivePacket;

- (void) update;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (BOOL) doneTakingData;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) load_HW_Config:(SBC_crate_config*)aConfig;
- (unsigned long) throttle;

- (NSString*) sbcLockName;
- (NSString*) crateName;

- (void) ping;
- (BOOL) pingTaskRunning;
- (void) startCBTransferTest;
- (BOOL) cbTestRunning;
- (int) cbTestCount;
- (NSPoint) cbPoint:(unsigned)i;
- (double) cbTestProgress;
- (long) totalRecordsChecked;
- (long) totalErrors;
- (int) recordSizeHisto:(int)aChannel;
- (int) numHistoChannels;
- (BOOL) productionSpeedValueValid;
- (float) productionSpeed;

#pragma mark •••DataSource
- (void) getQueMinValue:(unsigned long*)aMinValue maxValue:(unsigned long*)aMaxValue head:(unsigned long*)aHeadValue tail:(unsigned long*)aTailValue;

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;


- (void) throwError:(int)anError;
- (void) fillInScript:(NSString*)theScript;
- (void) runFailed;
- (void) startCrateProcess;
- (void) watchIrqSocket;
- (void) write:(int)aSocket buffer:(SBC_Packet*)aPacket;
- (void) read:(int)aSocket buffer:(SBC_Packet*)aPacket;
- (BOOL) dataAvailable:(int) sck;
- (BOOL) canWriteTo:(int) sck;
- (void) readSocket:(int)aSocket buffer:(SBC_Packet*)aPacket;
- (void) sampleCBTransferSpeed;
- (void) doOneCBTransferTest:(long)payloadSize;
- (void) doCBTransferTest;

@end

@interface NSObject (SBC_Link)
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;
- (NSString*) sbcLockName;
- (SBC_Link*) sbcLink;
@end

extern NSString* SBC_LinkLoadModeChanged;
extern NSString* SBC_LinkInitAfterConnectChanged;	
extern NSString* SBC_LinkReloadingChanged;
extern NSString* SBC_LinkWriteValueChanged;	
extern NSString* SBC_LinkWriteAddressChanged;
extern NSString* SBC_LinkPathChanged;	
extern NSString* SBC_LinkUserNameChanged;
extern NSString* SBC_LinkPassWordChanged;
extern NSString* SBC_LinkPortChanged;	
extern NSString* SBC_LinkIPNumberChanged;
extern NSString* SBC_LinkRunInfoChanged;
extern NSString* SBC_LinkTimeConnectedChanged;
extern NSString* SBC_LinkConnectionChanged;	
extern NSString* SBC_LinkCompilerErrorsChanged;	
extern NSString* SBC_LinkCompilerWarningsChanged;
extern NSString* SBC_LinkVerboseChanged;	
extern NSString* SBC_LinkForceReloadChanged;	
extern NSString* SBC_LinkCrateStartStatusChanged;
extern NSString* SBC_LinkTryingToStartCrateChanged;
extern NSString* SBC_LinkByteRateChanged;	
extern NSString* SBC_LinkRangeChanged;
extern NSString* SBC_LinkDoRangeChanged;
extern NSString* SBC_LinkAddressModifierChanged;
extern NSString* SBC_LinkRWTypeChanged;
extern NSString* SBC_LinkInfoTypeChanged;
extern NSString* ORSBC_LinkPingTask;
extern NSString* ORSBC_LinkCBTest;
extern NSString* ORSBC_LinkNumCBTextPointsChanged;
extern NSString* ORSBC_LinkNumPayloadSizeChanged;

