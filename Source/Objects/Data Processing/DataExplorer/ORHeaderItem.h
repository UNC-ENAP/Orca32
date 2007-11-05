//
//  ORHeaderItem.h
//  Orca
//
//  Created by Mark Howe on 12/6/04.
//  Copyright 2004 CENPA, University of Washington. All rights reserved.
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





@interface ORHeaderItem : NSObject {
    NSString* name;
    NSString* classType;
    NSMutableArray* items;
    id object;
}

+ (ORHeaderItem*) headerFromObject:(id)anObject named:(NSString*)aName;

- (NSString *) name;
- (void) setName: (NSString *) aName;

- (NSString *) classType;
- (void) setClassType: (NSString *) aType;
- (id) object;
- (void) setObject: (id) anObject;

- (NSMutableArray *) items;
- (void) setItems: (NSMutableArray *) anItems;
- (void) addObject:(id)anObject;
- (unsigned) count;
- (BOOL) isLeafNode;
- (id) childAtIndex:(int)index;
@end
