//
//  ORRangeTimerModel.m
//  Orca
//
//  Created by Mark Howe on Fri Sept 8, 2006.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#import "ORRangeTimerModel.h"
#import "ORProcessOutConnector.h"
#import "ORProcessModel.h"
#import "ORProcessThread.h"
#import "ORAdcProcessing.h"

#import <Message/NSMailDelivery.h>

NSString* ORRangeTimerModelEnableMailChanged = @"ORRangeTimerModelEnableMailChanged";
NSString* ORRangeTimerModelDirectionChanged  = @"ORRangeTimerModelDirectionChanged";
NSString* ORRangeTimerModelLimitChanged		 = @"ORRangeTimerModelLimitChanged";
NSString* ORRangeTimerModelDeadbandChanged	 = @"ORRangeTimerModelDeadbandChanged";
NSString* ORRangeTimerModelAddressesChanged  = @"ORRangeTimerModelAddressesChanged";

NSString* ORRangeTimerModelOKConnection     = @"ORRangeTimerModelOKConnection";

@interface ORRangeTimerModel (private)
- (void) eMailThread:(id)userInfo;
@end


@implementation ORRangeTimerModel

- (void) dealloc
{
    [eMailList release];
	[startTime release];
	[deadTimeStart release];
	[super dealloc];
}

-(void)makeConnectors
{  
    ORProcessOutConnector* aConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,[self frame].size.height/2 - kConnectorSize/2+5) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORRangeTimerModelOKConnection];
    [ aConnector setConnectorType: 'LP2 ' ];
    [ aConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [aConnector release];

}

- (NSString*) elementName
{
	return @"RangeTimer";
}


- (NSArray*) validObjects
{
    return [[self document] collectObjectsConformingTo:@protocol(ORAdcProcessing)];
}

- (void) makeMainController
{
    [self linkToController:@"ORRangeTimerController"];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"rangeTimer"]];
    [self addOverLay];
}

- (double) hwValue
{
	return hwValue;
}

- (void) viewSource
{
	[[self hwObject] showMainInterface];
}

#pragma mark ���Accessors

- (NSMutableArray*) eMailList
{
    return eMailList;
}

- (unsigned) addressCount
{
	return [eMailList count];
}
- (id)   addressEntry:(unsigned)index
{
	return [eMailList objectAtIndex:index];
}

- (void) addAddress
{
	if(!eMailList){
		[self setEMailList:[NSMutableArray array]];
	}
	[eMailList addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"<eMail>",@"Address",[NSNumber numberWithFloat:0],@"TimeLimit",nil]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRangeTimerModelAddressesChanged object:self];
	
}

- (void) removeAddressAtIndex:(int) anIndex
{
	[eMailList removeObjectAtIndex:anIndex];
}

- (void) setEMailList:(NSMutableArray*)aEMailList
{
    [aEMailList retain];
    [eMailList release];
    eMailList = aEMailList;
}
- (void) disableEMail
{
    [[self undoManager] disableUndoRegistration];
	[self setEnableMail:NO];
    [[self undoManager] enableUndoRegistration];
}

- (BOOL) enableMail
{
    return enableMail;
}

- (void) setEnableMail:(BOOL)aEnableMail
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnableMail:enableMail];
    
    enableMail = aEnableMail;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRangeTimerModelEnableMailChanged object:self];
}

- (int) direction
{
    return direction;
}

- (void) setDirection:(int)aDirection
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDirection:direction];
    
    direction = aDirection;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRangeTimerModelDirectionChanged object:self];
}

- (float) limit
{
    return limit;
}

- (void) setLimit:(float)aLimit
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLimit:limit];
    
    limit = aLimit;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRangeTimerModelLimitChanged object:self];
}

- (int) deadband
{
    return deadband;
}

- (void) setDeadband:(int)aDeadband
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDeadband:deadband];
    
    deadband = aDeadband;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRangeTimerModelDeadbandChanged object:self];
}

- (void) setDeadTimeStart:(NSDate*)aDate
{
	[aDate retain];
	[deadTimeStart release];
	deadTimeStart = aDate;
}
- (void) setStartTime:(NSDate*)aDate
{
	[aDate retain];
	[startTime release];
	startTime = aDate;
}

- (BOOL) isTrueEndNode
{
    return [self objectConnectedTo:ORRangeTimerModelOKConnection] == nil;
}

