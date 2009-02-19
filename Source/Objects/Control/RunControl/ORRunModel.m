//
//  ORRunModel.m
//  Orca
//
//  Created by Mark Howe on Tue Dec 24 2002.
//  Copyright � 2002 CENPA, University of Washington. All rights reserved.
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




#pragma mark ���Imported Files
#import "ORRunModel.h"
#import "ORDataTaker.h"
#import "ORDataPacket.h"
#import "ORDataTypeAssigner.h"
#import "ORRunScriptModel.h";

#pragma mark ���Definitions

NSString* ORRunModelSequenceCommentChanged		= @"ORRunModelSequenceCommentChanged";
NSString* ORRunModelSequenceNumberChanged		= @"ORRunModelSequenceNumberChanged";
NSString* ORRunModelShutDownScriptStateChanged	= @"ORRunModelShutDownScriptStateChanged";
NSString* ORRunModelStartScriptStateChanged		= @"ORRunModelStartScriptStateChanged";
NSString* ORRunModelShutDownScriptChanged		= @"ORRunModelShutDownScriptChanged";
NSString* ORRunModelStartScriptChanged			= @"ORRunModelStartScriptChanged";
NSString* ORRunRemoteInterfaceChangedNotification = @"ORRunRemoteInterfaceChangedNotification";
NSString* ORRunTimedRunChangedNotification      = @"RunModel TimedRun? Changed";
NSString* ORRunRepeatRunChangedNotification 	= @"RunModel RepeatRun? Changed";
NSString* ORRunTimeLimitChangedNotification 	= @"RunModel Time Limit Changed";
NSString* ORRunTimeToGoChangedNotification      = @"RunModel Time To Go Changed";
NSString* ORRunElapsedTimeChangedNotification	= @"RunModel Elapsed Time Changed";
NSString* ORRunStartTimeChangedNotification     = @"RunModel Start Time Changed";
NSString* ORRunNumberChangedNotification		= @"RunModel RunNumber Changed";
NSString* ORRunNumberDirChangedNotification     = @"The RunNumber Dir Changed";
NSString* ORRunModelExceptionCountChanged       = @"ORRunModelExceptionCountChanged";
NSString* ORRunTypeChangedNotification			= @"ORRunTypeChangedNotification";
NSString* ORRunRemoteControlChangedNotification = @"ORRunRemoteControlChangedNotification";
NSString* ORRunQuickStartChangedNotification    = @"ORRunQuickStartChangedNotification";
NSString* ORRunDefinitionsFileChangedNotification    = @"ORRunDefinitionsFileChangedNotification";
NSString* ORRunNumberLock						= @"ORRunNumberLock";
NSString* ORRunTypeLock							= @"ORRunTypeLock";

static NSString *ORRunModelRunControlConnection = @"Run Control Connector";

#define kHeartBeatTime 30.0

@interface ORRunModel (private)
- (void) startRun1:(NSNumber*)doInit;
- (void) waitForRunToStop;
- (void) finishRunStop;

@end

@implementation ORRunModel

#pragma mark ���Initialization
- (id)init //designated initializer
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setTimeLimit:3600];
    [self setDirName:@"~"];
    [[self undoManager] enableUndoRegistration];
    
    _ignoreMode = YES;
    
    
    return self;
}

- (void) dealloc
{
    [sequenceComment release];
    [shutDownScriptState release];
    [startScriptState release];
    [shutDownScript release];
    [startScript release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [timer invalidate];
    [timer release];
    timer = nil;
    
    [heartBeatTimer invalidate];
    [heartBeatTimer release];
    heartBeatTimer = nil;
	
    [dataPacket release];
    [dirName release];
    [startTime release];
    [definitionsFilePath release];
    
    [runFailedAlarm clearAlarm];
    [runFailedAlarm release];
	
    [runStoppedByVetoAlarm clearAlarm];
	[runStoppedByVetoAlarm release];
	
    [super dealloc];
}


- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self x]+[self frame].size.width - kConnectorSize,[self y]) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORRunModelRunControlConnection];
    [aConnector setOffColor:[NSColor purpleColor]];
    [aConnector setConnectorType:'RUNC'];
    [aConnector release];
}

- (void) makeMainController
{
    [self linkToController:@"ORRunController"];
}

- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
    
    NSImage* aCachedImage;
	if(![[ORGlobal sharedGlobal] anyVetosInPlace]){
		aCachedImage = [NSImage imageNamed:@"RunControl"];
	}
	else {
		aCachedImage = [NSImage imageNamed:@"RunControlVetoed"];
	}
    NSSize theIconSize = [aCachedImage size];
    NSPoint theOffset = NSZeroPoint;
    NSImage* netConnectIcon = nil;
    if(remoteControl){
        netConnectIcon = [NSImage imageNamed:@"NetConnect"];
        theIconSize.width += 10;
    }
    
    NSImage* i = [[NSImage alloc] initWithSize:theIconSize];
    [i lockFocus];
    if(remoteControl){
        [netConnectIcon compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];
        theOffset.x += 10;
    }
    [aCachedImage compositeToPoint:theOffset operation:NSCompositeCopy];
    
    if([[ORGlobal sharedGlobal] runMode] == kOfflineRun && !_ignoreMode){
        NSImage* aNoticeImage = [NSImage imageNamed:@"notice"];
        [aNoticeImage compositeToPoint:NSMakePoint(theOffset.x/2.+[i size].width/2-[aNoticeImage size].width/2 ,[i size].height/2-[aNoticeImage size].height/2)operation:NSCompositeSourceOver];
    }
	
	
    [i unlockFocus];
    
    [self setImage:i];
    [i release];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORForceRedraw
	 object: self];
    
}

#pragma mark ���Accessors

- (NSString*) sequenceComment
{
	if(!sequenceComment)return @"no Comment";
    else return sequenceComment;
}

