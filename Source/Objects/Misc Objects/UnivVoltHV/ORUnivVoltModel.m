//
//  ORUnivVoltModel.m
//  Orca
//
//  Created by Jan Wouters on Mon Apr 21 2008
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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
#import "ORUnivVoltModel.h"
#import "ORUnivVoltHVCrateModel.h"
#import "NetSocket.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORQueue.h"


//NSString* ORUVChnlSlotChanged				= @"ORUVChnlSlotChanged";

// HV Unit parameters
NSString* HVkChannelEnabled = @"CE";
NSString* HVkMeasuredCurrent = @"MC";
NSString* HVkMeasuredHV = @"MV";
NSString* HVkDemandHV = @"DV";
NSString* HVkRampUpRate = @"RUP";
NSString* HVkRampDownRate = @"RDN";
NSString* HVkTripCurrent = @"TC";
NSString* HVkStatus = @"ST";
NSString* HVkMVDZ = @"MVDZ";
NSString* HVkMCDZ = @"MCDZ";
NSString* HVkHVLimit = @"HVL";

// Notifications
NSString* UVChnlEnabledChanged			= @"ChnlChannelEnabledChanged";
NSString* UVChnlDemandHVChanged			= @"ChnlDemandHVChanged";
NSString* UVChnlMeasuredHVChanged		= @"ChnlMeasuredChanged";
NSString* UVChnlMeasuredCurrentChanged	= @"ChnlMeasuredCurrentChanged";
//NSString* UVChnlSlotChanged				= @"UnitSlotChanged";
NSString* UVChnlTripCurrentChanged		= @"ChnlTripCurrentChanged";
NSString* UVChnlRampUpRateChanged		= @"ChnlRampUpRateChanged";
NSString* UVChnlRampDownRateChanged		= @"ChnlRampDownRateChanged";
NSString* UVChnlMVDZChanged				= @"ChnlMVDZChanged";
NSString* UVChnlMCDZChanged				= @"ChnlMCDZChanged";
NSString* UVChnlHVLimitChanged			= @"ChnlHVLimitChanged";


// Commands possible from HV Unit.
NSString* HVkModuleDMP	= @"DMP";

// Dictionary keys for data return dictionary
//NSString* UVkSlot	 = @"Slot";
//NSString* UVkChnl    = @"Chnl";
//NSString* UVkCommand = @"Command";
//NSString* UVkReturn  = @"Return";

// params dictionary holds NAME, R/W and TYPE
NSString* UVkNAME = @"NAME";
NSString* UVkReadWrite = @"RW";
NSString* UVkType = @"TYPE";

NSString* UVkRead = @"R";
NSString* UVkWrite = @"W";

NSString* UVkInt = @"int";
NSString* UVkFloat = @"float";
NSString* UVkString = @"string";


@implementation ORUnivVoltModel
#pragma mark •••Init/Dealloc
/*- (NSString*) fullID
{
    return [NSString stringWithFormat:@"%@,%d,%d",NSStringFromClass([self class]),[self crateNumber], [self stationNumber]];
}
*/
- (Class) guardianClass 
{
	return NSClassFromString(@"ORUnivVoltHVCrateModel");
}

- (void) makeMainController
{
    [self linkToController: @"ORUnivVoltController"];
}

