//
//  ORIpeV4SLTModel.m
//  Orca
//
//  Created by Mark Howe on Wed Aug 24 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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

#import "ORIpeDefs.h"
#import "ORCrate.h"
#import "ORIpeV4SLTModel.h"
#import "ORIpeFLTModel.h"
#import "ORIpeCrateModel.h"
#import "ORIpeV4SLTDefs.h"
#import "ORReadOutList.h"
#import "unistd.h"
#import "TimedWorker.h"
#import "ORDataTypeAssigner.h"
#import "PCM_Link.h"
#import "SLTv4_HW_Definitions.h"

//IPE V4 register definitions
enum IpeV4Enum {
	kSltV4ControlReg,
	kSltV4StatusReg,
	kSltV4CommandReg,
	kSltV4InterruptReguestReg,
	kSltV4InterruptMaskReg,
	kSltV4RequestSemaphoreReg,
	kSltV4HWRevisionReg,
	kSltV4PixelBusErrorReg,
	kSltV4PixelBusEnableReg,
	kSltV4PixelBusTestReg,
	kSltV4AuxBusTestReg,
	kSltV4DebugStatusReg,
	kSltV4DeadTimeCounterLoReg,
	kSltV4DeadTimeCounterHiReg,
	kSltV4VetoCounterLoReg,
	kSltV4VetoCounterHiReg,
	kSltV4RunCounterLoReg,
	kSltV4RunCounterHiReg,
	kSltV4SecondSetReg,
	kSltV4SecondCounterReg,
	kSltV4SubSecondCounterReg,
	kSltV4PageManagerReg,
	kSltV4TriggerTimingReg,
	kSltV4PageSelectReg,
	kSltV4NumberPagesReg,
	kSltV4PageNumbersReg,
	kSltV4EventStatusReg,
	kSltV4ReadoutCSRReg,
	kSltV4BufferSelectReg,
	kSltV4ReadoutDefinitionReg,
	kSltV4TPTimingReg,
	kSltV4TPShapeReg,
	kSltV4i2cCommandReg,
	kSltV4epcsCommandReg,
	kSltV4BoardIDLoReg,
	kSltV4BoardIDHiReg,
	kSltV4PROMsControlReg,
	kSltV4PROHiufferReg,
	kSltV4TriggerDataReg,
	kSltV4ADCDataReg,
	kSltV4NumRegs //must be last
};

static IpeRegisterNamesStruct regV4[kSltV4NumRegs] = {
{@"Control",			0xa80000,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"Status",				0xa80004,		1,			kIpeRegReadable },
{@"Command",			0xa80008,		1,			kIpeRegWriteable },
{@"Interrupt Reguest",	0xA8000C,		1,			kIpeRegReadable },
{@"Interrupt Mask",		0xA80010,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"Request Semaphore",	0xA80014,		3,			kIpeRegReadable },
{@"HWRevision",			0xa80020,		1,			kIpeRegReadable },
{@"Pixel Bus Error",	0xA80024,		1,			kIpeRegReadable },			
{@"Pixel Bus Enable",	0xA80028,		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"Pixel Bus Test",		0xA8002C, 		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"Aux Bus Test",		0xA80030, 		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"Debug Status",		0xA80034,  		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"Dead Counter (LSB)",	0xA80080, 		1,			kIpeRegReadable },	
{@"Dead Counter (MSB)",	0xA80084,		1,			kIpeRegReadable },	
{@"Veto Counter (LSB)",	0xA80088, 		1,			kIpeRegReadable },	
{@"Veto Counter (MSB)",	0xA8008C, 		1,			kIpeRegReadable },	
{@"Run Counter  (LSB)",	0xA80090,		1,			kIpeRegReadable },	
{@"Run Counter  (MSB)",	0xA80094, 		1,			kIpeRegReadable },	
{@"Second Set",			0xB00000,  		1, 			kIpeRegReadable | kIpeRegWriteable }, 
{@"Second Counter",		0xB00004, 		1,			kIpeRegReadable },
{@"Sub-second Counter",	0xB00008, 		1,			kIpeRegReadable }, 
{@"Page Manager",		0xB80000,  		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"Trigger Timing",		0xB80004,  		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"Page Select",		0xB80008, 		1,			kIpeRegReadable },
{@"Number of Pages",	0xB8000C, 		1,			kIpeRegReadable },
{@"Page Numbers",		0xB81000,		64, 		kIpeRegReadable | kIpeRegWriteable },
{@"Event Status",		0xB82000,		64,			kIpeRegReadable },
{@"Readout CSR",		0xC00000,		1,			kIpeRegWriteable },
{@"Buffer Select",		0xC00004,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"Readout Definition",	0xC10000,	  2048,			kIpeRegReadable | kIpeRegWriteable },			
{@"TP Timing",			0xC80000,	   128,			kIpeRegReadable | kIpeRegWriteable },	
{@"TP Shape",			0xC81000,	   512,			kIpeRegReadable | kIpeRegWriteable },	
{@"I2C Command",		0xD00000,		1,			kIpeRegReadable },
{@"EPC Command",		0xD00004,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"Board ID (LSB)",		0xD00008,		1,			kIpeRegReadable },
{@"Board ID (MSB)",		0xD0000C,		1,			kIpeRegReadable },
{@"PROMs Control",		0xD00010,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"PROMs Buffer",		0xD00100,		256,		kIpeRegReadable | kIpeRegWriteable },
{@"Trigger Data",		0xD80000,	  14000,		kIpeRegReadable | kIpeRegWriteable },
{@"ADC Data",			0xE00000,	 0x8000,		kIpeRegReadable | kIpeRegWriteable },
//{@"Data Block RW",		0xF00000 Data Block RW
//{@"Data Block Length",	0xF00004 Data Block Length 
//{@"Data Block Address",	0xF00008 Data Block Address
};


#pragma mark ***External Strings

NSString* ORIpeV4SLTModelPageManagerRegChanged  = @"ORIpeV4SLTModelPageManagerRegChanged";
NSString* ORIpeV4SLTModelSecondsSetChanged		= @"ORIpeV4SLTModelSecondsSetChanged";
NSString* ORIpeV4SLTModelStatusRegChanged		= @"ORIpeV4SLTModelStatusRegChanged";
NSString* ORIpeV4SLTModelControlRegChanged		= @"ORIpeV4SLTModelControlRegChanged";
NSString* ORIpeV4SLTModelFanErrorChanged		= @"ORIpeV4SLTModelFanErrorChanged";
NSString* ORIpeV4SLTModelVttErrorChanged		= @"ORIpeV4SLTModelVttErrorChanged";
NSString* ORIpeV4SLTModelGpsErrorChanged		= @"ORIpeV4SLTModelGpsErrorChanged";
NSString* ORIpeV4SLTModelClockErrorChanged		= @"ORIpeV4SLTModelClockErrorChanged";
NSString* ORIpeV4SLTModelPpsErrorChanged		= @"ORIpeV4SLTModelPpsErrorChanged";
NSString* ORIpeV4SLTModelPixelBusErrorChanged	= @"ORIpeV4SLTModelPixelBusErrorChanged";
NSString* ORIpeV4SLTModelHwVersionChanged		= @"ORIpeV4SLTModelHwVersionChanged";

