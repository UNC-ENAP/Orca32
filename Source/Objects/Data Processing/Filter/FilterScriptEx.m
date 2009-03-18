//
//  FilterScriptEx.m
//  Orca
//
//  Created by Mark Howe on Fri Jan 25 2008.
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

#include <stdio.h>
#include "FilterScript.h"
#include "ORFilterModel.h"
#include "FilterScript.tab.h"
#import "StatusLog.h"
#import "ORDataTypeAssigner.h"
#import <time.h>
#include <stdlib.h>

extern unsigned short   switchLevel;
extern long				switchValue[512];
extern long startFilterNodeCount;
extern nodeType** startFilterNodes;
extern long filterNodeCount;
extern nodeType** filterNodes;
extern long finishFilterNodeCount;
extern nodeType** finishFilterNodes;
extern long maxFilterNodeCount;
extern long maxStartFilterNodeCount;
extern long maxFinishFilterNodeCount;
filterData ex(nodeType*,id);

void startFilterScript(id delegate)
{
	
	time_t seconds;
	time(&seconds);
	srand((unsigned int) seconds);
	
	unsigned node;
	for(node=0;node<startFilterNodeCount;node++){
		@try {
			ex(startFilterNodes[node],delegate);
		}
		@catch(NSException* localException) {
		}
	}
}

void finishFilterScript(id delegate)
{
	unsigned node;
	for(node=0;node<finishFilterNodeCount;node++){
		@try {
			ex(finishFilterNodes[node],delegate);
		}
		@catch(NSException* localException) {
		}
	}
}


void runFilterScript(id delegate)
{
	unsigned node;
	for(node=0;node<filterNodeCount;node++){
		@try {
			ex(filterNodes[node],delegate);
		}
		@catch(NSException* localException) {
		}
	}
}

void doSwitch(nodeType *p, id delegate)
{
	@try {
		switchLevel++;
		switchValue[switchLevel] = ex(p->opr.op[0],delegate).val.lValue;
		ex(p->opr.op[1],delegate);
	}
	@catch(NSException* localException) {
		if(![[localException name] isEqualToString:@"break"]){
			switchValue[switchLevel] = 0;
			switchLevel--;
			[localException raise]; //rethrow
		}
	}
	switchValue[switchLevel] = 0;
	switchLevel--;
}

void doCase(nodeType *p, id delegate)
{
	if(switchValue[switchLevel] == ex(p->opr.op[0],delegate).val.lValue){
		ex(p->opr.op[1],delegate);
		if (p->opr.nops == 3)ex(p->opr.op[2],delegate);
	}
}

void doDefault(nodeType *p, id delegate)
{
	ex(p->opr.op[0],delegate);
	if (p->opr.nops == 2)ex(p->opr.op[1],delegate);
}


void doLoop(nodeType *p, id delegate)
{
	BOOL breakLoop		= NO;
	BOOL continueLoop	= NO;
	do {
		if([delegate exitNow])break; 
		else {
			@try {
				ex(p->opr.op[0],delegate);
			}
			@catch(NSException* localException) {
				if([[localException name] isEqualToString:@"continue"])continueLoop = YES;
				else if([[localException name] isEqualToString:@"break"])breakLoop = YES;
				else [localException raise];
			}
		}
		if(breakLoop)break;
		if(continueLoop)continue;
	} while(ex(p->opr.op[1],delegate).val.lValue);
}

void whileLoop(nodeType* p, id delegate)
{
	BOOL breakLoop		= NO;
	BOOL continueLoop	= NO;
	while(ex(p->opr.op[0],delegate).val.lValue){ 
		if([delegate exitNow])break; 
		else {
			@try {
				ex(p->opr.op[1],delegate);
			}
			@catch(NSException* localException) {
				if([[localException name] isEqualToString:@"continue"])continueLoop = YES;
				else if([[localException name] isEqualToString:@"break"])breakLoop = YES;
				else [localException raise];
			}
		}
		if(breakLoop)	 break;
		if(continueLoop) continue;
	}
}

void forLoop(nodeType* p, id delegate)
{
	BOOL breakLoop		= NO;
	BOOL continueLoop	= NO;
	for(ex(p->opr.op[0],delegate).val.lValue ; ex(p->opr.op[1],delegate).val.lValue ; ex(p->opr.op[2],delegate).val.lValue){
		if([delegate exitNow])break;
		else {
			@try {
				ex(p->opr.op[3],delegate);
			}
			@catch(NSException* localException) {
				if([[localException name] isEqualToString:@"continue"])  continueLoop = YES;
				else if([[localException name] isEqualToString:@"break"])breakLoop = YES;
				else [localException raise];
			}
		}
		if(breakLoop)	 break;
		if(continueLoop) continue;
	}
}

