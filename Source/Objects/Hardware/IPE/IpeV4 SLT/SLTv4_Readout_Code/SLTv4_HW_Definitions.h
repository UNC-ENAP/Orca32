//
// SLTv4_HW_Definitions.h
//  Orca
//
//  Created by Mark Howe on Mon Mar 10, 2008
//  Copyright � 2002 CENPA, University of Washington. All rights reserved.
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
#ifndef _H_SLTV4HWDEFINITIONS_
#define _H_SLTV4HWDEFINITIONS_

#define kSLTv4    1
#define kFLTv4    2


#define kReadWaveForms	0x1 << 0

//flt run modes (sent to hw)
#define kIpeFltV4Katrin_StandBy_Mode		0
#define kIpeFltV4Katrin_Run_Mode			1
#define kIpeFltV4Katrin_Histo_Mode			2
#define kIpeFltV4Katrin_Test_Mode			3

typedef struct { // -tb- 2008-02-27
	int32_t readoutSec;
	int32_t recordingTimeSec;  //! this holds the refresh time -tb-
	int32_t firstBin;
	int32_t lastBin;
	int32_t histogramLength; //don't use unsigned! - it may become negative, at least temporaryly -tb-
    int32_t maxHistogramLength;
    int32_t binSize;
    int32_t offsetEMin;
} katrinHistogramDataStruct;


#endif
