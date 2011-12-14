//
//  KatrinModel.m
//  Orca
//
//  Created by Mark Howe on Tue Jun 28 2005.
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


#pragma mark ���Imported Files
#import "KatrinModel.h"
#import "KatrinController.h"
#import "ORFPDSegmentGroup.h"
#import "KatrinConstants.h"
#import "ORSocketClient.h"
#import "ORCommandCenter.h"

NSString* KatrinModelSlowControlIsConnectedChanged = @"KatrinModelSlowControlIsConnectedChanged";
NSString* KatrinModelSlowControlNameChanged			= @"KatrinModelSlowControlNameChanged";
NSString* ORKatrinModelViewTypeChanged				= @"ORKatrinModelViewTypeChanged";
NSString* ORKatrinModelSNTablesChanged				= @"ORKatrinModelSNTablesChanged";

static NSString* KatrinDbConnector		= @"KatrinDbConnector";
@interface KatrinModel (private)
- (void) validateSNArrays;
@end

@implementation KatrinModel

#pragma mark ���Initialization
- (void) wakeUp
{
	[super wakeUp];
	BOOL exists = [[ORCommandCenter sharedCommandCenter] clientWithNameExists:slowControlName];
	[self setSlowControlIsConnected: exists];

}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"katrin"]];
}

- (void) makeMainController
{
    [self linkToController:@"KatrinController"];
}

- (NSString*) helpURL
{
	return @"KATRIN/Index.html";
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - 35,2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:KatrinDbConnector];
    [aConnector setOffColor:[NSColor brownColor]];
    [aConnector setOnColor:[NSColor magentaColor]];
	[ aConnector setConnectorType: 'DB O' ];
	[ aConnector addRestrictedConnectionType: 'DB I' ]; //can only connect to DB outputs
    [aConnector release];
}

- (void) registerNotificationObservers
{
	[super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(slowControlConnectionChanged:)
                         name : ORCommandClientsChangedNotification
                       object : nil];
	
}

- (void) slowControlConnectionChanged:(NSNotification*)aNote
{
	ORSocketClient* theClient = [[aNote userInfo] objectForKey:@"client"];
	if([[theClient name] isEqualToString:slowControlName]){
		BOOL exists = [[[ORCommandCenter sharedCommandCenter]clients] containsObject:theClient];
		[self setSlowControlIsConnected: [theClient isConnected] && exists];
	}
}

#pragma mark ���Accessors
- (NSString*) slowControlName;
{
	if(!slowControlName)return @"";
	return slowControlName;
}

- (void) setSlowControlName:(NSString*)aName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSlowControlName:slowControlName];
    
	[slowControlName autorelease];
    slowControlName = [aName copy];    
	
	BOOL exists = [[ORCommandCenter sharedCommandCenter] clientWithNameExists:slowControlName];
	[self setSlowControlIsConnected: exists];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:KatrinModelSlowControlNameChanged object:self];
	
}

- (BOOL) slowControlIsConnected
{
	return slowControlIsConnected;
}

- (void) setSlowControlIsConnected:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSlowControlIsConnected:slowControlIsConnected];
    
    slowControlIsConnected = aState;    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:KatrinModelSlowControlIsConnectedChanged object:self];
	
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)aDictionary
{
	NSString* segmentGeometryName[2] = {@"FPDGeometry",@"VetoGeometry"};
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
	int i;
	int n = MIN(2,[segmentGroups count]);
	for(i=0;i<n;i++){
		ORSegmentGroup* aSegmentGroup = [segmentGroups objectAtIndex:i];
		[aSegmentGroup addParametersToDictionary:objDictionary useName:segmentGeometryName[i]];
	}
	
	NSString* rootMapFile = [[[segmentGroups objectAtIndex:0] mapFile] stringByExpandingTildeInPath];
	rootMapFile = [rootMapFile stringByDeletingPathExtension];

	//add the FLT/ORB SN
	NSString* contents = [NSString stringWithContentsOfFile:FLTORBSNFILE(rootMapFile) encoding:NSASCIIStringEncoding error:nil];
	if(!contents)contents = @"NONE";
    [objDictionary setObject:contents forKey:@"FltOrbSNs"];
	
	//add the Preamp SN
	contents = [NSString stringWithContentsOfFile:PREAMPSNFILE(rootMapFile) encoding:NSASCIIStringEncoding error:nil];
	if(!contents)contents = @"NONE";
    [objDictionary setObject:contents forKey:@"PreampSNs"];
	
	//add the OSB SN
	contents = [NSString stringWithContentsOfFile:OSBSNFILE(rootMapFile) encoding:NSASCIIStringEncoding error:nil];
	if(!contents)contents = @"NONE";
    [objDictionary setObject:contents forKey:@"OsbSNs"];

	//add the SLT and Wafer SN
	contents = [NSString stringWithContentsOfFile:SLTWAFERSNFILE(rootMapFile) encoding:NSASCIIStringEncoding error:nil];
	if(!contents)contents = @"NONE";
    [objDictionary setObject:contents forKey:@"SltWaferSNs"];
		
    [aDictionary setObject:objDictionary forKey:[self className]];
    return aDictionary;
}

