//
//  ORIOLogicChildReadModel.m
//  Orca
//
//  Created by Mark Howe on 10/6/10.
//  Copyright  � 2009 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Physics and 
//Astrophysics Department sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ���Imported Files
#import "ORLogicChildReadModel.h"

NSString* ORLogicChildReadChanged = @"ORLogicChildReadChanged";

@implementation ORLogicChildReadModel

#pragma mark ���Initialization
- (void) setUpImage
{
	NSImage* aCachedImage = [NSImage imageNamed:@"LogicChildRead"];
	NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
	[i lockFocus];
	[aCachedImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
	NSAttributedString* n = [[NSAttributedString alloc] 
							 initWithString:[NSString stringWithFormat:@"Read %d",[self childIndex]] 
							 attributes:[NSDictionary dictionaryWithObject:[NSFont labelFontOfSize:12] forKey:NSFontAttributeName]];

	[n drawAtPoint:NSMakePoint(17,4)];
	[n release];
	[i unlockFocus];		
	[self setImage:i];
	[i release];

	[[NSNotificationCenter defaultCenter]
	 postNotificationName:OROrcaObjectImageChanged
	 object:self];
}
- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian
{
    return  [aGuardian conformsToProtocol:NSProtocolFromString(@"TriggerChildReading")];
}

- (void) makeMainController
{
    [self linkToController:@"ORLogicChildReadController"];
}

-(void) makeConnectors
{	
	NSPoint loc = NSMakePoint(0,[self frame].size.height/2 - kConnectorSize/2 );
	ORConnector* aConnector = [[ORConnector alloc] initAt:loc withGuardian:self withObjectLink:self];
	[[self connectors] setObject:aConnector forKey:@"Input1"];
	[ aConnector setConnectorType: 'TLI ' ];
	[ aConnector addRestrictedConnectionType: 'TLO ' ]; //can only connect to processor inputs
	[aConnector release];
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"Child Read %d",[self uniqueIdNumber]];
}

- (unsigned short) childIndex
{
	return childIndex;
}

- (void) setChildIndex:(unsigned short)anIndex
{
	[[[self undoManager] prepareWithInvocationTarget:self] setChildIndex:childIndex];
    childIndex = anIndex;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLogicChildReadChanged object:self];
}	

- (BOOL) evalWithDelegate:(id)anObj
{
	BOOL state = [[self objectConnectedTo:@"Input1"] evalWithDelegate:anObj];
	if(state)[anObj readChild:childIndex];
	return NO;
}

- (void) reset
{
	[[self objectConnectedTo:@"Input1"] reset];
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setChildIndex:[decoder decodeIntForKey:@"ChildIndex"]];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:childIndex forKey:@"ChildIndex"];
}
@end

@implementation ORLogicChildRead2Model

#pragma mark ���Initialization
- (void) setUpImage
{
	NSImage* aCachedImage = [NSImage imageNamed:@"LogicChildRead2"];
	NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
	[i lockFocus];
	[aCachedImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
	NSAttributedString* n = [[NSAttributedString alloc] 
							 initWithString:[NSString stringWithFormat:@"Read %d",[self childIndex]] 
							 attributes:[NSDictionary dictionaryWithObject:[NSFont labelFontOfSize:12] forKey:NSFontAttributeName]];
	
	[n drawAtPoint:NSMakePoint(17,4)];
	[n release];
	[i unlockFocus];		
	[self setImage:i];
	[i release];
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:OROrcaObjectImageChanged
	 object:self];
}

- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian
{
    return  [aGuardian conformsToProtocol:NSProtocolFromString(@"TriggerChildReading")];
}

- (void) makeMainController
{
    [self linkToController:@"ORLogicChildReadController"];
}

-(void) makeConnectors
{	
	ORConnector* inConnector = [[ORConnector alloc] initAt:NSMakePoint(0,[self frame].size.height/2-kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:@"Input1"];
    [ inConnector setConnectorType: 'TLI ' ];
    [ inConnector addRestrictedConnectionType: 'TLO ' ]; //can only connect to logic outputs
    [inConnector release];
	
    ORConnector* outConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,[self frame].size.height/2-kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:outConnector forKey:@"Output1"];
    [ outConnector setConnectorType: 'TLO ' ];
    [ outConnector addRestrictedConnectionType: 'TLI ' ]; //can only connect to logic inputs
    [outConnector release];	
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"Child Read2 %d",[self uniqueIdNumber]];
}

- (unsigned short) childIndex
{
	return childIndex;
}

- (void) setChildIndex:(unsigned short)anIndex
{
	[[[self undoManager] prepareWithInvocationTarget:self] setChildIndex:childIndex];
    childIndex = anIndex;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLogicChildReadChanged object:self];
}	

- (BOOL) evalWithDelegate:(id)anObj
{
	BOOL state = [[self objectConnectedTo:@"Input1"] evalWithDelegate:anObj];
	if(state)[anObj readChild:childIndex];
	return state;
}

- (void) reset
{
	[[self objectConnectedTo:@"Input1"] reset];
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setChildIndex:[decoder decodeIntForKey:@"ChildIndex"]];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:childIndex forKey:@"ChildIndex"];
}
@end