NSString* ORIpeV4SLTModelPatternFilePathChanged		= @"ORIpeV4SLTModelPatternFilePathChanged";
NSString* ORIpeV4SLTModelInterruptMaskChanged		= @"ORIpeV4SLTModelInterruptMaskChanged";
NSString* ORIpeV4SLTPulserDelayChanged				= @"ORIpeV4SLTPulserDelayChanged";
NSString* ORIpeV4SLTPulserAmpChanged				= @"ORIpeV4SLTPulserAmpChanged";
NSString* ORIpeV4SLTSettingsLock					= @"ORIpeV4SLTSettingsLock";
NSString* ORIpeV4SLTStatusRegChanged				= @"ORIpeV4SLTStatusRegChanged";
NSString* ORIpeV4SLTControlRegChanged				= @"ORIpeV4SLTControlRegChanged";
NSString* ORIpeV4SLTSelectedRegIndexChanged			= @"ORIpeV4SLTSelectedRegIndexChanged";
NSString* ORIpeV4SLTWriteValueChanged				= @"ORIpeV4SLTWriteValueChanged";
NSString* ORIpeV4SLTModelNextPageDelayChanged		= @"ORIpeV4SLTModelNextPageDelayChanged";
NSString* ORIpeV4SLTModelPollRateChanged			= @"ORIpeV4SLTModelPollRateChanged";

NSString* ORIpeV4SLTModelPageSizeChanged			= @"ORIpeV4SLTModelPageSizeChanged";
NSString* ORIpeV4SLTModelDisplayTriggerChanged		= @"ORIpeV4SLTModelDisplayTrigerChanged";
NSString* ORIpeV4SLTModelDisplayEventLoopChanged	= @"ORIpeV4SLTModelDisplayEventLoopChanged";
NSString* ORSLTV4cpuLock							= @"ORSLTV4cpuLock";

@interface ORIpeV4SLTModel (private)
- (unsigned long) read:(unsigned long) address;
- (void) write:(unsigned long) address value:(unsigned long) aValue;
@end

@implementation ORIpeV4SLTModel

- (id) init
{
    self = [super init];
	ORReadOutList* readList = [[ORReadOutList alloc] initWithIdentifier:@"ReadOut List"];	
	[self setReadOutGroup:readList];
    [self makePoller:0];
	[readList release];
	pcmLink = [[PCM_Link alloc] initWithDelegate:self];
    return self;
}

-(void) dealloc
{
    [patternFilePath release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[readOutGroup release];
    [poller stop];
    [poller release];
    [super dealloc];
}

- (void) wakeUp
{
    if([self aWake])return;
	[pcmLink wakeUp];
    [super wakeUp];
    if(![gOrcaGlobals runInProgress]){
        [poller runWithTarget:self selector:@selector(readAllStatus)];
    }
}

- (void) sleep
{
    [super sleep];
	[pcmLink sleep];
    [poller stop];
}

- (void) awakeAfterDocumentLoaded
{
	@try {
		if(!pcmLink){
			pcmLink = [[PCM_Link alloc] initWithDelegate:self];
		}
		[pcmLink connect];
	}
	@catch(NSException* localException) {
	}
}

- (void) setUpImage			{ [self setImage:[NSImage imageNamed:@"IpeV4SLTCard"]]; }
- (void) makeMainController	{ [self linkToController:@"ORIpeV4SLTController"];		}
- (Class) guardianClass		{ return NSClassFromString(@"ORIpeV4CrateModel");		}

- (void) setGuardian:(id)aGuardian //-tb-
{
	if(aGuardian){
		if([aGuardian adapter] == nil){
			[aGuardian setAdapter:self];			
		}
	}
	else {
		[[self guardian] setAdapter:nil];
	}
	[super setGuardian:aGuardian];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [notifyCenter addObserver : self
                     selector : @selector(runIsAboutToStart:)
                         name : ORRunAboutToStartNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(runIsStopped:)
                         name : ORRunStoppedNotification
                       object : nil];
}

#pragma mark •••Accessors
- (unsigned long) pageManagerReg
{
    return pageManagerReg;
}

- (void) setPageManagerReg:(unsigned long)aPageManagerReg
{
    pageManagerReg = aPageManagerReg;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelPageManagerRegChanged object:self];
}

- (unsigned long) secondsSet
{
    return secondsSet;
}

- (void) setSecondsSet:(unsigned long)aSecondsSet
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSecondsSet:secondsSet];
    secondsSet = aSecondsSet;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelSecondsSetChanged object:self];
}

- (unsigned long) statusReg
{
    return statusReg;
}

- (void) setStatusReg:(unsigned long)aStatusReg
{
    statusReg = aStatusReg;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelStatusRegChanged object:self];
}

- (unsigned long) controlReg
{
    return controlReg;
}

- (void) setControlReg:(unsigned long)aControlReg
{
    [[[self undoManager] prepareWithInvocationTarget:self] setControlReg:controlReg];
    controlReg = aControlReg;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelControlRegChanged object:self];
}

- (unsigned long) projectVersion  { return (hwVersion & kRevisionProject)>>28;}
- (unsigned long) documentVersion { return (hwVersion & kDocRevision)>>16;}
- (unsigned long) implementation  { return hwVersion & kImplemention;}

- (void) setHwVersion:(unsigned long) aVersion
{
	hwVersion = aVersion;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelHwVersionChanged object:self];	
}

- (void) writeSetInhibit		{ [self writeReg:kSltV4CommandReg value:kCmdSetInh]; }
- (void) writeClrInhibit	{ [self writeReg:kSltV4CommandReg value:kCmdClrInh]; }
- (void) writeSwTrigger			{ [self writeReg:kSltV4CommandReg value:kCmdSwTr];   }
- (void) writeTpStart			{ [self writeReg:kSltV4CommandReg value:kCmdTpStart];   }
- (void) writeFwCfg				{ [self writeReg:kSltV4CommandReg value:kCmdFwCfg];   }
- (void) writeSltRes			{ [self writeReg:kSltV4CommandReg value:kCmdSltRes];   }
- (void) writeFltRes			{ [self writeReg:kSltV4CommandReg value:kCmdFltRes];   }
- (void) writeSwRq				{ [self writeReg:kSltV4CommandReg value:kCmdSwRq];   }
- (void) writeClrCnt			{ [self writeReg:kSltV4CommandReg value:kCmdClrCnt];   }
- (void) writeEnCnt				{ [self writeReg:kSltV4CommandReg value:kCmdEnCnt];   }
- (void) writeDisCnt			{ [self writeReg:kSltV4CommandReg value:kCmdDisCnt];   }
- (void) writeReleasePage		{ [self writeReg:kSltV4PageManagerReg value:kPageMngRelease];   }
- (void) writePageManagerReset	{ [self writeReg:kSltV4PageManagerReg value:kPageMngReset];   }

