//
//  ORDataSet.m
//  Orca
//
//  Created by Mark Howe on Tue Mar 18 2003.
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
#import "ORDataSet.h"
#import "OR1DHisto.h"
#import "OR2DHisto.h"
#import "ORPlotFFT.h"
#import "ORWaveform.h"
#import "ORMaskedWaveform.h"
#import "ORGenericData.h"
#import "ORScalerSum.h"
#import "ORDataPacket.h"
#import "ORCARootServiceDefs.h"
#import "ORPlotTimeSeries.h"

NSString* ORDataSetRemoved= @"ORDataSetRemoved";
NSString* ORDataSetCleared= @"ORDataSetCleared";
NSString* ORDataSetAdded  = @"ORDataSetAdded";

@implementation ORDataSet

#pragma mark •••Initialization
- (id) initWithKey: (NSString*) aKey guardian:(ORDataSet*)aGuardian
{
    self = [super init];
    if (self != nil) {
        realDictionary = [[NSMutableDictionary alloc] initWithCapacity: 32];
        [self setKey:aKey];
        [self setGuardian:aGuardian]; //we don't retain the guardian, so just set it here.
        data = nil;
		dataSetLock = [[NSLock alloc] init];
		if(kORCARootFitNames[0] != nil){} //just to get rid of stupid compiler warning
		if(kORCARootFFTNames[0] != nil){} //just to get rid of stupid compiler warning
		if(kORCARootFitShortNames[0] != nil){} //just to get rid of stupid compiler warning
		if(kORCARootFFTWindowOptions[0] != nil){} //just to get rid of stupid compiler warning
		if(kORCARootFFTWindowNames[0] != nil){} //just to get rid of stupid compiler warning
    }
    return self;
}

- (void) dealloc
{
	[dataSetLock lock];
    [[NSNotificationCenter defaultCenter]
			postNotificationName:ORDataSetRemoved
                          object:self
                        userInfo: nil];
    
    [realDictionary release];
    realDictionary = nil;
    
    [key release];
    [data release];
    
    [sortedArray release];
    sortedArray = nil;
	[dataSetLock unlock];
	[dataSetLock release];
    [super dealloc];
}

- (void) removeAllObjects
{
    [realDictionary removeAllObjects];
}

- (void) makeMainController
{
    [self linkToController:@"ORDataSetController"];
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    if([self leafNode]){
        [[self data] appendDataDescription:aDataPacket userInfo:userInfo];
    }
    else {
        NSEnumerator* e = [realDictionary  objectEnumerator];
        ORDataSet* d;
        while(d = [e nextObject]){
            [d appendDataDescription:aDataPacket userInfo:userInfo];
        }
    }
 }

- (ORDataSet*) dataSetWithName:(NSString*)aName
{
    ORDataSet* result = nil;
    if([self leafNode]){
        if([[[self data] shortName] isEqualToString:aName])result = [self data];
    }
    else {
        NSEnumerator* e = [realDictionary  objectEnumerator];
        ORDataSet* d;
        while(d = [e nextObject]){
            result = [d dataSetWithName:aName];
            if(result)return result;
        }
    }
    return result;
}

- (void) runTaskBoundary
{
    NSEnumerator* e = [realDictionary  objectEnumerator];
    ORDataSet* d;
    while(d = [e nextObject]){
        [d runTaskBoundary];
    }
    [data runTaskBoundary];
}


- (void) runTaskStopped
{
    //totalCounts = 0;
    NSEnumerator* e = [realDictionary  objectEnumerator];
    ORDataSet* d;
    while(d = [e nextObject]){
        [d runTaskStopped];
    }
    [data runTaskStopped];
}


- (void) clear
{
    totalCounts = 0;
    NSEnumerator* e = [realDictionary  objectEnumerator];
    ORDataSet* d;
    while(d = [e nextObject]){
        [d clear];
    }
    
    [data clear];
    
    [[NSNotificationCenter defaultCenter]
			postNotificationName:ORDataSetCleared
                          object:self
                        userInfo: nil];
    
    
}