- (void) setSequenceComment:(NSString*)aSequenceComment
{
	if(!aSequenceComment)aSequenceComment = @"no Comment";
    [sequenceComment autorelease];
    sequenceComment = [aSequenceComment copy];    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunModelSequenceCommentChanged object:self];
}

- (int) sequenceNumber
{
    return sequenceNumber;
}

- (void) setSequenceNumber:(int)aSequenceNumber
{
    sequenceNumber = aSequenceNumber;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunModelSequenceNumberChanged object:self];
}

- (NSString*) shutDownScriptState
{
	if(!shutDownScriptState)return @"---";
	else  return shutDownScriptState;
}

- (void) setShutDownScriptState:(NSString*)aShutDownScriptState
{
	if(!aShutDownScriptState)aShutDownScriptState = @"---";
    [shutDownScriptState autorelease];
    shutDownScriptState = [aShutDownScriptState copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunModelShutDownScriptStateChanged object:self];
}

- (NSString*) startScriptState
{
	if(!startScriptState)return @"---";
    return startScriptState;
}

- (void) setStartScriptState:(NSString*)aStartScriptState
{
	if(!aStartScriptState)aStartScriptState = @"---";
    [startScriptState autorelease];
    startScriptState = [aStartScriptState copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunModelStartScriptStateChanged object:self];
}

- (ORRunScriptModel*) shutDownScript
{
    return shutDownScript;
}

- (void) setShutDownScript:(ORRunScriptModel*)aShutDownScript
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShutDownScript:shutDownScript];
    
    [aShutDownScript retain];
    [shutDownScript release];
    shutDownScript = aShutDownScript;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunModelShutDownScriptChanged object:self];
}

- (ORRunScriptModel*) startScript
{
    return startScript;
}

- (void) setStartScript:(ORRunScriptModel*)aStartScript
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStartScript:startScript];
    
    [aStartScript retain];
    [startScript release];
    startScript = aStartScript;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunModelStartScriptChanged object:self];
}

- (BOOL) runPaused
{
	return runPaused;
}

- (void) setRunPaused:(BOOL)aFlag
{    
	runPaused = aFlag;
    
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunStatusChangedNotification
	 object:self];	
}

- (BOOL) remoteInterface
{
	return remoteInterface;
}
- (void) setRemoteInterface:(BOOL)aRemoteInterface
{
	[[[self undoManager] prepareWithInvocationTarget:self] setRemoteInterface:remoteInterface];
    
	remoteInterface = aRemoteInterface;
    
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunRemoteInterfaceChangedNotification
	 object:self];
}

- (NSArray*) runTypeNames
{
    if(definitionsFilePath && !runTypeNames){
        [self readRunTypeNames];
    }
    return runTypeNames;
}

- (void) setRunTypeNames:(NSMutableArray*)aRunTypeNames
{
    [aRunTypeNames retain];
    [runTypeNames release];
    runTypeNames = aRunTypeNames;
}

- (unsigned long)getCurrentRunNumber
{
    if(!remoteControl || remoteInterface){
        NSString* fullFileName = [[[self dirName]stringByExpandingTildeInPath] stringByAppendingPathComponent:@"RunNumber"];
        NSString* s = [NSString stringWithContentsOfFile:fullFileName];
        runNumber = [s intValue];
    }
    
    return runNumber;
}

- (unsigned long)runNumber
{
    return runNumber;
}

- (void) setRunNumber:(unsigned long)aRunNumber
{
    runNumber = aRunNumber;
    
    if(!remoteControl || remoteInterface){
        NSString* fullFileName = [[[self dirName]stringByExpandingTildeInPath] stringByAppendingPathComponent:@"RunNumber"];
        NSFileManager* fileManager = [NSFileManager defaultManager];
        if([fileManager fileExistsAtPath:fullFileName] == NO){
            if([fileManager createFileAtPath:fullFileName contents:nil attributes:nil]){
                NSLog(@"created <%@>\n",fullFileName);
            }
            else NSLog(@"Could NOT create <%@>\n",fullFileName);
        }
        NSFileHandle* file = [NSFileHandle fileHandleForWritingAtPath:fullFileName];
        NSString* s = [NSString stringWithFormat:@"%d",runNumber];
        
        [file writeData:[NSData dataWithBytes:[s cStringUsingEncoding:NSASCIIStringEncoding] length:[s length]+1]];
        [file closeFile];
        
    }
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunNumberChangedNotification
	 object: self];
}

- (BOOL)isRunning
{
	return [self runningState] != eRunStopped;
}

- (NSString*) startTimeAsString
{
    return [startTime description];
}

- (NSCalendarDate*)startTime
{
    return startTime;
}

- (void) setStartTime:(NSCalendarDate*)aDate
{
    [aDate retain];
    [startTime release];
    startTime = aDate;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunStartTimeChangedNotification
	 object: self];
}

- (NSString*) elapsedTimeString
{
	if([self isRunning]){
		int hr = elapsedTime/3600;
		int min =(elapsedTime - hr*3600)/60;
		int sec = elapsedTime - hr*3600 - min*60;
		return [NSString stringWithFormat:@"%02d:%02d:%02d",hr,min,sec];
	}
	else return @"---";
}

- (NSTimeInterval) elapsedTime
{
    return elapsedTime;
}

- (void) setElapsedTime:(NSTimeInterval)aValue
{
    elapsedTime = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunElapsedTimeChangedNotification
	 object: self];
}

- (NSTimeInterval) timeToGo
{
    return timeToGo;
}

- (void) setTimeToGo:(NSTimeInterval)aValue
{
    timeToGo = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunTimeToGoChangedNotification
	 object: self];
}

- (BOOL)timedRun
{
    return timedRun;
}

- (void) setTimedRun:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTimedRun:[self timedRun]];
    timedRun = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunTimedRunChangedNotification
	 object: self];
}

