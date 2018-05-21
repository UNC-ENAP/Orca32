//
//  ORTDS2024Model.h
//  Orca
//  Created by Mark Howe on Mon, May 9, 2018.
//  Copyright (c) 2018 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#pragma mark •••Imported Files
#import "ORTDS2024Model.h"
#import "ORUSB.h"
#import "ORGroup.h"

@class ORUSBInterface;
@class ORAlarm;
@class ThreadWorker;

@interface ORTDS2024Model : ORGroup <USBDevice> {
    ThreadWorker*   curvesThread;
	NSLock*         localLock;
	ORUSBInterface* usbInterface;
    NSString*       serialNumber;
	ORAlarm*        noUSBAlarm;
	BOOL            okToCheckUSB;
    int             pollTime;
    int             chanEnabledMask;
    int             numPoints[4];
    unsigned char   waveForm[4][2600];
    char            wfmPre[4][512];
     NSMutableString* curveStr[4];
}

- (id) getUSBController;
- (NSArray*) usbInterfaces;
- (void) checkNoUsbAlarm;

#pragma mark ***Accessors
- (unsigned short) chanEnabledMask;
- (void) setChanEnabledMask:(unsigned short)aMask;
- (void) setChanEnabled:(unsigned short) aChan withValue:(BOOL) aState;
- (int)  pollTime;
- (void) setPollTime:(int)aPollTime;
- (ORUSBInterface*) usbInterface;
- (void) setUsbInterface:(ORUSBInterface*)anInterface;
- (NSString*) serialNumber;
- (void) setSerialNumber:(NSString*)aSerialNumber;
- (BOOL) curveIsBusy;
- (void) postCouchDB;

- (unsigned long) vendorID;
- (unsigned long) productID;
- (NSString*) usbInterfaceDescription;
- (void) connectionChanged;

#pragma mark •••Cmd Handling
- (void) interfaceAdded:(NSNotification*)aNote;
- (void) interfaceRemoved:(NSNotification*)aNote;
- (long) readFromDevice: (char*) aData maxLength: (long) aMaxLength;
- (void) writeToDevice: (NSString*) aCommand;
- (void) writeCommand:(NSString*)aCmd;

- (void) readIDString;
- (void) readWaveformPreamble;
- (void) pollHardware;
- (void) getCurves;
- (void) readDataInfo;
- (int) numPoints:(int)index;
- (long) dataSet:(int)index valueAtChannel:(int)x;
- (void) curvesThreadFinished:(id)userInfo;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORTDS2024ChanEnabledMaskChanged;
extern NSString* ORTDS2024SerialNumberChanged;
extern NSString* ORTDS2024USBInterfaceChanged;
extern NSString* ORTDS2024Lock;
extern NSString* ORTDS2024PollTimeChanged;
extern NSString* ORTDS2024BusyChanged;

extern NSString* ORWaveFormDataChanged;