#pragma mark ���Segment Group Methods
- (void) makeSegmentGroups
{
    ORFPDSegmentGroup* group = [[ORFPDSegmentGroup alloc] initWithName:@"Focal Plane" numSegments:kNumFocalPlaneSegments mapEntries:[self initMapEntries:0]];
	[self addGroup:group];
	[group release];
	
    group = [[ORSegmentGroup alloc] initWithName:@"Veto" numSegments:kNumVetoSegments mapEntries:[self initMapEntries:1]];
	[self addGroup:group];
	[group release];
}

- (NSMutableArray*) initMapEntries:(int)index
{
	if(index==1){
		NSMutableArray* mapEntries = [NSMutableArray array];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kSegmentNumber",	@"key", [NSNumber numberWithInt:0], @"sortType", nil]];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kFLTSlot",		@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kFLTChannel",	@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
		return mapEntries;
	}
	else {
		NSMutableArray* mapEntries = [NSMutableArray array];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kSegmentNumber",	@"key", [NSNumber numberWithInt:0], @"sortType", nil]];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kFLTSlot",		@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kFLTChannel",	@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kPreampModule",	@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kPreampChannel",	@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kOSBSlot",		@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kOSBChannel",	@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
		return mapEntries;
	}
}

- (int)  maxNumSegments
{
	return kNumFocalPlaneSegments;
}


- (NSString*) reformatSelectionString:(NSString*)aString forSet:(int)aSet
{
	if(aSet == 0){
		//the focal plane
		NSString* finalString = @"";
		NSArray* parts = [aString componentsSeparatedByString:@"\n"];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Segment" parts:parts]];
		finalString = [finalString stringByAppendingString:@"-----------------------\n"];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" CardSlot" parts:parts]];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Channel" parts:parts]];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Threshold" parts:parts]];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Gain" parts:parts]];
		finalString = [finalString stringByAppendingString:@"-----------------------\n"];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" ModuleAddress" parts:parts]];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" ModuleChannel" parts:parts]];
		finalString = [finalString stringByAppendingString:@"-----------------------\n"];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" OSBSlot" parts:parts]];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" OSBChannel" parts:parts]];
		return finalString;
	}
	else {
		//the veto
		//the focal plane
		NSString* finalString = @"";
		NSArray* parts = [aString componentsSeparatedByString:@"\n"];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Segment" parts:parts]];
		finalString = [finalString stringByAppendingString:@"-----------------------\n"];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" CardSlot" parts:parts]];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Channel" parts:parts]];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Threshold" parts:parts]];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Gain" parts:parts]];
		finalString = [finalString stringByAppendingString:@"-----------------------\n"];
		return finalString;
	}
}

- (NSString*) getPartStartingWith:(NSString*)aLabel parts:(NSArray*)parts
{
	for(id aLine in parts){
		if([aLine rangeOfString:aLabel].location != NSNotFound) return aLine;
	}
	return @"";
}