- (BOOL)repeatRun
{
    return repeatRun;
}

- (void) setRepeatRun:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRepeatRun:[self repeatRun]];
    repeatRun = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunRepeatRunChangedNotification
	 object: self];
}

- (NSTimeInterval) timeLimit
{
    return timeLimit;
}

- (void) setTimeLimit:(NSTimeInterval)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTimeLimit:[self timeLimit]];
    timeLimit = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunTimeLimitChangedNotification
	 object: self];
}


- (ORDataPacket*)dataPacket
{
    return dataPacket;
}

- (void) setDataPacket:(ORDataPacket*)aDataPacket
{
    [aDataPacket retain];
    [dataPacket release];
    dataPacket = aDataPacket;
}


- (void) setDirName:(NSString*)aDirName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDirName:[self dirName]];
    
    [dirName autorelease];
    dirName = [aDirName copy];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunNumberDirChangedNotification
	 object: self];
    
}

- (NSString*)dirName
{
    return dirName;
}

- (unsigned long)	runType
{
    return runType;
}

- (void) setRunType:(unsigned long)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRunType:runType];
    runType = aMask;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunTypeChangedNotification
	 object: self];
    
}

- (BOOL)remoteControl
{
    return remoteControl;
}
- (void) setRemoteControl:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRemoteControl:remoteControl];
    remoteControl = aState;
    if(remoteControl)NSLog(@"Remote Run Control.\n");
    else NSLog(@"Local Run Control.\n");
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunRemoteControlChangedNotification
	 object: self];
    
    if([self isRunning] && (remoteControl == NO)){
        _ignoreRunTimeout = YES;
    }
    [self setUpImage];
}


- (BOOL) quickStart
{
    return quickStart;
}

- (void) setQuickStart:(BOOL)flag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setQuickStart:quickStart];
    quickStart = flag;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunQuickStartChangedNotification
	 object: self];
    
}


- (unsigned long)  exceptionCount
{
    return exceptionCount;
}

- (void) clearExceptionCount
{
    exceptionCount = 0;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunModelExceptionCountChanged
	 object:self];
    
}

- (void) incExceptionCount
{
    ++exceptionCount;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunModelExceptionCountChanged
	 object:self];
}


- (BOOL)nextRunWillQuickStart
{
    return _nextRunWillQuickStart;
}

- (void) setNextRunWillQuickStart:(BOOL)state
{
    _nextRunWillQuickStart = state;
}

- (int)runningState
{
    return runningState;
}

- (void) setRunningState:(int)aRunningState
{
    runningState = aRunningState;
    
    NSDictionary* userInfo = [NSDictionary
							  dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:runningState],ORRunStatusValue,
							  runState[runningState],ORRunStatusString,
							  [NSNumber numberWithLong:runType],ORRunTypeMask,nil];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunStatusChangedNotification
	 object: self
	 userInfo: userInfo];
}

- (void) setForceRestart:(BOOL)aState
{
    [self setNextRunWillQuickStart:YES];
    _forceRestart = aState;
}

- (NSString *)definitionsFilePath
{
    return definitionsFilePath;
}

- (void) setDefinitionsFilePath:(NSString *)aDefinitionsFilePath
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDefinitionsFilePath:definitionsFilePath];
    
    [definitionsFilePath autorelease];
    definitionsFilePath = [aDefinitionsFilePath copy];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunDefinitionsFileChangedNotification
	 object: self];
    
}

- (ORDataTypeAssigner *) dataTypeAssigner 
{ 
    return dataTypeAssigner; 
}

- (void) setDataTypeAssigner: (ORDataTypeAssigner *) aDataTypeAssigner
{
    [aDataTypeAssigner retain];
    [dataTypeAssigner release];
    dataTypeAssigner = aDataTypeAssigner;
}


- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherObj
{
    [self setDataId:[anotherObj dataId]];
}

- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}

#pragma mark ���Run Modifiers

- (void) startRun
{
    
    [self setNextRunWillQuickStart:quickStart];
    if([self isRunning]){
        _forceRestart = YES;
        [self stopRun];
    }
    else [self startRun:!quickStart];
}

- (void) restartRun
{
    [self setNextRunWillQuickStart:YES];
    if([self isRunning]){
        _forceRestart = YES;
        [self stopRun];
    }
    else [self startRun:NO];
}


- (void) remoteStartRun:(unsigned long)aRunNumber
{
	if([[self document] isDocumentEdited])return;
	
	[self setRemoteInterface:NO];
    [self setNextRunWillQuickStart:NO];
    if(aRunNumber==0xffffffff){
        [self setRemoteControl:NO];
        [self getCurrentRunNumber];
        [self setRunNumber:[self runNumber]+1];
        [self setRemoteControl:YES];
    }
    else {
        [self setRemoteControl:YES];
        [self setRunNumber:aRunNumber];
    }
    if([self isRunning]){
        _forceRestart = YES;
        [self stopRun];
    }
    else {
        [self startRun:YES];
    }
}

- (void) remoteRestartRun:(unsigned long)aRunNumber
{
	[self setRemoteInterface:NO];
    if(aRunNumber==0xffffffff){
        [self setRemoteControl:NO];
        [self getCurrentRunNumber];
        [self setRunNumber:[self runNumber]+1];
        [self setRemoteControl:YES];
    }
    else {
        [self setRemoteControl:YES];
        [self setRunNumber:aRunNumber];
    }
    [self setNextRunWillQuickStart:YES];
    [self setRunNumber:aRunNumber];
    if([self isRunning]){
        _forceRestart = YES;
        [self stopRun];
    }
    else {
        [self startRun:NO];
    }
    
}