- (void) dealloc
{
		
    [super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
//	NS_DURING
		mParams = [NSMutableDictionary dictionaryWithCapacity: ORUVChnlNumParameters];

		// Load dictionary with commands supported for this unit.
		NSArray* keysCmd = [NSArray arrayWithObjects: UVkNAME, @"SLOT", @"CHNL", nil];
		
		NSArray* objectsCmd0 = [NSArray arrayWithObjects: @"DMP", @"YES", @"YES", nil];
		NSDictionary* tmpCmd0 = [NSDictionary dictionaryWithObjects: objectsCmd0 forKeys: keysCmd];
		[mCommands insertObject: tmpCmd0 atIndex: 0];
		
		NSArray* objectsCmd1 = [NSArray arrayWithObjects: @"LD", @"YES", @"YES", nil];
		NSDictionary* tmpCmd1 = [NSDictionary dictionaryWithObjects: objectsCmd1 forKeys: keysCmd];
		[mCommands insertObject: tmpCmd1 atIndex: 1];
		

		// load array with dictionary values for parameters - Store name of n
		NSArray* keys = [NSArray arrayWithObjects: UVkReadWrite, UVkType, nil];
				
		
		NSArray* objects0 = [NSArray arrayWithObjects: UVkRead, @"int", nil];
		NSDictionary* tmpParam0 = [NSDictionary dictionaryWithObjects: objects0 forKeys: keys];
		[mParams setObject: tmpParam0 forKey: @"Chnl"];

		NSArray* objects1 = [NSArray arrayWithObjects: UVkRead, UVkFloat, nil];
		NSDictionary* tmpParam1 = [NSDictionary dictionaryWithObjects: objects1 forKeys: keys];
		[mParams setObject: tmpParam1 forKey: HVkMeasuredCurrent];

		NSArray* objects2 = [NSArray arrayWithObjects: UVkRead, UVkFloat, nil];
		NSDictionary* tmpParam2 = [NSDictionary dictionaryWithObjects: objects2 forKeys: keys];
		[mParams setObject: tmpParam2 forKey: HVkMeasuredHV];

		NSArray* objects3 = [NSArray arrayWithObjects:  UVkRead, UVkInt, nil];
		NSDictionary* tmpParam3 = [NSDictionary dictionaryWithObjects: objects3 forKeys: keys];
		[mParams setObject: tmpParam3 forKey: @"ST"];

		NSArray* objects4 = [NSArray arrayWithObjects: UVkWrite, UVkInt, nil];
		NSDictionary* tmpParam4 = [NSDictionary dictionaryWithObjects: objects4 forKeys: keys];
		[mParams setObject: tmpParam4 forKey: HVkChannelEnabled];

		NSArray* objects5 = [NSArray arrayWithObjects: UVkWrite, UVkFloat, nil];
		NSDictionary* tmpParam5 = [NSDictionary dictionaryWithObjects: objects5 forKeys: keys];
		[mParams setObject: tmpParam5 forKey: HVkDemandHV];

		NSArray* objects6 = [NSArray arrayWithObjects: UVkWrite, UVkFloat, nil];
		NSDictionary* tmpParam6 = [NSDictionary dictionaryWithObjects: objects6 forKeys: keys];
		[mParams setObject: tmpParam6 forKey: HVkRampUpRate];

		NSArray* objects7 = [NSArray arrayWithObjects: UVkWrite, UVkFloat, nil];
		NSDictionary* tmpParam7 = [NSDictionary dictionaryWithObjects: objects7 forKeys: keys];
		[mParams setObject: tmpParam7 forKey: HVkRampDownRate];

		NSArray* objects8 = [NSArray arrayWithObjects: UVkWrite, UVkFloat, nil];
		NSDictionary* tmpParam8 = [NSDictionary dictionaryWithObjects: objects8 forKeys: keys];
		[mParams setObject: tmpParam8 forKey: HVkTripCurrent];
		
		NSArray* objects9 = [NSArray arrayWithObjects: UVkWrite, @"NSSTRING", nil];
		NSDictionary* tmpParam9 = [NSDictionary dictionaryWithObjects: objects9 forKeys: keys];
		[mParams setObject: tmpParam9 forKey: HVkStatus];

		NSArray* objects10 = [NSArray arrayWithObjects: UVkWrite, UVkFloat, nil];
		NSDictionary* tmpParam10 = [NSDictionary dictionaryWithObjects: objects10 forKeys: keys];
		[mParams setObject: tmpParam10 forKey: HVkMVDZ];
		
		NSArray* objects11 = [NSArray arrayWithObjects: UVkWrite, UVkFloat, nil];
		NSDictionary* tmpParam11 = [NSDictionary dictionaryWithObjects: objects11 forKeys: keys];
		[mParams setObject: tmpParam11 forKey: HVkMCDZ];
		
		NSArray* objects12 = [NSArray arrayWithObjects: UVkRead, UVkInt, nil];
		NSDictionary* tmpParam12 = [NSDictionary dictionaryWithObjects: objects12 forKeys: keys];
		[mParams setObject: tmpParam12 forKey: HVkHVLimit];

	
		[mParams retain];
				
//	NS_HANDLER
//	NS_ENDHANDLER
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"UnivVoltHVIcon"]];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers{
//    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
    [notifyCenter addObserver : self
                     selector : @selector( interpretDataReturn: )
                         name : UVHVUnitInfoAvailableNotification
                       object : nil];
					   
}


