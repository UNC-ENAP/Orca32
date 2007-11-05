//
//  ORAlarmElementModel.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 18 2005.
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
#import "ORAlarmElementModel.h"


NSString* ORAlarmElementNameChangedNotification     = @"ORAlarmElementNameChangedNotification";
NSString* ORAlarmElementHelpChangedNotification     = @"ORAlarmElementHelpChangedNotification";
NSString* ORAlarmElementSeverityChangedNotification = @"ORAlarmElementSeverityChangedNotification";

@implementation ORAlarmElementModel

#pragma mark ���Initialization

- (void) dealloc
{
    [alarm clearAlarm];
    [alarm release];
    [alarmName release];
    [alarmHelp release];
    [super dealloc];
}

-(void) makeConnectors
{
    [super makeConnectors];
    ORConnector* aConnector;
    aConnector = [[self connectors] objectForKey:OROutputElementInConnection];
    [aConnector setLocalFrame: NSMakeRect(10,5,kConnectorSize,kConnectorSize)];
    
    aConnector = [[self connectors] objectForKey:OROutputElementOutConnection];
    [aConnector setLocalFrame: NSMakeRect([self frame].size.width - kConnectorSize ,5,kConnectorSize,kConnectorSize)];
}

- (NSString*) elementName
{
	return @"Alarm";
}
- (NSString*) fullHwName
{
	return alarmName;
}

- (id) stateValue
{
	if([self state])return @"Posted";
	else			return @"-";
}

- (void) setUpImage
{
    if([self state]) {
        [self setImage:[NSImage imageNamed:@"AlarmElementOn"]];
        if(!alarm){
            alarm = [[ORAlarm alloc] initWithName:alarmName severity:alarmSeverity];
            [alarm setSticky:YES];
        }
        [alarm setHelpString:alarmHelp];
        [alarm postAlarm];
    }
    else {
        [alarm clearAlarm];
        [alarm release];
        alarm = nil;
        [self setImage:[NSImage imageNamed:@"AlarmElementOff"]];
    }
}

- (void) makeMainController
{
    [self linkToController:@"ORAlarmElementController"];
}

- (NSString*) alarmName
{
    return alarmName;
}

- (NSString*) alarmHelp
{
    return alarmHelp;
}

- (int) alarmSeverity
{
    return alarmSeverity;
}

- (void)setAlarmName:(NSString*)aName
{
    if(aName == nil)aName = @"Process Alarm";
    [[[self undoManager] prepareWithInvocationTarget:self] setAlarmName:alarmName];
	
    [aName retain];
    [alarmName release];
    alarmName = aName;

    if(alarm){
        [alarm setName:aName];
        if([alarm isPosted]){
            [alarm clearAlarm];
            [alarm postAlarm];
        }
    }
	
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORAlarmElementNameChangedNotification
					  object:self];
    
}

- (void)setAlarmHelp:(NSString*)aName
{
    if(aName == nil)aName = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setAlarmHelp:alarmHelp];
	
    [alarmHelp autorelease];
    alarmHelp = [aName copy];    

    if(alarm){
        [alarm setHelpString:alarmHelp];
    }
	
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORAlarmElementHelpChangedNotification
					  object:self];
}

- (void)setAlarmSeverity:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAlarmSeverity:alarmSeverity];
	
    alarmSeverity = aValue;

    if(alarm){
        [alarm setSeverity:aValue];
        if([alarm isPosted]){
            [alarm clearAlarm];
            [alarm postAlarm];
        }
    }
    
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORAlarmElementSeverityChangedNotification
					  object:self];
}

- (NSString*) description:(NSString*)prefix
{
    NSString* s = [super description:prefix];
    id obj1 = [self objectConnectedTo:OROutputElementInConnection];
    NSString* nextPrefix = [prefix stringByAppendingString:@"  "];
    NSString* noConnectionString = [NSString stringWithFormat:@"%@--",nextPrefix];
    return [NSString stringWithFormat:@"%@\n%@",s,
                                    obj1?[obj1 description:nextPrefix]:noConnectionString];
}
- (void) processIsStopping
{
    [super processIsStopping];
    [self setState:NO];
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setAlarmSeverity:[decoder decodeIntForKey:@"alarmSeverity"]];
    [self setAlarmName:[decoder decodeObjectForKey: @"alarmName"]];
    [self setAlarmHelp:[decoder decodeObjectForKey: @"alarmHelp"]];
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:alarmSeverity forKey:@"alarmSeverity"];
    [encoder encodeObject:alarmName forKey:@"alarmName"];
    [encoder encodeObject:alarmHelp forKey:@"alarmHelp"];
    
}

@end