- (void) startRun:(BOOL)doInit
{
    
    _forceRestart = NO;
    
    if([self isRunning]){
        NSLogColor([NSColor redColor],@"Warning...Programming error..should not be able to\n");
        NSLogColor([NSColor redColor],@"Start a run while one is already in progress.\n");
        return;
    }
	
	//movedfrom startrun1 06/29/05 MAH to test remote run stuff
	[self getCurrentRunNumber];
	
	if([[ORGlobal sharedGlobal] runMode] == kNormalRun && (!remoteControl || remoteInterface)){
		[self setRunNumber:[self runNumber]+1];
	}
	
	[self setRunningState:eRunStarting];
	//pass off to the next event cycle so the run starting state can be drawn on the screen
	if(startScript){
		[startScript setSelectorOK:@selector(startRun1:) bad:@selector(runAbortFromScript) withObject:[NSNumber numberWithBool:doInit] target:self];
		[self setStartScriptState:@"Running"];
		if(![startScript runScript]){
			[self runAbortFromScript];
		}
	}
	else [self performSelector:@selector(startRun1:) withObject:[NSNumber numberWithBool:doInit] afterDelay:0];
}

- (void) startRun1:(NSNumber*)doInitBool
{
	if(startScript){
		[self setShutDownScriptState:@"---"];
		[self setStartScriptState:@"Done"];
	}
	
	BOOL doInit = [doInitBool boolValue];
    @try {
        [runFailedAlarm clearAlarm];
        client =  [self objectConnectedTo: ORRunModelRunControlConnection];
        
		//        [self getCurrentRunNumber];
        
		//        if([[ORGlobal sharedInstance] runMode] == kNormalRun && (!remoteControl || remoteInterface)){
		//           [self setRunNumber:[self runNumber]+1];
		//       }
        
        [self runStarted:doInit];
        
        //start the thread
        if(dataTakingThreadRunning){
            NSLogColor([NSColor redColor],@"*****runthread still exists\n");
        }
		
		timeToStopTakingData = NO;
		[NSThread detachNewThreadSelector:@selector(takeData) toTarget:self withObject:nil];
		[NSThread setThreadPriority:.7];
        
        [self setStartTime:[NSCalendarDate date]];
        [self setElapsedTime:0];
        
        [timer invalidate];
        [timer release];
        timer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(incrementTime:)userInfo:nil repeats:YES] retain];
        
        
        [[self document] setStatusText:[[ORGlobal sharedGlobal] runModeString]];
        
        [[ORGlobal sharedGlobal] checkRunMode];
        
        [self setRunningState:eRunInProgress];
		
        _ignoreRunTimeout = NO;
        
	}
	@catch(NSException* localException) {
        [self stopRun];
        [self setRunningState:eRunStopped];
        
		if(!runFailedAlarm){
			runFailedAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"Run %d did NOT start",[self runNumber]] severity:kRunInhibitorAlarm];
			[runFailedAlarm setSticky:YES];
		}
		[runFailedAlarm setAcknowledged:NO];
		[runFailedAlarm postAlarm];
        
        NSLogColor([NSColor redColor],@"Run Not Started because of exception: %@\n",[localException name]);
        
    }
    
    
}

- (void) setOfflineRun:(BOOL)offline
{
	[[ORGlobal sharedGlobal] setRunMode:offline]; //0 = NormalRun, 1= offlineRun
}

- (BOOL) offlineRun
{
	return [[ORGlobal sharedGlobal] runMode];
}

- (void) remoteHaltRun
{
    if(remoteControl){
		ignoreRepeat = YES;
        [self haltRun];
    }
}

- (void) remoteStopRun:(BOOL)fullInitNextRun
{
	[self setRemoteInterface:NO];
    if(remoteControl){
		[self setNextRunWillQuickStart:fullInitNextRun];
		ignoreRepeat = YES;
        [self stopRun];
        [self setRemoteControl:NO];
    }
}

- (void) runAbortFromScript
{
	NSLogColor([NSColor redColor], @"Run startup aborted by script!\n");
	[self haltRun];
}

- (void) haltRun
{
    ignoreRepeat = YES;
    [self stopRun];
}


- (void) stopRun
{
	[self setShutDownScriptState:@"---"];
	[self setStartScriptState:@"---"];
	
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    if(!dataTakingThreadRunning && !startScript){
        NSLog(@"Stop Run message received and ignored because no run in progress.\n");
        return;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunAboutToStopNotification
                                                        object: self
                                                      userInfo: nil];
    
    [self setRunningState:eRunStopping];
    
    [timer invalidate];
    [heartBeatTimer invalidate];
    
    [timer release];
    timer = nil;
    
    [heartBeatTimer release];
    heartBeatTimer = nil;
    
	totalWaitTime = 0;
	[self waitForRunToStop];
	
}

- (void) needMoreTimeToStopRun:(NSNotification*)aNote
{
	totalWaitTime = 0;	
}

- (void) waitForRunToStop
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(waitForRunToStop) object:nil];
	
    //wait for runthread to exit
    if(dataTakingThreadRunning){
		timeToStopTakingData= YES;
		totalWaitTime += .1;
		if(totalWaitTime > 10){
			NSLogColor([NSColor redColor], @"Run Thread Failed to stop.....You should stop and restart ORCA!\n");
			[self finishRunStop];
		}
		[self performSelector:@selector(waitForRunToStop) withObject:nil afterDelay:.1];
	}
	else {
		if(shutDownScript){
			[self setShutDownScriptState:@"Running"];
			[shutDownScript setSelectorOK:@selector(finishRunStop) bad:nil withObject:nil target:self];
			[shutDownScript runScript];
		}
		else [self finishRunStop];
	}
}

