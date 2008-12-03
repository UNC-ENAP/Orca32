//
//  ORXL2Model.m
//  Orca
//
//  Created by Mark Howe on Tue, Apr 30, 2008.
//  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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
#import "ORXL2Model.h"
#import "ORXL1Model.h"
#import "ORSNOCrateModel.h"
#import "ORSNOCard.h"
#import "ORSNOConstants.h"
#import "SBC_Cmds.h"
#import "SNOCmds.h"
#import "SBC_Link.h"

unsigned long xl2_register_offsets[] =
{	
0,				// [ 0]  Select Register
4,				// [ 1]  Data Available Register
8,				// [ 2]  XL2 Control Status Register
12,				// [ 3]  Mask Register
16,				// [ 4]  Clock CSR
20,				// [ 5]  HV Relay Control
24,				// [ 6]  Xilinx User Control
28, 			// [ 7]  General R/W display test register
32,				// [ 8]  HV CSR
36,				// [ 9]  HV Setpoints
40,				// [10]  HV Voltage Readback
44,				// [11]  HV Current Readback
};

@interface ORXL2Model (SBC)
- (void) loadClocksUsingSBC:(NSData*)theData;
- (void) loadXilinixUsingSBC:(NSData*)theData;
@end

@interface ORXL2Model (LocalAdapter)
- (void) loadClocksUsingLocalAdapter:(NSData*)theData;
- (void) loadXilinixUsingLocalAdapter:(NSData*)theData;
@end

@implementation ORXL2Model

#pragma mark •••Initialization
- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"XL2Card"]];
}


-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [inputConnector release];
    [outputConnector release];
    [super dealloc];
}

- (void) makeConnectors
{
    //make and cache our connector. However this connector will be 'owned' by another object (the SNORack)
    //so we don't add it to our list of connectors. It will be added to the true owner later.
    [self setInputConnector: [[[ORConnector alloc] initAt:NSZeroPoint withGuardian:self withObjectLink:self] autorelease]];
    [self setOutputConnector: [[[ORConnector alloc] initAt:NSZeroPoint withGuardian:self withObjectLink:self] autorelease]];
	
	[inputConnector setConnectorType: 'XL2I'];
	[inputConnector setConnectorImageType:kSmallDot]; 
	[inputConnector setIoType:kInputConnector];
	[inputConnector addRestrictedConnectionType: 'XL2O']; //can only connect to XL2O inputs
	[inputConnector addRestrictedConnectionType: 'XL1O']; //and XL1O inputs
	[inputConnector setOffColor:[NSColor colorWithCalibratedRed:0 green:.68 blue:.65 alpha:1.]];
	
	[outputConnector setConnectorType: 'XL2O'];
	[outputConnector setConnectorImageType:kSmallDot]; 
	[outputConnector setIoType:kOutputConnector];
	[outputConnector addRestrictedConnectionType: 'XL2I']; //can only connect to XL2I inputs
	[outputConnector setOffColor:[NSColor colorWithCalibratedRed:0 green:.68 blue:.65 alpha:1.]];
	
}

- (void) positionConnector:(ORConnector*)aConnector
{
	
	float x,y;
	NSRect aFrame = [[self guardian] frame];
	if(aConnector == inputConnector) {
		x = 0;      
		y = 0;
	}
	else {
		x = 0;      
		y = aFrame.size.height-10;
	}
	aFrame = [aConnector localFrame];
	aFrame.origin = NSMakePoint(x,y);
	[aConnector setLocalFrame:aFrame];
}

- (BOOL) solitaryInViewObject
{
	return YES;
}

#pragma mark •••Accessors

- (ORConnector*) inputConnector
{
    return inputConnector;
}

- (void) setInputConnector:(ORConnector*)aConnector
{
    [aConnector retain];
    [inputConnector release];
    inputConnector = aConnector;
}


- (ORConnector*) outputConnector
{
    return outputConnector;
}

- (void) setOutputConnector:(ORConnector*)aConnector
{
    [aConnector retain];
    [outputConnector release];
    outputConnector = aConnector;
}

- (void) setSlot:(int)aSlot
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSlot:[self slot]];
    [self setTag:aSlot];
    [self guardian:guardian positionConnectorsForCard:self];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORSNOCardSlotChanged
	 object: self];
}