- (unsigned long) recountTotal
{
    if(data != nil)return totalCounts;
    else totalCounts = 0;
    NSEnumerator* e = [realDictionary  objectEnumerator];
    ORDataSet* d;
    while(d = [e nextObject]){
        totalCounts += [d recountTotal];
    }
    return totalCounts;
}

- (unsigned long) totalCounts
{
    return totalCounts;
}

- (void) setTotalCounts:(unsigned long) newCount
{
    totalCounts = newCount;
}

- (void) incrementTotalCounts
{
	++totalCounts;
}

- (id) objectForKeyArray:(NSMutableArray*)anArray
{
	if([anArray count] == 0)return data;
	else {
		id aKey = [anArray objectAtIndex:0];
		[anArray removeObjectAtIndex:0];
		return [[realDictionary objectForKey:aKey] objectForKeyArray:anArray];;
    }
}

#pragma mark •••Writing Data
- (void) writeDataToFile:(FILE*)aFile
{
    if(data){
        if([data respondsToSelector:@selector(writeDataToFile:)]){
            [data writeDataToFile:aFile];
        }
    }
    else {
        NSEnumerator* e = [realDictionary objectEnumerator];
        id obj;
        while(obj = [e nextObject]){
            [obj writeDataToFile:aFile];
        }
    }
}

- (NSArray*) collectObjectsOfClass:(Class)aClass
{
    NSMutableArray* collection = [NSMutableArray arrayWithCapacity:256];
    
    NSEnumerator* e  = [realDictionary keyEnumerator];
    id aKey;
    id objectData;
    while(aKey = [e nextObject]){
        objectData = [[realDictionary objectForKey:aKey] data];
        if(objectData)[collection addObjectsFromArray:[objectData collectObjectsOfClass:aClass]];
        else [collection addObjectsFromArray:[[realDictionary objectForKey:aKey] collectObjectsOfClass:aClass]];
    }	
    return collection;
}

#pragma mark •••Primative NSDictionary Methods
- (unsigned) count
{
    return [realDictionary count];
}

- (NSEnumerator *) keyEnumerator
{
    return [realDictionary keyEnumerator];
}

- (id) objectForKey: (id) aKey
{
    return  [realDictionary objectForKey: aKey];
}

- (void) removeObject:(id)anObj
{
    NSEnumerator* e = [realDictionary keyEnumerator];
    id aKey;
	NSMutableArray* keysToRemoveFromSelf = [NSMutableArray array];
    while(aKey = [e nextObject]){
        ORDataSet* aDataSet = [realDictionary objectForKey:aKey];
        if(aDataSet == anObj){
			[keysToRemoveFromSelf addObject:aKey];
        }
        else {
            [[realDictionary objectForKey:aKey] removeObject:anObj];
        }
    }
    [realDictionary removeObjectsForKeys: keysToRemoveFromSelf];
    [sortedArray release];
    sortedArray = [[realDictionary keysSortedByValueUsingSelector:@selector(compare:)] retain];

}

- (void) removeObjectForKey: (id) aKey;
{
    [realDictionary removeObjectForKey: aKey];
    [sortedArray release];
    sortedArray = [[realDictionary keysSortedByValueUsingSelector:@selector(compare:)] retain];
}

- (void) setObject: (id) anObject forKey: (id) aKey;
{
    BOOL newObj = NO;
    if(![realDictionary objectForKey:aKey])newObj = YES;
    
    [realDictionary setObject: anObject  forKey: aKey];
    [sortedArray release];
    sortedArray = [[realDictionary keysSortedByValueUsingSelector:@selector(compare:)] retain];

}

- (NSComparisonResult) compare:(NSString *)aString
{
    return [aString compare:[self name]];
}

#pragma mark •••Accessors
- (NSString*) shortName
{
    if([self leafNode])return [data shortName];
    else return key;
}