- (void) finishRunStop
{
	[self setStartScriptState:@"---"];
	[self setShutDownScriptState:@"---"];
	[dataTypeAssigner release];
	dataTypeAssigner = nil;
    
    
    id nextObject = [self objectConnectedTo:ORRunModelRunControlConnection];
    
    @try {
        
        [nextObject runTaskStopped:dataPacket userInfo:nil];
		[NSThread setThreadPriority:1];
		
        NSDictionary* statusInfo = [NSDictionary
									dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:eRunStopped],ORRunStatusValue,
									@"Not Running",ORRunStatusString,
									dataPacket,@"DataPacket",nil];
        
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ORRunStoppedNotification
                                                            object: self
                                                          userInfo: statusInfo];
        
	}
	@catch(NSException* localException) {
	}
	
	
	
	//get the time(UT!)
	time_t	theTime;
	time(&theTime);
	struct tm* theTimeGMTAsStruct = gmtime(&theTime);
	time_t ut_time = mktime(theTimeGMTAsStruct);
	
	unsigned long data[4];
	data[0] = dataId | 4;
	data[1] =  0;
	if(_nextRunWillQuickStart){
		data[1] |= 0x2;			//set the reset bit
		_nextRunWillQuickStart = NO;
	}
	
	if(remoteControl){
		data[1] |= 0x4;			//set the remotebit
	}
	
	data[2] = lastRunNumberShipped;
	data[3] = ut_time;
	
	[dataPacket addLongsToFrameBuffer:data length:4];
	
	//closeout run will wait until the processing thread is done.
	[nextObject closeOutRun:dataPacket userInfo:nil];
	
	if([[ORGlobal sharedGlobal] runMode] == kNormalRun){
		NSLog(@"Run %d stopped.\n",_currentRun);
	}
	else {
		NSLog(@"Offline Run stopped.\n");
	}
	NSLog(@"---------------------------------------\n");
	
	[[self document] setStatusText:@"Not Running"];
	
	NSDictionary* statusInfo = [NSDictionary
								dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:eRunStopped],ORRunStatusValue,
								@"Not Running",ORRunStatusString,nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRunStatusChangedNotification
														object: self
													  userInfo: statusInfo];
	
	
	[self setRunningState:eRunStopped];
	
	[dataTypeAssigner release];
	dataTypeAssigner = nil;
	
	if(_forceRestart ||([self timedRun] && [self repeatRun] && !ignoreRepeat && (!remoteControl || remoteInterface))){
		ignoreRepeat  = NO;
		_forceRestart = NO;
		[self restartRun];
	}
 	[NSThread setThreadPriority:.9];
	
}

- (void) sendHeartBeat:(NSTimer*)aTimer
{
    unsigned long dataHeartBeat[4];
    
    dataHeartBeat[0] = dataId | 4; 
    dataHeartBeat[1] =         0x8; //fourth bit is the heart beat bit
    dataHeartBeat[2] = kHeartBeatTime;
    
    //get the time(UT!)
    time_t	theTime;
    time(&theTime);
    struct tm* theTimeGMTAsStruct = gmtime(&theTime);
    time_t ut_time = mktime(theTimeGMTAsStruct);
    
    dataHeartBeat[3] = ut_time;
    
	[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
														object:[NSData dataWithBytes:dataHeartBeat length:4*sizeof(long)]];
	
}

- (void) incrementTime:(NSTimer*)aTimer
{
    if([self isRunning]){
        NSTimeInterval deltaTime = -[startTime timeIntervalSinceNow];
        [self setElapsedTime:deltaTime];
        if(!remoteControl || remoteInterface){
            [self setTimeToGo:(timeLimit - deltaTime)+1];
            if(!_ignoreRunTimeout && timedRun &&(deltaTime >= timeLimit)){
                if(repeatRun){
                    [self setNextRunWillQuickStart:YES];
                }
                [self stopRun];
            }
        }
    }
}


- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    //get the time(UT!)
    time_t	theTime;
    time(&theTime);
    struct tm* theTimeGMTAsStruct = gmtime(&theTime);
    time_t ut_time = mktime(theTimeGMTAsStruct);
    NSTimeInterval refTime = [NSDate timeIntervalSinceReferenceDate];
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
    [objDictionary setObject:NSStringFromClass([self class])            forKey:@"Class Name"];
    [objDictionary setObject:[NSNumber numberWithLong:ut_time]          forKey:@"startTime"];
    [objDictionary setObject:[NSNumber numberWithFloat:refTime]         forKey:@"refTime"];
    [objDictionary setObject:[NSNumber numberWithBool:remoteControl]    forKey:@"remoteControl"];
    [objDictionary setObject:[NSNumber numberWithLong:runType]          forKey:@"runType"];
    [objDictionary setObject:[NSNumber numberWithBool:quickStart]       forKey:@"quickStart"];
    [objDictionary setObject:[NSNumber numberWithLong:[self runNumber]] forKey:@"RunNumber"];
    [objDictionary setObject:[NSNumber numberWithInt:[self sequenceNumber]] forKey:@"sequenceNumber"];
    [objDictionary setObject:[self sequenceComment]						forKey:@"sequenceComment"];
    
    [dictionary setObject:objDictionary forKey:@"Run Control"];
    
    
    return objDictionary;
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORRunDecoderForRun",              @"decoder",
								 [NSNumber numberWithLong:dataId],   @"dataId",
								 [NSNumber numberWithBool:NO],       @"variable",
								 [NSNumber numberWithLong:4],        @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Run"];
    return dataDictionary;
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORRunModel"];
}