#pragma mark •••sendCommands
- (void) getValues
{
	int		i;	
	int		slot;
	
	slot = [self slot];
	for ( i = 0; i < ORHVNumChannels; i++ )
	{
		NSString* command = [NSString stringWithFormat: @"DMP S%d.%d", slot, i];
		[[self crate] sendCommand: slot channel: i command: command];

	}
}

- (void) loadValues
{
	int			i;
	int			j;
//	float		value;

	NSArray* allKeys = [mParams allKeys];
	for ( j = 0; j < [mParams count]; j++ )
	{
		NSDictionary* dictObj = [mParams objectForKey: [allKeys objectAtIndex: j]];				// Get static dictionary for this chnl describing the parameters.
		NSString*	command = [dictObj objectForKey: @"NAME"];		
		NSString*	writable = [mParams objectForKey: @"RW"];
		if ( [writable isEqualTo: UVkWrite] )
		{
			for ( i = 0; i < ORHVNumChannels; i++ )
			{
				NSMutableDictionary* chnlDict = [mChannelArray objectAtIndex: i]; // Get values we want to set for channel.
				NSNumber* valueObj = [chnlDict objectForKey: command];
			
				if ( i == 0 )
				{
					command = [NSString stringWithFormat: @"LD S%d.%d", [self slot], i];
				}
			
				if ( [[dictObj objectForKey: @"TYPE"] isEqualTo: UVkInt] )
					command = [command stringByAppendingFormat: @" %d", [valueObj intValue]];
				else if ([[dictObj objectForKey: @"TYPE"] isEqualTo: @"FLOAT"])
					command = [command stringByAppendingFormat: @" %g", [valueObj floatValue]];
				
	//			command = [NSString stringWithFormat: @"LD S%d.%d %@ %d ", [self slot], i, value];
			}
			
			[[self crate] sendCommand: [self slot] channel: i command: command];
		}
	}
}


#pragma mark •••Accessors
- (NSMutableArray*) channelArray
{
	return( mChannelArray );
}

- (void) setChannelArray: (NSMutableArray*) anArray
{
	[anArray retain];
	[mChannelArray release];
	mChannelArray = anArray;
}

- (NSMutableDictionary*) channelDictionary: (int) aCurrentChnl
{
	return( [mChannelArray objectAtIndex: aCurrentChnl] );
}

- (int) chnlEnabled: (int) aCurrentChnl
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurrentChnl];
	NSNumber* numObj = [tmpChnl objectForKey: [tmpChnl objectForKey: @"CE"]];
	return( [numObj intValue] );
}

- (void) setChannelEnabled: (int) anEnabled chnl: (int) aCurrentChnl
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurrentChnl];
	
	NSNumber* enabledNumber = [NSNumber numberWithInt: anEnabled];
	[tmpChnl setObject: enabledNumber forKey: enabledNumber];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: UVChnlEnabledChanged object: self];		
}

- (float) demandHV: (int) aCurChannel
{
	NSDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	
	return ( [[tmpChnl objectForKey: HVkDemandHV] floatValue] );
}

- (void) setDemandHV: (float) aDemandHV chnl: (int) aCurChannel
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	NSNumber* demandHV = [NSNumber numberWithFloat: aDemandHV];
	[tmpChnl setObject: demandHV forKey: HVkDemandHV];
	
	// Put specific code here to talk with unit.
	[[NSNotificationCenter defaultCenter] postNotificationName: UVChnlDemandHVChanged object: self];	
}

- (float) measuredCurrent: (int) aChnl
{
	// Send command to get HV
//	[adapter sendCommand: @"RC"];
	
	// Now update dictionary
	
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aChnl];
	return( [[tmpChnl objectForKey: HVkMeasuredCurrent] floatValue] );
}



- (float) measuredHV: (int) aChnl
{
	// Send command to get HV
//	[adapter sendCommand: @"RC"];
	
	// Now update dictionary
	
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aChnl];
	return( [[tmpChnl objectForKey: HVkDemandHV] floatValue] );
}

- (float) tripCurrent: (int) aChnl
{
	// Send command to get trip current
	//	[adapter sendCommand: @"RC"];
	
	// Now update dictionary
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aChnl];
	return( [[tmpChnl objectForKey: HVkTripCurrent] floatValue] );
}