- (id) controllerCard		{ return self;	  }
- (SBC_Link*)sbcLink		{ return pcmLink; } 
- (TimedWorker *) poller	{ return poller;  }

- (void) setPoller: (TimedWorker *) aPoller
{
    if(aPoller == nil){
        [poller stop];
    }
    [aPoller retain];
    [poller release];
    poller = aPoller;
}

- (void) setPollingInterval:(float)anInterval
{
	[self readAllStatus];
    if(!poller){
        [self makePoller:(float)anInterval];
    }
    else [poller setTimeInterval:anInterval];
    
	[poller stop];
    [poller runWithTarget:self selector:@selector(readAllStatus)];
}


- (void) makePoller:(float)anInterval
{
    [self setPoller:[TimedWorker TimeWorkerWithInterval:anInterval]];
}


- (void) runIsAboutToStart:(NSNotification*)aNote
{
	if([readOutGroup count] == 0){
		[self initBoard];
	}	
}

- (void) runIsStopped:(NSNotification*)aNote
{	
	// Stop all activities by software inhibit
	if([readOutGroup count] == 0){
		[self writeSetInhibit];
	}
	
	// TODO: Save dead time counters ?!
	// Is it sensible to send a new package here?
	// ak 18.7.07
	
	//NSLog(@"Deadtime: %lld\n", [self readDeadTime]);
}


#pragma mark •••Accessors

- (NSString*) patternFilePath
{
    return patternFilePath;
}

- (void) setPatternFilePath:(NSString*)aPatternFilePath
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPatternFilePath:patternFilePath];
	
	if(!aPatternFilePath)aPatternFilePath = @"";
    [patternFilePath autorelease];
    patternFilePath = [aPatternFilePath copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelPatternFilePathChanged object:self];
}

- (unsigned long) nextPageDelay
{
	return nextPageDelay;
}

- (void) setNextPageDelay:(unsigned long)aDelay
{	
	if(aDelay>102400) aDelay = 102400;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setNextPageDelay:nextPageDelay];
    
    nextPageDelay = aDelay;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelNextPageDelayChanged object:self];
	
}

- (unsigned long) interruptMask
{
    return interruptMask;
}

- (void) setInterruptMask:(unsigned long)aInterruptMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInterruptMask:interruptMask];
    
    interruptMask = aInterruptMask;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelInterruptMaskChanged object:self];
}

- (ORReadOutList*) readOutGroup
{
	return readOutGroup;
}

- (void) setReadOutGroup:(ORReadOutList*)newReadOutGroup
{
	[readOutGroup autorelease];
	readOutGroup=[newReadOutGroup retain];
}

- (NSMutableArray*) children 
{
	//method exists to give common interface across all objects for display in lists
	return [NSMutableArray arrayWithObject:readOutGroup];
}


- (float) pulserDelay
{
    return pulserDelay;
}

- (void) setPulserDelay:(float)aPulserDelay
{
	if(aPulserDelay<100)		 aPulserDelay = 100;
	else if(aPulserDelay>3276.7) aPulserDelay = 3276.7;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setPulserDelay:pulserDelay];
    
    pulserDelay = aPulserDelay;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTPulserDelayChanged object:self];
}

- (float) pulserAmp
{
    return pulserAmp;
}

- (void) setPulserAmp:(float)aPulserAmp
{
	if(aPulserAmp>4)aPulserAmp = 4;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setPulserAmp:pulserAmp];
    
    pulserAmp = aPulserAmp;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTPulserAmpChanged object:self];
}

- (short) getNumberRegisters			
{ 
    return kSltV4NumRegs; 
}

- (NSString*) getRegisterName: (short) anIndex
{
    return regV4[anIndex].regName;
}

- (unsigned long) getAddress: (short) anIndex
{
    return( regV4[anIndex].addressOffset>>2);

}

- (short) getAccessType: (short) anIndex
{
	return regV4[anIndex].accessType;
}

- (unsigned short) selectedRegIndex
{
    return selectedRegIndex;
}

- (void) setSelectedRegIndex:(unsigned short) anIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRegIndex:selectedRegIndex];
    
    selectedRegIndex = anIndex;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORIpeV4SLTSelectedRegIndexChanged
	 object:self];
}

- (unsigned long) writeValue
{
    return writeValue;
}

- (void) setWriteValue:(unsigned long) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:[self writeValue]];
    
    writeValue = aValue;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORIpeV4SLTWriteValueChanged
	 object:self];
}


- (BOOL) displayTrigger
{
	return displayTrigger;
}

- (void) setDisplayTrigger:(BOOL) aState
{
	[[[self undoManager] prepareWithInvocationTarget:self] setDisplayTrigger:displayTrigger];
	
	displayTrigger = aState;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelDisplayTriggerChanged object:self];
	
}

- (BOOL) displayEventLoop
{
	return displayEventLoop;
}

- (void) setDisplayEventLoop:(BOOL) aState
{
	[[[self undoManager] prepareWithInvocationTarget:self] setDisplayEventLoop:displayEventLoop];
	
	displayEventLoop = aState;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelDisplayEventLoopChanged object:self];
	
}

- (unsigned long) pageSize
{
	return pageSize;
}

- (void) setPageSize: (unsigned long) aPageSize
{
	
	[[[self undoManager] prepareWithInvocationTarget:self] setPageSize:pageSize];
	
    if (aPageSize < 0) pageSize = 0;
	else if (aPageSize > 100) pageSize = 100;
	else pageSize = aPageSize;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelPageSizeChanged object:self];
	
}  

