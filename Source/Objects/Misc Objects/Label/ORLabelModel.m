//
//  ORLabelModel.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 19 2005.
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
#import "ORLabelModel.h"
#import "TimedWorker.h"
#import "ORCommandCenter.h"

NSString* ORLabelModelControllerStringChanged	 = @"ORLabelModelControllerStringChanged";
NSString* ORLabelModelTextSizeChanged			 = @"ORLabelModelTextSizeChanged";
NSString* ORLabelModelLabelChangedNotification   = @"ORLabelModelLabelChangedNotification";
NSString* ORLabelLock							 = @"ORLabelLock";
NSString* ORLabelPollRateChanged				 = @"ORLabelPollRateChanged";
NSString* ORLabelModelLabelTypeChanged			 = @"ORLabelModelLabelTypeChanged";
NSString* ORLabelModelUpdateIntervalChanged		 = @"ORLabelModelUpdateIntervalChanged";
NSString* ORLabelModelFormatChanged				 = @"ORLabelModelFormatChanged";

@interface ORLabelModel (private)
- (NSString*) stringToDisplay;
@end

@implementation ORLabelModel

#pragma mark ���initialization
- (id) init
{
    self = [super init];
    return self;
}

-(void) dealloc
{
    [controllerString release];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [poller stop];
    [poller release];
	[displayValue release];
    [super dealloc];
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
	if(labelType == kDynamiclabel){
		[poller runWithTarget:self selector:@selector(updateValue)];
	}
}

- (void) sleep
{
    [super sleep];
    [poller stop];
}

- (NSString*) helpURL
{
	return @"Subsystems/Containers_and_Dynamic_Labels.html";
}

- (NSString*) label
{
	return label;
}

- (NSString*) elementName
{
	return @"Text Label";
}

- (int) state
{
	return 0;
}
- (NSString*) comment
{
	return label;
}

- (void) setComment:(NSString*)aComment
{
	[self setLabel:aComment];
}

- (NSString*) description:(NSString*)prefix
{
    return [NSString stringWithFormat:@"%@%@ %d",prefix,[self elementName],[self uniqueIdNumber]];
}


- (id) stateValue
{
	return 0;
}

- (NSString*) fullHwName
{
    return @"N/A";
}

- (int) compareStringTo:(id)anElement usingKey:(NSString*)aKey
{
    NSString* ourKey   = [self valueForKey:aKey];
    NSString* theirKey = [anElement valueForKey:aKey];
    if(!ourKey && theirKey)         return 1;
    else if(ourKey && !theirKey)    return -1;
    else if(!ourKey || !theirKey)   return 0;
    return [ourKey compare:theirKey];
}

- (void) makeMainController
{
    [self linkToController:@"ORLabelController"];
}

- (void) doCmdClick:(id)sender
{
	if(controllerString){
		id obj = [[self document] findObjectWithFullID:controllerString];
		if([obj respondsToSelector:@selector(makeMainController)]){
			[obj makeMainController];
		}
	}
}

#pragma mark ***Accessors

- (NSString*) controllerString
{
    return controllerString;
}

- (void) setControllerString:(NSString*)aControllerString
{
    [[[self undoManager] prepareWithInvocationTarget:self] setControllerString:controllerString];
    
    [controllerString autorelease];
    controllerString = [aControllerString copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabelModelControllerStringChanged object:self];
}

- (int) updateInterval
{
	return updateInterval;
}

- (void) setUpdateInterval:(int) anInterval
{
	if(anInterval==0)anInterval = 1;
    [[[self undoManager] prepareWithInvocationTarget:self] setUpdateInterval:updateInterval];
	updateInterval = anInterval;
	if(labelType == kDynamiclabel){
		[self setPollingInterval:updateInterval];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORLabelModelUpdateIntervalChanged object:self];
}

- (int) textSize
{
    return textSize;
}

- (void) setTextSize:(int)aTextSize
{
	if(aTextSize==0)aTextSize = 16;
	else if(aTextSize<9)aTextSize = 9;
	else if(aTextSize>36)aTextSize = 36;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setTextSize:textSize];
    
    textSize = aTextSize;
	
    [self setUpImage];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabelModelTextSizeChanged object:self];

}

- (void) setLabel:(NSString*)aLabel
{
    if(!aLabel)aLabel = @"Text Box";
    [[[self undoManager] prepareWithInvocationTarget:self] setLabel:label];
    
    [label autorelease];
    label = [aLabel copy];
	if(!scheduledForUpdate){
		scheduledForUpdate = YES;
		[self performSelector:@selector(setUpImage) withObject:nil afterDelay:1];
	}
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORLabelModelLabelChangedNotification
                              object:self];
}

- (void) setLabelNoNotify:(NSString*)aLabel
{
    if(!aLabel)aLabel = @"Text Box";
    [label autorelease];
    label = [aLabel copy];
    [self setUpImage];
}

- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian
{
    return  [aGuardian isMemberOfClass:NSClassFromString(@"ORGroup")]           || 
			[aGuardian isMemberOfClass:NSClassFromString(@"ORProcessModel")]	||
            [aGuardian isMemberOfClass:NSClassFromString(@"ORContainerModel")];
}