- (void) setTripCurrent: (float) aTripCurrent chnl: (int) aCurChannel
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	NSNumber* tripCurrent = [NSNumber numberWithFloat: aTripCurrent];
	[tmpChnl setObject: tripCurrent forKey: HVkTripCurrent];
	
	// Put specific code here to talk with unit.
	[[NSNotificationCenter defaultCenter] postNotificationName: UVChnlTripCurrentChanged object: self];	
}

- (float) rampUpRate: (int) aChnl
{
	// Send command to get HV
//	[adapter sendCommand: @"RC"];
	
	// Now update dictionary
	
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aChnl];
	return( [[tmpChnl objectForKey: HVkRampUpRate] floatValue] );
}

- (void) setRampUpRate: (float) aRampUpRate chnl: (int) aCurChannel
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	NSNumber* rampUpRate = [NSNumber numberWithFloat: aRampUpRate];
	[tmpChnl setObject: rampUpRate forKey: HVkRampUpRate];
	
	// Put specific code here to talk with unit.
	[[NSNotificationCenter defaultCenter] postNotificationName: UVChnlRampUpRateChanged object: self];	
}



- (float) rampDownRate: (int) aChnl
{
	// Send command to get HV
//	[adapter sendCommand: @"RC"];
	
	// Now update dictionary
	
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aChnl];
	return( [[tmpChnl objectForKey: HVkRampDownRate] floatValue] );
}

- (void) setRampDownRate: (float) aRampDownRate chnl: (int) aCurChannel
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	NSNumber* rampDownRate = [NSNumber numberWithFloat: aRampDownRate];
	[tmpChnl setObject: rampDownRate forKey: HVkRampUpRate];
	
	// Put specific code here to talk with unit.
	[[NSNotificationCenter defaultCenter] postNotificationName: UVChnlRampDownRateChanged object: self];	
}

- (NSString*) status: (int) aCurChannel
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	NSString* status = [tmpChnl objectForKey: HVkStatus];
	[status autorelease];
	return( status );
}

- (float) MVDZ: (int) aCurChannel
{
	// Send command to get HV
//	[adapter sendCommand: @"RC"];
	
	// Now update dictionary
	
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	return( [[tmpChnl objectForKey: HVkMVDZ] floatValue] );
}

- (void) setMVDZ: (float) aChargeWindow chnl: (int) aCurChannel
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	NSNumber* hvWindow = [NSNumber numberWithFloat: aChargeWindow];
	[tmpChnl setObject: hvWindow forKey: HVkMVDZ];
	
	// Put specific code here to talk with unit.
	[[NSNotificationCenter defaultCenter] postNotificationName: UVChnlMVDZChanged object: self];	
}

- (float) MCDZ: (int) aChnl
{
	// Send command to get HV
//	[adapter sendCommand: @"RC"];
	
	// Now update dictionary
	
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aChnl];
	return( [[tmpChnl objectForKey: HVkMCDZ] floatValue] );
}

- (void) setMCDZ: (float) aChargeWindow chnl: (int) aCurChannel
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	NSNumber* chargeWindow = [NSNumber numberWithFloat: aChargeWindow];
	[tmpChnl setObject: chargeWindow forKey: HVkMCDZ];
	
	// Put specific code here to talk with unit.
	[[NSNotificationCenter defaultCenter] postNotificationName: UVChnlMCDZChanged object: self];	
}

- (float) HVLimit: (int) aCurChannel
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	return( [[tmpChnl objectForKey: HVkHVLimit] floatValue] );
}


#pragma mark •••Interpret Data
- (void) interpretDataReturn: (NSNotification*) aNote
{
	@try {
		int slotThisUnit;
	
		// Get data for this channel from crate - in ORCA place data in NOTIFICATION Object.
		NSDictionary* returnData = [[self crate] returnDataToHVUnit];
		NSLog ( @"Command from dictionary '%@'", [returnData objectForKey: UVkCommand]);
		[returnData retain];
	
		NSNumber* slotNum = [returnData objectForKey: UVkSlot];
		slotThisUnit = [self slot];
		if ( [slotNum intValue] == slotThisUnit )
		{
			NSString* retCmd = [returnData objectForKey: UVkCommand];
			if ( [retCmd isEqualTo: HVkModuleDMP] )
			{
				[self interpretDMPReturn: returnData];
			}
		}
	}
	@catch (NSException * e) {
		NSLog( @"Caught exception '%@'.", [e reason] );
	}
	@finally {
		
	}
}