- (void) showDataSetForSet:(int)aSet segment:(int)index
{ 
	if(aSet>=0 && aSet < [segmentGroups count]){
		ORSegmentGroup* aGroup = [segmentGroups objectAtIndex:aSet];
		NSString* cardName = [aGroup segment:index objectForKey:@"kCardSlot"];
		NSString* chanName = [aGroup segment:index objectForKey:@"kChannel"];
		if(cardName && chanName && ![cardName hasPrefix:@"-"] && ![chanName hasPrefix:@"-"]){
			ORDataSet* aDataSet = nil;
			[[[self document] collectObjectsOfClass:NSClassFromString(@"OrcaObject")] makeObjectsPerformSelector:@selector(clearLoopChecked)];
			NSArray* objs = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
			if([objs count]){
				NSArray* arrayOfHistos = [[objs objectAtIndex:0] collectConnectedObjectsOfClass:NSClassFromString(@"ORHistoModel")];
				if([arrayOfHistos count]){
					id histoObj = [arrayOfHistos objectAtIndex:0];
				//	if([[aGroup adcClassName] isEqualToString:@"ORKatrinFLTModel"] || [[aGroup adcClassName] isEqualToString:@"ORIpeV4FLTModel"]){
						aDataSet = [histoObj objectForKeyArray:[NSMutableArray arrayWithObjects:@"FLT", @"Energy", @"Crate  0",
																[NSString stringWithFormat:@"Station %2d",[cardName intValue]], 
																[NSString stringWithFormat:@"Channel %2d",[chanName intValue]],
																nil]];
			//		}
					
					[aDataSet doDoubleClick:nil];
				}
			}
		}
	}
}

- (NSString*) dataSetNameGroup:(int)aGroup segment:(int)index
{
	ORSegmentGroup* theGroup = [segmentGroups objectAtIndex:aGroup];

	NSString* crateName = [theGroup segment:index objectForKey:@"kCrate"];
	NSString* cardName  = [theGroup segment:index objectForKey:@"kCardSlot"];
	NSString* chanName  = [theGroup segment:index objectForKey:@"kChannel"];
	
	return [NSString stringWithFormat:@"FLT,Energy,Crate %2d,Station %2d,Channel %2d",[crateName intValue],[cardName intValue],[chanName intValue]];
}

- (int) numberSegmentsInGroup:(int)aGroup
{
	if(aGroup == 0)		 return kNumFocalPlaneSegments;
	else if(aGroup == 1) return kNumVetoSegments;
	else return 0;
}


#pragma mark ���Specific Dialog Lock Methods
- (NSString*) experimentMapLock
{
	return @"KatrinMapLock";
}

- (NSString*) experimentDetectorLock
{
	return @"KatrinDetectorLock";
}

- (NSString*) experimentDetailsLock	
{
	return @"KatrinDetailsLock";
}

- (void) setViewType:(int)aViewType
{
	[[[self undoManager] prepareWithInvocationTarget:self] setViewType:aViewType];
	viewType = aViewType;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinModelViewTypeChanged object:self userInfo:nil];
}

- (int) viewType
{
	return viewType;
}

- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
	//backward compatibility check
    if([segmentGroups count]>1){
		NSObject* firstSegmentGroup = [segmentGroups objectAtIndex:0];
		if(![firstSegmentGroup isKindOfClass:NSClassFromString(@"ORFPDSegmentGroup")]){
			ORFPDSegmentGroup* group = [[ORFPDSegmentGroup alloc] initWithName:@"Focal Plane" numSegments:kNumFocalPlaneSegments mapEntries:[self initMapEntries:0]];
			[segmentGroups replaceObjectAtIndex:0 withObject:group];
			[group release];
		}
	}
    [self setSlowControlName:[decoder decodeObjectForKey:@"slowControlName"]];
    [self setViewType:[decoder decodeIntForKey:@"viewType"]];
	fltSNs		= [[decoder decodeObjectForKey:@"fltSNs"] retain];
	preAmpSNs	= [[decoder decodeObjectForKey:@"preAmpSNs"] retain];
	osbSNs		= [[decoder decodeObjectForKey:@"osbSNs"] retain];
	otherSNs	= [[decoder decodeObjectForKey:@"otherSNs"] retain];
	[self validateSNArrays];
	[[self undoManager] enableUndoRegistration];

    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	
    [encoder encodeObject:slowControlName	forKey: @"slowControlName"];
    [encoder encodeInt:viewType				forKey: @"viewType"];
    [encoder encodeObject:fltSNs			forKey: @"fltSNs"];
    [encoder encodeObject:preAmpSNs			forKey: @"preAmpSNs"];
    [encoder encodeObject:osbSNs			forKey: @"osbSNs"];
    [encoder encodeObject:otherSNs			forKey: @"otherSNs"];
}