- (NSString*) key
{
    if([self leafNode])return [data key];
    else return key;
}

- (NSString*) name
{
    if([self leafNode])return [data name];
    else return [NSString stringWithFormat:@"%@   count: %u",key,totalCounts];
}

- (void) setKey:(NSString*)aKey
{
    [key autorelease];
    key = [aKey copy];
}

- (id) data
{
    return [[data retain] autorelease];
}


- (void) setData:(id)someData
{	
	[dataSetLock lock];
    [someData retain];
    [data release];
    data = someData;
	[dataSetLock unlock];

}



- (NSString*) prependFullName:(NSString*)aName
{
    if(guardian == nil)return aName;
    return [guardian prependFullName:[key stringByAppendingFormat:@",%@",aName]];
}


- (NSEnumerator*) objectEnumerator
{
    return [realDictionary objectEnumerator];
}

#pragma mark •••Level Info
- (BOOL) leafNode
{
    return data != nil;
}


- (void) packageData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    NSEnumerator* e = [realDictionary keyEnumerator];
    NSString* aKey;
    while(aKey = [e nextObject]){
        ORDataSet* ds = [realDictionary objectForKey:aKey];
        [ds packageData:aDataPacket userInfo:userInfo keys:[NSMutableArray arrayWithObject:aKey]];
    }
}

- (void) packageData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo keys:(NSMutableArray*)aKeyArray
{
    if([self leafNode]){
        [[self data] packageData:aDataPacket userInfo:userInfo keys:aKeyArray];
    }
    else {
        NSEnumerator* e = [realDictionary keyEnumerator];
        NSString* aKey;
        while(aKey = [e nextObject]){
            ORDataSet* ds = [realDictionary objectForKey:aKey];
            [aKeyArray addObject:aKey];
            [ds packageData:aDataPacket userInfo:userInfo keys:aKeyArray];
            [aKeyArray removeObject:aKey];
        }
    }
}

- (NSArray*) collectObjectsRespondingTo:(SEL)aSelector
{
    NSMutableArray* collection = [NSMutableArray arrayWithCapacity:256];

    if([self leafNode]){
        [collection addObjectsFromArray:[[self data] collectObjectsRespondingTo:aSelector]];
    }
    else {
        NSEnumerator* e = [realDictionary keyEnumerator];
        NSString* aKey;
        while(aKey = [e nextObject]){
            ORDataSet* ds = [realDictionary objectForKey:aKey];
            [collection addObjectsFromArray:[ds collectObjectsRespondingTo:aSelector]];
        }
    }
    return collection;
    
}

#pragma mark •••Data Insertion
- (void)loadHistogram:(unsigned long*)ptr numBins:(unsigned long)numBins withKeyArray:(NSArray*)keyArray
{
    
    int n = [keyArray count];
    int i;
    ORDataSet* currentLevel = self;
    ORDataSet* nextLevel    = nil;
    [currentLevel incrementTotalCounts];
    
    for(i=0;i<n;i++){
        NSString* s = [keyArray objectAtIndex:i];
        nextLevel = [currentLevel objectForKey:s];
        if(nextLevel){
            if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
            currentLevel = nextLevel;
        }
        else {
            nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
            [currentLevel setObject:nextLevel forKey:s];
            currentLevel = nextLevel;
            [nextLevel release];
        }
        [currentLevel incrementTotalCounts];
    }
    
    OR1DHisto* histo = [nextLevel data];
    if(!histo){
        histo = [[OR1DHisto alloc] init];
        [histo setKey:[nextLevel key]];
        [histo setFullName:[[nextLevel guardian] prependFullName:[nextLevel key]]];
        [histo setNumberBins:numBins];
        [nextLevel setData:histo];
		[histo setDataSet:self];
        [histo mergeHistogram:ptr numValues:numBins];
        [histo release];
        [[NSNotificationCenter defaultCenter]
                postNotificationName:ORDataSetAdded
                              object:self
                            userInfo: nil];
    }
    else [histo mergeHistogram:ptr numValues:numBins];
}