#pragma mark ***HW Access
- (void) checkPresence
{
	@try {
		[self readStatusReg];
		[self setPresent:YES];
	}
	@catch(NSException* localException) {
		[self setPresent:NO];
	}
}
/*
- (void) loadPatternFile
{
	NSString* contents = [NSString stringWithContentsOfFile:patternFilePath encoding:NSASCIIStringEncoding error:nil];
	if(contents){
		NSLog(@"loading Pattern file: <%@>\n",patternFilePath);
		NSScanner* scanner = [NSScanner scannerWithString:contents];
		int amplitude;
		[scanner scanInt:&amplitude];
		int i=0;
		int j=0;
		unsigned long time[256];
		unsigned long mask[20][256];
		int len = 0;
		BOOL status;
		while(1){
			status = [scanner scanHexInt:(unsigned*)&time[i]];
			if(!status)break;
			if(time[i] == 0){
				break;
			}
			for(j=0;j<20;j++){
				status = [scanner scanHexInt:(unsigned*)&mask[j][i]];
				if(!status)break;
			}
			i++;
			len++;
			if(i>256)break;
			if(!status)break;
		}
		
		@try {
			//collect all valid cards
			ORIpeFLTModel* cards[20];//TODO: ORIpeV4SLTModel -tb-
			int i;
			for(i=0;i<20;i++)cards[i]=nil;
			
			NSArray* allFLTs = [[self crate] orcaObjects];
			NSEnumerator* e = [allFLTs objectEnumerator];
			id aCard;
			while(aCard = [e nextObject]){
				if([aCard isKindOfClass:NSClassFromString(@"ORIpeFireWireCard")])continue;//TODO: is this still true for v4? -tb-
				int index = [aCard stationNumber] - 1;
				if(index<20){
					cards[index] = aCard;
				}
			}
			for(i=0;i<20;i++){
				[cards[i] setFltRunMode: kIpeFlt_Test_Mode];
			}
			
			
			[self writeReg:kSltTestpulsAmpl value:amplitude];
			[self writeBlock:SLT_REG_ADDRESS(kSltTimingMemory) 
				  dataBuffer:time
					  length:len
				   increment:1];
			
			
			int j;
			for(j=0;j<20;j++){
				[cards[j] writeTestPattern:mask[j] length:len];
			}
			
			[self swTrigger];
			
			NSFont* aFont = [NSFont userFixedPitchFontOfSize:9];
			NSLogFont(aFont,@"-----------------------------------------------------------------------------\n");			
			NSLogFont(aFont,@"Index|  Time    | Mask                              Amplitude = %5d\n",amplitude);			
			NSLogFont(aFont,@"-----------------------------------------------------------------------------\n");			
			NSLogFont(aFont,@"     |    delta |  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20\n");			
			unsigned int delta = time[0];
			for(i=0;i<len;i++){
				NSMutableString* line = [NSMutableString stringWithFormat:@"  %2d |=%4d=%4d|",i,delta,time[i]];
				delta += time[i];
				for(j=0;j<20;j++){
					if(mask[j][i] != 0x1000000)[line appendFormat:@"%3s",mask[j][i]?"•":"-"];
					else [line appendFormat:@"%3s","="];
				}
				NSLogFont(aFont,@"%@\n",line);
			}
			NSLogFont(aFont,@"-----------------------------------------------------------------------------\n",amplitude);			
			
			
			for(i=0;i<20;i++){
				[cards[i] setFltRunMode: kIpeFlt_Run_Mode];
			}
			
			
		}
		@catch(NSException* localException) {
			NSLogColor([NSColor redColor],@"Couldn't load Pattern file <%@>\n",patternFilePath);
		}
	}
	else NSLogColor([NSColor redColor],@"Couldn't open Pattern file <%@>\n",patternFilePath);
}

- (void) swTrigger
{
	[self writeReg:kSltSwTestpulsTrigger value:0];
}
*/

- (void) writeReg:(unsigned short)index value:(unsigned long)aValue
{
	[self write: [self getAddress:index] value:aValue];
}

- (unsigned long) readReg:(unsigned short) index
{
	return [self read: [self getAddress:index]];

}

- (void) readAllStatus
{
	[self readControlReg];
	[self readStatusReg];
	[self readPageManagerReg];
}

- (unsigned long) readStatusReg
{
	unsigned long data = [self readReg:kSltV4StatusReg];
	[self setStatusReg:data];
	return data;
}

- (void) printStatusReg
{
	unsigned long data = [self readStatusReg];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"----Status Register %@ ----\n",[self fullID]);
	NSLogFont(aFont,@"WatchDogError : %@\n",IsBitSet(data,kStatusWDog)?@"YES":@"NO");
	NSLogFont(aFont,@"PixelBusError : %@\n",IsBitSet(data,kStatusPixErr)?@"YES":@"NO");
	NSLogFont(aFont,@"PPSError      : %@\n",IsBitSet(data,kStatusPpsErr)?@"YES":@"NO");
	NSLogFont(aFont,@"Clock         : 0x%02x\n",ExtractValue(data,kStatusClkErr,4));
	NSLogFont(aFont,@"VttError      : %@\n",IsBitSet(data,kStatusVttErr)?@"YES":@"NO");
	NSLogFont(aFont,@"GPSError      : %@\n",IsBitSet(data,kStatusGpsErr)?@"YES":@"NO");
	NSLogFont(aFont,@"FanError      : %@\n",IsBitSet(data,kStatusFanErr)?@"YES":@"NO");
}

- (unsigned long) readPageManagerReg
{
	unsigned long data = [self readReg:kSltV4PageManagerReg];
	[self setPageManagerReg:data];
	return data;
}

- (void) printPageManagerReg
{
	unsigned long data = [self readPageManagerReg];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"----Page Manager Register %@ ----\n",[self fullID]);
	NSLogFont(aFont,@"Page Ready  : %@\n",	IsBitSet(data,kPageMngReady)?@"YES":@"NO");
	NSLogFont(aFont,@"Oldest Page : 0x%02x\n",(data & kPageMngOldestPage)>>kPageMngOldestPageShift);
	NSLogFont(aFont,@"Next Page   : 0x%02x\n",(data & kPageMngNextPageShift)>>kPageMngNextPageShift);
	NSLogFont(aFont,@"Page Full   : %@\n",	IsBitSet(data,kPageMngPgFull)?@"YES":@"NO");
	NSLogFont(aFont,@"Free Pages  : 0x%02x\n",(data & kPageMngNumFreePagesShift)>>kPageMngNumFreePagesShift);
}

/*
- (void) writeStatusReg
{
	unsigned long data = 0;
	data |= veto			 << SLT_VETO;
	data |= extInhibit		 << SLT_EXTINHIBIT;
	data |= nopgInhibit		 << SLT_NOPGINHIBIT;
	data |= swInhibit		 << SLT_SWINHIBIT;
	data |= inhibit			 << SLT_INHIBIT;
	[self writeReg:kSltStatusReg value:data];
}

- (void) writeNextPageDelay
{
	//nextPageDelay stored as number from 0 - 100
	unsigned long aValue = nextPageDelay * 1999./100.; //convert to value 0 - 1999 x 50us  // ak, 5.10.07
	[self writeReg:kSltT1 value:aValue];
}

*/

