//-------------------------------------------------------------------------
//  ORAdcRateModel.h
//
//  Created by Mark A. Howe on Thursday 05/12/2011.
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

#pragma mark ***Imported Files
#import "ORSimpleLogic.h"
#import "ORProcessNub.h"

@class ORAdcRateGTNub;
@class ORAdcRateLTNub;

@interface ORAdcRateModel : ORSimpleLogic
{
  @private
    float           rangeForEqual;
    NSMutableArray* buffer;
    ORAdcRateGTNub* gtOutputNub;
	float           rate;
    float           rateLimit;
    BOOL            valid;
    float           integrationTime;
}

#pragma mark ***Initialization
- (void) dealloc;

#pragma mark ***Accessors
- (float) integrationTime;
- (void) setIntegrationTime:(float)aIntegrationTime;
- (BOOL) valid;
- (void) setValid:(BOOL)aValid;
- (float) rateLimit;
- (void) setRateLimit:(float)aRateLimit;
- (float) rate;
- (void) adjustBufferLength;
#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORAdcRateModelIntegrationTimeChanged;
extern NSString* ORAdcRateModelValidChanged;
extern NSString* ORAdcRateModelRateLimitChanged;

@interface ORAdcRateGTNub : ORProcessNub
- (id) eval;
- (int) evaluatedState;
@end

