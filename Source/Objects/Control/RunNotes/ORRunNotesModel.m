//
//  ORRunNotesModel.m
//  Orca
//
//  Created by Mark Howe on Tues Feb 09 2009.
//  Copyright (c) 2009 University of North Carolina. All rights reserved.
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
#import "ORRunNotesModel.h"
#import "ORDataPacket.h"
#import "ORDataProcessing.h"

#pragma mark •••Local Strings
static NSString* ORRunNotesInConnector 	= @"Data Task In Connector";
static NSString* ORRunNotesDataOut      = @"Data Task Data Out Connector";

NSString* ORRunNotesModelDoNotOpenChanged	 = @"ORRunNotesModelDoNotOpenChanged";
NSString* ORRunNotesModelIgnoreValuesChanged = @"ORRunNotesModelIgnoreValuesChanged";
NSString* ORRunNotesModelModalChanged		 = @"ORRunNotesModelModalChanged";
NSString* ORRunNotesItemsAdded				 = @"ORRunNotesItemsAdded";
NSString* ORRunNotesItemsRemoved		     = @"ORRunNotesItemsRemoved";
NSString* ORRunNotesCommentsChanged			 = @"ORRunNotesCommentsChanged";
NSString* ORRunNotesListLock				 = @"ORRunNotesListLock";
NSString* ORRunNotesItemChanged				 = @"ORRunNotesItemChanged";

@implementation ORRunNotesModel

#pragma mark •••initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc
{
	[items release];
    [super dealloc];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(8,[self frame].size.height-[self frame].size.height/2+kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORRunNotesInConnector];
    [aConnector setOffColor:[NSColor purpleColor]];
    [aConnector setConnectorType:'RUNC'];
    [aConnector release];
    
    aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize-2,[self frame].size.height-[self frame].size.height/2+kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORRunNotesDataOut];
	[aConnector setIoType:kOutputConnector];
    [aConnector setOffColor:[NSColor purpleColor]];
    [aConnector setConnectorType:'RUNC'];
    [aConnector release];
}

- (BOOL) solitaryObject
{
    return YES;
}

- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
	if(ignoreValues || doNotOpen){
		NSImage* aCachedImage = [NSImage imageNamed:@"RunNotes"];
		NSSize theIconSize = [aCachedImage size];
		
		NSImage* i = [[NSImage alloc] initWithSize:theIconSize];
		[i lockFocus];
		
        [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
		NSImage* aNoticeImage = [NSImage imageNamed:@"notice"];
		[aNoticeImage drawAtPoint:NSMakePoint([i size].width/2-[aNoticeImage size].width/2 ,[i size].height/2-[aNoticeImage size].height) fromRect:[aNoticeImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
		
		[i unlockFocus];
		
		[self setImage:i];
		[i release];
		
	}
	else [self setImage:[NSImage imageNamed:@"RunNotes"]];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORForceRedraw object: self];
}


- (void) makeMainController
{
    [self linkToController:@"ORRunNotesController"];
}

- (NSString*) helpURL
{
	return @"Data_Chain/Run_Notes.html";
}

#pragma mark ***Accessors
- (BOOL) doNotOpen
{
    return doNotOpen;
}

- (void) setDoNotOpen:(BOOL)aDoNotOpen
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDoNotOpen:doNotOpen];
    
    doNotOpen = aDoNotOpen;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunNotesModelDoNotOpenChanged object:self];
	
	[self setUpImage];
}

- (BOOL) ignoreValues
{
    return ignoreValues;
}

- (void) setIgnoreValues:(BOOL)aIgnoreValues
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIgnoreValues:ignoreValues];
    
    ignoreValues = aIgnoreValues;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunNotesModelIgnoreValuesChanged object:self];
	[self setUpImage];
}

- (BOOL) isModal
{
	return isModal;
}

- (void) setIsModal:(BOOL)state
{
	isModal = state;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRunNotesModelModalChanged object:self];
}

- (BOOL) runModals
{
	BOOL continueRun = NO;
	if(doNotOpen)continueRun = YES;
	else {
		[self makeMainController];
		NSWindow* myWindow = [[self findController] window];
		[myWindow center];
		if(!myWindow)continueRun = YES;
		else {
			[self setIsModal:YES];
			modalResult = 0;
			NSModalSession session = [NSApp beginModalSessionForWindow:myWindow];
			for (;;) {
				NSInteger result = [NSApp runModalSession:session];
				if (result != NSRunContinuesResponse){
					break;
				}
			}
			[NSApp endModalSession:session];
			[self setIsModal:NO];
			continueRun = modalResult;
		}
	}	
	return continueRun;
}

- (void) cancelRun
{
	NSLog(@"RunNotes canceling run\n");
	[NSApp stopModalWithCode:0]; //Arg... seems to have no effect
	modalResult = 0;			 //so we have to set this variable
	[self setIsModal:NO];
}

- (void) continueWithRun
{
	[NSApp stopModalWithCode:1]; //Arg... seems to have no effect
	modalResult = 1;			 //so we have to set this variable
	[self setIsModal:NO];
}


- (NSString*) comments
{
	if(!comments)return @"";
	return comments;
}

- (void) setCommentsNoNote:(NSString*)aString
{
	if(!aString)aString= @"";
    [comments autorelease];
    comments = [aString copy];	
}