void defineArray(nodeType* p, id delegate)
{
	int n = ex(p->opr.op[1],delegate).val.lValue;
	unsigned long* ptr = 0;
	if(n>0) ptr = calloc(n, sizeof(unsigned long));
	filterData tempData;
	tempData.type		= kFilterPtrType;
	tempData.val.pValue = ptr;
	[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
}

void freeArray(nodeType* p, id delegate)
{
	filterData theFilterData;
	if([symbolTable getData:&theFilterData forKey:p->opr.op[0]->ident.key]){
		if(theFilterData.type == kFilterPtrType){
			if(theFilterData.val.pValue !=0){
				free(theFilterData.val.pValue);
				theFilterData.val.pValue = 0;
				[symbolTable setData:theFilterData forKey:p->opr.op[0]->ident.key];
			}
			//else {
			//	[NSException raise:@"Access Violation" format:@"Free of NIL pointer"];
			//}
		}
	}
}
unsigned long* loadArray(unsigned long* ptr, nodeType* p)
{
	filterData tempData;
    switch(p->type) {
		case typeCon: *ptr++ = p->con.value;		 break;
		case typeId:       
			[symbolTable getData:&tempData forKey:p->ident.key];
			*ptr++ = tempData.val.lValue;
			break;
		case typeOpr:
			switch(p->opr.oper) {
				case kMakeArgList:	
					ptr = loadArray(ptr++,p->opr.op[0]); 
					if(p->opr.nops == 2)ptr = loadArray(ptr++,p->opr.op[1]); 
					break;
				default: break;
			}
		default: break;
	}
	return ptr;
}

void arrayList(nodeType* p, id delegate)
{
	int n = ex(p->opr.op[1],delegate).val.lValue;
	unsigned long* ptr = 0;
	if(n>0) ptr = calloc(n, sizeof(unsigned long));
	filterData tempData;
	tempData.type		= kFilterPtrType;
	tempData.val.pValue = ptr;
	[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
	loadArray(ptr,p->opr.op[2]);
}	

filterData ex(nodeType *p,id delegate) 
{
	filterData tempData = {0,{0}};
	filterData tempData1 = {0,{0}};
    if (!p) {
		tempData.type = kFilterLongType;
		tempData.val.lValue = 0;
		
	}
    switch(p->type) {
		case typeCon:       
			tempData.type = kFilterLongType;
			tempData.val.lValue = p->con.value;
			return tempData;
			
		case typeId:       
			[symbolTable getData:&tempData forKey:p->ident.key];
			return tempData;
			
		case typeOpr:
			switch(p->opr.oper) {
				case DO:		doLoop(p,delegate); return tempData;
				case WHILE:     whileLoop(p,delegate); return tempData;
				case FOR:		forLoop(p,delegate); return tempData;
				case CONTINUE:	[NSException raise:@"continue" format:nil]; return tempData;
				case IF:        if (ex(p->opr.op[0],delegate).val.lValue != 0) ex(p->opr.op[1],delegate);
				else if (p->opr.nops > 2) ex(p->opr.op[2],delegate);
					return tempData;
					
				case UNLESS:    if (ex(p->opr.op[0],delegate).val.lValue) ex(p->opr.op[1],delegate);
					return tempData;
					
				case BREAK:		[NSException raise:@"break" format:nil]; return tempData;
				case SWITCH:	doSwitch(p,delegate); return tempData;
				case CASE:		doCase(p,delegate); return tempData;
				case DEFAULT:	doDefault(p,delegate); return tempData;
				case PRINT:
					tempData = ex(p->opr.op[0],delegate);
					if(tempData.type == kFilterPtrType){
						if(tempData.val.pValue) NSLog(@"%ld\n", *tempData.val.pValue); 
						else					NSLog(@"<nil ptr>\n"); 
					}
					else NSLog(@"%ld\n", tempData.val.lValue); 
					return tempData;
					
				case PRINTH:
					tempData = ex(p->opr.op[0],delegate);
					if(tempData.type == kFilterPtrType){
						if(tempData.val.pValue) NSLog(@"0x%07lx\n", *tempData.val.pValue); 
						else					NSLog(@"<nil ptr>\n"); 
					}
					else NSLog(@"0x%07lx\n", tempData.val.lValue); 
					return tempData;
				case ';':       if (p->opr.nops>=1) ex(p->opr.op[0],delegate); if (p->opr.nops>=2)return ex(p->opr.op[1],delegate); else return tempData;
				case '=':      
				{
					tempData = ex(p->opr.op[1],delegate);
					[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
					return tempData;
				}
				case UMINUS: 
					tempData = ex(p->opr.op[0],delegate);
					tempData.val.lValue = -tempData.val.lValue;
					return tempData;
					
				case '+':       tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue + ex(p->opr.op[1],delegate).val.lValue; return tempData;
				case '-':       tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue - ex(p->opr.op[1],delegate).val.lValue; return tempData;
				case '*':       tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue * ex(p->opr.op[1],delegate).val.lValue; return tempData;
				case '/':       tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue / ex(p->opr.op[1],delegate).val.lValue; return tempData;
				case '<':       tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue < ex(p->opr.op[1],delegate).val.lValue; return tempData;
				case '>':       tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue > ex(p->opr.op[1],delegate).val.lValue; return tempData;
				case '^':       tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue ^ ex(p->opr.op[1],delegate).val.lValue; return tempData;
				case '%':       tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue % ex(p->opr.op[1],delegate).val.lValue; return tempData;
				case '|':       tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue | ex(p->opr.op[1],delegate).val.lValue; return tempData;
				case '&':       tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue & ex(p->opr.op[1],delegate).val.lValue; return tempData;
				case '!':       tempData.val.lValue = !ex(p->opr.op[0],delegate).val.lValue; return tempData;
				case '~':       tempData.val.lValue = ~ex(p->opr.op[0],delegate).val.lValue; return tempData;
				case GE_OP:     tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue >= ex(p->opr.op[1],delegate).val.lValue; return tempData;
				case LE_OP:     tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue <= ex(p->opr.op[1],delegate).val.lValue; return tempData;
				case NE_OP:     tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue != ex(p->opr.op[1],delegate).val.lValue; return tempData;
				case EQ_OP:     tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue == ex(p->opr.op[1],delegate).val.lValue; return tempData;
				case LEFT_OP:   tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue << ex(p->opr.op[1],delegate).val.lValue; return tempData;
				case RIGHT_OP:  tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue >> ex(p->opr.op[1],delegate).val.lValue; return tempData;
				case AND_OP:	tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue && ex(p->opr.op[1],delegate).val.lValue; return tempData;
				case OR_OP:		tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue || ex(p->opr.op[1],delegate).val.lValue; return tempData;
					
				case RIGHT_ASSIGN: 
					tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue>>ex(p->opr.op[1],delegate).val.lValue;
					[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
					return tempData;
					
				case LEFT_ASSIGN: 
					tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue<<ex(p->opr.op[1],delegate).val.lValue;
					[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
					return tempData;
					
				case MUL_ASSIGN: 
					tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue * ex(p->opr.op[1],delegate).val.lValue;
					[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
					return tempData;
					
				case DIV_ASSIGN: 
					tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue / ex(p->opr.op[1],delegate).val.lValue;
					[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
					return tempData;
					
				case OR_ASSIGN: 
					tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue | ex(p->opr.op[1],delegate).val.lValue;
					[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
					return tempData;
					
				case MOD_ASSIGN: 
					tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue % ex(p->opr.op[1],delegate).val.lValue;
					[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
					return tempData;
					
				case AND_ASSIGN: 
					tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue & ex(p->opr.op[1],delegate).val.lValue;
					[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
					return tempData;
					
				case XOR_ASSIGN: 
					tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue ^ ex(p->opr.op[1],delegate).val.lValue;
					[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
					return tempData;
					
					
				case kPostInc: 
					tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue;
					tempData1 = tempData;
					tempData1.val.lValue++;
					[symbolTable setData:tempData1 forKey:p->opr.op[0]->ident.key];
					return tempData;
					
				case kPreInc: 
					tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue+1;
					[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
					return tempData;
					
				case kPostDec: 
					tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue;
					tempData1 = tempData;
					tempData1.val.lValue--;
					[symbolTable setData:tempData1 forKey:p->opr.op[0]->ident.key];
					
				case kPreDec: 
					tempData.val.lValue = ex(p->opr.op[0],delegate).val.lValue-1;
					[symbolTable setData:tempData forKey:p->opr.op[0]->ident.key];
					return tempData;
					
					
					//array stuff
				case kArrayAssign:
				{
					unsigned long* ptr = ex(p->opr.op[0],delegate).val.pValue;
					if(ptr!=0){
						*ptr = ex(p->opr.op[1],delegate).val.lValue;
						tempData.type = kFilterLongType;
						tempData.val.lValue = *ptr;
					}
					else {
						[NSException raise:@"Access Violation" format:@"Nil Pointer"];
					}
				}
					return tempData;
					
				case kLeftArray:
				{
					unsigned long* ptr = ex(p->opr.op[0],delegate).val.pValue;
					if(ptr!=0){
						unsigned long offset = ex(p->opr.op[1],delegate).val.lValue;
						tempData.type = kFilterPtrType;
						tempData.val.pValue = ptr+offset;
					}
					else {
						[NSException raise:@"Access Violation" format:@"Nil Pointer"];
					}
				}
					return tempData;
					
				case kArrayElement:
				{
					unsigned long* ptr = ex(p->opr.op[0],delegate).val.pValue;
					if(ptr!=0){
						unsigned long offset = ex(p->opr.op[1],delegate).val.lValue;
						tempData.type = kFilterLongType;
						tempData.val.lValue = ptr[offset];
					}
					else {
						[NSException raise:@"Access Violation" format:@"Nil Pointer"];
					}
				}
					return tempData;
					
				case kDefineArray:		defineArray(p,delegate); 		break;
				case FREEARRAY:			freeArray(p,delegate); 			break;
					
				case kArrayListAssign:	
					arrayList(p,delegate);
					break;
					
				case CURRENTRECORD_IS:
					[symbolTable getData:&tempData forKey:"CurrentRecordPtr"];
					tempData.val.lValue =  [delegate record:tempData.val.pValue isEqualTo:ex(p->opr.op[0],delegate).val.lValue]; 
					return tempData;
					
				case EXTRACTRECORD_ID: 
					tempData.val.lValue =  [delegate extractRecordID:ex(p->opr.op[0],delegate).val.lValue]; 
					return tempData;
					
				case EXTRACTRECORD_LEN: 
					tempData.val.lValue =  [delegate extractRecordLen:ex(p->opr.op[0],delegate).val.lValue]; 
					return tempData;
					
				case EXTRACT_VALUE: 
					tempData.val.lValue =  [delegate extractValue:ex(p->opr.op[0],delegate).val.lValue 
															 mask:ex(p->opr.op[1],delegate).val.lValue
														thenShift:ex(p->opr.op[2],delegate).val.lValue]; 
					return tempData;
					
					
				case SHIP_RECORD:
				{
					unsigned long* ptr = ex(p->opr.op[0],delegate).val.pValue;
					if(ptr) [delegate shipRecord:ptr length:ExtractLength(*ptr)]; 
				}
					break;
					
				case PUSH_RECORD:
				{
					long stack = ex(p->opr.op[0],delegate).val.lValue;
					unsigned long* ptr  = ex(p->opr.op[1],delegate).val.pValue;
					if(ptr)[delegate pushOntoStack:stack record:ptr]; 
				}
					break;
					
				case POP_RECORD:
					tempData.val.pValue = [delegate popFromStack:ex(p->opr.op[0],delegate).val.lValue];
					return tempData;
					
				case BOTTOM_POP_RECORD:
					tempData.val.pValue = [delegate popFromStackBottom:ex(p->opr.op[0],delegate).val.lValue];
					return tempData;
					
				case SHIP_STACK:
					[delegate shipStack:ex(p->opr.op[0],delegate).val.lValue];
					break;
					
				case DUMP_STACK:
					[delegate dumpStack:ex(p->opr.op[0],delegate).val.lValue];
					break;
					
				case STACK_COUNT:
					tempData.val.lValue = [delegate stackCount:ex(p->opr.op[0],delegate).val.lValue];
					return tempData;
					
				case HISTO_1D:				
					[delegate histo1D:ex(p->opr.op[0],delegate).val.lValue value:ex(p->opr.op[1],delegate).val.lValue];
					break;
					
				case HISTO_2D:	
				{
					unsigned long x = ex(p->opr.op[1],delegate).val.lValue;
					unsigned long y = ex(p->opr.op[2],delegate).val.lValue;
					[delegate histo2D:ex(p->opr.op[0],delegate).val.lValue x:x y:y];
				}
					break;
					
				case STRIPCHART:	
				{
					unsigned long aTime = ex(p->opr.op[1],delegate).val.lValue;
					unsigned long aValue = ex(p->opr.op[2],delegate).val.lValue;
					[delegate stripChart:ex(p->opr.op[0],delegate).val.lValue time:aTime value:aValue];
				}
					break;
					
				case TIME:	
				{
					time_t theTime;
					time(&theTime);
					tempData.val.lValue = theTime;
				}
					break;
					
					
				case DISPLAY_VALUE:	
					[delegate setOutput:ex(p->opr.op[0],delegate).val.lValue 
							  withValue:ex(p->opr.op[1],delegate).val.lValue];
					break;
					
				case RANDOM:
				{
					int high = ex(p->opr.op[0],delegate).val.lValue;
					int low  = ex(p->opr.op[1],delegate).val.lValue;
					if(low>high){
						int temp = high;
						high = low;
						low = temp;
					}
					tempData.val.lValue = rand() % (high - low + 1) + low;
				}
					break;
					
					
				case RESET_DISPLAYS:
					[delegate resetDisplays];
					break;	
					
			}
    }
    return tempData;
}