- (void) histogram:(unsigned long)aValue numBins:(unsigned long)numBins sender:(id)obj  withKeys:(NSString*)firstArg,...
{
    va_list myArgs;
    va_start(myArgs,firstArg);
    
    NSString* s             = firstArg;
    ORDataSet* currentLevel = self;
    ORDataSet* nextLevel    = nil;
    [currentLevel incrementTotalCounts];
    
    do {
        nextLevel = [currentLevel objectForKey:s];
        if(nextLevel){
            if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
            currentLevel = nextLevel;
        }
        else {
            nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
            [currentLevel setObject:nextLevel forKey:s];
            currentLevel = nextLevel;
            [nextLevel release];
        }
        [currentLevel incrementTotalCounts];
        
    } while(s = va_arg(myArgs, NSString *));
    
    
    OR1DHisto* histo = [nextLevel data];
    if(!histo){
        histo = [[OR1DHisto alloc] init];
        [histo setKey:[nextLevel key]];
        [histo setFullName:[[nextLevel guardian] prependFullName:[nextLevel key]]];
        [histo setNumberBins:numBins];
		[histo setDataSet:self];
        [nextLevel setData:histo];
        [histo histogram:aValue];
        [histo release];
        [[NSNotificationCenter defaultCenter]
                postNotificationName:ORDataSetAdded
                              object:self
                            userInfo: nil];
    }
    else [histo histogram:aValue];
    
    va_end(myArgs);
    
}

// ak 6.8.07 
- (void) histogramWW:(unsigned long)aValue weight:(unsigned long)aWeight numBins:(unsigned long)numBins sender:(id)obj  withKeys:(NSString*)firstArg,...
{
    va_list myArgs;
    va_start(myArgs,firstArg);
    
    NSString* s             = firstArg;
    ORDataSet* currentLevel = self;
    ORDataSet* nextLevel    = nil;
    [currentLevel incrementTotalCounts];
    
    do {
        nextLevel = [currentLevel objectForKey:s];
        if(nextLevel){
            if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
            currentLevel = nextLevel;
        }
        else {
            nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
            [currentLevel setObject:nextLevel forKey:s];
            currentLevel = nextLevel;
            [nextLevel release];
        }
        [currentLevel incrementTotalCounts];
        
    } while(s = va_arg(myArgs, NSString *));
    
    
    OR1DHisto* histo = [nextLevel data];
    if(!histo){
        histo = [[OR1DHisto alloc] init];
        [histo setKey:[nextLevel key]];
        [histo setFullName:[[nextLevel guardian] prependFullName:[nextLevel key]]];
        [histo setNumberBins:numBins];
		[histo setDataSet:self];
        [nextLevel setData:histo];
        [histo histogramWW:aValue weight:aWeight];
        [histo release];
        [[NSNotificationCenter defaultCenter]
                postNotificationName:ORDataSetAdded
                              object:self
                            userInfo: nil];
    }
    else [histo histogramWW:aValue weight:aWeight];
    
    va_end(myArgs);
    
}


- (void) histogram2DX:(unsigned long)xValue y:(unsigned long)yValue size:(unsigned short)numBins sender:(id)obj  withKeys:(NSString*)firstArg,...
{
    va_list myArgs;
    va_start(myArgs,firstArg);
    
    NSString* s             = firstArg;
    ORDataSet* currentLevel = self;
    ORDataSet* nextLevel    = nil;
    [currentLevel incrementTotalCounts];
    
    do {
        nextLevel = [currentLevel objectForKey:s];
        if(nextLevel){
            if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
            currentLevel = nextLevel;
        }
        else {
            nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
            [currentLevel setObject:nextLevel forKey:s];
            currentLevel = nextLevel;
            [nextLevel release];
        }
        [currentLevel incrementTotalCounts];
        
    } while(s = va_arg(myArgs, NSString *));
    
    
    OR2DHisto* histo = [nextLevel data];
    if(!histo){
        histo = [[OR2DHisto alloc] init];
        [histo setKey:[nextLevel key]];
        [histo setFullName:[[nextLevel guardian] prependFullName:[nextLevel key]]];
        [histo setNumberBinsPerSide:numBins];
        [nextLevel setData:histo];
        [histo histogramX:xValue y:yValue];  
        [histo release];
        [[NSNotificationCenter defaultCenter]
                postNotificationName:ORDataSetAdded
                              object:self
                            userInfo: nil];
    }
    
    else [histo histogramX:xValue y:yValue];
    
    va_end(myArgs);
    
}


