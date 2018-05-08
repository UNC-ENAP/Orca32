//--------------------------------------------------------
// ORMotoGPSModel
// Created by Mark  A. Howe on Fri Jul 22 2005 / Julius Hartmann, KIT, November 2017
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2005 CENPA, University of Washington. All rights reserved.
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

#pragma mark ***Imported Files

@class ORRefClockModel;

@interface ORMotoGPSModel : NSObject
{
    @private
        ORRefClockModel* refClock;

        // int reTxCount;  // in case of errors or timeout retransmit; if retransmit
        // // is required, put last command to cmdQueue and dequeueFromBottom
        //
        int         cableDelayNs;
        BOOL        statusPoll;
        NSString*   lastRecTelegram;
    
        //status variables
        unsigned int    visibleSatellites;
        unsigned int    trackedSatellites;
        unsigned int    accSignalStrength;
        NSString*       antennaSense;
        float           oscTemperature;
}

#pragma mark ***Initialization
- (void) dealloc;

#pragma mark ***Accessors
- (void) setRefClock:(ORRefClockModel*)aRefClock;
- (BOOL) portIsOpen;
- (BOOL) statusPoll;
- (void) setStatusPoll:(BOOL)aStatusPoll;
- (int) cableDelay;
- (void) setCableDelay:(int)aDelay;
- (NSString*) lastReceived;

- (unsigned int) visibleSatellites;
- (unsigned int) trackedSatellites;
- (unsigned int) accSignalStrength;
- (NSString*) antennaSense;
- (float) oscTemperature;

#pragma mark ***Commands
- (void) writeData:(NSDictionary*)aDictionary;
- (void) processResponse:(NSData*)someData forRequest:(NSDictionary*)lastRequest;
- (NSString*) bytesToPrintable:(unsigned char *)bytes length:(unsigned short)aLength;
- (void) setDefaults;
- (void) autoSurvey;
- (void) requestStatus;
- (void) cableDelayCorrection:(int)nanoseconds;
- (void) deviceInfo;
- (NSDictionary*) defaultsCommand;
- (NSDictionary*) autoSurveyCommand;
- (NSDictionary*) statusCommand;
- (NSDictionary*) cableCorrCommand:(int)nanoseconds;
- (NSDictionary*) deviceInfoCommand;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORMotoGPSModelSetDefaultsChanged;
extern NSString* ORMotoGPSModelTrackModeChanged;
extern NSString* ORMotoGPSModelSyncChanged;
extern NSString* ORMotoGPSModelAlarmWindowChanged;
extern NSString* ORMotoGPSModelStatusChanged;
extern NSString* ORMotoGPSModelStatusPollChanged;
extern NSString* ORMotoGPSStatusValuesReceived;
extern NSString* ORMotoGPSModelReceivedMessageChanged;

