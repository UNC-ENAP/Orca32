//
//  ORCouchDBModel.m
//  Orca
//
//  Created by Mark Howe on 10/18/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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


#import "ORCouchDBModel.h"
#import "ORCouchDB.h"
#import "MemoryWatcher.h"
#import "NSNotifications+Extensions.h"
#import "Utilities.h"
#import "ORRunModel.h"
#import "ORExperimentModel.h"
#import "ORAlarmCollection.h"
#import "ORAlarm.h"
#import "OR1DHisto.h"
#import "ORStatusController.h"
#import "ORProcessModel.h"

NSString* ORCouchDBModelStealthModeChanged	= @"ORCouchDBModelStealthModeChanged";
NSString* ORCouchDBDataBaseNameChanged		= @"ORCouchDBDataBaseNameChanged";
NSString* ORCouchDBPasswordChanged			= @"ORCouchDBPasswordChanged";
NSString* ORCouchDBUserNameChanged			= @"ORCouchDBUserNameChanged";
NSString* ORCouchDBHostNameChanged			= @"ORCouchDBHostNameChanged";
NSString* ORCouchDBModelDBInfoChanged		= @"ORCouchDBModelDBInfoChanged";

NSString* ORCouchDBLock						= @"ORCouchDBLock";

#define kCreateDB		 @"kCreateDB"
#define kDeleteDB		 @"kDeleteDB"
#define kListDB			 @"kListDB"
#define kDocument		 @"kDocument"
#define kInfoDB			 @"kInfoDB"
#define kDocumentAdded	 @"kDocumentAdded"
#define kDocumentUpdated @"kDocumentUpdated"
#define kDocumentDeleted @"kDocumentDeleted"
#define kCompactDB		 @"kCompactDB"
#define kInfoInternalDB  @"kInfoInternalDB"
#define kAttachmentAdded @"kAttachmentAdded"

#define kCouchDBPort 5984

static NSString* ORCouchDBModelInConnector 	= @"ORCouchDBModelInConnector";

@interface ORCouchDBModel (private)
- (void) updateProcesses;
- (void) updateMachineRecord;
- (void) postRunState:(NSNotification*)aNote;
- (void) postRunTime:(NSNotification*)aNote;
- (void) postRunOptions:(NSNotification*)aNote;
- (void) updateRunState:(ORRunModel*)rc;
- (void) periodicCompact;
- (void) updateDataSets;
- (void) updateStatus;
@end

@implementation ORCouchDBModel

#pragma mark ***Initialization
- (id) init
{
	[super init];
    [[self undoManager] disableUndoRegistration];
	[self registerNotificationObservers];
    [[self undoManager] enableUndoRegistration];
	return self;
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [dataBaseName release];
    [password release];
    [userName release];
    [hostName release];
	[super dealloc];
}

- (void) wakeUp
{
    if(![self aWake]){
		[self performSelector:@selector(updateMachineRecord) withObject:nil afterDelay:2];
		[self performSelector:@selector(updateDatabaseStats) withObject:nil afterDelay:3];
		[self performSelector:@selector(periodicCompact) withObject:nil afterDelay:60];
    }
    [super wakeUp];
}


- (void) sleep
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[self deleteDatabase];
	[super sleep];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"CouchDB"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORCouchDBController"];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(0,[self frame].size.height/2-kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORCouchDBModelInConnector];
    [aConnector setOffColor:[NSColor brownColor]];
    [aConnector setOnColor:[NSColor magentaColor]];
	[ aConnector setConnectorType: 'DB I' ];
	[ aConnector addRestrictedConnectionType: 'DB O' ]; //can only connect to DB outputs
	
    [aConnector release];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
	[notifyCenter removeObserver:self];
	
    [notifyCenter addObserver : self
                     selector : @selector(applicationIsTerminating:)
                         name : @"ORAppTerminating"
                       object : [NSApp delegate]];
	
	[notifyCenter addObserver : self
                     selector : @selector(runStatusChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(runOptionsOrTimeChanged:)
                         name : ORRunElapsedTimesChangedNotification
                       object : nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(runOptionsOrTimeChanged:)
                         name : ORRunRepeatRunChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(alarmsChanged:)
                         name : ORAlarmWasPostedNotification
                       object : nil];	
	
    [notifyCenter addObserver : self
                     selector : @selector(alarmsChanged:)
                         name : ORAlarmWasClearedNotification
                       object : nil];	
	
    [notifyCenter addObserver : self
                     selector : @selector(statusLogChanged:)
                         name : ORStatusLogUpdatedNotification
                       object : nil];    
	
	[notifyCenter addObserver : self
					 selector : @selector(updateProcesses)
						 name : ORProcessRunningChangedNotification
					   object : nil];	
	
	
}