- (void)loadHistogram2D:(unsigned long*)ptr numBins:(unsigned long)numBins withKeyArray:(NSArray*)keyArray
{
    
    int n = [keyArray count];
    int i;
    ORDataSet* currentLevel = self;
    ORDataSet* nextLevel    = nil;
    [currentLevel incrementTotalCounts];
    
    for(i=0;i<n;i++){
        NSString* s = [keyArray objectAtIndex:i];
        nextLevel = [currentLevel objectForKey:s];
        if(nextLevel){
            if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
            currentLevel = nextLevel;
        }
        else {
            nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
            [currentLevel setObject:nextLevel forKey:s];
            currentLevel = nextLevel;
            [nextLevel release];
        }
        [currentLevel incrementTotalCounts];
    }
    
    OR2DHisto* histo = [nextLevel data];
    if(!histo){
        histo = [[OR2DHisto alloc] init];
        [histo setKey:[nextLevel key]];
        [histo setFullName:[[nextLevel guardian] prependFullName:[nextLevel key]]];
        [histo setNumberBinsPerSide:(unsigned int)pow((float)numBins,.5)];
        [nextLevel setData:histo];
        [histo mergeHistogram:ptr numValues:numBins];
        [histo release];
        [[NSNotificationCenter defaultCenter]
                postNotificationName:ORDataSetAdded
                              object:self
                            userInfo: nil];
    }
    else [histo mergeHistogram:ptr numValues:numBins];
}




- (void) loadWaveform:(NSData*)aWaveForm offset:(unsigned long)anOffset unitSize:(int)aUnitSize sender:(id)obj  withKeys:(NSString*)firstArg,...
{
    va_list myArgs;
    va_start(myArgs,firstArg);
    
    NSString* s             = firstArg;
    ORDataSet* currentLevel = self;
    ORDataSet* nextLevel    = nil;
    [currentLevel incrementTotalCounts];

    
    do {
        nextLevel = [currentLevel objectForKey:s];
        if(nextLevel){
            if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
            currentLevel = nextLevel;
        }
        else {
            nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
            [currentLevel setObject:nextLevel forKey:s];
            currentLevel = nextLevel;
            [nextLevel release];
        }
        [currentLevel incrementTotalCounts];
        
    } while(s = va_arg(myArgs, NSString *));
    
    ORWaveform* waveform = [nextLevel data];
    if(!waveform){
        waveform = [[ORWaveform alloc] init];
		[waveform setDataSet:self];
        [waveform setDataOffset:anOffset];
        [waveform setKey:[nextLevel key]];
        [waveform setFullName:[[nextLevel guardian] prependFullName:[nextLevel key]]];
		[waveform setUnitSize:aUnitSize];
        [nextLevel setData:waveform];
        [waveform setWaveform:aWaveForm];       
        [waveform release];
        [[NSNotificationCenter defaultCenter]
                postNotificationName:ORDataSetAdded
                              object:self
                            userInfo: nil];
    }
    
    else {
		[waveform setDataSet:self];
		[waveform setWaveform:aWaveForm];
    }
    va_end(myArgs);
    
}