- (void) interpretDMPReturn: (NSDictionary*) aReturnData
{
// HV Unit parameters
//	NSString* HVkChannel = @"Chnl";
	NSString* HVkChannelEnabled = @"CE";
	NSString* HVkMeasuredCurrent = @"MC";
	NSString* HVkMeasuredHV = @"MV";
	NSString* HVkDemandHV = @"DV";
	NSString* HVkRampUpRate = @"RUP";
	NSString* HVkRampDownRate = @"RDN";
	NSString* HVkTripCurrent = @"TC";
	NSString* HVkStatus = @"ST";
	NSString* HVkMVDZ = @"MVDZ";
	NSString* HVkMCDZ = @"MCDZ";
	NSString* HVkHVLimit = @"HVL";
	
// Order of return from DMP command
//	const int HVkCommandIndx = 0;
//	const int ORHvKSlot_ChnlIndx = 1;
	const int HVkMeasuredCurrentIndx = 2;
	const int HVkMeasuredHVIndx = 3;
	const int HVkDemandHVIndx = 4;
	const int HVkRampUpRateIndx = 5;
	const int HVkRampDownRateIndx = 6;
	const int HVkTripCurrentIndx = 7;
	const int HVkChannelEnabledIndx = 8;
	const int HVkStatusIndx = 9;
	const int HVkMVDZIndx = 10;
	const int HVkMCDZIndx = 11;
	const int HVkHVLimitIndx = 12;

	NSString*			statusStr;
	int					status;
	
	int curChnl = [[aReturnData objectForKey: UVkChnl] intValue];
	NSMutableDictionary* chnl = [mChannelArray objectAtIndex: curChnl];
	NSArray* tokens = [aReturnData objectForKey: UVkReturn];
	
	NSNumber* measuredCurrent = [NSNumber numberWithFloat: [[tokens objectAtIndex: HVkMeasuredCurrentIndx] floatValue]];
	[chnl setObject: measuredCurrent forKey: HVkMeasuredCurrent];
	
	NSNumber* measuredHV = [NSNumber numberWithFloat: [[tokens objectAtIndex: HVkMeasuredHVIndx] floatValue]];
	[chnl setObject: measuredHV forKey: HVkMeasuredHV];
	
	NSNumber* demandHV = [NSNumber numberWithFloat: [[tokens objectAtIndex: HVkDemandHVIndx] floatValue]];
	[chnl setObject: demandHV forKey: HVkDemandHV];
	
	NSNumber* rampUpRate = [NSNumber numberWithFloat: [[tokens objectAtIndex: HVkRampUpRateIndx] floatValue]];
	[chnl setObject: rampUpRate forKey: HVkRampUpRate];
	
	NSNumber* rampDownRate = [NSNumber numberWithFloat: [[tokens objectAtIndex: HVkRampDownRateIndx] floatValue]];
	[chnl setObject: rampDownRate forKey: HVkRampDownRate];

	NSNumber* tripCurrent = [NSNumber numberWithFloat: [[tokens objectAtIndex: HVkTripCurrentIndx] floatValue]];
	[chnl setObject: tripCurrent forKey: HVkTripCurrent];
	
	NSNumber* channelEnabled = [NSNumber numberWithFloat: [[tokens objectAtIndex: HVkChannelEnabledIndx] intValue]];
	[chnl setObject: channelEnabled forKey: HVkChannelEnabled];

	// Interpret status
	NSNumber* statusNum = [NSNumber numberWithFloat: [[tokens objectAtIndex: HVkStatusIndx] intValue]];
	status = [statusNum intValue];
	
		// status case statement
	switch ( status ) {
		case eHVUEnabled:
			statusStr = [NSString stringWithString: @"Enabled"];
			break;
			
		case eHVURampingUp:
			statusStr = [NSString stringWithString: @"Ramping up"];
			break;
			
		case eHVURampingDown:
			statusStr = [NSString stringWithString: @"Ramping down"];
			break;
			
		case evHVUTripForSupplyLimits:
			statusStr = [NSString stringWithString: @"Trip for viol. supply lmt"];
			break;
			
		case eHVUTripForUserCurrent:
			statusStr = [NSString stringWithString: @"Trip for viol. current lmt"];
			break;
			
		case eHVUTripForHVError:
			statusStr = [NSString stringWithString: @"Trip HV for volt. error"];
			break;
			
		case eHVUTripForHVLimit:
			statusStr = [NSString stringWithString: @"Trip for voil. of volt. lmt"];
			
		default:
			statusStr = [NSString stringWithString: @"Undefined"];
			break;
	}
	[chnl setObject: statusStr forKey: HVkStatus];

	NSNumber* MVDZ = [NSNumber numberWithFloat: [[tokens objectAtIndex: HVkMVDZIndx] floatValue]];
	[chnl setObject: MVDZ forKey: HVkMVDZ];
	
	NSNumber* MCDZ = [NSNumber numberWithFloat: [[tokens objectAtIndex: HVkMCDZIndx] floatValue]];
	[chnl setObject: MCDZ forKey: HVkMCDZ];
	
	NSNumber* hvLimit = [NSNumber numberWithFloat: [[tokens objectAtIndex: HVkHVLimitIndx] floatValue]];
	[chnl setObject: hvLimit forKey: HVkHVLimit];
}