- (void) applicationIsTerminating:(NSNotification*)aNote
{
	[self deleteDatabase];
}

- (void) awakeAfterDocumentLoaded
{
	[self runStatusChanged:nil];
	[self alarmsChanged:nil];
	[self statusLogChanged:nil];
}

#pragma mark ***Accessors
- (BOOL) stealthMode
{
    return stealthMode;
}

- (void) setStealthMode:(BOOL)aStealthMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStealthMode:stealthMode];
    stealthMode = aStealthMode;
	if(stealthMode){
		if([ORCouchDBQueue operationCount]) [ORCouchDBQueue cancelAllOperations];
		[self deleteDatabase];
	}
	else {
		[self createDatabase];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORCouchDBModelStealthModeChanged object:self];
}

- (id) nextObject
{
	return [self objectConnectedTo:ORCouchDBModelInConnector];
}

- (NSString*) dataBaseName
{
    return dataBaseName;
}

- (void) setDataBaseName:(NSString*)aDataBaseName
{
	if(aDataBaseName){
		[[[self undoManager] prepareWithInvocationTarget:self] setDataBaseName:dataBaseName];
		
		[dataBaseName autorelease];
		dataBaseName = [aDataBaseName copy];    
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORCouchDBDataBaseNameChanged object:self];
	}
}

- (NSString*) password
{
    return password;
}

- (void) setPassword:(NSString*)aPassword
{
	if(aPassword){
		[[[self undoManager] prepareWithInvocationTarget:self] setPassword:password];
		
		[password autorelease];
		password = [aPassword copy];    
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORCouchDBPasswordChanged object:self];
	}
}

- (NSString*) userName
{
    return userName;
}

- (void) setUserName:(NSString*)aUserName
{
	if(aUserName){
		[[[self undoManager] prepareWithInvocationTarget:self] setUserName:userName];
		
		[userName autorelease];
		userName = [aUserName copy];    
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORCouchDBUserNameChanged object:self];
	}
}

- (NSString*) hostName
{
    return hostName;
}

- (void) setHostName:(NSString*)aHostName
{
	if(aHostName){
		[[[self undoManager] prepareWithInvocationTarget:self] setHostName:hostName];
		
		[hostName autorelease];
		hostName = [aHostName copy];    
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORCouchDBHostNameChanged object:self];
	}
}

- (NSString*) machineName
{		
	NSString* machineName = [NSString stringWithFormat:@"%@",computerName()];
	machineName = [machineName stringByReplacingOccurrencesOfString:@" " withString:@"_"];
	return [machineName lowercaseString];
}

- (void) createDatabase
{
	//set up the views
	NSString* aMap;
	NSDictionary* aMapDictionary;
	NSMutableDictionary* aViewDictionary = [NSMutableDictionary dictionary];
	
	aMap            = @"function(doc) { if(doc.type == 'Histogram1D') { emit(doc.name, { 'name': doc.name, 'counts': doc.counts }); } }";
	aMapDictionary  = [NSDictionary dictionaryWithObject:aMap forKey:@"map"]; 
	[aViewDictionary setObject:aMapDictionary forKey:@"counts"]; 

	aMap            = @"function(doc) { if(doc.type == 'alarms') { emit(doc.type, {'alarmlist': doc.alarmlist}); } }";
	aMapDictionary  = [NSDictionary dictionaryWithObject:aMap forKey:@"map"]; 
	[aViewDictionary setObject:aMapDictionary forKey:@"alarms"]; 

	aMap            = @"function(doc) { if(doc.type == 'processes') { emit(doc.type, {'processlist': doc.processlist}); } }";
	aMapDictionary  = [NSDictionary dictionaryWithObject:aMap forKey:@"map"]; 
	[aViewDictionary setObject:aMapDictionary forKey:@"processes"]; 
	
	
	aMap            = @"function(doc) { if(doc.type == 'machineinfo') { emit(doc.type, doc); } }";
	aMapDictionary  = [NSDictionary dictionaryWithObject:aMap forKey:@"map"]; 
	[aViewDictionary setObject:aMapDictionary forKey:@"machineinfo"]; 

	aMap            = @"function(doc) { if(doc.type == 'runinfo') { emit(doc._id, doc); } }";
	aMapDictionary  = [NSDictionary dictionaryWithObject:aMap forKey:@"map"]; 
	[aViewDictionary setObject:aMapDictionary forKey:@"runinfo"]; 

	aMap            = @"function(doc) { if(doc.type == 'StatusLog') { emit(doc._id, doc); } }";
	aMapDictionary  = [NSDictionary dictionaryWithObject:aMap forKey:@"map"]; 
	[aViewDictionary setObject:aMapDictionary forKey:@"statuslog"]; 
	
	
	NSDictionary* theViews = [NSDictionary dictionaryWithObjectsAndKeys:
				  @"javascript",@"language",
				  aViewDictionary,@"views",
				  nil];	
	
	ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort username:userName pwd:password database:[self machineName] delegate:self];
	
	[db createDatabase:kCreateDB views:theViews];
	
	NSArray* runObjects = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
	if([runObjects count]){
		ORRunModel* rc = [runObjects objectAtIndex:0];
		[self updateRunState:rc];
	}
	
	[self updateMachineRecord];
	[self updateDatabaseStats];
	[self alarmsChanged:nil];
	[self statusLogChanged:nil];
	[self updateProcesses];
}