- (void) loadWaveform:(NSData*)aWaveForm offset:(unsigned long)anOffset unitSize:(int)aUnitSize mask:(unsigned long)aMask sender:(id)obj  withKeys:(NSString*)firstArg,...
{
    va_list myArgs;
    va_start(myArgs,firstArg);
    
    NSString* s             = firstArg;
    ORDataSet* currentLevel = self;
    ORDataSet* nextLevel    = nil;
    [currentLevel incrementTotalCounts];

    
    do {
        nextLevel = [currentLevel objectForKey:s];
        if(nextLevel){
            if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
            currentLevel = nextLevel;
        }
        else {
            nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
            [currentLevel setObject:nextLevel forKey:s];
            currentLevel = nextLevel;
            [nextLevel release];
        }
        [currentLevel incrementTotalCounts];
        
    } while(s = va_arg(myArgs, NSString *));
    
    ORMaskedWaveform* waveform = [nextLevel data];
    if(!waveform){
        waveform = [[ORMaskedWaveform alloc] init];
		[waveform setDataSet:self];
		[waveform setMask:aMask];
        [waveform setDataOffset:anOffset];
        [waveform setKey:[nextLevel key]];
        [waveform setFullName:[[nextLevel guardian] prependFullName:[nextLevel key]]];
		[waveform setUnitSize:aUnitSize];
        [nextLevel setData:waveform];
        [waveform setWaveform:aWaveForm];       
        [waveform release];
        [[NSNotificationCenter defaultCenter]
                postNotificationName:ORDataSetAdded
                              object:self
                            userInfo: nil];
    }
    
    else {
		[waveform setDataSet:self];
		[waveform setWaveform:aWaveForm];
    }
    va_end(myArgs);
    
}


- (void) loadGenericData:(NSString*)aString sender:(id)obj withKeys:(NSString*)firstArg,...
{
    va_list myArgs;
    va_start(myArgs,firstArg);
    
    NSString* s             = firstArg;
    ORDataSet* currentLevel = self;
    ORDataSet* nextLevel    = nil;
    
    [currentLevel incrementTotalCounts];
    do {
        nextLevel = [currentLevel objectForKey:s];
        if(nextLevel){
            if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
            currentLevel = nextLevel;
        }
        else {
            nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
            [currentLevel setObject:nextLevel forKey:s];
            currentLevel = nextLevel;
            [nextLevel release];
        }
        [currentLevel incrementTotalCounts];
        
    } while(s = va_arg(myArgs, NSString *));

    ORGenericData* genericData = [nextLevel data];
    if(!genericData){
        genericData = [[ORGenericData alloc] init];
        [genericData setKey:[nextLevel key]];
        [nextLevel setData:genericData];
        [genericData release];
        [[NSNotificationCenter defaultCenter]
                postNotificationName:ORDataSetAdded
                              object:self
                            userInfo: nil];
    }
    
    [genericData setGenericData:aString];
    
    
    va_end(myArgs);
}




//exists only as a alternate calling method. i.e. used by NSLogError.
- (void) loadGenericData:(NSString*)aString sender:(id)obj usingKeyArray:(NSArray*)myArgs
{
    ORDataSet* currentLevel = self;
    ORDataSet* nextLevel = nil;
    [currentLevel incrementTotalCounts];
    NSEnumerator* e = [myArgs objectEnumerator];
    if(myArgs){
        id s;
        while(s = [e nextObject]) {
            nextLevel = [currentLevel objectForKey:s];
            if(nextLevel == nil){
                nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
                [currentLevel setObject:nextLevel forKey:s];
                currentLevel = nextLevel;
                [nextLevel release];
            }
            else {
                if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
                currentLevel = nextLevel;
            }
            [currentLevel incrementTotalCounts];
            
        }
    }
    else nextLevel = self;
    ORGenericData* genericData = [nextLevel data];
    if(!genericData){
        genericData = [[ORGenericData alloc] init];
        [genericData setKey:[nextLevel key]];
        [nextLevel setData:genericData];
        [genericData setGenericData:aString];
        [genericData release];
        [[NSNotificationCenter defaultCenter]
                postNotificationName:ORDataSetAdded
                              object:self
                            userInfo: nil];
    }
    
    else [genericData setGenericData:aString];
}