/*
#pragma mark •••Data Records
- (unsigned long) dataId
{
	return dataId;
}

- (void) setDataId: (unsigned long) aDataId
{
	dataId = aDataId;
}

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"NplpCMeter"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORUnivVoltDecoder",					@"decoder",
        [NSNumber numberWithLong:dataId],       @"dataId",
        [NSNumber numberWithBool:YES],          @"variable",
        [NSNumber numberWithLong:-1],			@"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"NplpCMeter"];
    
    return dataDictionary;
}

- (void) shipValues
{
	if(meterData){
	
		unsigned int numBytes = [meterData length];
		if(numBytes%4 == 0) {											//OK, we know we got a integer number of long words
			if([self validateMeterData]){
				unsigned long data[1003];									//max buffer size is 1000 data words + ORCA header
				unsigned int numLongsToShip = numBytes/sizeof(long);		//convert size to longs
				numLongsToShip = numLongsToShip<1000?numLongsToShip:1000;	//don't exceed the data array
				data[0] = dataId | (3 + numLongsToShip);					//first word is ORCA id and size
				data[1] =  [self uniqueIdNumber]&0xf;						//second word is device number
				
				//get the time(UT!)
				time_t	theTime;
				time(&theTime);
				struct tm* theTimeGMTAsStruct = gmtime(&theTime);
				time_t ut_time = mktime(theTimeGMTAsStruct);
				data[2] = ut_time;											//third word is seconds since 1970 (UT)
				
				unsigned long* p = (unsigned long*)[meterData bytes];
				
				int i;
				for(i=0;i<numLongsToShip;i++){
					p[i] = CFSwapInt32BigToHost(p[i]);
					data[3+i] = p[i];
					int chan = (p[i] & 0x00600000) >> 21;
					if(chan < kNplpCNumChannels) [dataStack[chan] enqueue: [NSNumber numberWithLong:p[i] & 0x000fffff]];
				}
				
				[self averageMeterData];
				
				if(numLongsToShip*sizeof(long) == numBytes){
					//OK, shipped it all
					[meterData release];
					meterData = nil;
				}
				else {
					//only part of the record was shipped, zero the part that was and keep the part that wasn't
					[meterData replaceBytesInRange:NSMakeRange(0,numLongsToShip*sizeof(long)) withBytes:nil length:0];
				}
				
				if([gOrcaGlobals runInProgress] && numBytes>0){
					[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
																object:[NSData dataWithBytes:data length:(3+numLongsToShip)*sizeof(long)]];
				}
				[self setReceiveCount: receiveCount + numLongsToShip];
			}
			
			else {
				[meterData release];
				meterData = nil;
				[self setFrameError:frameError+1];
			}
		}
	}
}

*/
#pragma mark ***Archival
- (id) initWithCoder: (NSCoder*) decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
	[self setChannelArray: [decoder decodeObjectForKey: @"channelArray"]];
	
	if( !mChannelArray ){
		//first time.... set up the structure....
		[self setChannelArray: [NSMutableArray array]];
		int i;
		
		// Put in dummy values for testing.
		for(i=0 ; i<ORHVNumChannels; i++ )
		{
			NSNumber* chnl = [NSNumber numberWithInt: i];
			NSNumber* measuredCurrent = [NSNumber numberWithFloat: ((float)i * 1.0)];
			NSNumber* measuredHV = [NSNumber numberWithFloat: (1000.0 + 10.0 * (float)i)];
			NSNumber* demandHV = [NSNumber numberWithFloat: (2000.0 + (float) i)];
			NSNumber* rampUpRate = [NSNumber numberWithFloat: 61.3];
			NSNumber* rampDownRate = [NSNumber numberWithFloat: 61.3];
			NSNumber* tripCurrent = [NSNumber numberWithFloat: 2550.0];
			NSString* status = [NSString stringWithString: @"enabled"];
			NSNumber* enabled = [NSNumber numberWithInt: 1];
			NSNumber* MVDZ = [NSNumber numberWithFloat: 1.5];
			NSNumber* MCDZ = [NSNumber numberWithFloat: 1.3];
			NSNumber* HVLimit = [NSNumber numberWithFloat: 1580.0];
			
			NSMutableDictionary* tmpChnl = [NSMutableDictionary dictionaryWithCapacity: 9];
			
			[tmpChnl setObject: chnl forKey: @"channel"];
			[tmpChnl setObject: measuredCurrent forKey: HVkMeasuredCurrent];
			[tmpChnl setObject: measuredHV forKey:HVkMeasuredHV];
			[tmpChnl setObject: demandHV forKey: HVkDemandHV];
			[tmpChnl setObject: tripCurrent	forKey: HVkTripCurrent];
			[tmpChnl setObject: enabled forKey:HVkChannelEnabled];
			[tmpChnl setObject: rampUpRate forKey: HVkRampUpRate];			
			[tmpChnl setObject: rampDownRate forKey: HVkRampDownRate];
			[tmpChnl setObject: status forKey: HVkStatus];
			[tmpChnl setObject: MVDZ forKey: HVkMVDZ];			
			[tmpChnl setObject: MCDZ forKey: HVkMCDZ];
			[tmpChnl setObject: HVLimit forKey: HVkHVLimit];			

			[tmpChnl setObject: status forKey: HVkStatus];
			
			[mChannelArray insertObject: tmpChnl atIndex: i];
		}
	}
	
	[mChannelArray retain];
    [[self undoManager] enableUndoRegistration];    
	
    return self;
}