- (void) runStarted:(BOOL)doInit
{
	
    [heartBeatTimer invalidate];
    [heartBeatTimer release];
    heartBeatTimer = nil;
    
    ignoreRepeat = NO;
    id nextObject = [self objectConnectedTo:ORRunModelRunControlConnection];
    
    [self setDataPacket:[[[ORDataPacket alloc] init]autorelease]];
    [[self dataPacket] setRunNumber:[self runNumber]];
    
    [[self dataPacket] makeFileHeader];
    
    if([self remoteControl]){
        [[self dataPacket] setFilePrefix:@"R_Run"];
    }
    else {
        [[self dataPacket] setFilePrefix:@"Run"];
    }
    
    _currentRun = [self runNumber];
    
    NSArray* objs = [[self document]  collectObjectsRespondingTo:@selector(preRunChecks)];
    [objs makeObjectsPerformSelector:@selector(preRunChecks) withObject:nil];
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [self setDataTypeAssigner:[[[ORDataTypeAssigner alloc] init]autorelease]];
    
    [dataTypeAssigner assignDataIds];
    
    
    
    //get the time(UT!)
    time_t	theTime;
    time(&theTime);
    struct tm* theTimeGMTAsStruct = gmtime(&theTime);
    time_t ut_time = mktime(theTimeGMTAsStruct);
    
    unsigned long data[4];
    
    data[0] = dataId | 4;
    data[1] =  1;
    _wasQuickStart = !doInit;
    
    if(_wasQuickStart){
        data[1] |= 0x2;			//set the reset bit
        _nextRunWillQuickStart = NO;
    }
    if(remoteControl){
        data[1] |= 0x4;			//set the remotebit
    }
    
    data[2] = [self runNumber];
    data[3] = ut_time;
    
    //and into the data stream.
    //don't put into the framebuffer because we want this record to go out first.
    [dataPacket addData:[NSData dataWithBytes:data length:4*sizeof(long)]];
    
    lastRunNumberShipped = data[2];
	
    //pack up some info about the run.
    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  [NSNumber numberWithLong:runNumber],@"RunNumber",
							  [NSNumber numberWithLong:runType],  @"RunType",
							  [NSNumber numberWithInt:doInit||forceFullInit], @"doinit",
							  nil];
    
    //let others know the run is about to start
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunAboutToStartNotification
                                                        object: self
                                                      userInfo: userInfo];
    
    //tell them to start up
    [nextObject runTaskStarted:dataPacket userInfo:userInfo];
    
    //tell them it has been started.
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunStartedNotification
                                                        object: self
                                                      userInfo: userInfo];
    
	NSLog(@"---------------------------------------\n");
    
    if([[ORGlobal sharedGlobal] runMode] == kNormalRun){
        if(!forceFullInit)NSLog(@"Run %d started(%@).\n",[self runNumber],doInit?@"cold start":@"quick start");
		else NSLog(@"Run %d started(%@).\n",[self runNumber],@"Full Init because of Pwr Failure");
    }
    else {
        NSLog(@"Offline Run started(%@).\n",doInit?@"cold start":@"quick start");
    }
    
    forceFullInit = NO;
    
    heartBeatTimer = [[NSTimer scheduledTimerWithTimeInterval:kHeartBeatTime target:self selector:@selector(sendHeartBeat:)userInfo:nil repeats:YES] retain];
    
    [self sendHeartBeat:nil];
	[NSThread setThreadPriority:.7];
	
	[self setRunPaused:NO];
	
}


//takeData runs in the data Taking thread. It should not be called from anywhere else.
//and it should not call anything that is not thread safe.
- (void) takeData
{
	NSAutoreleasePool *outerpool = [[NSAutoreleasePool allocWithZone:nil] init];
	NSLog(@"DataTaking Thread Started\n");
	[NSThread setThreadPriority:.9];
	
	//alloc a large block to force the memory system to clean house
	char* p = malloc(1024*1024*50);
	if(p)*p=1;
	free(p);
	
	dataTakingThreadRunning = YES;
    [self clearExceptionCount];
    while(!timeToStopTakingData) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool allocWithZone:nil] init];
        @try {
            if(!runPaused){
				[client takeData:dataPacket userInfo:nil];
			}
			else {
				[NSThread sleepUntilDate:[[NSDate date] addTimeInterval:.05]];
			}
		}
		@catch(NSException* localException) {
            [self incExceptionCount];
            NSLogError(@"Uncaught exception",@"Main Run Loop",nil);
        }
        [pool release];
    }
    
	[client runIsStopping:dataPacket userInfo:nil];
	
	BOOL allDone = NO;
	if(client) do {
        NSAutoreleasePool *pool = [[NSAutoreleasePool allocWithZone:nil] init];
		[client takeData:dataPacket userInfo:nil];
		allDone = [client doneTakingData];
		[pool release];
	}while(!allDone);
	
	NSLog(@"DataTaking Thread Exited\n");
	dataTakingThreadRunning = NO;
	[outerpool release];
}

#pragma mark ���Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver: self
                     selector: @selector(runModeChanged:)
                         name: ORRunModeChangedNotification
                       object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(vmePowerFailed:)
                         name: @"VmePowerFailedNotification"
                       object: nil];
    
    
    [notifyCenter addObserver: self
                     selector: @selector(gotForceRunStopNotification:)
                         name: @"forceRunStopNotification"
                       object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(gotRequestedRunHaltNotification:)
                         name: ORRequestRunHalt
                       object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(gotRequestedRunStopNotification:)
                         name: ORRequestRunStop
                       object: nil];
	
    [notifyCenter addObserver: self
                     selector: @selector(vetosChanged:)
                         name: ORRunVetosChanged
                       object: nil];    
	
	[notifyCenter addObserver:self 
					 selector:@selector(needMoreTimeToStopRun:) 
						 name:ORNeedMoreTimeToStopRun 
					   object:nil];
	
}