- (void) loadScalerSum:(unsigned long)aValue sender:(id)obj withKeys:(NSString*)firstArg,...
{
    va_list myArgs;
    va_start(myArgs,firstArg);
    
    NSString* s             = firstArg;
    ORDataSet* currentLevel = self;
    ORDataSet* nextLevel    = nil;
    
    do {
        nextLevel = [currentLevel objectForKey:s];
        if(nextLevel){
            if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
            currentLevel = nextLevel;
        }
        else {
            nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
            [currentLevel setObject:nextLevel forKey:s];
            currentLevel = nextLevel;
            [nextLevel release];
        }
        
    } while(s = va_arg(myArgs, NSString *));

    ORScalerSum* scalerSumData = [nextLevel data];
    if(!scalerSumData){
        scalerSumData = [[ORScalerSum alloc] init];
        [scalerSumData setKey:[nextLevel key]];
        [nextLevel setData:scalerSumData];
        [scalerSumData release];
        [[NSNotificationCenter defaultCenter]
                postNotificationName:ORDataSetAdded
                              object:self
                            userInfo: nil];
    }
    
    [scalerSumData loadScalerValue:aValue];
    
    va_end(myArgs);
}

- (void) loadTimeSeries:(float)aValue atTime:(unsigned long)aTime sender:(id)obj withKeys:(NSString*)firstArg,...
{
    va_list myArgs;
    va_start(myArgs,firstArg);
    
    NSString* s             = firstArg;
    ORDataSet* currentLevel = self;
    ORDataSet* nextLevel    = nil;
    [currentLevel incrementTotalCounts]; // was missing -tb- 2008-02-07
    
    do {
        nextLevel = [currentLevel objectForKey:s];
        if(nextLevel){
            if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
            currentLevel = nextLevel;
        }
        else {
            nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
            [currentLevel setObject:nextLevel forKey:s];
            currentLevel = nextLevel;
            [nextLevel release];
        }
        [currentLevel incrementTotalCounts];
        
    } while(s = va_arg(myArgs, NSString *));

    ORPlotTimeSeries* timeSeries = [nextLevel data];
    if(!timeSeries){
        timeSeries = [[ORPlotTimeSeries alloc] init];
        [timeSeries setKey:[nextLevel key]];
		[timeSeries setDataSet:self]; // was missing -tb- 2008-02-07
        [nextLevel setData:timeSeries];
        [timeSeries setFullName:[[nextLevel guardian] prependFullName:[nextLevel key]]];
        [timeSeries release];
        [[NSNotificationCenter defaultCenter]
                postNotificationName:ORDataSetAdded
                              object:self
                            userInfo: nil];
    }
    
    [timeSeries addValue:aValue atTime:aTime];
    
    va_end(myArgs);
}


- (void)loadFFTReal:(NSArray*)realArray imaginary:(NSArray*)imaginaryArray withKeyArray:(NSArray*)keyArray
{
    
    int n = [keyArray count];
    int i;
    ORDataSet* currentLevel = self;
    ORDataSet* nextLevel    = nil;
    [currentLevel incrementTotalCounts];
    
    for(i=0;i<n;i++){
        NSString* s = [keyArray objectAtIndex:i];
        nextLevel = [currentLevel objectForKey:s];
        if(nextLevel){
            if([nextLevel guardian] == nil)[nextLevel setGuardian:currentLevel];
            currentLevel = nextLevel;
        }
        else {
            nextLevel = [[ORDataSet alloc] initWithKey:s guardian:currentLevel];
            [currentLevel setObject:nextLevel forKey:s];
            currentLevel = nextLevel;
            [nextLevel release];
        }
        [currentLevel incrementTotalCounts];
    }
    
    ORPlotFFT* fftPlot = [nextLevel data];
    if(!fftPlot){
        fftPlot = [[ORPlotFFT alloc] init];
        [fftPlot setKey:[nextLevel key]];
        [fftPlot setFullName:[[nextLevel guardian] prependFullName:[nextLevel key]]];
 		[fftPlot setRealArray:realArray imaginaryArray:imaginaryArray];
        [nextLevel setData:fftPlot];
        [fftPlot release];
        [[NSNotificationCenter defaultCenter]
                postNotificationName:ORDataSetAdded
                              object:self
                            userInfo: nil];
    }
    else {
		[fftPlot setRealArray:realArray imaginaryArray:imaginaryArray];
 	}
	[[currentLevel data] makeMainController];
}


