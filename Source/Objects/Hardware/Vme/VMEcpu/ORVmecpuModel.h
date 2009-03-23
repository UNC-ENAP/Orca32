//--------------------------------------------------------
// ORVmecpuModel
// Created by Mark  A. Howe on Tue Feb 07 2006
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2006 CENPA, University of Washington. All rights reserved.
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

#import "ORVmeAdapter.h"
#import "ORDataTaker.h"
#import "ORVmeBusProtocol.h"
#import "SBC_Linking.h"
#import "ORCommandList.h"

@class ORReadOutList;
@class ORDataPacket;
@class SBC_Link;

#pragma mark ���Exceptions
#define OExceptionVmeAccessError		@"Vme Access Error"

@interface ORVmecpuModel : ORVmeAdapter <ORDataTaker,SBC_Linking,ORVmeBusProtocol>
{
	ORReadOutList*	readOutGroup;
	SBC_Link*		sbcLink;
	NSArray*		dataTakers;			//cache of data takers.
}

#pragma mark ���Initialization
- (id)   init;
- (void) dealloc;

#pragma mark ���Accessors
- (id) controllerCard;
- (SBC_Link*)sbcLink;
- (ORReadOutList*)	readOutGroup;
- (void)			setReadOutGroup:(ORReadOutList*)newReadOutGroup;
- (NSMutableArray*) children;
- (void) performSysReset;

#pragma mark ���DataTaker
- (void) load_HW_Config;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) saveReadOutList:(NSFileHandle*)aFile;
- (void) loadReadOutList:(NSFileHandle*)aFile;


#pragma mark ���Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark ���ORVmeBusProtocol Protocol
- (void) resetContrl;
- (void) checkStatusErrors;

#pragma mark ���SBC_Linking Protocol
- (NSString*) cpuName;
- (NSString*) sbcLockName;
- (NSString*) sbcLocalCodePath;
- (NSString*) codeResourcePath;


- (void) readLongBlock:(unsigned long *) readAddress
			atAddress:(unsigned int) vmeAddress
			numToRead:(unsigned int) numberLongs
		   withAddMod:(unsigned short) anAddressModifier
		usingAddSpace:(unsigned short) anAddressSpace;

- (void) writeLongBlock:(unsigned long *) writeAddress
			 atAddress:(unsigned int) vmeAddress
			numToWrite:(unsigned int) numberLongs
			withAddMod:(unsigned short) anAddressModifier
		 usingAddSpace:(unsigned short) anAddressSpace;

- (void) readLong:(unsigned long *) readAddress
	   atAddress:(unsigned int) vmeAddress
	 timesToRead:(unsigned int) numberLongs
	  withAddMod:(unsigned short) anAddressModifier
   usingAddSpace:(unsigned short) anAddressSpace;

- (void) readByteBlock:(unsigned char *) readAddress
			atAddress:(unsigned int) vmeAddress
			numToRead:(unsigned int) numberBytes
		   withAddMod:(unsigned short) anAddressModifier
		usingAddSpace:(unsigned short) anAddressSpace;

- (void) writeByteBlock:(unsigned char *) writeAddress
			 atAddress:(unsigned int) vmeAddress
			numToWrite:(unsigned int) numberBytes
			withAddMod:(unsigned short) anAddressModifier
		 usingAddSpace:(unsigned short) anAddressSpace;

- (void) readWordBlock:(unsigned short *) readAddress
			atAddress:(unsigned int) vmeAddress
			numToRead:(unsigned int) numberWords
		   withAddMod:(unsigned short) anAddressModifier
		usingAddSpace:(unsigned short) anAddressSpace;

- (void) writeWordBlock:(unsigned short *) writeAddress
			 atAddress:(unsigned int) vmeAddress
			numToWrite:(unsigned int) numberWords
			withAddMod:(unsigned short) anAddressModifier
		 usingAddSpace:(unsigned short) anAddressSpace;

- (void) executeCommandList:(ORCommandList*)aList;

@end

@interface ORVmecpuModel (OROrderedObjHolding)
- (int) maxNumberOfObjects;
- (int) objWidth;
@end

extern NSString* ORVmecpuLock;	