- (void) deleteDatabase
{
	ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort   username:userName pwd:password database:[self machineName] delegate:self];
	[db deleteDatabase:kDeleteDB];
}

- (void) updateProcesses
{
	if(!stealthMode){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateProcesses) object:nil];
		
		ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort  username:userName pwd:password database:[self machineName] delegate:self];
		
		NSArray* theProcesses = [[[[self document] collectObjectsOfClass:NSClassFromString(@"ORProcessModel")] retain] autorelease];
		
		NSMutableArray* arrayForDoc = [NSMutableArray array];
		if([theProcesses count]){
			for(id aProcess in theProcesses){
				NSString* shortName     = [aProcess shortName];
				NSString* lastTimeStamp = [[aProcess lastSampleTime] description];
				if(![lastTimeStamp length]) lastTimeStamp = @"0";
				if(![shortName length]) shortName = @"Untitled";
				
				NSString* s = [aProcess description];
				
				NSDictionary* processInfo = [NSDictionary dictionaryWithObjectsAndKeys:
											 [aProcess fullID],@"name",
											 shortName,@"title",
											 lastTimeStamp,@"timestamp",
											 s,@"data",
											 [NSNumber numberWithUnsignedLong:[aProcess processRunning]] ,@"state",
											 nil];
				[arrayForDoc addObject:processInfo];
			}
		}
		
		NSDictionary* processInfo  = [NSDictionary dictionaryWithObjectsAndKeys:@"processinfo",@"name",arrayForDoc,@"processlist",@"processes",@"type",nil];
		[db updateDocument:processInfo documentId:@"processinfo" tag:kDocumentUpdated];
		
		[self performSelector:@selector(updateProcesses) withObject:nil afterDelay:30];	
	}
}

- (void) updateMachineRecord
{
	if(!stealthMode){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateMachineRecord) object:nil];
		
		ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort  username:userName pwd:password database:[self machineName] delegate:self];
		
		NSString* thisHostAdress = @"";
		NSArray* names =  [[NSHost currentHost] addresses];
		NSEnumerator* e = [names objectEnumerator];
		id aName;
		while(aName = [e nextObject]){
			if([aName rangeOfString:@"::"].location == NSNotFound){
				if([aName rangeOfString:@".0.0."].location == NSNotFound){
					thisHostAdress = aName;
					break;
				}
			}
		}
		NSDictionary* machineInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 @"machineinfo",@"type",
									 [NSNumber numberWithLong:[[[NSApp delegate] memoryWatcher] accurateUptime]], @"uptime",
									  computerName(),@"name",
									  macAddress(),@"hw_address",
									  thisHostAdress,@"ip_address",
									  fullVersion(),@"version",nil];	
			
		[db updateDocument:machineInfo documentId:@"machineinfo" tag:kDocumentUpdated];
		
		[self performSelector:@selector(updateMachineRecord) withObject:nil afterDelay:5];	
	}
}