- (void) processResponse:(NSDictionary*)aResponse
{
	NSString* title = [aResponse objectForKey:ORCARootServiceTitleKey];
	NSMutableArray* keyArray = [NSMutableArray arrayWithArray:[title componentsSeparatedByString:@","]];
	[keyArray insertObject:@"FFT" atIndex:0];
	NSArray* complex = [aResponse nestedObjectForKey:@"Request Outputs",@"FFTComplex",nil];
	NSArray* real    = [aResponse nestedObjectForKey:@"Request Outputs",@"FFTReal",nil];
	[self loadFFTReal:real imaginary:complex withKeyArray:keyArray];
}

#pragma mark •••Data Source Methods
- (unsigned)  numberOfChildren
{
    return [self count];
}

- (id)   childAtIndex:(int)index
{
    if([self leafNode])return data;
    else {
        id obj = [realDictionary objectForKey:[sortedArray objectAtIndex:index]];
        if(obj)return obj;
    }
    return nil;
}

- (void) doDoubleClick:(id)sender
{
    if([self leafNode])[data makeMainController];
    else {
        NSEnumerator* e = [realDictionary objectEnumerator];
        id obj;
        while(obj=[e nextObject]){
            if([obj data] == nil){
                return;
            }
        }
        [self makeMainController];
        
    }
}

- (NSString*) summarizeIntoString:(NSMutableString*)summary
{
    return [self summarizeIntoString:summary level:0];
}

- (NSString*) summarizeIntoString:(NSMutableString*)summary level:(int)level
{
    NSMutableString* padding = [NSMutableString stringWithCapacity:level];
    int i;
    for(i=0;i<level;i++)[padding appendString:@" "];
    if([padding length] == 0)[padding appendString:@""];
    
    [summary appendFormat:@"%@%@\n",padding,[self name]];
    
    NSEnumerator* e = [sortedArray objectEnumerator];
    id akey;
    ++level;
    while(akey = [e nextObject]){
        id obj = [realDictionary objectForKey:akey];
        NSMutableString* aString = [NSMutableString stringWithCapacity:256];
        NSString* s = [obj summarizeIntoString:aString level:level];
        if(s)[summary appendString:s];
    }
    
    return summary;
}



#pragma mark •••Archival
static NSString *ORDataSetRealDictionary 	= @"OR Data Dictionary";
static NSString *ORDataData 			= @"OR Data Data";
static NSString *ORDataKey 			= @"OR Data Key";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    dataSetLock = [[NSLock alloc] init];
    realDictionary = [[decoder decodeObjectForKey:ORDataSetRealDictionary] retain];
    if(data == nil){
        [sortedArray release];
        sortedArray = [[realDictionary keysSortedByValueUsingSelector:@selector(compare:)] retain];
    }
    [self setData:[decoder decodeObjectForKey:ORDataData]];
    [self setKey:[decoder decodeObjectForKey:ORDataKey]];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    
    [encoder encodeObject:realDictionary forKey:ORDataSetRealDictionary];
    [encoder encodeObject:data forKey:ORDataData];
    [encoder encodeObject:key forKey:ORDataKey];
}

@end