- (void) processIsStarting
{
    [super processIsStarting];
    [ORProcessThread registerInputObject:self];
	lastOutOfBounds = NO;
	timing			= NO;
	firstTime		= YES;
	sentMessage     = NO;
}
//--------------------------------
//runs in the process logic thread
- (int) eval
{
	if(!alreadyEvaluated){
		alreadyEvaluated = YES;
		BOOL updateNeeded = NO;
		BOOL outOfBounds;
		BOOL newState = NO;
		if(![guardian inTestMode] && hwObject!=nil){
			double theConvertedValue  = [hwObject convertedValue:[self bit]]; //reads the hw
			if(fabs(theConvertedValue-hwValue)>.1)updateNeeded = YES;
			hwValue = theConvertedValue;
			if(direction==0)outOfBounds = hwValue>limit;
			else		    outOfBounds = hwValue<limit;
			
			//handle special case where we start out of bounds
			if(firstTime && outOfBounds){
				firstTime = NO;
				[self setDeadTimeStart:[NSDate date]];
				lastOutOfBounds = outOfBounds;
			}
						
			//check for crossing the limit line
			if(lastOutOfBounds != outOfBounds){
				[self setDeadTimeStart:[NSDate date]];
				lastOutOfBounds = outOfBounds;
			}
			
			NSDate* now = [NSDate date];
			NSTimeInterval timeInDeadBand = [now timeIntervalSinceDate:deadTimeStart];
			if(timeInDeadBand>deadband){
				//OK the deadband time has passed.. check for whether or not to send
				//the message
				if(!timing && outOfBounds){
					[self setStartTime:[NSDate date]];
					timing		= YES;
					sentMessage = NO;
					newState	= YES;
				}
				else if(timing && outOfBounds){
					newState	= YES;
				}
				else if(timing && !outOfBounds){
					timing		= NO;
					newState	= NO;
					if(!sentMessage){
						sentMessage = YES;
						NSTimeInterval timeOutOfBounds = [now timeIntervalSinceDate:startTime] - deadband;
						NSString* theContent = [NSString stringWithFormat:[self comment],timeOutOfBounds];
						theContent = [theContent stringByAppendingFormat:@"\n\nLevel went %@ the limit value of %.2f at %@\n and returned %@ the limit %.2f seconds later\n\n",
								direction?@"below":@"above",
								limit,
								startTime,
								direction?@"above":@"below",
								timeOutOfBounds];
						theContent = [theContent stringByAppendingFormat:@"The dead band time is: %d seconds.\n\n",deadband];
						
						theContent = [theContent stringByAppendingFormat:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];						
						theContent = [theContent stringByAppendingFormat:@"This message generated from %@ %d\n",[self className],[self uniqueIdNumber]];
						theContent = [theContent stringByAppendingFormat:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];						
						
						NSDictionary* item;
						NSEnumerator* e = [eMailList objectEnumerator];
						while(item = [e nextObject]){
							NSString* address = [item objectForKey:@"Address"];
							float     theLimit= [[item objectForKey:@"TimeLimit"] floatValue];
							if(	!address || 
								[address length] == 0 ||
								[address isEqualToString:@"<eMail>"] ||
								![self enableMail] ||
								timeOutOfBounds < theLimit)continue;
							NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:address,@"Address",theContent,@"Message",nil];
							[NSThread detachNewThreadSelector:@selector(eMailThread:) toTarget:self withObject:userInfo];
						}
					}
				}
			}
		}
		
		if((newState == [self state]) && updateNeeded){
			//if the state will not post an update, then do it here.
			[self performSelectorOnMainThread:@selector(postStateChange) withObject:nil waitUntilDone:NO];
		}
		[self setState: newState];
		[self setEvaluatedState: newState];
	}
	return evaluatedState;
}
//--------------------------------