#pragma mark ���SN Access Methods
- (id) fltSN:(int)i objectForKey:(id)aKey
{
	if(i>=0 && i<8){
		return [[fltSNs objectAtIndex:i] objectForKey:aKey];
	}
	else return @"";
}

- (void) fltSN:(int)i setObject:(id)anObject forKey:(id)aKey
{
	if(i>=0 && i<8){
		id entry = [fltSNs objectAtIndex:i];
		id oldValue = [self fltSN:i objectForKey:aKey];
		if(oldValue)[[[self undoManager] prepareWithInvocationTarget:self] fltSN:i setObject:oldValue forKey:aKey];
		[entry setObject:anObject forKey:aKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinModelSNTablesChanged object:self userInfo:nil];
		
	}
}

- (id) preAmpSN:(int)i objectForKey:(id)aKey
{
	if(i>=0 && i<24){
		return [[preAmpSNs objectAtIndex:i] objectForKey:aKey];
	}
	else return @"";
}
- (void) preAmpSN:(int)i setObject:(id)anObject forKey:(id)aKey
{
	if(i>=0 && i<24){
		id entry = [preAmpSNs objectAtIndex:i];
		id oldValue = [self preAmpSN:i objectForKey:aKey];
		if(oldValue)[[[self undoManager] prepareWithInvocationTarget:self] preAmpSN:i setObject:oldValue forKey:aKey];
		[entry setObject:anObject forKey:aKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinModelSNTablesChanged object:self userInfo:nil];
	}
}

- (id) osbSN:(int)i objectForKey:(id)aKey
{
	if(i>=0 && i<4){
		return [[osbSNs objectAtIndex:i] objectForKey:aKey];
	}
	else return @"";
}
- (void) osbSN:(int)i setObject:(id)anObject forKey:(id)aKey
{
	if(i>=0 && i<4){
		id entry = [osbSNs objectAtIndex:i];
		id oldValue = [self osbSN:i objectForKey:aKey];
		if(oldValue)[[[self undoManager] prepareWithInvocationTarget:self] osbSN:i setObject:oldValue forKey:aKey];
		[entry setObject:anObject forKey:aKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinModelSNTablesChanged object:self userInfo:nil];
	}
}
- (id) otherSNForKey:(id)aKey
{
	return [otherSNs objectForKey:aKey];
}

- (void) setOtherSNObject:(id)anObject forKey:(id)aKey
{
	id oldValue = [self otherSNForKey:aKey];
	if(oldValue)[[[self undoManager] prepareWithInvocationTarget:self] setOtherSNObject:oldValue forKey:aKey];
	[otherSNs setObject:anObject forKey:aKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinModelSNTablesChanged object:self userInfo:nil];
}

- (void) validateSNArrays
{
	if(!fltSNs){
		fltSNs = [[NSMutableArray array] retain];
		int i;
		for(i=0;i<8;i++){
			[fltSNs addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
							   [NSNumber numberWithInt:i+2], @"kFltSlot",
							   @"-",						 @"kFltSN",
							   @"-",						 @"kORBSN", nil]];
		}
	}
	if(!preAmpSNs){
		preAmpSNs = [[NSMutableArray array] retain];
		int i;
		for(i=0;i<24;i++){
			[preAmpSNs addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
							   [NSNumber numberWithInt:i], @"kPreAmpMod",
							   @"-",					   @"kPreAmpSN", nil]];
		}
	}
	if(!osbSNs){
		osbSNs = [[NSMutableArray array] retain];
		int i;
		for(i=0;i<4;i++){
			[osbSNs addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:i], @"kOSBSlot",
								 @"-",						@"kOSBSN", nil]];
		}
	}
	if(!otherSNs){
		otherSNs = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
							  @"-",			@"kSltSN",
							  @"-",			@"kWaferSN", nil] retain];
	}
}

