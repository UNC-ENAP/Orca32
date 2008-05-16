//
//  ORSNOCrateModel.m
//  Orca
//
//  Created by Mark Howe on Tue, Apr 30, 2008.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORSNOCrateModel.h"
#import "ORSNOCard.h"


#define kMaxSNOCrates 20
const struct {
	unsigned long Register;
	unsigned long Memory;
}kSnoCrateBaseAddress[]={
	{0x00002800, 	0x01400000},
	{0x00003000,	0x01800000},
	{0x00003800,	0x01c00000},
	{0x00004000,	0x02000000},
	{0x00004800,	0x02400000},
	{0x00005000,	0x02800000},
	{0x00005800,	0x02c00000},
	{0x00006000,	0x03000000},
	{0x00006800,	0x03400000},
	{0x00007800,	0x03C00000},
	{0x00008000,	0x04000000},
	{0x00008800,	0x04400000},
	{0x00009000,	0x04800000},
	{0x00009800,	0x04C00000},
	{0x0000a000,	0x05000000},
	{0x0000a800,	0x05400000},
	{0x0000b000,	0x05800000},
	{0x0000b800,	0x05C00000},
	{0x0000c000,	0x06000000},
	//{0x0000c800,	0x06400000}	//crate 19 is really at 0xd000
	{0x0000d000,	0x06800000}
};

@implementation ORSNOCrateModel

#pragma mark •••initialization
- (void) makeConnectors
{	
}

- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each crate can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
    NSImage* aCachedImage = [NSImage imageNamed:@"SNOCrate"];
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
    if(powerOff){
        NSAttributedString* s = [[[NSAttributedString alloc] initWithString:@"No Pwr"
                                                                 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                     [NSColor redColor],NSForegroundColorAttributeName,
                                                                     [NSFont fontWithName:@"Geneva" size:10],NSFontAttributeName,
                                                                     nil]] autorelease]; 
        [s drawAtPoint:NSMakePoint(25,5)];
    }
    
    if([[self orcaObjects] count]){
        NSAffineTransform* transform = [NSAffineTransform transform];
        [transform translateXBy:7 yBy:25];
        [transform scaleXBy:.38 yBy:.3];
        [transform concat];
        NSEnumerator* e  = [[self orcaObjects] objectEnumerator];
        OrcaObject* anObject;
        while(anObject = [e nextObject]){
            BOOL oldHighlightState = [anObject highlighted];
            [anObject setHighlighted:NO];
            [anObject drawSelf:NSMakeRect(0,0,500,[[self image] size].height)];
            [anObject setHighlighted:oldHighlightState];
        }
    }
    [i unlockFocus];
    [self setImage:i];
    [i release];
    
    [[NSNotificationCenter defaultCenter]
                postNotificationName:OROrcaObjectImageChanged
                              object:self];

}

- (void) makeMainController
{
    [self linkToController:@"ORSNOCrateController"];
}

- (void) connected
{
	[[self orcaObjects] makeObjectsPerformSelector:@selector(connected)];
}

- (void) disconnected
{
	[[self orcaObjects] makeObjectsPerformSelector:@selector(disconnected)];
}

#pragma mark •••Accessors
- (unsigned long) memoryAddress
{
	int index =  [self crateNumber];
	if(index>=0 && index<=kMaxSNOCrates) return kSnoCrateBaseAddress[index].Memory;
	else {
		[[NSException exceptionWithName:@"SNO Crate" reason:@"SNO Crate Index out of bounds" userInfo:nil] raise];
		return 0; //to get rid of compiler warning, can't really get here
	}
}

- (unsigned long) registerAddress
{
	int index =  [self crateNumber];
	if(index>=0 && index<=kMaxSNOCrates) return kSnoCrateBaseAddress[index].Register;
	else {
		[[NSException exceptionWithName:@"SNO Crate" reason:@"SNO Crate Index out of bounds" userInfo:nil] raise];
		return 0; //to get rid of compiler warning, can't really get here
	}
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
	[super registerNotificationObservers];
	   
    [notifyCenter addObserver : self
                     selector : @selector(viewChanged:)
                         name : ORSNOCardSlotChangedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(powerFailed:)
                         name : @"VmePowerFailedNotification"
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(powerRestored:)
                         name : @"VmePowerRestoredNotification"
                       object : nil];
}


- (void) powerFailed:(NSNotification*)aNotification
{
    if([aNotification object] == [self controllerCard]){
        [self setPowerOff:YES];
		if(!cratePowerAlarm){
			cratePowerAlarm = [[ORAlarm alloc] initWithName:@"No SNO Crate Power" severity:0];
			[cratePowerAlarm setSticky:YES];
			[cratePowerAlarm setHelpStringFromFile:@"NoSNOCratePowerHelp"];
			[cratePowerAlarm postAlarm];
		} 
    }
}

- (void) powerRestored:(NSNotification*)aNotification
{
    if([aNotification object] == [self controllerCard]){
        [self setPowerOff:NO];
		[cratePowerAlarm clearAlarm];
		[cratePowerAlarm release];
		cratePowerAlarm = nil;
    }
}
- (NSString*) identifier
{
    return [NSString stringWithFormat:@"SNO Crate %d",[self crateNumber]];
}

@end