- (void) vetosChanged:(NSNotification*)aNotification
{
	[self setUpImage];
	if([[ORGlobal sharedGlobal] anyVetosInPlace] && [self isRunning]){
		NSLogColor([NSColor redColor],@"====================================\n");
		NSLogColor([NSColor redColor],@"Run is being stopped by veto system.\n");
		[[ORGlobal sharedGlobal] listVetoReasons];
		NSLogColor([NSColor redColor],@"====================================\n");
		[self haltRun];
		if(!runStoppedByVetoAlarm){
			runStoppedByVetoAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"Run %d Halted by Veto",[self runNumber]] severity:kRunInhibitorAlarm];
			[runStoppedByVetoAlarm setSticky:NO];
			[runStoppedByVetoAlarm setHelpString:@"Run stopped by Veto system. See status log for details."];
		}
		[runStoppedByVetoAlarm setAcknowledged:NO];
		[runStoppedByVetoAlarm postAlarm];
	}
}


- (void) vmePowerFailed:(NSNotification*)aNotification
{
	if(!forceFullInit){
		NSLog(@"Run Control: Full init will be forced on next run because of Vme power failure.\n");
		if([self isRunning])[self performSelectorOnMainThread:@selector(haltRun) withObject:nil waitUntilDone:NO];
        
	}
	forceFullInit = YES;
}
- (void) gotRequestedRunHaltNotification:(NSNotification*)aNotification
{
	[self performSelectorOnMainThread:@selector(requestedRunHalt:) withObject:[aNotification userInfo] waitUntilDone:NO];
}

- (void) gotForceRunStopNotification:(NSNotification*)aNotification
{
	[self performSelectorOnMainThread:@selector(forceHalt) withObject:nil waitUntilDone:NO];
}

- (void) gotRequestedRunStopNotification:(NSNotification*)aNotification
{
	[self performSelectorOnMainThread:@selector(requestedRunStop:) withObject:[aNotification userInfo] waitUntilDone:NO];
}

- (void) requestedRunHalt:(id)userInfo
{
	if(userInfo)NSLog(@"Got halt run request:     %@\n",userInfo);
	else NSLog(@"Got halt run request (No reason given)\n");
	[self haltRun];
}
- (void) requestedRunStop:(id)userInfo
{
	if(userInfo)NSLog(@"Got stop run request:     %@\n",userInfo);
	else NSLog(@"Got stop run request (No reason given)\n");
	[self stopRun];
}

- (void) forceHalt
{
	if([self isRunning]){
		[self haltRun];
		if(!runFailedAlarm){
			runFailedAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"Run %d did NOT start",[self runNumber]] severity:kRunInhibitorAlarm];
			[runFailedAlarm setSticky:YES];
            [runFailedAlarm setHelpStringFromFile:@"RunFailedHelp"];
            
		}
		if(![runFailedAlarm isPosted]){
			[runFailedAlarm setAcknowledged:NO];
			[runFailedAlarm postAlarm];
		}
	}
}

- (void) runModeChanged:(NSNotification*)aNotification
{
    [self setUpImage];
}


#pragma mark ���Archival
static NSString *ORRunTimeLimit		= @"Run Time Limit";
static NSString *ORRunTimedRun		= @"Run Is Timed";
static NSString *ORRunRepeatRun		= @"Run Will Repeat";
static NSString *ORRunNumberDir		= @"Run Number Dir";
static NSString *ORRunType_Mask		= @"ORRunTypeMask";
static NSString *ORRunRemoteControl = @"ORRunRemoteControl";
static NSString *ORRunQuickStart 	= @"ORRunQuickStart";
static NSString *ORRunDefinitions 	= @"ORRunDefinitions";
static NSString *ORRunTypeNames 	= @"ORRunTypeNames";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setShutDownScript:[decoder decodeObjectForKey:@"shutDownScript"]];
    [self setStartScript:[decoder decodeObjectForKey:@"startScript"]];
    [self setTimeLimit:[decoder decodeInt32ForKey:ORRunTimeLimit]];
    [self setRunType:[decoder decodeInt32ForKey:ORRunType_Mask]];
    [self setTimedRun:[decoder decodeBoolForKey:ORRunTimedRun]];
    [self setRepeatRun:[decoder decodeBoolForKey:ORRunRepeatRun]];
    [self setQuickStart:[decoder decodeBoolForKey:ORRunQuickStart]];
    [self setDirName:[decoder decodeObjectForKey:ORRunNumberDir]];
    [self setRemoteControl:[decoder decodeBoolForKey:ORRunRemoteControl]];
    [self setRunTypeNames:[decoder decodeObjectForKey:ORRunTypeNames]];
    [self setDefinitionsFilePath:[decoder decodeObjectForKey:ORRunDefinitions]];
    [self setRemoteInterface:[decoder decodeBoolForKey:@"RemoteInterface"]];
    
    [[self undoManager] enableUndoRegistration];
    
    _ignoreMode = NO;
    [self registerNotificationObservers];
    
    
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:shutDownScript forKey:@"shutDownScript"];
    [encoder encodeObject:startScript forKey:@"startScript"];
    [encoder encodeInt32:[self timeLimit] forKey:ORRunTimeLimit];
    [encoder encodeInt32:[self runType] forKey:ORRunType_Mask];
    [encoder encodeBool:[self timedRun] forKey:ORRunTimedRun];
    [encoder encodeBool:[self repeatRun] forKey:ORRunRepeatRun];
    [encoder encodeBool:[self quickStart] forKey:ORRunQuickStart];
    [encoder encodeObject:[self dirName] forKey:ORRunNumberDir];
    [encoder encodeBool:[self remoteControl] forKey:ORRunRemoteControl];
    [encoder encodeObject:[self runTypeNames] forKey:ORRunTypeNames];
    [encoder encodeObject:[self definitionsFilePath] forKey:ORRunDefinitions];
    [encoder encodeBool:remoteInterface forKey:@"RemoteInterface"];
}

- (NSString*)commandID
{
    return @"RunControl";
}

- (BOOL) solitaryObject
{
    return YES;
}

