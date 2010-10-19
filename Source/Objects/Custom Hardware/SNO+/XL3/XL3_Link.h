//
//  XL3_Link.h
//  ORCA
//
//  Created by Jarek Kaspar on Sat, Jul 9, 2010.
//  Copyright (c) 2010 CENPA, University of Washington. All rights reserved.
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

#import "XL3_Cmds.h"
@class ORSafeCircularBuffer;

typedef enum eXL3_ConnectStates {
	kDisconnected,
	kWaiting,
	kConnected,
	kNumStates //must be last
}
eXL3_CrateStates;


@interface XL3_Link : ORGroup
{
	int		serverSocket;
	int		workingSocket;
	NSLock*		commandSocketLock;	//only one command to XL3 at the moment, to be released later
	NSLock*		coreSocketLock;		//to synchronize both the threads touching the socket, with additional lockers to be removed later
	NSLock*		cmdArrayLock;		//to synchronize the threaded worker pushing XL3 responses and XL3Model pulling the responses
	BOOL		needToSwap;
	NSString*	IPNumber;
	NSString*	crateName;
	unsigned long	portNumber;
	BOOL		isConnected;
	int		connectState;
	int		errorTimeOut;
	NSCalendarDate*	timeConnected;
	NSMutableArray*	cmdArray;
	ORSafeCircularBuffer* bundleBuffer;
	unsigned long long num_cmd_packets;
	unsigned long long num_dat_packets;
}

- (id)   init;
- (void) dealloc;
- (void) wakeUp; 
- (void) sleep ;	

#pragma mark •••DataTaker Helpers
- (BOOL) bundleAvailable;
- (void) resetBundleBuffer;
- (NSData*) readNextBundle;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

#pragma mark •••Accessors
- (int)  serverSocket;
- (void) setServerSocket:(int) aSocket;
- (int)  workingSocket;
- (void) setWorkingSocket:(int) aSocket;
- (BOOL) needToSwap;
- (void) setNeedToSwap;
- (int)  connectState;
- (BOOL) isConnected;
- (void) setIsConnected:(BOOL)aNewIsConnected;
- (void) setErrorTimeOut:(int)aValue;
- (int) errorTimeOut;
- (int) errorTimeOutSeconds;
- (void) toggleConnect;
- (NSCalendarDate*) timeConnected;
- (void) setTimeConnected:(NSCalendarDate*)newTimeConnected;
- (NSString*) IPNumber;
- (void) setIPNumber:(NSString*)aIPNumber;
- (unsigned long)  portNumber;
- (void) setPortNumber:(unsigned long)aPortNumber;
- (NSString*) crateName;
- (void) setCrateName:(NSString*)aCrateName;

- (void) sendXL3Packet:(XL3_Packet*)aSendPacket;
- (void) sendCommand:(long)aCmd withPayload:(XL3_PayloadStruct*)payloadBlock expectResponse:(BOOL)askForResponse;
- (void) sendCommand:(long)aCmd expectResponse:(BOOL)askForResponse;
- (void) sendFECCommand:(long)aCmd toAddress:(unsigned long)address withData:(unsigned long*)value;
- (void) readXL3Packet:(XL3_Packet*)aPacket withPacketType:(unsigned char)packetType andPacketNum:(unsigned short)packetNum;

- (void) connectSocket;
- (void) disconnectSocket;
- (void) connectToPort;
- (void) writePacket:(char*)aPacket;
- (void) readPacket:(char*)aPacket;
- (BOOL) canWriteTo:(int)aSocket;

@end


extern NSString* XL3_LinkConnectionChanged;
extern NSString* XL3_LinkTimeConnectedChanged;
extern NSString* XL3_LinkIPNumberChanged;
extern NSString* XL3_LinkConnectStateChanged;
extern NSString* XL3_LinkErrorTimeOutChanged;
