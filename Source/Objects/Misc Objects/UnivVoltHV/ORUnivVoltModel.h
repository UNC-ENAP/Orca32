//
//  ORUnivVoltModel.h
//  Orca
//
//  Created by Mark Howe on Mon Apr 21 2008
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#pragma mark •••Imported Filesg

#import "ORCard.h"

#define kNplpCMeterPort 5000
#define kNplpCNumChannels 4
#define kNplpCStart  "B"
#define kNplpCStop	 "Q"

@class NetSocket;
@class ORAlarm;
@class ORQueue;

@interface ORUnivVoltModel : ORCard 
{
	NSLock* localLock;
    NSString* ipAddress;
    BOOL isConnected;
	NetSocket* socket;
    unsigned long dataId;
	NSMutableData* meterData;
	int frameError;
	ORQueue* dataStack[kNplpCNumChannels];
	float meterAverage[kNplpCNumChannels];
    unsigned short receiveCount;
}

#pragma mark ***Accessors
- (unsigned short) receiveCount;
- (void) setReceiveCount:(unsigned short)aCount;
- (unsigned int) frameError;
- (void) setFrameError:(unsigned int)aValue;
- (NetSocket*) socket;
- (void) setSocket:(NetSocket*)aSocket;
- (BOOL) isConnected;
- (void) setIsConnected:(BOOL)aFlag;
- (NSString*) ipAddress;
- (void) setIpAddress:(NSString*)aIpAddress;
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) aDataId;
- (void) appendMeterData:(NSData*)someData;
- (BOOL) validateMeterData;
- (void) averageMeterData;
- (void) setMeter:(int)chan average:(float)aValue;
- (float) meterAverage:(unsigned short)aChannel;

#pragma mark ***Utilities
- (void) connect;
- (void) start;
- (void) stop;

#pragma mark •••DataRecords
- (NSDictionary*) dataRecordDescription;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (void) shipValues;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORUnivVoltReceiveCountChanged;
extern NSString* ORUnivVoltIsConnectedChanged;
extern NSString* ORUnivVoltIpAddressChanged;
extern NSString* ORUnivVoltAverageChanged;
extern NSString* ORUnivVoltFrameError;
extern NSString* ORUnivVoltLock;