- (void) handleOldPrimaryMapFormats:(NSString*)aPath
{
	//the old format had the preamp s/n included.
	NSString* contents = [NSString stringWithContentsOfFile:[aPath stringByExpandingTildeInPath] encoding:NSASCIIStringEncoding error:nil];
	contents = [[contents componentsSeparatedByString:@"\r"] componentsJoinedByString:@"\n"];
	contents = [[contents componentsSeparatedByString:@"\n\n"] componentsJoinedByString:@"\n"];
    NSArray*  lines = [contents componentsSeparatedByString:@"\n"];
    for(id aLine in lines){
        aLine = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        aLine = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
        if([aLine length] && [aLine characterAtIndex:0] != '#'){
			NSArray* parts =  [aLine componentsSeparatedByString:@","];
			if([parts count] != 13) break;
			if(![aLine hasPrefix:@"--"]){
				int preAmpModule = [[parts objectAtIndex:6] intValue];
				NSString* preAmpSN = [parts objectAtIndex:8];
				if(preAmpModule < [preAmpSNs count]){
					id entry = [preAmpSNs objectAtIndex:preAmpModule];
					[entry setObject:preAmpSN forKey:@"kPreAmpSN"];
				}
			}
        }
    }	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSegmentGroupMapReadNotification object:self];
}

- (NSString*) validateHWMapPath:(NSString*)aPath
{
	if([aPath hasSuffix:@"_FltOrbSN"])	 return [aPath substringToIndex:[aPath length]-9];
	if([aPath hasSuffix:@"_PreampSN"])	 return [aPath substringToIndex:[aPath length]-9];
	if([aPath hasSuffix:@"_OsbSN"])		 return [aPath substringToIndex:[aPath length]-6];
	if([aPath hasSuffix:@"_SltWaferSN"]) return [aPath substringToIndex:[aPath length]-11];
	return aPath;
}

- (void) readAuxFiles:(NSString*)aPath 
{
	aPath = [aPath stringByDeletingPathExtension];
	NSFileManager* fm = [NSFileManager defaultManager];
	if([fm fileExistsAtPath:FLTORBSNFILE(aPath)]){
		//read in the FLT/ORB Serial Numbers
		NSArray* lines  = [self linesInFile:FLTORBSNFILE(aPath)];
		for(id aLine in lines){
			if([aLine length] && [aLine characterAtIndex:0] != '#'){ //skip comments
				NSArray* parts =  [aLine componentsSeparatedByString:@","];
				if([parts count]>=3){
					int index = [[parts objectAtIndex:0] intValue]-2;
					if(index<8){
						NSMutableDictionary* dict = [fltSNs objectAtIndex:index];
						[dict setObject:[parts objectAtIndex:0] forKey:@"kFltSlot"];
						[dict setObject:[parts objectAtIndex:1] forKey:@"kFltSN"];
						[dict setObject:[parts objectAtIndex:2] forKey:@"kORBSN"];
					}
				}
			}
		}
	}
	if([fm fileExistsAtPath:OSBSNFILE(aPath)]){
		//read in the OSB Serial Numbers
		NSArray* lines  = [self linesInFile:OSBSNFILE(aPath)];
		for(id aLine in lines){
			if([aLine length] && [aLine characterAtIndex:0] != '#'){ //skip comments
				NSArray* parts =  [aLine componentsSeparatedByString:@","];
				if([parts count]>=2){
					int index = [[parts objectAtIndex:0] intValue];
					if(index<4){
						NSMutableDictionary* dict = [osbSNs objectAtIndex:index];
						[dict setObject:[parts objectAtIndex:0] forKey:@"kOSBSlot"];
						[dict setObject:[parts objectAtIndex:1] forKey:@"kOSBSN"];
					}
				}
			}
		}
	}
	if([fm fileExistsAtPath:PREAMPSNFILE(aPath)]){
		//read in the PreAmp Serial Numbers
		NSArray* lines  = [self linesInFile:PREAMPSNFILE(aPath)];
		for(id aLine in lines){
			if([aLine length] && [aLine characterAtIndex:0] != '#'){ //skip comments
				NSArray* parts =  [aLine componentsSeparatedByString:@","];
				if([parts count]>=2){
					int index = [[parts objectAtIndex:0] intValue];
					if(index<24){
						NSMutableDictionary* dict = [preAmpSNs objectAtIndex:index];
						[dict setObject:[parts objectAtIndex:0] forKey:@"kPreAmpMod"];
						[dict setObject:[parts objectAtIndex:1] forKey:@"kPreAmpSN"];
					}
				}
			}
		}
	}
	if([fm fileExistsAtPath:SLTWAFERSNFILE(aPath)]){
		//read in the Slt and Wafer Serial Numbers
		NSArray* lines  = [self linesInFile:SLTWAFERSNFILE(aPath)];
		for(id aLine in lines){
			if([aLine length] && [aLine characterAtIndex:0] != '#'){ //skip comments
				NSArray* parts =  [aLine componentsSeparatedByString:@","];
				if([parts count]>=2){
					[otherSNs setObject:[parts objectAtIndex:0] forKey:@"kSltSN"];
					[otherSNs setObject:[parts objectAtIndex:1] forKey:@"kWaferSN"];
				}
			}
		}
	}
}