- (void) setComments:(NSString*)aString
{
	[[[self undoManager] prepareWithInvocationTarget:self] setComments:comments];
    
    [comments autorelease];
    comments = [aString copy];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunNotesCommentsChanged object: self];
}

- (void) addItem
{
	if(!items) items= [[NSMutableArray array] retain];
	id newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Label",@"Label",@"0",@"Value",nil];
	[self addItem:newItem atIndex:[items count]];
}

- (void) addItem:(id)anItem atIndex:(int)anIndex
{
	if(!items) items= [[NSMutableArray array] retain];
	if([items count] == 0)anIndex = 0;
	anIndex = MIN(anIndex,[items count]);
	[[[self undoManager] prepareWithInvocationTarget:self] removeItemAtIndex:anIndex];
	[items insertObject:anItem atIndex:anIndex];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Index"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunNotesItemsAdded object:self userInfo:userInfo];
}

- (void) removeItemAtIndex:(int) anIndex
{
	id anItem = [items objectAtIndex:anIndex];
	[[[self undoManager] prepareWithInvocationTarget:self] addItem:anItem atIndex:anIndex];
	[items removeObjectAtIndex:anIndex];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Index"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunNotesItemsRemoved object:self userInfo:userInfo];
}

- (id) itemAtIndex:(int)anIndex
{
	if(anIndex>=0 && anIndex<[items count])return [items objectAtIndex:anIndex];
	else return nil;
}

- (unsigned long) itemCount
{
	return [items count];
}

- (NSString*) commonScriptMethods { return methodsInCommonSection(self); }


#pragma mark Scripting Methods
- (void) commonScriptMethodSectionBegin { }

- (void) change:(id)aKey toValue:(id)aValue
{
	if(!items) items= [[NSMutableArray array] retain];
 	for(id anObj in items){
		if([[anObj objectForKey:@"Label"] isEqual:aKey]){
            [anObj setObject:aValue forKey:@"Value"];
            [[NSNotificationCenter defaultCenter] postNotificationName:ORRunNotesItemChanged object:self userInfo:nil];
			return;
		}
	}
    //if we get here there, the key wasn't found. Add it
    [self addObject:aValue forKey:aKey];
}

- (void) addObject:(id)anItem forKey:(id)aKey
{
    [[self undoManager] disableUndoRegistration];
	if(!items) items= [[NSMutableArray array] retain];
    for(id anObj in items){
		if([[anObj objectForKey:@"Label"] isEqual:aKey]){
			int index = [items indexOfObject:anObj];
			[self removeItemAtIndex:index];
			break;
		}
	}
	id newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:aKey,@"Label",anItem,@"Value",nil];
	[self addItem:newItem atIndex:[items count]];
    [[self undoManager] enableUndoRegistration];
}

- (void) removeObjectWithKey:(id)aKey
{
    [[self undoManager] enableUndoRegistration];
	for(id anObj in items){
		if([[anObj objectForKey:@"Label"] isEqual:aKey]){
			int index = [items indexOfObject:anObj];
			[self removeItemAtIndex:index];
			break;
		}
	}
    [[self undoManager] disableUndoRegistration];
}

- (void) commonScriptMethodSectionEnd { }


#pragma mark •••Run Management
//mostly just pass-thrus for the run control commands.
- (void) runTaskStarted:(id)userInfo
{	
	if(!ignoreValues){
		NSMutableDictionary* runNotes = [NSMutableDictionary dictionary];
		[runNotes setObject:[self comments] forKey:@"comments"];
		for(id obj in items){
			[runNotes setObject:[obj objectForKey:@"Value"] forKey:[obj objectForKey:@"Label"]];
		}
		[[userInfo objectForKey:kHeader] setObject:runNotes forKey:@"RunNotes"];
	}
		
	nextObject =  [self objectConnectedTo: ORRunNotesDataOut]; //cach for a little more efficiency
    [nextObject runTaskStarted:userInfo];
}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo { [nextObject takeData:aDataPacket userInfo:userInfo]; }
- (void) runIsStopping:(id)userInfo		{ [nextObject runIsStopping:userInfo];  }
- (void) runTaskStopped:(id)userInfo	{ [nextObject runTaskStopped:userInfo]; }
- (void) closeOutRun:(id)userInfo		{ [nextObject closeOutRun:userInfo];    }
- (BOOL) doneTakingData					{ return [nextObject doneTakingData];   }
- (void) setRunMode:(int)runMode		{ [[self objectConnectedTo: ORRunNotesDataOut] setRunMode:runMode]; }

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
	
	items = [[decoder decodeObjectForKey:@"items"] retain];
	
    [self setDoNotOpen:		[decoder decodeBoolForKey:@"doNotOpen"]];
    [self setIgnoreValues:	[decoder decodeBoolForKey:@"ignoreValues"]];
	[self setComments:		[decoder decodeObjectForKey:@"comments"]];
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeBool:doNotOpen		forKey:@"doNotOpen"];
	[encoder encodeBool:ignoreValues	forKey:@"ignoreValues"];
	[encoder encodeObject:items			forKey:@"items"];
	[encoder encodeObject:comments		forKey:@"comments"];
}

@end