- (BOOL) readRunTypeNames
{
    if(definitionsFilePath){
        NSMutableArray* names = [NSMutableArray array];
        int i;
        [names addObject:[NSString stringWithFormat:@"Maintenance"]];
        for(i=1;i<32;i++){
            [names addObject:[NSString stringWithFormat:@"Bit %d",i]];
        }
        
        NSString* contents = [NSString stringWithContentsOfFile:definitionsFilePath];
        NSArray* items;
		contents = [[contents componentsSeparatedByString:@"\r"] componentsJoinedByString:@"\n"];
		contents = [[contents componentsSeparatedByString:@"\n\n"] componentsJoinedByString:@"\n"];
        items = [contents componentsSeparatedByString:@"\n"];
		
        NSEnumerator* e = [items objectEnumerator];
        NSString* aLine;
        while(aLine = [e nextObject]){
			aLine = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
			aLine = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if([aLine length] == 0)continue;
            NSArray* parts = [aLine componentsSeparatedByString:@","];
            if([parts count] == 2){
                int index = [[parts objectAtIndex:0] intValue];
                if(index>0 && index<32){
                    //note that bit 0 is predefined and is ignored if defined in the file.
                    [names replaceObjectAtIndex:index withObject:[parts objectAtIndex:1]];
                }
            }
            else {
                return NO;
            }
        }
        [self setRunTypeNames:names];
        return YES;
    }
    return YES;
}

- (NSString*) shortStatus
{
	if(runningState == eRunInProgress){
		if(!runPaused)return @"Running";
		else return @"Paused";
	}
	else if(runningState == eRunStopped){
		return @"Stopped";
	}
	else if(runningState == eRunStarting || runningState == eRunStopping){
		if(runningState == eRunStarting)return @"Starting..";
		else return @"Stopping..";
	}
	else return @"?";
}

#pragma mark ���Remote Run Control Helpers
- (NSArray*) runScriptList
{
	NSArray* theScripts = [[self document] collectObjectsOfClass:[ORRunScriptModel class]];
	ORRunScriptModel* aScript;
	NSMutableArray* theNameList = [NSMutableArray array];
	NSEnumerator* e = [theScripts objectEnumerator];
	while(aScript = [e nextObject]){
		[theNameList addObject: [aScript identifier]];
	}
	return theNameList;
}

- (NSString*) selectedStartScriptName
{
	if(!startScript) return @"---";
	else return [startScript identifier];
}

- (NSString*) selectedShutDownScriptName
{
	if(!shutDownScript) return @"---";
	else return [shutDownScript identifier];
}

- (void) setStartScriptName:(NSString*)aName
{
	[[self undoManager] disableUndoRegistration];
	
	if([aName isEqualToString:@"---"])[self setStartScript:nil];
	else {
		NSArray* theScripts = [[self document] collectObjectsOfClass:[ORRunScriptModel class]];
		ORRunScriptModel* aScript;
		NSEnumerator* e = [theScripts objectEnumerator];
		BOOL foundIt = NO;
		while(aScript = [e nextObject]){
			if([aName isEqualToString:[aScript identifier]]){
				[self setStartScript:aScript];
				NSLog(@"startup: %@\n",[aScript identifier]);
				foundIt	 = YES;
				break;
			}
		}
		if(!foundIt)[self setStartScript:nil];
	}
	[[self undoManager] enableUndoRegistration];
	
}

- (void) setShutDownScriptName:(NSString*)aName
{
	[[self undoManager] disableUndoRegistration];
	if([aName isEqualToString:@"---"])[self setShutDownScript:nil];
	else {
		NSArray* theScripts = [[self document] collectObjectsOfClass:[ORRunScriptModel class]];
		ORRunScriptModel* aScript;
		NSEnumerator* e = [theScripts objectEnumerator];
		BOOL foundIt = NO;
		while(aScript = [e nextObject]){
			if([aName isEqualToString:[aScript identifier]]){
				[self setShutDownScript:aScript];
				NSLog(@"shutDown: %@\n",[aScript identifier]);
				foundIt	 = YES;
				break;
			}
		}
		if(!foundIt)[self setShutDownScript:nil];
	}
	[[self undoManager] enableUndoRegistration];
}


@end


@implementation ORRunDecoderForRun
- (unsigned long)decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet
{
	return 4; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)dataPtr
{
    NSString* runState;
    NSString* thirdWordKey;
    NSString* init = @"";
    NSString* title= @"Run Control Record\n\n";
    if(dataPtr[1] & 0x8){
        runState     = @"Type       = HeartBeat\n";
        thirdWordKey = @"Next Beat  = ";
    }
    else {
        thirdWordKey = @"Run Number = ";
        
        if(dataPtr[1] & 0x1){
            runState = @"Type       = Start Run\n";
            init = [NSString stringWithFormat:@"Full Init  = %@\n",(dataPtr[1]&0x2)?@"YES":@"NO"];
        }
        else runState = @"Type       = End Run\n";
    }
    NSString* remote    = [NSString stringWithFormat:@"Remote     = %@\n",(dataPtr[1] & 0x4)?@"YES":@"NO"];
    NSString* thirdWord = [NSString stringWithFormat:@"%@%d\n",thirdWordKey,dataPtr[2]];
    
    if(dataPtr[1] & 0x1) return [NSString stringWithFormat:@"%@%s%@%@%@%@",title,ctime((const time_t *)(&dataPtr[3])),runState,init,remote,thirdWord]; 
    else                 return [NSString stringWithFormat:@"%@%s%@%@%@",title,ctime((const time_t *)(&dataPtr[3])),runState,remote,thirdWord];               
}

@end

@implementation NSObject (SpecialDataTakingFinishUp)
- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	//classes can override as needed
}

- (BOOL) doneTakingData
{
	//classes can override as needed. Most classes don't need to override -- the special cases
	//would be, for example, those taking data from a circular buffer and need to empty it 
	//before declaring that they 
	return YES;
}


@end