- (void) saveAuxFiles:(NSString*)aPath 
{
	aPath = [aPath stringByDeletingPathExtension];
	NSFileManager* fm = [NSFileManager defaultManager];
	NSMutableString* contents = [NSMutableString string];
	//save the FLT/ORB Serial Numbers
	if([fm fileExistsAtPath: FLTORBSNFILE(aPath)])[fm removeItemAtPath:FLTORBSNFILE(aPath) error:nil];
	for(id item in fltSNs)[contents appendFormat:@"%@,%@,%@\n",[item objectForKey:@"kFltSlot"],[item objectForKey:@"kFltSN"],[item objectForKey:@"kORBSN"]];
	NSData* data = [contents dataUsingEncoding:NSASCIIStringEncoding];
	[fm createFileAtPath:FLTORBSNFILE(aPath) contents:data attributes:nil];
	
	//save the OSB Serial Numbers
	contents = [NSMutableString string];
	if([fm fileExistsAtPath: OSBSNFILE(aPath)])[fm removeItemAtPath:OSBSNFILE(aPath) error:nil];
	for(id item in osbSNs)[contents appendFormat:@"%@,%@\n",[item objectForKey:@"kOSBSlot"],[item objectForKey:@"kOSBSN"]];
	data = [contents dataUsingEncoding:NSASCIIStringEncoding];
	[fm createFileAtPath:OSBSNFILE(aPath) contents:data attributes:nil];

	//save the Preamp Serial Numbers
	contents = [NSMutableString string];
	if([fm fileExistsAtPath: PREAMPSNFILE(aPath)])[fm removeItemAtPath:PREAMPSNFILE(aPath) error:nil];
	for(id item in preAmpSNs)[contents appendFormat:@"%@,%@\n",[item objectForKey:@"kPreAmpMod"],[item objectForKey:@"kPreAmpSN"]];
	data = [contents dataUsingEncoding:NSASCIIStringEncoding];
	[fm createFileAtPath:PREAMPSNFILE(aPath) contents:data attributes:nil];
	
	//save the Slt and Wafer Serial Numbers
	contents = [NSMutableString string];
	if([fm fileExistsAtPath: SLTWAFERSNFILE(aPath)])[fm removeItemAtPath:SLTWAFERSNFILE(aPath) error:nil];
	[contents appendFormat:@"%@,%@\n",[otherSNs objectForKey:@"kSltSN"],[otherSNs objectForKey:@"kWaferSN"]];
	data = [contents dataUsingEncoding:NSASCIIStringEncoding];
	[fm createFileAtPath:SLTWAFERSNFILE(aPath) contents:data attributes:nil];
	
}

- (NSArray*) linesInFile:(NSString*)aPath
{
	NSString* contents = [NSString stringWithContentsOfFile:[aPath stringByExpandingTildeInPath] encoding:NSASCIIStringEncoding error:nil];
	contents = [[contents componentsSeparatedByString:@"\r"] componentsJoinedByString:@"\n"];
	contents = [[contents componentsSeparatedByString:@"\n\n"] componentsJoinedByString:@"\n"];
    return [contents componentsSeparatedByString:@"\n"];
}

@end