- (void) addOverLay
{
    if(!guardian) return;
    
    NSImage* aCachedImage = [self image];
    NSSize theIconSize = [aCachedImage size];
    NSImage* i = [[NSImage alloc] initWithSize:theIconSize];
    [i lockFocus];
    [aCachedImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
        
    NSString* label;
    NSFont* theFont;
    NSAttributedString* n;
    
    theFont = [NSFont messageFontOfSize:8];
    NSDictionary* attrib;

    if(hwName)	label = [NSString stringWithFormat:@"%.1f",[self hwValue]];
	else		label = @"--";
	n = [[NSAttributedString alloc] 
		initWithString:label 
			attributes:[NSDictionary dictionaryWithObject:theFont forKey:NSFontAttributeName]];
	
	NSSize textSize = [n size];
	[n drawInRect:NSMakeRect((theIconSize.width-10)/2-textSize.width/2,13,textSize.width,textSize.height)];
	[n release];


    if(hwName){
        label = [NSString stringWithFormat:@"%@,%d",hwName,bit];
        attrib = [NSDictionary dictionaryWithObject:theFont forKey:NSFontAttributeName];
    }
    else {
        label = @"XXXXXXXX";
        attrib = [NSDictionary dictionaryWithObjectsAndKeys:theFont,NSFontAttributeName,[NSColor redColor],NSForegroundColorAttributeName,nil];
        
    }
    n = [[NSAttributedString alloc] initWithString:label attributes:attrib];
    
    textSize = [n size];
    float x = theIconSize.width/2 - textSize.width/2;
    [n drawInRect:NSMakeRect(x,0,textSize.width,textSize.height)];
    [n release];

    if([self uniqueIdNumber]){
        theFont = [NSFont messageFontOfSize:9];
        n = [[NSAttributedString alloc] 
            initWithString:[NSString stringWithFormat:@"%d",[self uniqueIdNumber]] 
                attributes:[NSDictionary dictionaryWithObject:theFont forKey:NSFontAttributeName]];
        
        NSSize textSize = [n size];
        [n drawInRect:NSMakeRect(5,theIconSize.height-textSize.height,textSize.width,textSize.height)];
        [n release];
    }


    
    [i unlockFocus];
    
    [self setImage:i];
    [i release];
    
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setEMailList: [decoder decodeObjectForKey:@"ORRangeTimerModelEMailList"]];
    [self setEnableMail:[decoder decodeBoolForKey  :@"ORRangeTimerModelEnableMail"]];
    [self setDirection: [decoder decodeIntForKey:	@"ORRangeTimerModelDirection"]];
    [self setLimit:     [decoder decodeFloatForKey:	@"ORRangeTimerModelLimit"]];
    [self setDeadband:  [decoder decodeIntForKey:	@"ORRangeTimerModelDeadband"]];
    [[self undoManager] enableUndoRegistration];    

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:  eMailList forKey:	@"ORRangeTimerModelEMailList"];
    [encoder encodeBool:	enableMail forKey:	@"ORRangeTimerModelEnableMail"];
    [encoder encodeInt:		direction forKey:	@"ORRangeTimerModelDirection"];
    [encoder encodeFloat:	limit forKey:		@"ORRangeTimerModelLimit"];
    [encoder encodeInt:		deadband forKey:	@"ORRangeTimerModelDeadband"];
}

@end

@implementation ORRangeTimerModel (private)
- (void) eMailThread:(id)userInfo
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	BOOL configured;
	@synchronized([NSApp delegate]){
		configured = [NSMailDelivery hasDeliveryClassBeenConfigured];
	}
	if(configured){
		NSString* address =  [userInfo objectForKey:@"Address"];
		NSString* theContent = [userInfo objectForKey:@"Message"];
		NSString* emailHeader = [NSString string];
		NSString* hostAddress = @"<Unable to get host address>";
		NSArray* names =  [[NSHost currentHost] addresses];
		NSEnumerator* e = [names objectEnumerator];
		id aName;
		while(aName = [e nextObject]){
			if([aName rangeOfString:@"::"].location == NSNotFound){
				if([aName rangeOfString:@".0.0."].location == NSNotFound){
					hostAddress = aName;
					break;
				}
			}
		}
		emailHeader = [emailHeader stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];
		emailHeader = [emailHeader stringByAppendingFormat:@"ORCA Message From Host: %@\n",hostAddress];
		emailHeader = [emailHeader stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n\n"];
		
			
		BOOL result = NO;
		@synchronized([NSApp delegate]){
			result = [NSMailDelivery deliverMessage:[emailHeader stringByAppendingString:theContent] 
											subject:@"Orca Message"
												 to: address];
		}
		if(result)NSLog(@"Message mailed to: %@\n",address);
		else	  NSLogColor([NSColor redColor], @"Message FAILED to be mailed to: %@\n",address);
	}
	else {
		NSLogColor([NSColor redColor], @"Message e-mail could NOT be sent because eMail delivery has not been configured in Mail.app\n");
		NSLogColor([NSColor redColor], @"Message e-mails disabled\n");
		[self performSelectorOnMainThread:@selector(disableEMail) withObject:nil waitUntilDone:NO];
	}

	[pool release];
		
}

@end

