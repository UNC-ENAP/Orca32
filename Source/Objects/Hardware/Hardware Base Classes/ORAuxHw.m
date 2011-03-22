//
//  ORAuxHw.m
//  Orca
//
//  Created by Mark Howe on Tues Mar 22 2011.
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
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
#pragma mark ���Imported Files
#import "ORAuxHw.h"

@implementation ORAuxHw

- (void) addObjectInfoToArray:(NSMutableArray*)anArray
{
	NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
	if([self respondsToSelector:@selector(addParametersToDictionary:)]){
		[self addParametersToDictionary:dictionary];
	}
	if([dictionary count]){
		[anArray addObject:dictionary];
	}
}
@end