- (int) slotConv
{
    return [self slot];
}

- (int) crateNumber
{
    return [guardian crateNumber];
}


- (void) setGuardian:(id)aGuardian
{
    id oldGuardian = guardian;
	
	[super setGuardian:aGuardian];
	
    if(oldGuardian != aGuardian){
		[oldGuardian setAdapter:nil];	//old crate can't use this card any more
        [oldGuardian removeDisplayOf:[self inputConnector]];
        [oldGuardian removeDisplayOf:[self outputConnector]];
    }
    [aGuardian setAdapter:self];		//our new crate will use this card for hardware access
	
    [aGuardian assumeDisplayOf:[self inputConnector]];
    [aGuardian assumeDisplayOf:[self outputConnector]];
    [self guardian:aGuardian positionConnectorsForCard:self];
}
- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard
{
    [aGuardian positionConnector:[self inputConnector] forCard:self];
    [aGuardian positionConnector:[self outputConnector] forCard:self];
}

- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian removeDisplayOf:[self inputConnector]];
    [aGuardian removeDisplayOf:[self outputConnector]];
}

- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian assumeDisplayOf:[self inputConnector]];
    [aGuardian assumeDisplayOf:[self outputConnector]];
}

- (id) adapter
{
	id anAdapter = [self getXL1]; //should chain all the way back to the IC XL1
	if(anAdapter)return anAdapter;
	else [NSException raise:@"No XL1" format:@"Check that connections are made all the way back to an XL1.\n"];
	return nil;
}

- (id) xl1
{
	return [self adapter];
}

- (id) getXL1
{
	id obj = [inputConnector connectedObject];
	return [obj getXL1];
}

- (void) connectionChanged
{
	ORXL1Model* theXL1 = [self getXL1];
	[theXL1 setCrateNumbers];
}

- (void) setCrateNumber:(int)crateNumber
{
	[[self guardian] setCrateNumber:crateNumber];
	id nextXL2 = [outputConnector connectedObject];
	[nextXL2 setCrateNumber:crateNumber+1];
}



#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setInputConnector:		[decoder decodeObjectForKey:@"inputConnector"]];
    [self setOutputConnector:		[decoder decodeObjectForKey:@"outputConnector"]];
	[self setSlot:					[decoder decodeIntForKey:   @"slot"]];
	
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:[self inputConnector]		 forKey:@"inputConnector"];
    [encoder encodeObject:[self outputConnector]	 forKey:@"outputConnector"];
    [encoder encodeInt:	  [self slot]			     forKey:@"slot"];
}

#pragma mark •••Hardware Access
- (void) selectCards:(unsigned long) selectBits
{
	[self writeToXL2Register:XL2_SELECT_REG value: selectBits]; // select the cards by writing to the XL2 REG 0 
}

- (void) deselectCards
{
	[self writeToXL2Register:XL2_SELECT_REG value:0UL];	//deselect the cards by writing to the XL2 REG 0
}

- (void) select:(ORSNOCard*) aCard
{
	unsigned long selectBits;
	if(aCard == self)	selectBits = XL2_SELECT_XL2;
	else				selectBits = (1L<<[aCard stationNumber]);
	[self writeToXL2Register:XL2_SELECT_REG value: selectBits]; // select the cards by writing to the XL2 REG 0 
}

- (void) writeToXL2Register:(unsigned long) aRegister value:(unsigned long) aValue
{
	if (aRegister > XL2_MASK_REG) {   //Higer registers require that bit 17 be set in the XL2 select register
		[[self xl1] writeHardwareRegister:[self xl2RegAddress:XL2_SELECT_REG] value:0x20000];
	}
	[[self xl1] writeHardwareRegister:[self xl2RegAddress:aRegister] value:aValue]; 		//Now write the value	
}

- (unsigned long) xl2RegAddress:(unsigned long)aRegOffset
{
	return [[self guardian] registerBaseAddress] + xl2_register_offsets[aRegOffset];
}

