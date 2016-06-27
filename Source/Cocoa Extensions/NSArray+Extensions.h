//
//  NSArray+Extensions.h
//
//  Copyright (c) 2001-2002, Apple. All rights reserved.
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


@interface NSArray (OrcaExtensions)
- (BOOL)containsObjectIdenticalTo: (id)object;
- (NSArray *)tabJoinedComponents;
- (NSString *)joinAsLinesOfEndingType:(LineEndingType)type;
- (NSData *)dataWithLineEndingType:(LineEndingType)lineEndingType;
- (id) objectForKeyArray:(NSMutableArray*)anArray;
- (void) prettyPrint:(NSString*)aTitle;
@end

@interface NSMutableArray (OrcaExtensions)
- (void) insertObjectsFromArray:(NSArray *)array atIndex:(int)index;
- (NSMutableArray*) children;
- (unsigned) numberOfChildren;
- (void) moveObject:(id)anObj toIndex:(unsigned)newIndex;

//implements stack behavior
- (id)   pop;
- (id)   popTop;
- (void) push:(id)object;
- (id)   peek;
@end
