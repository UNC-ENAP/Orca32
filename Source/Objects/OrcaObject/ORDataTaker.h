//
//  ORDataTaker.h
//  Orca
//
//  Created by Mark Howe on Thu Mar 06 2003.
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



#import "ORDataPacket.h"
#import "ORDataSet.h"

#define kSBCisDataTaker @"kSBCisDataTaker"

@protocol ORDataTaker
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) reset;
@end

@protocol ORFeraReadout
- (void) setVSN:(int)aVSN;
- (void) shipFeraData:(void*)ptr length:(int)len;
@end


@interface NSObject (ORDataTaker)
- (void) processData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet;
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (BOOL) dataAvailable;
- (BOOL) isRunning;
- (void) takeData:(ORDataPacket*)aDataPacket;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket;
- (void) closeOutRun:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;

@end