- (unsigned long) readControlReg
{
	return [self readReg:kSltV4ControlReg];
}

- (void) printControlReg
{
	unsigned long data = [self readControlReg];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"----Control Register %@ ----\n",[self fullID]);
	NSLogFont(aFont,@"Trigger Enable : 0x%02x\n",data & kCtrlTrgEnMask);
	NSLogFont(aFont,@"Inibit Enable  : 0x%02x\n",(data & kCtrlInhEnMask) >> 6);
	NSLogFont(aFont,@"PPS            : %@\n",IsBitSet(data,kCtrlPPSMask)?@"GPS":@"Internal");
	NSLogFont(aFont,@"TP Enable      : 0x%02x\n", ExtractValue(data,kCtrlTpEnMask,11));
	NSLogFont(aFont,@"TP Shape       : %d\n", IsBitSet(data,kCtrlShapeMask));
	NSLogFont(aFont,@"Run Mode       : %@\n", IsBitSet(data,kCtrlRunMask)?@"Normal":@"Test");
	NSLogFont(aFont,@"Test SLT       : %@\n", IsBitSet(data,kCtrlTstSltMask)?@"Enabled":@"Disabled");
	NSLogFont(aFont,@"IntA Enable    : %@\n", IsBitSet(data,kCtrlIntEnMask)?@"Enabled":@"Disabled");
}


- (void) writeControlReg
{
	[self writeReg:kSltV4ControlReg value:controlReg];
}

- (void) loadSecondsReg
{
	[self writeReg:kSltV4SecondSetReg value:secondsSet];
}

/*
- (void) writeInterruptMask
{
	[self writeReg:kSltIRMask value:interruptMask];
}

- (void) readInterruptMask
{
	[self setInterruptMask:[self readReg:kSltIRMask]];
}

- (void) printInterruptMask
{
	unsigned long data = [self readReg:kSltIRMask];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"----Interrupt Mask SLT (%d) ----\n",[self stationNumber]);
	if(!data)NSLogFont(aFont,@"Interrupt Mask is Clear (No interrupts enabled)\n");
	else {
		NSLogFont(aFont,@"The following interrupts are enabled:\n");
		
		if(data & (1<<0))NSLogFont(aFont,@"\tNext Page\n");
		if(data & (1<<1))NSLogFont(aFont,@"\tAll Pages Full\n");
		if(data & (1<<2))NSLogFont(aFont,@"\tFLT Config Failure\n");
		if(data & (1<<3))NSLogFont(aFont,@"\tFLT Cmd sent after Config Failure\n");
		if(data & (1<<4))NSLogFont(aFont,@"\tWatchDog Error\n");
		if(data & (1<<5))NSLogFont(aFont,@"\tSecond Strobe Error\n");
		if(data & (1<<6))NSLogFont(aFont,@"\tParity Error\n");
		if(data & (1<<7))NSLogFont(aFont,@"\tNext Page When Full\n");
		if(data & (1<<8))NSLogFont(aFont,@"\tNext Page , Previous\n");
	}
}
*/

- (unsigned long) readHwVersion
{
	unsigned long value;
	@try {
		[self setHwVersion:[self readReg: kSltV4HWRevisionReg]];	
	}
	@catch (NSException* e){
	}
	return value;
}


- (unsigned long long) readDeadTime
{
	unsigned long low  = [self readReg:kSltV4DeadTimeCounterLoReg];
	unsigned long high = [self readReg:kSltV4DeadTimeCounterHiReg];
	return ((unsigned long long)high << 32) | low;
}

- (unsigned long long) readVetoTime
{
	unsigned long low  = [self readReg:kSltV4VetoCounterLoReg];
	unsigned long high = [self readReg:kSltV4VetoCounterHiReg];
	return ((unsigned long long)high << 32) | low;
}

- (unsigned long long) readRunTime
{
	unsigned long low  = [self readReg:kSltV4RunCounterLoReg];
	unsigned long high = [self readReg:kSltV4RunCounterHiReg];
	return ((unsigned long long)high << 32) | low;
}

- (unsigned long) readSecondsCounter
{
	return [self readReg:kSltV4SecondCounterReg];
}

- (unsigned long) readSubSecondsCounter
{
	return [self readReg:kSltV4SubSecondCounterReg];
}

- (void) initBoard
{
	
	//-----------------------------------------------
	//board doesn't appear to start without this stuff
	//[self writeReg:kSltActResetFlt value:0];
	//[self writeReg:kSltActResetSlt value:0];
	//usleep(10);
	//[self writeReg:kSltRelResetFlt value:0];
	//[self writeReg:kSltRelResetSlt value:0];
	//[self writeReg:kSltSwSltTrigger value:0];
	//[self writeReg:kSltSwSetInhibit value:0];
	
	//usleep(100);
	
//	int savedTriggerSource = triggerSource;
//	int savedInhibitSource = inhibitSource;
//	triggerSource = 0x1; //sw trigger only
//	inhibitSource = 0x3; 
	[self writeControlReg];
//	[self releaseAllPages];
	//unsigned long long p1 = ((unsigned long long)[self readReg:kPageStatusHigh]<<32) | [self readReg:kPageStatusLow];
	//[self writeReg:kSltSwRelInhibit value:0];
	//int i = 0;
	//unsigned long lTmp;
    //do {
	//	lTmp = [self readReg:kSltStatusReg];
		//NSLog(@"waiting for inhibit %x i=%d\n", lTmp, i);
		//usleep(10);
		//i++;
   // } while(((lTmp & 0x10000) != 0) && (i<10000));
	
   // if (i>= 10000){
		//NSLog(@"Release inhibit failed\n");
		//[NSException raise:@"SLT error" format:@"Release inhibit failed"];
	//}
/*	
	unsigned long long p2  = ((unsigned long long)[self readReg:kPageStatusHigh]<<32) | [self readReg:kPageStatusLow];
	if(p1 == p2) NSLog (@"No software trigger\n");
	[self writeReg:kSltSwSetInhibit value:0];
 */
//	triggerSource = savedTriggerSource;
	//inhibitSource = savedInhibitSource;
	//-----------------------------------------------
	
	//[self writeControlReg];
	//[self writeInterruptMask];
	//[self writeNextPageDelay];
	[self printStatusReg];
	[self printControlReg];
	[self printPageManagerReg];
}

- (void) reset
{
	[self hw_config];
	[self hw_reset];
}

- (void) hw_config
{
	NSLog(@"SLT: HW Configure\n");
	[ORTimer delay:1.5];
	[ORTimer delay:1.5];
	//[self readReg:kSltStatusReg];
	[guardian checkCards];
}

