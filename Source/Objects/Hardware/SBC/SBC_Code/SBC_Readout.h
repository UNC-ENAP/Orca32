/*---------------------------------------------------------------------------
/	SBC_Readout.h
/
/	09/09/07 Mark A. Howe
/	CENPA, University of Washington. All rights reserved.
/	ORCA project
/  ---------------------------------------------------------------------------
*/
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

#ifndef _H_SBC_Readout_
#define _H_SBC_Readout_

#include "SBC_Cmds.h"
#include "SBC_Config.h"
#include <sys/types.h>

#define kMaxDataBufferSize 1024*400

void processBuffer(SBC_Packet* aPacket);
void processSBCCommand(SBC_Packet* aPacket);
void doRunCommand(SBC_Packet* aPacket);
void sendResponse(SBC_Packet* aPacket);
int32_t readBuffer(SBC_Packet* aPacket);
int32_t writeBuffer(SBC_Packet* aPacket);
int32_t writeIRQ(int n);
void SwapLongBlock(void* p, int32_t n);
void SwapShortBlock(void* p, int32_t n);
void postLAM(SBC_Packet* lamPacket);
void LogMessage (const char *format,...);
void LogError (const char *format,...);
void LogBusError (const char *format,...);
#endif