- (void) updateDatabaseStats
{
	if(!stealthMode){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateDatabaseStats) object:nil];
		
		ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort database:[self machineName] delegate:self];
		[db databaseInfo:self tag:kInfoInternalDB];
		
		[self performSelector:@selector(updateDatabaseStats) withObject:nil afterDelay:30];	
	}
}

- (void) setDBInfo:(NSDictionary*)someInfo
{
	@synchronized(self){
		[someInfo retain];
		[dBInfo release];
		dBInfo = someInfo;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORCouchDBModelDBInfoChanged object:self];
}

- (NSDictionary*) dBInfo
{
	return [[dBInfo retain] autorelease];
}

- (void) couchDBResult:(id)aResult tag:(NSString*)aTag
{
	@synchronized(self){
		if([aResult isKindOfClass:[NSDictionary class]]){
			NSString* message = [aResult objectForKey:@"Message"];
			if(message){
				[aResult prettyPrint:@"CouchDB Message:"];
			}
			else {
				if([aTag isEqualToString:kInfoDB]){
					[aResult prettyPrint:@"CouchDB Info:"];
				}
				
				else if([aTag isEqualToString:kCreateDB]){
					[self setDataBaseName:[self machineName]];
				}
				else if([aTag isEqualToString:kDeleteDB]){
					[self setDataBaseName:@"---"];
				}
				
				else if([aTag isEqualToString:kInfoInternalDB]){
					[self performSelectorOnMainThread:@selector(setDBInfo:) withObject:aResult waitUntilDone:NO];
				}
				
				else if([aTag isEqualToString:@"Message"]){
					[aResult prettyPrint:@"CouchDB Message:"];
				}
				else if([aTag isEqualToString:kCompactDB]){
					//[aResult prettyPrint:@"CouchDB Compacted:"];
				}
				else {
					[aResult prettyPrint:@"CouchDB"];
				}
			}
		}
		else if([aResult isKindOfClass:[NSArray class]]){
			if([aTag isEqualToString:kListDB]){
				[aResult prettyPrint:@"CouchDB List:"];
			}
			else [aResult prettyPrint:@"CouchDB"];
		}
		else {
			NSLog(@"%@\n",aResult);
		}
	}
}

- (void) periodicCompact
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(periodicCompact) object:nil];
	[self compactDatabase];
	[self performSelector:@selector(periodicCompact) withObject:nil afterDelay:600];
}

- (void) compactDatabase
{
	ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort   username:userName pwd:password database:[self machineName] delegate:self];
	[db compactDatabase:self tag:kCompactDB];
	[self performSelector:@selector(updateDatabaseStats) withObject:nil afterDelay:4];
}

- (void) listDatabases
{
	ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort database:[self machineName] delegate:self];
	[db listDatabases:self tag:kListDB];
}

- (void) databaseInfo:(BOOL)toStatusWindow
{
	ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort database:[self machineName] delegate:self];
	if(toStatusWindow)	[db databaseInfo:self tag:kInfoDB];
	else				[db databaseInfo:self tag:kInfoInternalDB];
}

- (void) runStatusChanged:(NSNotification*)aNote
{
	[self updateRunState:[aNote object]];
	[self updateDataSets];
}

- (void) runOptionsOrTimeChanged:(NSNotification*)aNote
{
	[self updateRunState:[aNote object]];
}

- (void) updateRunState:(ORRunModel*)rc
{
	if(!stealthMode){
		@try {
			
			id nextObject = [self nextObject];
			NSString* experimentName;
			if(!nextObject)	experimentName = @"TestStand";
			else {
				experimentName = [nextObject className];
				if([experimentName hasPrefix:@"OR"])experimentName = [experimentName substringFromIndex:2];
				if([experimentName hasSuffix:@"Model"])experimentName = [experimentName substringToIndex:[experimentName length] - 5];
			}
			
			NSMutableDictionary* runInfo = [NSMutableDictionary dictionaryWithDictionary:[rc fullRunInfo]];
			[runInfo setObject:@"runinfo" forKey:@"type"];	
			[runInfo setObject:experimentName forKey:@"experiment"];	
			
			ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort   username:userName pwd:password database:[self machineName] delegate:self];
			[db updateDocument:runInfo documentId:@"runinfo" tag:kDocumentUpdated];
			
			int runState = [[runInfo objectForKey:@"state"] intValue];
			if(runState == eRunInProgress){
				if(!dataMonitors){
					dataMonitors = [[NSMutableArray array] retain];
					NSArray* list = [[self document] collectObjectsOfClass:NSClassFromString(@"ORHistoModel")];
					for(ORDataChainObject* aDataMonitor in list){
						if([aDataMonitor involvedInCurrentRun]){
							[dataMonitors addObject:aDataMonitor];
						}
					}
				}
			}
			else {
				[dataMonitors release];
				dataMonitors = nil;
				[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateDataSets) object:nil];
			}
		}
		@catch (NSException* e) {
			//silently catch and continue
		}
	}
}

