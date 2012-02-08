//
//  ORMacModel.h
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
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
#import "OROrderedObjHolding.h"

#pragma mark ���Imported Files

#pragma mark ���Forward Declarations
@class ORConnector;
@class ORFireWireBus;
@class ORUSB;

@interface ORMacModel : ORGroup <OROrderedObjHolding> {
    NSMutableArray* serialPorts;
	BOOL			mStarted;
	ORFireWireBus*	fwBus;
	ORUSB*			usb;
    int				eolType;
    NSString* lastStringReceived;
}

#pragma mark ���Accessors
- (NSString*) lastStringReceived;
- (void) setLastStringReceived:(NSString*)aLastStringReceived;
- (int) eolType;
- (void) setEolType:(int)aEolType;
- (NSMutableArray*) serialPorts;
- (void) setSerialPorts:(NSMutableArray*)somePorts;
- (id) serialPort:(int)index;

- (void) positionConnector:(ORConnector*)aConnector forCard:(id)aCard;
- (int) crateNumber;
- (void) registerNotifications;

#pragma mark ���Serial Ports
- (void) scanForSerialPorts;
- (void) sendOnPort:(int)index anArray:(NSArray*)someData;
- (void) serialPortWriteProgress:(NSDictionary *)dataDictionary;

#pragma mark ���IP
- (NSString*) ipAddress:(int)desiredNetwork;

#pragma mark ���FireWire
- (id) getFireWireInterface:(unsigned long)aVenderID;

#pragma mark ���USB
- (unsigned) usbDeviceCount;
- (id)		 usbDeviceAtIndex:(unsigned)index;
- (void)	 objectsAdded:(NSNotification*)aNote;
- (void)	 objectsRemoved:(NSNotification*)aNote;
- (id)		 getUSBController;
- (id)		 initWithCoder:(NSCoder*)decoder;
- (void)	 encodeWithCoder:(NSCoder*)encoder;

#pragma mark ���OROrderedObjHolding Protocol
- (int) maxNumberOfObjects;
- (int) objWidth;
- (BOOL) slot:(int)aSlot excludedFor:(id)anObj;
- (NSString*) nameForSlot:(int)aSlot;
- (NSRange) legalSlotsForObj:(id)anObj;
- (int) slotAtPoint:(NSPoint)aPoint; 
- (NSPoint) pointForSlot:(int)aSlot;
- (void) place:(id)anObj intoSlot:(int)aSlot;
- (int) slotForObj:(id)anObj;
- (int) numberSlotsNeededFor:(id)anObj;
@end


void RegistryChanged (id sender, io_service_t service, natural_t messageType, void* messageArgument ) ;

@interface NSObject (USB)
- (NSString*) usbInterfaceDescription;
@end

extern NSString* ORMacModelEolTypeChanged;
extern NSString* ORMacModelSerialPortsChanged;
extern NSString* ORMacModelUSBChainVerified;