- (void) setUpImage
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setupImage) object:nil];

    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each Label can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
	if(label){
		NSString* s = [self stringToDisplay];

		NSAttributedString* n = [[NSAttributedString alloc] 
								initWithString:[s length]?s:@"Text Label"
									attributes:[NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Geneva"  size:textSize] forKey:NSFontAttributeName]];
		
		NSSize theSize = [n size];

		NSImage* i = [[NSImage alloc] initWithSize:theSize];
		[i lockFocus];
		
			
		[n drawInRect:NSMakeRect(0,0,theSize.width,theSize.height)];
		[n release];
		[i unlockFocus];
		[self setImage:i];
		[i release];
    }
	else {
		[self setImage:[NSImage imageNamed:@"Label"]];
	}
    [[NSNotificationCenter defaultCenter]
                postNotificationName:OROrcaObjectImageChanged
                              object:self];
	scheduledForUpdate = NO;
}

- (void) setImage:(NSImage*)anImage
{
	[super setImage:anImage];
	if(anImage){
		[highlightedImage release];
		highlightedImage = [[NSImage alloc] initWithSize:[anImage size]];
		[highlightedImage lockFocus];
		NSString* s = [self stringToDisplay];
		NSAttributedString* n = [[NSAttributedString alloc] 
								 initWithString:[s length]?s:@"Text Label"
								 attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Geneva"  size:textSize],NSFontAttributeName,
											 [NSColor colorWithCalibratedRed:.5 green:.5 blue:.5 alpha:.3],NSBackgroundColorAttributeName,nil]];
		
		NSSize theSize = [n size];
		[n drawInRect:NSMakeRect(0,0,theSize.width,theSize.height)];
		[n release];
		[highlightedImage unlockFocus];
	}
}


- (int) labelType
{
	return labelType;
}

- (void) setLabelType:(int)aType
{
	[[[self undoManager] prepareWithInvocationTarget:self] setLabelType:labelType];
	labelType = aType;
	[displayValue release];
	displayValue = nil;
	if(labelType == kDynamiclabel){
		[self setPollingInterval:updateInterval];
	}
	else {
		[self setLabel:[self label]];
		[poller stop];
		[poller release];
		poller = nil;
		[self setUpImage];
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabelModelLabelTypeChanged object:self];
}

- (NSString*) displayFormat
{
	if(!displayFormat)return @"";
	else return displayFormat;
}


- (void) setDisplayFormat:(NSString*)aFormat
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLabel:label];
    [displayFormat autorelease];
    displayFormat = [aFormat copy];
	[self setUpImage];
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORLabelModelFormatChanged
	 object:self];
}

- (TimedWorker *) poller
{
    return poller; 
}

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
    if(!poller){
        [self makePoller:(float)anInterval];
    }
    else [poller setTimeInterval:anInterval];
    
	[poller stop];
	[self updateValue];
    [poller runWithTarget:self selector:@selector(updateValue)];
}


- (void) makePoller:(float)anInterval
{
    [self setPoller:[TimedWorker TimeWorkerWithInterval:anInterval]];
}

- (void) updateValue
{
	id aValue = nil;
	@try {
		aValue = [[ORCommandCenter sharedCommandCenter] executeSimpleCommand:[self label]];
	}
	@catch (NSException* e){
	}
	if(![aValue isEqual:displayValue]){
		[aValue retain];
		[displayValue release];
		displayValue = aValue;
		[self setUpImage];
	}
}

#pragma mark ���Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	
    [self setLabel:				[decoder decodeObjectForKey:@"label"]];
	[self setLabelType:			[decoder decodeIntForKey:	@"labelType"]];
    [self setDisplayFormat:		[decoder decodeObjectForKey:@"displayFormat"]];
    [self setTextSize:			[decoder decodeIntForKey:	@"textSize"]];
    [self setUpdateInterval:	[decoder decodeIntForKey:	@"updateInterval"]];
    [self setControllerString:	[decoder decodeObjectForKey:@"controllerString"]];
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:label				forKey:@"label"];
    [encoder encodeObject:displayFormat		forKey:@"displayFormat"];
    [encoder encodeInt:textSize				forKey:@"textSize"];
	[encoder encodeInt:labelType			forKey:@"labelType"];
    [encoder encodeObject:controllerString	forKey:@"controllerString"];
	[encoder encodeInt:updateInterval		forKey:@"updateInterval"];
}

@end

@implementation ORLabelModel (private)
- (NSString*) stringToDisplay
{
	NSString* s = @"";
	NSString* f;
	if(labelType == kStaticLabel){
		s = label;
	}
	else {
		if([displayValue isKindOfClass:NSClassFromString(@"NSNumber")]){
			if([displayFormat length])f = displayFormat;
			else f = @"%.2f";
			if([f rangeOfString:@"%@"].location != NSNotFound){
				s = [NSString stringWithFormat:f,displayValue];
			}
			else if([f rangeOfString:@"%d"].location != NSNotFound){
				s = [NSString stringWithFormat:f,[displayValue intValue]];
			}
			else {
				s = [NSString stringWithFormat:f,[displayValue floatValue]];
			}
		}
		else {
			if([displayFormat length])f = displayFormat;
			else f = @"%@";
			s = [NSString stringWithFormat:f,displayValue];
		}
	}
	return s;
}
@end
