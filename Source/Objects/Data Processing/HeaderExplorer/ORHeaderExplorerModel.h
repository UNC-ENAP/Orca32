//
//  ORHeaderExplorerModel.h
//  Orca
//
//  Created by Mark Howe on Tue Feb 26.
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


#pragma mark •••Imported Files
#import "ORFileMover.h"

#pragma mark •••Forward Declarations
@class ORDataPacket;
@class ThreadWorker;
@class ORHeaderItem;
@class ORDataSet;

@interface ORHeaderExplorerModel :  OrcaObject
{
    @private
		BOOL			stop;
        NSMutableArray*	filesToProcess;
        id              nextObject;

        ORHeaderItem*   header;
        NSString*       lastListPath;
        NSString*       lastFilePath;
		NSString*       fileToProcess;
        ORDataPacket*   fileAsDataPacket;
        NSArray*        dataRecords;

        BOOL			reading;
        unsigned long   total;
        unsigned long   numberLeft;
        unsigned long   currentFileIndex;
		BOOL			sentRunStart;
		
		NSMutableArray* runArray;
		unsigned long	minRunStartTime;
		unsigned long	maxRunEndTime;
		int				selectionDate;
		int				selectedRunIndex;

}

#pragma mark •••Accessors
- (int) selectedRunIndex;
- (void) setSelectedRunIndex:(int)anIndex;
- (int)  selectionDate;
- (void) setSelectionDate:(int)aValue;
- (NSDictionary*) runDictionaryForIndex:(int)index;
- (unsigned long)   total;
- (unsigned long)   numberLeft;
- (NSArray *)   dataRecords;
- (void)        setDataRecords: (NSArray *) aDataRecords;
- (id)          dataRecordAtIndex:(int)index;
- (NSString*)   fileToProcess;
- (void)        setFileToProcess:(NSString*)newFileToProcess;
- (NSArray*) filesToProcess;
- (void) addFilesToProcess:(NSMutableArray*)newFilesToProcess;
- (ORHeaderItem *)header;
- (void)setHeader:(ORHeaderItem *)aHeader;
- (BOOL)isProcessing;
- (NSString *) lastListPath;
- (void) setLastListPath: (NSString *) aSetLastListPath;
- (NSString *) lastFilePath;
- (void) setLastFilePath: (NSString *) aSetLastListPath;
- (unsigned long)	minRunStartTime;
- (unsigned long)	maxRunEndTime;

#pragma mark •••Data Handling
- (void) stopProcessing;
- (void) removeFilesWithIndexes:(NSIndexSet*)indexSet;
- (void) stopProcessing;
- (void) removeAll;
- (void) removeFiles:(NSMutableArray*)anArray;
- (void) readHeaders;
- (void) findSelectedRun;

#pragma mark •••Data Handling
- (void) readNextFile;

@end

#pragma mark •••External String Definitions
extern NSString* ORHeaderExplorerListChangedNotification;
extern NSString* ORHeaderExplorerAtEndNotification;
extern NSString* ORHeaderExplorerRunningNotification;
extern NSString* ORHeaderExplorerStoppedNotification;
extern NSString* ORHeaderExplorerInProgressNotification;

extern NSString* ORHeaderExplorerProcessingEndedNotification;
extern NSString* ORHeaderExplorerReadingNotification;
extern NSString* ORHeaderExplorerSelectionDateNotification;
extern NSString* ORHeaderExplorerRunSelectionChanged;
extern NSString* ORHeaderExplorerOneFileDoneNotification;
