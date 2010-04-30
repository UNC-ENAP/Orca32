//
//  ORDataExplorerModel.h
//  Orca
//
//  Created by Mark Howe on Sun Dec 05 2004.
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


#pragma mark ���Imported Files

#pragma mark ���Forward Declarations
@class ORHeaderItem;
@class ORDataSet;
@class ORRecordIndexer;

@interface ORDataExplorerModel :  OrcaObject
{
    @private
        NSString*       fileToExplore;
        ORHeaderItem*   header;
        NSArray*        dataRecords;
        ORDataSet*      dataSet;

        unsigned        totalLength;
        unsigned        lengthDecoded;
		BOOL			multiCatalog;
		BOOL			histoErrorFlag;
		ORRecordIndexer* recordIndexer;
		NSOperationQueue*   queue;
    BOOL headerOnly;
}

#pragma mark ���Accessors
- (BOOL) headerOnly;
- (void) setHeaderOnly:(BOOL)aHeaderOnly;
- (BOOL) histoErrorFlag;
- (void) setHistoErrorFlag:(BOOL)aHistoErrorFlag;
- (BOOL) multiCatalog;
- (void) setMultiCatalog:(BOOL)aMultiCatalog;
- (ORDataSet*) 	dataSet;
- (void)        setDataSet:(ORDataSet*)aDataSet;
- (NSString*)   fileToExplore;
- (void)        setFileToExplore:(NSString*)newFileToExplore;
- (ORHeaderItem*)header;
- (void)        setHeader:(ORHeaderItem *)aHeader;
- (NSArray *)   dataRecords;
- (void)        setDataRecords: (NSArray *) aDataRecords;
- (id)          dataRecordAtIndex:(int)index;
- (void) removeDataSet:(ORDataSet*)item;
- (id)   childAtIndex:(int)index;
- (unsigned)  numberOfChildren;
- (unsigned)  count;
- (void) createDataSet;
- (void) decodeOneRecordAtOffset:(unsigned long)offset forKey:(id)aKey;
- (void) byteSwapOneRecordAtOffset:(unsigned long)anOffset forKey:(id)aKey;
- (NSString*) dataRecordDescription:(unsigned long)anOffset forKey:(NSNumber*)aKey;
- (void) setTotalLength:(unsigned)aLength;
- (void) setLengthDecoded:(unsigned)aLength;
- (unsigned) totalLength;
- (unsigned) lengthDecoded;
- (void) clearCounts;
- (void) stopParse;
- (void) flushMemory;

#pragma mark ���Data Handling
- (void) parseFile;
- (BOOL) parseInProgress;
- (void) parseEnded;
- (void) delayedSendParseEnded;

#pragma mark ���Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end


#pragma mark ���External String Definitions
extern NSString* ORDataExplorerModelHeaderOnlyChanged;
extern NSString* ORDataExplorerModelHistoErrorFlagChanged;
extern NSString* ORDataExplorerModelMultiCatalogChanged;
extern NSString* ORDataExplorerFileChangedNotification;
extern NSString* ORDataExplorerDataChanged;
extern NSString* ORDataExplorerParseStartedNotification;
extern NSString* ORDataExplorerParseEndedNotification;