// read bit pattern from specified register on XL2
- (unsigned long) readFromXL2Register:(unsigned long) aRegister
{
	if (aRegister > XL2_MASK_REG){   //Higer registers require that bit 17 be set in the XL2 select register
		[self writeHardwareRegister:[self xl2RegAddress:XL2_SELECT_REG] value:0x20000];
	}
	
	// Now read the value
	return  [self  readHardwareRegister:[self xl2RegAddress:aRegister]]; 	
}

//call thrus for the Fec hardware access
- (void) writeHardwareRegister:(unsigned long) anAddress value:(unsigned long) aValue
{
	[[self xl1] writeHardwareRegister:anAddress value:aValue];
}

- (unsigned long) readHardwareRegister:(unsigned long) regAddress
{
	return [[self xl1] readHardwareRegister:regAddress];
}

#pragma mark •••Composite HW Functions

- (void) reset
{
	@try {
		[self writeToXL2Register:XL2_CONTROL_STATUS_REG value: XL2_CONTROL_CRATE_RESET | XL2_CONTROL_DONE_PROG]; // select the cards by writing to the XL2 REG 0 
		[self writeToXL2Register:XL2_CONTROL_STATUS_REG value: XL2_CONTROL_DONE_PROG]; // select the cards by writing to the XL2 REG 0 
	}
	@catch(NSException* localException) {
		NSLog(@"Failure during reset of XL2 Crate %d Slot %d.\n", [self crateNumber], [self stationNumber]);	
	}		
	
}

- (BOOL) adapterIsSBC
{
	return [[[self xl1] adapter] isKindOfClass:NSClassFromString(@"ORVmecpuModel")];
}

- (void) loadTheClocks
{
	NSData* theData = [[self xl1] clockFileData];	// load the entire content of the file
	if([self adapterIsSBC])	[self loadClocksUsingSBC:theData];
	else					[self loadClocksUsingLocalAdapter:theData];
}

- (void) loadTheXilinx
{
	NSData* theData = [[self xl1] xilinxFileData];	// load the entire content of the file
	if([self adapterIsSBC])	[self loadXilinixUsingSBC:theData];
	else					[self loadXilinixUsingLocalAdapter:theData];
}

- (BOOL) checkXlinixLoadOK:(unsigned long) aSelectionMask
{
	[self writeToXL2Register:XL2_CONTROL_STATUS_REG value:XL2_CONTROL_DONE_PROG];
	[self selectCards:aSelectionMask];
	
	[self writeToXL2Register:XL2_CONTROL_STATUS_REG value:XL2_CONTROL_BIT11];
	// More Changes, PW, RGV
	// check to see if the Xilinx was loaded properly 
	// read the bit 8, this should be high if the Xilinx was loaded
	unsigned long readValue = [self readFromXL2Register:XL2_CONTROL_STATUS_REG];
	
	if (!(readValue & XL2_CONTROL_DONE_PROG)){	
		[ORTimer delay:.1];
		readValue = [self readFromXL2Register:XL2_CONTROL_STATUS_REG];
		if (!(readValue & XL2_CONTROL_DONE_PROG)){	
			return false;
		}
	}
	
	[self writeToXL2Register:XL2_CONTROL_STATUS_REG value:XL2_CONTROL_DONE_PROG]; // set bit 11 low
	return true;
}

@end

