//-------------------------------------------------------------------------
//  ORCouchDBModel.h
//
//  Created by Mark A. Howe on Wednesday 10/18/2006.
//  Copyright (c) 2006 CENPA, University of Washington. All rights reserved.
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

#pragma mark ***Imported Files
@class ORCouchDB;
@class ORAlarm;

@interface ORCouchDBModel : OrcaObject
{
@private
	NSString*	remoteHostName;
    NSString*	userName;
    NSString*	password;
	BOOL		stealthMode;
	NSDictionary* dBInfo;
	NSDictionary* dBHistoryInfo;
	NSMutableArray* dataMonitors;
	BOOL statusUpdateScheduled;
	BOOL historyUpdateScheduled;
    BOOL keepHistory;
	//cache
	unsigned long runNumber;
	unsigned long subRunNumber;
    BOOL replicationRunning;
	NSDictionary* docList;
    NSString* oldName;
    NSString* betterName;
    BOOL sweepInProgress;
    BOOL cancelSweep;
    int processCount;
    int changedCount;
    BOOL wasReplicationRunning;
    int replicationCheckCount;
    ORAlarm* replicationAlarm;
    NSMutableDictionary* customDataBases;
}

#pragma mark ***Initialization
- (void) dealloc;

#pragma mark ***Notifications
- (void) registerNotificationObservers;
- (void) applicationIsTerminating:(NSNotification*)aNote;
- (void) runOptionsOrTimeChanged:(NSNotification*)aNote;
- (void) runStatusChanged:(NSNotification*)aNote;
- (void) alarmsChanged:(NSNotification*)aNote;
- (void) statusLogChanged:(NSNotification*)aNote;
- (void) runStarted:(NSNotification*)aNote;
- (void) runStopped:(NSNotification*)aNote;
- (void) addObjectValueRecord:(NSNotification*)aNote;
- (void) addObject:(OrcaObject*)anObj valueDictionary:(NSDictionary*)aDictionary;
- (void) addObject:(OrcaObject*)anObj valueDictionary:(NSDictionary*)aDictionary dataBaseRef:(ORCouchDB*)aDataBaseRef;
- (void) addAdcsToHistoryRecord:(NSNotification*)aNote;
- (void) addObject:(OrcaObject*)anObj adcDictionary:(NSDictionary*)aDictionary;
- (void) addObject:(OrcaObject*)anObj adcDictionary:(NSDictionary*)aDictionary dataBaseRef:(ORCouchDB*)aDataBaseRef;

#pragma mark ***Accessors
- (int) changedCount;
- (void) setChangedCount:(int)aChangedCount;
- (int) processCount;
- (void) setProcessCount:(int)aProcessCount;
- (void) cancelSweep;
- (BOOL) sweepInProgress;
- (void) setSweepInProgress:(BOOL)aSweepInProgress;
- (NSString*) betterName;
- (void) setBetterName:(NSString*)aBetterName;
- (NSString*) oldName;
- (void) setOldName:(NSString*)aOldName;
- (BOOL) replicationRunning;
- (void) setReplicationRunning:(BOOL)aReplicationRunning;
- (BOOL) couchRunning;
- (BOOL) keepHistory;
- (void) setKeepHistory:(BOOL)aKeepHistory;
- (BOOL) stealthMode;
- (void) setStealthMode:(BOOL)aStealthMode;
- (NSString*) password;
- (void) setPassword:(NSString*)aPassword;
- (NSString*) userName;
- (void) setUserName:(NSString*)aUserName;
- (NSString*) remoteHostName;
- (void) setRemoteHostName:(NSString*)aHostName;
- (id) nextObject;
- (NSString*) databaseName;
- (NSString*) historyDatabaseName;
- (NSString*) machineName;
- (void) setDBInfo:(NSDictionary*)someInfo;
- (void) setDBHistoryInfo:(NSDictionary*)someInfo;
- (NSDictionary*) dBHistoryInfo;
- (NSDictionary*) dBInfo;
- (void) startingSweep;
- (void) sweepDone;
- (void) incChangeCounter;
- (void) checkReplication;
- (void) recordEvent:(NSString*)eventName symbol:(NSString*)aSymbol comment:(NSString*)aComment;
- (void) recordEvent:(NSString*)eventName symbol:(NSString*)aSymbol comment:(NSString*)aComment timeString:aDateString timeStamp:(unsigned long)aTimeStamp;
- (void) checkDataBaseExists:(ORCouchDB*)aDataBase;

#pragma mark ***DB Access
- (ORCouchDB*) statusDBRef;
- (ORCouchDB*) historyDBRef;
- (ORCouchDB*) statusDBRef:(NSString*)aName;
- (ORCouchDB*) historyDBRef:(NSString*)aName;

- (ORCouchDB*) remoteDBRef:(NSString*)aDatabaseName;
- (ORCouchDB*) remoteDBRef;
- (ORCouchDB*) remoteHistoryDBRef;
- (ORCouchDB*) remoteHistoryDBRef:(NSString*)aDatabaseName;
- (void) createDatabase;
- (void) createDatabase:(ORCouchDB*)aDBRef;
- (void) createHistoryDatabase:(ORCouchDB*)aDBRef;
- (void) createHistoryDatabase;
- (void) createRemoteDataBases;
- (void) startReplication;
- (void) replicate:(BOOL)continuously;
- (void) deleteDatabase;
- (void) couchDBResult:(id)aResult tag:(NSString*)aTag op:(id)anOp;
//test functions
- (void) databaseInfo:(BOOL)toStatusWindow;
- (void) listDatabases;
- (void) listDocuments;
- (void) getRemoteInfo:(BOOL)verbose;
- (void) processRemoteTaskList:(NSArray*)aList verbose:(BOOL)verbose;
- (void) compactDatabase;
- (void) updateDatabaseStats;
- (void) updateRunInfo;
- (void) getEachDocForRenamingAdc;
- (void) renameAdc:(id)aDoc;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORCouchDBModelChangedCountChanged;
extern NSString* ORCouchDBModelProcessCountChanged;
extern NSString* ORCouchDBModelSweepInProgressChanged;
extern NSString* ORCouchDBModelBetterNameChanged;
extern NSString* ORCouchDBModelOldNameChanged;
extern NSString* ORCouchDBModelReplicationRunningChanged;
extern NSString* ORCouchDBModelKeepHistoryChanged;
extern NSString* ORCouchDBPasswordChanged;
extern NSString* ORCouchDBUserNameChanged;
extern NSString* ORCouchDBRemoteHostNameChanged;
extern NSString* ORCouchDBModelStealthModeChanged;
extern NSString* ORCouchDBModelDBInfoChanged;
extern NSString* ORCouchDBLock;



