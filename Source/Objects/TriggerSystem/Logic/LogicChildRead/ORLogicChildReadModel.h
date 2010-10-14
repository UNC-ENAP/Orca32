//
//  ORLogicChildReadModel.h
//  Orca
//
//  Created by Mark Howe on 10/6/10.
//  Copyright  � 2009 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Physics and 
//Astrophysics Department sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#import "ORTriggerProtocols.h"

@interface ORLogicChildReadModel :  OrcaObject <TriggerChildReadingEndNode>
{
	unsigned long childIndex;
}
- (unsigned short) childIndex;
- (void) setChildIndex:(unsigned short)aBit;
- (BOOL) evalWithDelegate:(id)anObj;
@end

extern NSString* ORLogicChildReadChanged;

@interface ORLogicChildRead2Model :  OrcaObject
{
	unsigned long childIndex;
}
- (unsigned short) childIndex;
- (void) setChildIndex:(unsigned short)aBit;
- (void) useImage:(NSImage*) aCachedImage;
- (BOOL) evalWithDelegate:(id)anObj;
@end


@interface NSObject (ORLogicChildReadModel)
- (void) readChild:(int)index;
@end