- (void) hw_reset
{
	NSLog(@"SLT: HW Reset\n");
	//[self writeReg:kSltSwRelInhibit value:0];
	//[self writeReg:kSltActResetFlt value:0];
	//[self writeReg:kSltActResetSlt value:0];
	usleep(10);
	//[self writeReg:kSltRelResetFlt value:0];
	//[self writeReg:kSltRelResetSlt value:0];
	//[self writeReg:kSltSwSltTrigger value:0];
	//[self writeReg:kSltSwSetInhibit value:0];				
}
/*
- (void) loadPulseAmp
{
	unsigned short theConvertedAmp = pulserAmp * 4095./4.;
	[self writeReg:kSltTestpulsAmpl value:theConvertedAmp];
	NSLog(@"Wrote %.2fV to SLT pulser Amplitude\n",pulserAmp);
}

- (void) loadPulseDelay
{
	//delay goes from 100ns to 3276.8us
	//writing 0x00 to hw gives longest delay. 
	//conversion equation:  hwValue = -10.0*delay + 32768.
	unsigned short theConvertedDelay = pulserDelay * -10.0 + 32768.;
	[self write:SLT_REG_ADDRESS(kSltTestpulsTiming)+0 value:theConvertedDelay];
	[self write:SLT_REG_ADDRESS(kSltTestpulsTiming)+1 value:theConvertedDelay];
	int i; //load the rest of the pulser memory with 0's
	for (i=2;i<256;i++) [self write:SLT_REG_ADDRESS(kSltTestpulsTiming)+i value:theConvertedDelay];
}


- (void) loadPulserValues
{
	[self loadPulseAmp];
	[self loadPulseDelay];
}
*/

- (void) setCrateNumber:(unsigned int)aNumber
{
	[guardian setCrateNumber:aNumber];
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	
	pcmLink = [[decoder decodeObjectForKey:@"PCM_Link"] retain];
	if(!pcmLink)pcmLink = [[PCM_Link alloc] initWithDelegate:self];
	else [pcmLink setDelegate:self];

	[self setControlReg:				[decoder decodeInt32ForKey:@"controlReg"]];
	[self setSecondsSet:[decoder decodeInt32ForKey:@"secondsSet"]];

	//status reg
	[self setPatternFilePath:		[decoder decodeObjectForKey:@"ORIpeV4SLTModelPatternFilePath"]];
	[self setInterruptMask:			[decoder decodeInt32ForKey:@"ORIpeV4SLTModelInterruptMask"]];
	[self setPulserDelay:			[decoder decodeFloatForKey:@"ORIpeV4SLTModelPulserDelay"]];
	[self setPulserAmp:				[decoder decodeFloatForKey:@"ORIpeV4SLTModelPulserAmp"]];
		
	//special
    [self setNextPageDelay:			[decoder decodeIntForKey:@"nextPageDelay"]]; // ak, 5.10.07
	
	[self setReadOutGroup:			[decoder decodeObjectForKey:@"ReadoutGroup"]];
    [self setPoller:				[decoder decodeObjectForKey:@"poller"]];
	
    [self setPageSize:				[decoder decodeIntForKey:@"ORIpeV4SLTPageSize"]]; // ak, 9.12.07
    [self setDisplayTrigger:		[decoder decodeBoolForKey:@"ORIpeV4SLTDisplayTrigger"]];
    [self setDisplayEventLoop:		[decoder decodeBoolForKey:@"ORIpeV4SLTDisplayEventLoop"]];
    	
    if (!poller)[self makePoller:0];
	
	//needed because the readoutgroup was added when the object was already in the config and so might not be in the configuration
	if(!readOutGroup){
		ORReadOutList* readList = [[ORReadOutList alloc] initWithIdentifier:@"ReadOut List"];
		[self setReadOutGroup:readList];
		[readList release];
	}
	
	[[self undoManager] enableUndoRegistration];
	
	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
	
	[encoder encodeInt32:secondsSet forKey:@"secondsSet"];
	[encoder encodeObject:pcmLink		forKey:@"PCM_Link"];
	[encoder encodeInt32:controlReg	forKey:@"controlReg"];
	
	//status reg
	[encoder encodeObject:patternFilePath forKey:@"ORIpeV4SLTModelPatternFilePath"];
	[encoder encodeInt32:interruptMask	 forKey:@"ORIpeV4SLTModelInterruptMask"];
	[encoder encodeFloat:pulserDelay	 forKey:@"ORIpeV4SLTModelPulserDelay"];
	[encoder encodeFloat:pulserAmp		 forKey:@"ORIpeV4SLTModelPulserAmp"];
		
	//special
    [encoder encodeInt:nextPageDelay     forKey:@"nextPageDelay"]; // ak, 5.10.07
	
	[encoder encodeObject:readOutGroup  forKey:@"ReadoutGroup"];
    [encoder encodeObject:poller         forKey:@"poller"];
	
    [encoder encodeInt:pageSize         forKey:@"ORIpeV4SLTPageSize"]; // ak, 9.12.07
    [encoder encodeBool:displayTrigger   forKey:@"ORIpeV4SLTDisplayTrigger"];
    [encoder encodeBool:displayEventLoop forKey:@"ORIpeV4SLTDisplayEventLoop"];
		
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORIpeV4SLTDecoderForEvent",				@"decoder",
								 [NSNumber numberWithLong:eventDataId],	@"dataId",
								 [NSNumber numberWithBool:NO],			@"variable",
								 [NSNumber numberWithLong:5],			@"length",
								 nil];
	
    [dataDictionary setObject:aDictionary forKey:@"IpeV4SLTEvent"];
	
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORIpeV4SLTDecoderForMultiplicity",			@"decoder",
				   [NSNumber numberWithLong:multiplicityId],   @"dataId",
				   [NSNumber numberWithBool:NO],				@"variable",
				   [NSNumber numberWithLong:3+20*100],			@"length",
				   nil];
	
    [dataDictionary setObject:aDictionary forKey:@"IpeV4SLTMultiplicity"];
    
    return dataDictionary;
}

- (unsigned long) eventDataId        { return eventDataId; }
- (unsigned long) multiplicityId	 { return multiplicityId; }
- (void) setEventDataId: (unsigned long) aDataId    { eventDataId = aDataId; }
- (void) setMultiplicityId: (unsigned long) aDataId { multiplicityId = aDataId; }

- (void) setDataIds:(id)assigner
{
    eventDataId     = [assigner assignDataIds:kLongForm];
    multiplicityId  = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setEventDataId:[anotherCard eventDataId]];
    [self setMultiplicityId:[anotherCard multiplicityId]];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	return objDictionary;
}