@implementation ORXL2Model (SBC)
- (void) loadClocksUsingSBC:(NSData*)theData
{
	
	NSLog(@"Sending Clock file\n");
	
	long errorCode = 0;
	unsigned long numLongs		= ceil([theData length]/4.0); //round up to long word boundary
	SBC_Packet aPacket;
	aPacket.cmdHeader.destination			= kSNO;
	aPacket.cmdHeader.cmdID					= kSNOXL2LoadClocks;
	aPacket.cmdHeader.numberBytesinPayload	= sizeof(SNOXL2_ClockLoadStruct) + numLongs*sizeof(long);
	
	SNOXL2_ClockLoadStruct* payloadPtr		= (SNOXL2_ClockLoadStruct*)aPacket.payload;
	payloadPtr->addressModifier				= [self addressModifier];
	payloadPtr->xl2_select_reg				= [self xl2RegAddress:XL2_SELECT_REG];
	payloadPtr->xl2_clock_cs_reg			= [self xl2RegAddress:XL2_CLOCK_CS_REG];
	payloadPtr->xl2_select_xl2				= XL2_SELECT_XL2;
	payloadPtr->xl2_master_clk_en			= XL2_MASTER_CLK_EN;
	payloadPtr->allClocksEnabled			= XL2_MASTER_CLK_EN | XL2_MEMORY_CLK_EN | XL2_SEQUENCER_CLK_EN | XL2_ADC_CLK_EN;
	payloadPtr->fileSize					= [theData length];
	const char* dataPtr						= (const char*)[theData bytes];
	//really should be an error check here that the file isn't bigger than the max payload size
	char* p = (char*)payloadPtr + sizeof(SNOXL2_ClockLoadStruct);
	bcopy(dataPtr, p, [theData length]);
	
	@try {
		[[[[self xl1] adapter] sbcLink] send:&aPacket receive:&aPacket];
		SNOXL2_ClockLoadStruct *responsePtr = (SNOXL2_ClockLoadStruct*)aPacket.payload;
		errorCode = responsePtr->errorCode;
		if(errorCode){
			NSLog(@"%s\n",aPacket.message);
			[NSException raise:@"Clock load failed" format:@""];
		}
		else NSLog(@"Looks like success.\n");
	}
	@catch(NSException* localException) {
		NSLog(@"Clock load failed: %@\n",localException);
		[localException raise];
	}
}

- (void) loadXilinixUsingSBC:(NSData*)theData
{
	
	NSLog(@"Sending Xilinx file\n");
	
	long errorCode = 0;
	unsigned long numLongs		= ceil([theData length]/4.0); //round up to long word boundary
	SBC_Packet aPacket;
	aPacket.cmdHeader.destination			= kSNO;
	aPacket.cmdHeader.cmdID					= kSNOXL2LoadXilinx;
	aPacket.cmdHeader.numberBytesinPayload	= sizeof(SNOXL2_XilinixLoadStruct) + numLongs*sizeof(long);
	
	SNOXL2_XilinixLoadStruct* payloadPtr	= (SNOXL2_XilinixLoadStruct*)aPacket.payload;
	payloadPtr->addressModifier				= [self addressModifier];
	payloadPtr->selectBits					= ( 1UL << 8) | XL2_SELECT_XL2;  //Temp ....just loading board 8 and the xl2 in the test stand
	payloadPtr->xl2_select_reg				= [self xl2RegAddress:XL2_SELECT_REG];
	payloadPtr->xl2_control_status_reg		= [self xl2RegAddress:XL2_CONTROL_STATUS_REG];
	payloadPtr->xl2_xilinx_user_control		= [self xl2RegAddress:XL2_XILINX_USER_CONTROL];
	payloadPtr->xl2_select_xl2				= XL2_SELECT_XL2;
	payloadPtr->xl2_control_bit11			= XL2_CONTROL_BIT11;
	payloadPtr->xl2_xlpermit				= XL2_XLPERMIT;
	payloadPtr->xl2_enable_dp				= XL2_ENABLE_DP;
	payloadPtr->xl2_disable_dp				= XL2_DISABLE_DP;;
	payloadPtr->xl2_control_clock			= XL2_CONTROL_CLOCK;
	payloadPtr->xl2_control_data			= XL2_CONTROL_DATA;
	payloadPtr->xl2_control_done_prog		= XL2_CONTROL_DONE_PROG;
	payloadPtr->fileSize					= [theData length];
	
	const char* dataPtr						= (const char*)[theData bytes];
	//really should be an error check here that the file isn't bigger than the max payload size
	char* p = (char*)payloadPtr + sizeof(SNOXL2_XilinixLoadStruct);
	bcopy(dataPtr, p, [theData length]);
	
	@try {
		[[[[self xl1] adapter] sbcLink] send:&aPacket receive:&aPacket];
		SNOXL2_XilinixLoadStruct *responsePtr = (SNOXL2_XilinixLoadStruct*)aPacket.payload;
		errorCode = responsePtr->errorCode;
		if(errorCode){
			NSLog(@"Error Code: %d %s\n",errorCode,aPacket.message);
			[NSException raise:@"Xilinx load failed" format:@"%d",errorCode];
		}
		else NSLog(@"Looks like success.\n");
	}
	@catch(NSException* localException) {
		NSLog(@"Xilinx load failed. %@\n",localException);
		[localException raise];
	}
}
@end