- (void) encodeWithCoder: (NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeObject: @"mChannelArray"];
}

#pragma mark •••Utilities
/*- (void) interpretReturn: (NSString* ) aRawData dataStore: (NSMutableDictionary* ) aDataStore
{
	
	if ( [aRawData length] )
	{
		NSString*	values[ ORUVChnlNumParameters ];
		NSScanner* scanner = [NSScanner scannerWithString: aRawData];
		NSCharacterSet* blankSet = [NSCharacterSet characterSetWithCharactersInString: @" "];
		int i = 0;
		for ( i = 0; i < ORUVChnlNumParameters; i++ )
		{
			[scanner scanUpToCharactersFromSet: blankSet intoString: &values[ i ]];
			[scanner setScanLocation: [scanner scanLocation] + 1];

		}
	}
//	[scanner setCharactersToBeSkipped: newlineCharacterSet];

}
*/
- (void) printDictionary: (int) aCurrentChnl
{
	NSDictionary*	tmpChnl = [mChannelArray objectAtIndex: aCurrentChnl];
	
	NSLog( @"Channel: %d\n", aCurrentChnl);
	
	NSLog( @"Measured HV: %f\n", [[tmpChnl objectForKey: HVkMeasuredHV] floatValue] );

	NSLog( @"Measured Current: %g\n", [[tmpChnl objectForKey: HVkMeasuredCurrent] floatValue] );

	NSLog( @"Demand HV: %g\n", [[tmpChnl objectForKey: HVkDemandHV] floatValue] );

	NSLog( @"RampUpRate: %f\n", [[tmpChnl objectForKey: HVkRampUpRate] floatValue] );

	NSLog( @"RampDownRate: %f\n", [[tmpChnl objectForKey: HVkRampDownRate] floatValue] );

	NSLog( @"Trip current: %f\n", [[tmpChnl objectForKey: HVkTripCurrent] floatValue] );

	NSLog( @"Channel enabled: %d\n", [[tmpChnl objectForKey: HVkChannelEnabled] intValue] );

	NSLog( @"Status: %@\n", [tmpChnl objectForKey: HVkStatus] );
	
	NSLog( @"MVDZ: %f\n", [[tmpChnl objectForKey: HVkMCDZ] floatValue] );
	
	NSLog( @"MCDZ: %f\n", [[tmpChnl objectForKey: HVkMCDZ] floatValue] );

	NSLog( @"HV limit: %f\n", [[tmpChnl objectForKey: HVkHVLimit] floatValue] );	
}


@end