#pragma mark •••Data Taker
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    [self clearExceptionCount];
	
	//check that we can actually run
    if(![[[self crate] adapter] serviceIsAlive]){
		[NSException raise:@"No FireWire Service" format:@"Check Crate Power and FireWire Cable."];
    }
	
    //----------------------------------------------------------------------------------------
    // Add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORIpeV4SLTModel"];    
    //----------------------------------------------------------------------------------------	
	
	pollingWasRunning = [poller isRunning];
	if(pollingWasRunning) [poller stop];
	
	[self writeSetInhibit];
	
    if([[userInfo objectForKey:@"doinit"]intValue]){
		[self initBoard];					
	}	
	
	dataTakers = [[readOutGroup allObjects] retain];		//cache of data takers.
	
    NSEnumerator* e = [dataTakers objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        [obj runTaskStarted:aDataPacket userInfo:userInfo];
    }
	
	[self readStatusReg];
	actualPageIndex = 0;
	eventCounter    = 0;
	first = YES;
	lastDisplaySec = 0;
	lastDisplayCounter = 0;
	lastDisplayRate = 0;
	lastSimSec = 0;
	
	//load all the data needed for the eCPU to do the HW read-out.
	[self load_HW_Config];
	[pcmLink runTaskStarted:aDataPacket userInfo:userInfo];
	
}

-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	if(!first){
		//event readout controlled by the SLT cpu now. ORCA reads out 
		//the resulting data from a generic circular buffer in the pcmLink code.
		[pcmLink takeData:aDataPacket userInfo:userInfo];
	}
	else {
		//[self releaseAllPages];
		[self writeClrInhibit];
		//[self writeReg:kSltResetDeadTime value:0];
		first = NO;
	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	[self writeSetInhibit];
	
	[pcmLink runTaskStopped:aDataPacket userInfo:userInfo];
	
	if(pollingWasRunning) {
		[poller runWithTarget:self selector:@selector(readAllStatus)];
	}
}

- (unsigned long) calcProjection:(unsigned long *)pMult  xyProj:(unsigned long *)xyProj  tyProj:(unsigned long *)tyProj
{ 
	//temp----
	int i, j, k;
	int sltSize = pageSize * 20;	
	
	
	// Dislay the matrix of triggered pixel and timing
	// The xy-Projection is needed to readout only the triggered pixel!!!
	//unsigned long xyProj[20];
	//unsigned long tyProj[100];
	for (i=0;i<20;i++) xyProj[i] = 0;
	for (k=0;k<100;k++) tyProj[k] = 0;
	for (k=0;k<sltSize;k++){
		xyProj[k%20] = xyProj[k%20] | (pMult[k] & 0x3fffff);
	}  
	for (k=0;k<sltSize;k++){
		if (xyProj[k%20]) {
			tyProj[k/20] = tyProj[k/20] | (pMult[k] & 0x3fffff);
		}
	}
	
	int nTriggered = 0;
	for (i=0;i<20;i++){
		for(j=0;j<22;j++){
			if (((xyProj[i]>>j) & 0x1 ) == 0x1) nTriggered++;
		}
	}
	
	
	// Display trigger data
	if (displayTrigger) {	
		int i, j, k;
		NSFont* aFont = [NSFont userFixedPitchFontOfSize:9];
		
		for(j=0;j<22;j++){
			NSMutableString* s = [NSMutableString stringWithFormat:@"%2d: ",j];
			//matrix of triggered pixel
			for(i=0;i<20;i++){
				if (((xyProj[i]>>j) & 0x1) == 0x1) [s appendFormat:@"X"];
				else							   [s appendFormat:@"."];
			}
			[s appendFormat:@"  "];
			
			// trigger timing
			for (k=0;k<pageSize;k++){
				if (((tyProj[k]>>j) & 0x1) == 0x1 )[s appendFormat:@"="];
				else							   [s appendFormat:@"."];
			}
			NSLogFont(aFont, @"%@\n", s);
		}
		
		NSLogFont(aFont,@"\n");	
	}		
	return(nTriggered);
}

- (void) saveReadOutList:(NSFileHandle*)aFile
{
    [readOutGroup saveUsingFile:aFile];
}

- (void) loadReadOutList:(NSFileHandle*)aFile
{
    [self setReadOutGroup:[[[ORReadOutList alloc] initWithIdentifier:@"cPCI"]autorelease]];
    [readOutGroup loadUsingFile:aFile];
}
/*
- (void) dumpTriggerRAM:(int)aPageIndex
{
	
	//read page start address
	unsigned long lTimeL     = [self read: SLT_REG_ADDRESS(kSltLastTriggerTimeStamp) + aPageIndex];
	int iPageStart = (((lTimeL >> 10) & 0x7fe)  + 20) % 2000;
	
	unsigned long timeStampH = [self read: SLT_REG_ADDRESS(kSltPageTimeStamp) + 2*aPageIndex];
	unsigned long timeStampL = [self read: SLT_REG_ADDRESS(kSltPageTimeStamp) + 2*aPageIndex+1];
	
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:9];
	NSLogFont(aFont,@"Reading event from page %d, start=%d:  %ds %dx100us\n", 
			  aPageIndex+1, iPageStart, timeStampH, (timeStampL >> 11) & 0x3fff);
	
	//readout the SLT pixel trigger data
	unsigned long buffer[2000];
	unsigned long sltMemoryAddress = (SLTID << 24) | aPageIndex<<11;
	[self readBlock:sltMemoryAddress dataBuffer:(unsigned long*)buffer length:20*100 increment:1];
	unsigned long reorderBuffer[2000];
	// Re-organize trigger data to get it in a continous data stream
	unsigned long *pMult = reorderBuffer;
	memcpy( pMult, buffer + iPageStart, (2000 - iPageStart)*sizeof(unsigned long));  
	memcpy( pMult + 2000 - iPageStart, buffer, iPageStart*sizeof(unsigned long));  
	
	int i;
	int j;	
	int k;	
	
	// Dislay the matrix of triggered pixel and timing
	// The xy-Projection is needed to readout only the triggered pixel!!!
	unsigned long xyProj[20];
	unsigned long tyProj[100];
	for (i=0;i<20;i++) xyProj[i] = 0;
	for (k=0;k<100;k++) tyProj[k] = 0;
	for (k=0;k<2000;k++){
		xyProj[k%20] = xyProj[k%20] | (pMult[k] & 0x3fffff);
	}  
	for (k=0;k<2000;k++){
		if (xyProj[k%20]) {
			tyProj[k/20] = tyProj[k/20] | (pMult[k] & 0x3fffff);
		}
	}
	
	
	for(j=0;j<22;j++){
		NSMutableString* s = [NSMutableString stringWithFormat:@"%2d: ",j];
		//matrix of triggered pixel
		for(i=0;i<20;i++){
			if (((xyProj[i]>>j) & 0x1) == 0x1) [s appendFormat:@"X"];
			else							   [s appendFormat:@"."];
		}
		[s appendFormat:@"  "];
		
		// trigger timing
		for (k=0;k<100;k++){
			if (((tyProj[k]>>j) & 0x1) == 0x1 )[s appendFormat:@"="];
			else							   [s appendFormat:@"."];
		}
		NSLogFont(aFont, @"%@\n", s);
	}
	
	
	NSLogFont(aFont,@"\n");			
	
	
}
*/
- (void) autoCalibrate
{
	NSArray* allFLTs = [[self crate] orcaObjects];
	NSEnumerator* e = [allFLTs objectEnumerator];
	id aCard;
	while(aCard = [e nextObject]){
		if(![aCard isKindOfClass:NSClassFromString(@"ORIpeFireWireCard")]){
			[aCard autoCalibrate];
		}
	}
}