@implementation ORXL2Model (LocalAdapter)
- (void) loadClocksUsingLocalAdapter:(NSData*)theData
{
	//-------------- variables -----------------
	short 	theOffset = 0;	
	unsigned long writeValue;
	//------------------------------------------
	
	@try {
		
		NSData* theData = [[self xl1] clockFileData];	// load the entire content of the file
		char* charData = (char*)[theData bytes];		// high in the heap and then lock it before dereferencing
		
		[self select:self];
		
		// Enable master clock 
		[self writeToXL2Register:XL2_CLOCK_CS_REG value:XL2_MASTER_CLK_EN];
		
		int j;
		for(j = 1; j<=3; j++){			// there are three clocks, Memory, Sequencer and ADC
			
			// skip the comment line
			while ( *charData != '\r' ) charData++;
			
			charData++;
			
			// the first field has to be a ONE or a ZERO
			if ( ( *charData != '1') && ( *charData != '0')) {	
				[NSException raise:@"Bad Clock File" format:@"Invalid first characer in clock file"];
			}
			int i;
			for (i = 1; i<=4; i++){		// there are four lines of data per clock
				while ( *charData != '\r' ){    
					
					writeValue = XL2_MASTER_CLK_EN;	// keep the master clock enabled
					if( *charData == '1' ){
						writeValue |= (1UL<< (1 + theOffset));
					}
					charData++;
					
					[self writeToXL2Register:XL2_CLOCK_CS_REG value:writeValue];
					
					if (theOffset == 0)	writeValue += 1;
					else				writeValue |= (1UL << theOffset);
					
					[self writeToXL2Register:XL2_CLOCK_CS_REG value:writeValue];
					
				}
				
				charData++;
			}
			theOffset += 4;
		}
		
		// keep the master clock enabled and enable all three clocks
		writeValue = XL2_MASTER_CLK_EN | XL2_MEMORY_CLK_EN | XL2_SEQUENCER_CLK_EN | XL2_ADC_CLK_EN;	
		[self writeToXL2Register:XL2_CLOCK_CS_REG value:writeValue];
		
		[self deselectCards];
		NSLog(@"loaded the clock file\n");
	}
	@catch(NSException* localException) {
		[self deselectCards];
		NSLog(@"Could not load the clock file!\n");	
	}
}


