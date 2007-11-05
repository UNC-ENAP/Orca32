//
//  NSColor+Extensions.m
//  Orca
//
//  Created by snodaq on 9/22/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


@implementation NSColor (NSColor_Extensions)
+ (NSColor*) passedColor
{
	return [NSColor colorWithDeviceRed:0 green:.5 blue:0 alpha:1];
}

+ (NSColor*) failedColor
{
	return [NSColor colorWithDeviceRed:.5 green:0 blue:0 alpha:1];
}

@end