- (void) statusLogChanged:(NSNotification*)aNote
{
	if(!stealthMode){
		if(!statusUpdateScheduled){
			[self performSelector:@selector(updateStatus) withObject:nil afterDelay:10];
			statusUpdateScheduled = YES;
		}
	}
}

- (void) updateStatus
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateStatus) object:nil];
	statusUpdateScheduled = NO;
	NSString* s = [[ORStatusController sharedStatusController] contents];
	NSDictionary* dataInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  s,				@"statuslog",
							  @"StatusLog",		@"type",
							  nil];
	
	ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort   username:userName pwd:password database:[self machineName] delegate:self];
	[db updateDocument:dataInfo documentId:@"statuslog" tag:kDocumentAdded];
	
}

- (void) alarmsChanged:(NSNotification*)aNote
{
	if(!stealthMode){
		ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort   username:userName pwd:password database:[self machineName] delegate:self];
		ORAlarmCollection* alarmCollection = [ORAlarmCollection sharedAlarmCollection];
		NSArray* theAlarms = [[[alarmCollection alarms] retain] autorelease];
		NSMutableArray* arrayForDoc = [NSMutableArray array];
		if([theAlarms count]){
			for(id anAlarm in theAlarms)[arrayForDoc addObject:[anAlarm alarmInfo]];
		}
		NSDictionary* alarmInfo  = [NSDictionary dictionaryWithObjectsAndKeys:@"alarms",@"name",arrayForDoc,@"alarmlist",@"alarms",@"type",nil];
		[db updateDocument:alarmInfo documentId:@"alarms" tag:kDocumentAdded];
	}
}

- (void) updateDataSets
{
	if(!stealthMode){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateDataSets) object:nil];
		
		NSUInteger n = [ORCouchDBQueue operationCount];
		if(n<10){
				
			ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort   username:userName pwd:password database:[self machineName] delegate:self];
			for(id aMonitor in dataMonitors){
				NSArray* objs1d = [[aMonitor  collectObjectsOfClass:[OR1DHisto class]] retain];
				@try {
					for(id aDataSet in objs1d){
						unsigned long start,end;
						NSString* s = [aDataSet getnonZeroDataAsStringWithStart:&start end:&end];
						NSDictionary* dataInfo = [NSDictionary dictionaryWithObjectsAndKeys:
													[aDataSet fullName],										@"name",
													[NSNumber numberWithUnsignedLong:[aDataSet totalCounts]],	@"counts",
													[NSNumber numberWithUnsignedLong:start],					@"start",
													[NSNumber numberWithUnsignedLong:[aDataSet numberBins]],	@"length",
													s,															@"PlotData",
													@"Histogram1D",												@"type",
													 nil];
						NSString* dataName = [[[aDataSet fullName] lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""];

						[db updateDocument:dataInfo documentId:dataName tag:kDocumentAdded];
						
		 
					}
				}
				@catch(NSException* e){
				}
				@finally {
					[objs1d release];
				}
			}
		}

		[self performSelector:@selector(updateDataSets) withObject:nil afterDelay:10];
	}
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{    
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setDataBaseName:[decoder decodeObjectForKey:@"DataBaseName"]];
    [self setPassword:[decoder decodeObjectForKey:@"Password"]];
    [self setUserName:[decoder decodeObjectForKey:@"UserName"]];
    [self setHostName:[decoder decodeObjectForKey:@"HostName"]];
    [self setStealthMode:[decoder decodeBoolForKey:@"stealthMode"]];
    [[self undoManager] enableUndoRegistration];    
	[self registerNotificationObservers];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:dataBaseName forKey:@"DataBaseName"];
    [encoder encodeBool:stealthMode forKey:@"stealthMode"];
    [encoder encodeObject:password forKey:@"Password"];
    [encoder encodeObject:userName forKey:@"UserName"];
    [encoder encodeObject:hostName forKey:@"HostName"];
}
@end