- (void) loadXilinixUsingLocalAdapter:(NSData*)theData
{
	
	//--------------------------- The file format as of 4/17/96 -------------------------------------
	//
	// 1st field: Beginning of the comment block -- /
	//			  If no backslash then you will get an error message and Xilinx load will abort
	// Now include your comment.
	// The comment block is delimited by another backslash.
	// If no backslash at the end of the comment block then you will get error message.
	//
	// After the comment block include the data in ACSII binary.
	// No spaces or other characters in between data. It will complain otherwise.
	//
	//----------------------------------------------------------------------------------------------
	
	unsigned long bitCount		= 0UL;
	unsigned long writeValue	= 0UL;
	unsigned long mc_SelectBits	= 0;						
	Boolean firstPass			= TRUE;
	
	@try {
		
		// Load the data from the Xilinx File
		NSData* theData = [[self xl1] xilinxFileData];	// load the entire content of the file
		char*   charData = (char*)[theData bytes];
		unsigned long length = [theData length];
		unsigned long index = length; 
		
		// select the mother cards in the SNO Crate
		int card_index;
		for (card_index = 0; card_index < kNumSNOCards ; card_index++){
			//TBD Make select mask based on old criteria
			//if(    ( theConfigDB -> MCPresent(its_SC_Number,card_index) )
			//   && ( theConfigDB -> SlotOnline(its_SC_Number,card_index) ) ){
			
			// build the bit pattern			
			mc_SelectBits |= ( 1UL << 8);
			
			//}
		}	
		mc_SelectBits |= XL2_SELECT_XL2;
		[self selectCards:mc_SelectBits];
		
		// make sure that the XL2 DP bit is set low and bit 11 (xilinx active) is high -- 
		// this is not yet sent to the MB
		writeValue = XL2_CONTROL_BIT11;	
		[self writeToXL2Register:XL2_CONTROL_STATUS_REG value:writeValue];
		
		// This seems to fix the xilinx reprogramming problem with the Power PC
		[ORTimer delay:.200];   // doubled MAH 01/18/00
		
		// now toggle this on the MB and turn on the XL2 xilinx load permission bit
		
		// DO NOT USE CXL2_Secondary_Reg_Access here unless you retain the state
		// of the select bits in register zero!!!!		
		writeValue = XL2_XLPERMIT | XL2_ENABLE_DP;
		[self writeToXL2Register:XL2_XILINX_USER_CONTROL value:writeValue];
		//		Wait(100);   // 100 msec delay  QRA 1/18/98
		// This seems to fix the xilinx reprogramming problem with the Power PC
		[ORTimer delay:.200];   // doubled MAH 01/18/00
		
		// turn off the DP bit but keep 
		writeValue = XL2_XLPERMIT | XL2_DISABLE_DP;
		[self writeToXL2Register:XL2_XILINX_USER_CONTROL value:writeValue];
		
		// set  bit 11 high, bit 10 high
		writeValue = XL2_CONTROL_BIT11 | XL2_CONTROL_CLOCK;
		[self writeToXL2Register:XL2_CONTROL_STATUS_REG value:writeValue];
		
		[ORTimer delay:.200];   // doubled MAH 01/18/00
		
		//unsigned long theDelay = theConfigDB->getXiLinxLoadDelay(its_SC_Number); 
		unsigned long theDelay = 40000; //nSec
		int i;
		for (i = 1;i < index;i++){
			
			if ( (firstPass) && (*charData != '/') ){
				[NSException raise:@"Bad Xilinx File" format:@"Invalid first characer in xilinx file"];
			}
			
			if (firstPass){
				charData++;							// for the first backslash
				i++;  									// need to keep track of i
				
				while(*charData++ != '/'){
					
					i++;
					if ( i>index ){
						[NSException raise:@"Bad Xilinx File" format:@"Comment block not delimited by a backslash"];
					}
				}
			}
			
			firstPass = FALSE;
			
			// strip carriage return, tabs
			if ( ((*charData =='\r') || (*charData =='\n') || (*charData =='\t' )) && (!firstPass) ){		
				charData++;
			}
			else {
				bitCount++;
				
				if ( *charData == '1' ) {
					writeValue = XL2_CONTROL_BIT11 | XL2_CONTROL_DATA;	// bit set in data to load
				}
				else if ( *charData == '0' ) {
					writeValue = XL2_CONTROL_BIT11;						// bit not set in data
				}
				else {
					[NSException raise:@"Bad Xilinx File" format:@"Invalid character in Xilinx file"];
				}
				charData++;	
				
				[self writeToXL2Register:XL2_CONTROL_STATUS_REG value:writeValue | XL2_CONTROL_CLOCK];	// changed PMT 1/17/98 to match Penn code
				[ORTimer delayNanoseconds:theDelay];
				
				// toggle clock high
				[self writeToXL2Register:XL2_CONTROL_STATUS_REG value:writeValue]; // changed PMT 1/17/98 to match Penn code
				[ORTimer delayNanoseconds:theDelay];
			}
		}
		//Wait(100);   // 100 msec delay
		[ORTimer delay:.200];// doubled MAH 01/18/00
		
		// QRA :5/31/97 -- do this before reading the DON_PROG bit. Xilinx Load on our
		// system now works. Why this should make any diferrence is a puzzle. 
		// More Changes, RGV, PW : turn off XLPERMIT & clear this register
		writeValue = 0UL;
		[self writeToXL2Register:XL2_XILINX_USER_CONTROL value:writeValue];
		
		[ORTimer delay:.200];// added MAH 01/18/00
		
		if(![self checkXlinixLoadOK:XL2_SELECT_XL2]){
			NSLog(@"Xilinx load failed XL2! (Status bit checked twice)");
		}
		else NSLog(@"looks like a successful Xilinx load\n");
		
		[self writeToXL2Register:XL2_CONTROL_STATUS_REG value:XL2_CONTROL_DONE_PROG];	//BLW 10/31/02-set bit 11 low, similar to previous version
		
		// now deselect all mother cards
		[self deselectCards];
		
	}
	@catch(NSException* localException) {
		[self deselectCards];
	}	
	
}
@end
