//
//  ORNodeEvaluator.h
//  Orca
//
//  Created by Mark Howe on 12/29/06.
//  Copyright 2006 University of North Carolina. All rights reserved.
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

@interface ORNodeEvaluator : NSObject {
	NSMutableDictionary* symbolTable;
	NSMutableDictionary* argValueDicionary;
	NSArray*			 parsedNodes;
	NSDecimalNumber*	 _one;
	NSDecimalNumber*	 _zero;
	NSDictionary*		 functionTable;
	NSMutableDictionary* sysCallTable;
	unsigned short       switchLevel;
	id					 switchValue[256];
	id					 delegate;
	BOOL				 stop;
	NSFileHandle*		 logFileHandle;
	NSLock*				 symbolTableLock; 
	ORNodeEvaluator*	 functionEvaluator;
	int					 functionLevel;
	NSString*			 functionName;
}

#pragma mark •••Initialization
- (id) initWithFunctionTable:(id)aFunctionTable functionName:(NSString*)aFunctionName;
- (void) dealloc; 
- (NSUndoManager*) undoManager;

#pragma mark •••Accessors
- (ORNodeEvaluator*) functionEvaluator;
- (void) setDelegate:(id)aDelegate;
- (NSString*) scriptName;
- (BOOL)	exitNow;

#pragma mark •••Symbol Table Routines
- (void) setFunctionLevel:(int)aLevel;
- (int) functionLevel;
- (NSString*) functionName;
- (void) setValue:(id)aValue forIndex:(int) anIndex;
- (unsigned) symbolTableCount;
- (id) symbolNameForIndex:(int)i;
- (id) symbolValueForIndex:(int)i;
- (NSMutableDictionary*) minSymbolTable;
- (NSDictionary*) makeSymbolTableFor:(NSString*)aFunctionName args:(id)argObject;
- (void) setSymbolTable:(NSDictionary*)aSymbolTable;
- (void) setArgs:(id)someArgs;
- (id) valueForSymbol:(NSString*) aSymbol;
- (id) setValue:(id)aValue forSymbol:(id) aSymbol;
- (void) setUpSysCallTable;

#pragma mark •••Finders and Makers
- (id) findObject:(id) p;
- (id) findObject:(id) p;
- (id) findCrate:(id)p collection:objects;
- (id) findCard:(id)p collection:objects;
- (id) findVmeDaughterCard:(id)p collection:objects;

#pragma mark •••Individual Evaluators
- (id)		execute:(id) p container:(id)aContainer;
- (id)		printNode:(id) p;
- (void)	printAll:(NSArray*)someNodes;
- (id)		sciString:(id) p precision:(id)thePrecision;
- (id)		fixedString:(id) p precision:(id)thePrecision;
@end

@interface ORSysCall : NSObject
{
	void* funcPtr;
	NSString* funcName;
	int numArgs;
	id anObject;
}
+ (id) sysCall:(void*)aFuncPtr name:(NSString*)aFuncName numArgs:(int)aNumArgs;
+ (id) sysCall:(void*)aFuncPtr name:(NSString*)aFuncName obj:(id)anObject numArgs:(int)aNumArgs;

- (id) initWithCall:(void*)afunc name:(NSString*)aFuncName obj:(id)anObject numArgs:(int)n;
- (id) executeWithArgs:(NSArray*)valueArray;
@end

@interface NSArray (ORNodeEvaluation)
- (NSComparisonResult)compare:(NSArray *)otherNumber;
@end

@interface NSDictionary (ORNodeEvaluation)
- (NSComparisonResult)compare:(NSDictionary *)otherNumber;
@end

@interface OrcaObjectController (ORNodeEvaluation)
- (NSComparisonResult)compare:(NSNumber *)otherNumber;
- (BOOL)	exitNow;
@end