#pragma mark •••SBC_Linking protocol

- (NSString*) cpuName
{
	return [NSString stringWithFormat:@"SLT (Crate %d)",[self crateNumber]];
}

- (NSString*) sbcLockName
{
	return ORIpeV4SLTSettingsLock;
}

- (NSString*) sbcLocalCodePath
{
	return @"Source/Objects/Hardware/IPE/IpeV4 SLT/SLTv4_Readout_Code";
}

- (NSString*) codeResourcePath
{
	return [[self sbcLocalCodePath] lastPathComponent];
}


#pragma mark •••SBC I/O layer
- (unsigned long) read:(unsigned long) address
{
	if(![pcmLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	unsigned long theData;
	[pcmLink readLongBlockPbus:&theData
					  atAddress:address
					  numToRead: 1];
	return theData;
}

- (void) read:(unsigned long long) address data:(unsigned long*)theData size:(unsigned long)len
{ 
	if(![pcmLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	[pcmLink readLongBlockPbus:theData
					 atAddress:address
					 numToRead:len];
}

- (void) writeBitsAtAddress:(unsigned long)address 
					  value:(unsigned long)dataWord 
					   mask:(unsigned long)aMask 
					shifted:(int)shiftAmount
{
	if(![pcmLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	
	unsigned long buffer = [self  read:address];
	buffer =(buffer & ~(aMask<<shiftAmount) ) | (dataWord << shiftAmount);
	[self write:address value:buffer];
}

- (void) setBitsHighAtAddress:(unsigned long)address 
						 mask:(unsigned long)aMask
{
	if(![pcmLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	unsigned long buffer = [self  read:address];
	buffer = (buffer | aMask );
	[self write:address value:buffer];
}

- (void) readRegisterBlock:(unsigned long)  anAddress 
				dataBuffer:(unsigned long*) aDataBuffer
					length:(unsigned long)  length 
				 increment:(unsigned long)  incr
			   numberSlots:(unsigned long)  nSlots 
			 slotIncrement:(unsigned long)  incrSlots
{
	if(![pcmLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	
	int i,j;
	for(i=0;i<nSlots;i++) {
		for(j=0;j<length;j++) {
			aDataBuffer[i*length + j] = [self read:(anAddress + i*incrSlots + j*incr)]; // Slots start with id 1 !!!
		}
	}
}

- (void) readBlock:(unsigned long)  anAddress 
		dataBuffer:(unsigned long*) aDataBuffer
			length:(unsigned long)  length 
		 increment:(unsigned long)  incr
{
	if(![pcmLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	
	int i;
	for(i=0;i<length;i++) {
		aDataBuffer[i] = [self read:anAddress + i*incr];
	}
}

- (void) writeBlock:(unsigned long)  anAddress 
		 dataBuffer:(unsigned long*) aDataBuffer
			 length:(unsigned long)  length 
		  increment:(unsigned long)  incr
{
	if(![pcmLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	
	int i;
	for(i=0;i<length;i++) {
		[self write:anAddress + i*incr value:aDataBuffer[i]];
	}	
}

- (void) clearBlock:(unsigned long)  anAddress 
			pattern:(unsigned long) aPattern
			 length:(unsigned long)  length 
		  increment:(unsigned long)  incr
{
	if(![pcmLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	int i;
	for(i=0;i<length;i++) {
		[self write:anAddress + i*incr value:aPattern];
	}
}

#pragma mark •••SBC Data Structure Setup
- (void) load_HW_Config
{
	int index = 0;
	SBC_crate_config configStruct;
	
	configStruct.total_cards = 0;
	
	[self load_HW_Config_Structure:&configStruct index:index];
	
	[pcmLink load_HW_Config:&configStruct];
}

- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id	= kSLTv4;	//should be unique
	configStruct->card_info[index].hw_mask[0] 	= eventDataId;
	configStruct->card_info[index].hw_mask[1] 	= multiplicityId;
	configStruct->card_info[index].slot			= [self stationNumber];
	configStruct->card_info[index].crate		= [self crateNumber];
	configStruct->card_info[index].add_mod		= 0;		//not needed for this HW
	
	//use the following as needed to define base addresses and special data for use by the cpu to 
	//do the readout
	//configStruct->card_info[index].base_add		= [self baseAddress];
	//configStruct->card_info[index].deviceSpecificData[0] = onlineMask;
	//configStruct->card_info[index].deviceSpecificData[1] = register_offsets[kConversionStatusRegister];
	//configStruct->card_info[index].deviceSpecificData[2] = register_offsets[kADC1OutputRegister];
	
	configStruct->card_info[index].num_Trigger_Indexes = 1;	//Just 1 group of objects controlled by SLT
    int nextIndex = index+1;
    
	configStruct->card_info[index].next_Trigger_Index[0] = -1;
	NSEnumerator* e = [dataTakers objectEnumerator];
	id obj;
	while(obj = [e nextObject]){
		if([obj respondsToSelector:@selector(load_HW_Config_Structure:index:)]){
			if(configStruct->card_info[index].next_Trigger_Index[0] == -1){
				configStruct->card_info[index].next_Trigger_Index[0] = nextIndex;
			}
			int savedIndex = nextIndex;
			nextIndex = [obj load_HW_Config_Structure:configStruct index:nextIndex];
			if(obj == [dataTakers lastObject]){
				configStruct->card_info[savedIndex].next_Card_Index = -1; //make the last object a leaf node
			}
		}
	}
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	return index+1;
}
@end

@implementation ORIpeV4SLTModel (private)
- (unsigned long) read:(unsigned long) address
{
	if(![pcmLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	unsigned long theData;
	[pcmLink readLongBlockPbus:&theData
					  atAddress:address
					  numToRead: 1];
	return theData;
}

- (void) write:(unsigned long) address value:(unsigned long) aValue
{
	if(![pcmLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	[pcmLink writeLongBlockPbus:&aValue
					  atAddress:address
					 numToWrite:1];
}
@end

