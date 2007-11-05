//
//  ORProcessNub.m
//  Orca
//
//  Created by Mark Howe on 11/23/05.
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


#import "ORProcessEndNode.h"
//this is a placeholder class (for now) for objects that are at the start of
//the eval chain. Since the eval chain actually runs recursively backward
//these are objects like outputs.

@implementation ORProcessEndNode

- (BOOL) isTrueEndNode
{
    return YES;
}

@end
