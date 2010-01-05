//
//  ORMaskedWaveform.m
//  Orca
//
//  Created by Mark Howe on Wed Aug 7 2007.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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

#import "ORMaskedWaveform.h"

@implementation ORMaskedWaveform

#pragma mark ���Accessors
- (BOOL) useDataObject:(id)aPlotter  dataSet:(int)set
{
	return NO;
}

- (unsigned long) mask
{
	return mask;
}

- (void) setMask:(unsigned long)aMask
{
	mask=aMask;
}

-(long) value:(unsigned short)aChan
{
	if(!mask)return [super value:aChan];
	return [super value:aChan] & mask;
}

@end

@implementation ORMaskedIndexedWaveform

#pragma mark ���Accessors

- (void) setStartIndex:(unsigned long)anIndex
{
	startIndex = anIndex;
}

- (unsigned long) startIndex
{
	return startIndex;
}

-(long) value:(unsigned short)aChan
{
	aChan = (aChan + startIndex)%[self numberBins];;
	if(!mask)return [super value:aChan];
	return [super value:aChan] & mask;
}

@end


