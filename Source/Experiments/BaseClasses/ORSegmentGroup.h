//
//  ORSegmentGroup.h
//  Orca
//
//  Created by Mark Howe on 12/15/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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


#import <Cocoa/Cocoa.h>

@class ORTimeRate;
@class ORDetectorSegment;

@interface ORSegmentGroup : NSObject {
	NSMutableDictionary*	colorAxisAttributes;
	NSString*		groupName;
	NSMutableArray* segments;
	NSString*		adcClassName;
	NSString*		mapFile;
	ORTimeRate*		totalRate;
	int				thresholdHistogram[32*1024];
	int				gainHistogram[1020];
	float			rate;
	NSArray*		mapEntries;

}

#pragma mark •••Initialization
- (id) initWithName:(NSString*)aName numSegments:(int)numSegments mapEntries:(NSArray*)someMapEntries;
- (void) dealloc;
- (NSUndoManager*) undoManager;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) awakeAfterDocumentLoaded;
- (void) configurationChanged:(NSNotification*)aNote;
- (void) registerForRates;
- (void) unregisterRates;

#pragma mark •••Accessors
- (void) setMapEntries:(NSArray*)someMapEntries;
- (NSArray*) mapEntries;
- (int) numSegments;
- (ORDetectorSegment*) segment:(int)index;
- (id) segment:(int)index objectForKey:(id)aKey;
- (NSString*) groupName;
- (void) setGroupName:(NSString*)aName;
- (int) thresholdHistogram:(int) index;
- (int) gainHistogram:(int) index;
- (ORTimeRate*) totalRate;
- (void) setTotalRate:(ORTimeRate*)newTotalRate;
- (NSString*) mapFile;
- (void) setMapFile:(NSString*)aMapFile;
- (NSString*) adcClassName;
- (void) setAdcClassName:(NSString*)anAdcClassName;
- (void) setSegments:(NSMutableArray*)anArray;
- (NSMutableArray*) segments;
- (BOOL) hwPresent:(int)aChannel;
- (BOOL) online:(int)aChannel;
- (NSMutableDictionary*) colorAxisAttributes;
- (void) setColorAxisAttributes:(NSMutableDictionary*)newcolorAxisAttributes;
- (float) rate;
- (float) getThreshold:(int) index;
- (float) getRate:(int) index;
- (BOOL) getError:(int) index;
- (void) showDialogForSegment:(int)aSegment;
- (float) getGain:(int) index;
- (float) getPartOfEvent:(int) index;
- (NSString*) selectedSegementInfo:(int)index;
- (void) clearSegmentErrors;
- (NSSet*) hwCards;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;

#pragma mark •••Work Methods
- (void) histogram;
- (void) collectRates;
- (void) setSegmentErrorClassName:(NSString*)aClassName card:(int)card channel:(int)channel;

#pragma mark •••Map Methods
- (void) readMap;
- (void) saveMapFileAs:(NSString*)newFileName;

#pragma mark •••Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end


extern NSString* ORSegmentGroupConfiguationChanged;
extern NSString* ORSegmentGroupMapFileChanged;
extern NSString* ORSegmentGroupAdcClassNameChanged;
extern NSString* ORSegmentGroupMapReadNotification;