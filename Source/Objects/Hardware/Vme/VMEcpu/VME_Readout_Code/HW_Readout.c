//
//  HW_Readout.m
//  Orca
//
//  Created by Mark Howe on Mon Sept 10, 2007
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
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include "SBC_Cmds.h"
#include "SBC_Config.h"
#include "HW_Readout.h"
#include "SBC_Readout.h"
#include <errno.h>
#include "CircularBuffer.h"
#include "VME_HW_Definitions.h"
#include "VME_Trigger32.h"
#include "universe_api.h"

#define kDMALowerLimit 0x100 //require 256 bytes

void SwapLongBlock(void* p, int32_t n);
void SwapShortBlock(void* p, int32_t n);
int32_t writeBuffer(SBC_Packet* aPacket);

extern char needToSwap;
extern int32_t  dataIndex;
extern int32_t* data;

static TUVMEDevice* vmeAM29Handle = NULL;
static TUVMEDevice* controlHandle = NULL;
static TUVMEDevice* vmeAM39Handle = NULL;
static TUVMEDevice* vmeAM9Handle = NULL;

void processHWCommand(SBC_Packet* aPacket)
{
    /*look at the first word to get the destination*/
    int32_t destination = aPacket->cmdHeader.destination;

    switch(destination){
//        default:              processUnknownCommand(aPacket); break;
    }
}

void startHWRun (SBC_crate_config* config)
{    
    int32_t index = 0;
    while(1){
        switch(config->card_info[index].hw_type_id){
            default:     index =  -1; break;
        }
        if(index>=config->total_cards || index<0)break;
    }
}

void stopHWRun (SBC_crate_config* config)
{
    int32_t index = 0;
    while(1){
        switch(config->card_info[index].hw_type_id){
            default:     index =  -1; break;
        }
        if(index>=config->total_cards || index<0)break;
    }
}


void FindHardware(void)
{
    /* TBD **** MUST add some error checking here */

    vmeAM29Handle = get_new_device(0x0, 0x29, 2, 0x10000); 
    controlHandle = get_ctl_device(); 
    vmeAM39Handle = get_new_device(0x0, 0x39, 4, 0x1000000);
    vmeAM9Handle = get_new_device(0x0, 0x9, 4, 0x2000000);
    /* The entire A16 (D16), A24 (D16), space is mapped. */
    /* The bottom of A32 (D32) is mapped up to 0x2000000. */
    /* We need to be careful!*/
  
    set_hw_byte_swap(true);
}

void ReleaseHardware(void)
{
    close_device(vmeAM29Handle);    
    close_device(vmeAM39Handle);    
    close_device(vmeAM9Handle);    
}


void doWriteBlock(SBC_Packet* aPacket)
{
    SBC_VmeWriteBlockStruct* p = (SBC_VmeWriteBlockStruct*)aPacket->payload;
    if(needToSwap)SwapLongBlock(p,sizeof(SBC_VmeWriteBlockStruct)/sizeof(int32_t));

    uint32_t startAddress   = p->address;
    uint32_t oldAddress     = p->address;
    int32_t addressModifier = p->addressModifier;
    int32_t addressSpace    = p->addressSpace;
    int32_t unitSize        = p->unitSize;
    int32_t numItems        = p->numItems;
    TUVMEDevice* memMapHandle;
    bool deleteHandle = false;

    if (addressSpace == 0xFFFF) {
        memMapHandle = controlHandle;
        if (unitSize != sizeof(uint32_t) && numItems != 1) {
            sprintf(aPacket->message,"error: size and number not correct");
            p->errorCode = -1;
            writeBuffer(aPacket);
            return;
        }
    } else if(unitSize*numItems >= kDMALowerLimit) {
        if (addressSpace == 0xFF) set_dma_no_increment(true);
        else set_dma_no_increment(false);
        memMapHandle = get_dma_device(oldAddress, addressModifier, unitSize);
        addressSpace=0x1;
        startAddress = 0x0;
    } else if(addressModifier == 0x29 && unitSize == 2) {
        memMapHandle = vmeAM29Handle;
    } else if(addressModifier == 0x39 && unitSize == 4) {
        memMapHandle = vmeAM39Handle;
    } else if(addressModifier == 0x9 && unitSize == 4 && startAddress < 0x2000000) {
        memMapHandle = vmeAM9Handle;
    } else {
        /* The address must be byte-aligned */ 
        startAddress = p->address & 0xFFFF;
        p->address = p->address & 0xFFFF0000;
        memMapHandle = get_new_device(p->address, addressModifier, unitSize, 0); 
        if (memMapHandle == NULL) {
            sprintf(aPacket->message,"error: %d : %s\n",(int32_t)errno,strerror(errno));
            p->errorCode = -1;
            writeBuffer(aPacket);
            return;
        }
        deleteHandle = true;
    }
    
    p++; /*point to the data*/
    int16_t *sptr;
    int32_t  *lptr;
    switch(unitSize){
        case 1: /*bytes*/
            /*no need to swap*/
        break;
        
        case 2: /*shorts*/
            sptr = (int16_t*)p; /* cast to the data type*/ 
            if(needToSwap) SwapShortBlock(sptr,numItems);
        break;
        
        case 4: /*longs*/
            lptr = (int32_t*)p; /* cast to the data type*/ 
            if(needToSwap) SwapLongBlock(lptr,numItems);
        break;
    }
    
    int32_t result = 0;
    if (addressSpace == 0xFF) {
        /* We have to poll the same address. */
        uint32_t i = 0;
        for (i=0;i<numItems;i++) {
            result = 
                write_device(memMapHandle,
                    (char*)p + i*unitSize,unitSize,startAddress);
            if (result != unitSize) break;
        }
        if (result == unitSize) result = unitSize*numItems; 
    } else {
        result = 
            write_device(memMapHandle,(char*)p,numItems*unitSize,startAddress);
    }
    
    /* echo the structure back with the error code*/
    /* 0 == no Error*/
    /* non-0 means an error*/
    SBC_VmeWriteBlockStruct* returnDataPtr = 
        (SBC_VmeWriteBlockStruct*)aPacket->payload;
    returnDataPtr->address         = oldAddress;
    returnDataPtr->addressModifier = addressModifier;
    returnDataPtr->addressSpace    = addressSpace;
    returnDataPtr->unitSize        = unitSize;
    returnDataPtr->numItems        = 0;

    if(result == (numItems*unitSize)){
        returnDataPtr->errorCode = 0;
    }
    else {
        aPacket->cmdHeader.numberBytesinPayload    
          = sizeof(SBC_VmeWriteBlockStruct);
        returnDataPtr->errorCode = result;        
    }

    lptr = (int32_t*)returnDataPtr;
    if(needToSwap)SwapLongBlock(lptr,numItems);

    writeBuffer(aPacket);    
    if (deleteHandle) {
        close_device(memMapHandle);
    } 

}

void doReadBlock(SBC_Packet* aPacket)
{
    SBC_VmeReadBlockStruct* p = (SBC_VmeReadBlockStruct*)aPacket->payload;
    if(needToSwap) {
        SwapLongBlock(p,sizeof(SBC_VmeReadBlockStruct)/sizeof(int32_t));
    }
    uint32_t startAddress   = p->address;
    uint32_t oldAddress     = p->address;
    int32_t addressModifier = p->addressModifier;
    int32_t addressSpace    = p->addressSpace;
    int32_t unitSize        = p->unitSize;
    int32_t numItems        = p->numItems;
    TUVMEDevice* memMapHandle;
    bool deleteHandle = false;

    if (numItems*unitSize > kSBC_MaxPayloadSize) {
        sprintf(aPacket->message,"error: requested greater than payload size.");
        p->errorCode = -1;
        writeBuffer(aPacket);
        return;
    }
    if (addressSpace == 0xFFFF) {
        memMapHandle = controlHandle;
        if (unitSize != sizeof(uint32_t) && numItems != 1) {
            sprintf(aPacket->message,"error: size and number not correct");
            p->errorCode = -1;
            writeBuffer(aPacket);
            return;
         }
    } else if(unitSize*numItems >= kDMALowerLimit) {
        if (addressSpace == 0xFF) set_dma_no_increment(true);
        else set_dma_no_increment(false);
        memMapHandle = get_dma_device(oldAddress, addressModifier, unitSize);
        addressSpace=0x1;
        startAddress = 0x0;
    } else if(addressModifier == 0x29 && unitSize == 2) {
        memMapHandle = vmeAM29Handle;
    } else if(addressModifier == 0x39 && unitSize == 4) {
        memMapHandle = vmeAM39Handle;
    } else if(addressModifier == 0x9 && unitSize == 4 && startAddress < 0x2000000) {
        memMapHandle = vmeAM9Handle;
    } else {
        /* The address must be byte-aligned */ 
        startAddress = p->address & 0xFFFF;
        p->address = p->address & 0xFFFF0000;
        
        memMapHandle = get_new_device(p->address, addressModifier, unitSize, 0); 
        if (memMapHandle == NULL) {
            sprintf(aPacket->message,"error: %d : %s\n",
                (int32_t)errno,strerror(errno));
            p->errorCode = -1;
            writeBuffer(aPacket);
            return;
        }
        deleteHandle = true;
    }

    /*OK, got address and # to read, set up the response and go get the data*/
    aPacket->cmdHeader.destination = kSBC_Process;
    aPacket->cmdHeader.cmdID       = kSBC_VmeReadBlock;
    aPacket->cmdHeader.numberBytesinPayload    
        = sizeof(SBC_VmeReadBlockStruct) + numItems*unitSize;

    SBC_VmeReadBlockStruct* returnDataPtr = 
        (SBC_VmeReadBlockStruct*)aPacket->payload;
    char* returnPayload = (char*)(returnDataPtr+1);

    int32_t result = 0;
    
    if (addressSpace == 0xFF) {
        /* We have to poll the same address. */
        uint32_t i = 0;
        for (i=0;i<numItems;i++) {
            result = 
                read_device(memMapHandle,
                    returnPayload + i*unitSize,unitSize,startAddress);
            if (result != unitSize) break;
        }
        if (result == unitSize) result = unitSize*numItems; 
    } else {
        result = 
            read_device(memMapHandle,returnPayload,numItems*unitSize,startAddress);
    }
    
    returnDataPtr->address         = oldAddress;
    returnDataPtr->addressModifier = addressModifier;
    returnDataPtr->addressSpace    = addressSpace;
    returnDataPtr->unitSize        = unitSize;
    returnDataPtr->numItems        = numItems;
    if(result == (numItems*unitSize)){
        //printf("no read error\n");
        returnDataPtr->errorCode = 0;
        switch(unitSize){
            case 1: /*bytes*/
                /*no need to swap*/
                break;
            case 2: /*shorts*/
                if(needToSwap) SwapShortBlock((int16_t*)returnPayload,numItems);
                break;
            case 4: /*longs*/
                if(needToSwap) SwapLongBlock((int32_t*)returnPayload,numItems);
                break;
        }
    }
    else {
        sprintf(aPacket->message,"error: %d %d : %s\n",
           (int32_t)result,(int32_t)errno,strerror(errno));
        aPacket->cmdHeader.numberBytesinPayload    
            = sizeof(SBC_VmeReadBlockStruct);
        returnDataPtr->numItems  = 0;
        returnDataPtr->errorCode = result;        
    }

    if(needToSwap) {
        SwapLongBlock(returnDataPtr,
            sizeof(SBC_VmeReadBlockStruct)/sizeof(int32_t));
    }
    writeBuffer(aPacket);
    if (deleteHandle) {
        close_device(memMapHandle);
    } 

}

/*************************************************************/
/*  All HW Readout code for VMEcpu follows here.             */
/*                                                           */
/*  Readout_CARD() function returns the index of the next    */
/*   card to read out                                        */
/*************************************************************/

int32_t readHW(SBC_crate_config* config,int32_t index, SBC_LAM_Data* lamData, char recursive)
{
    if(index<config->total_cards && index>=0) {
        switch(config->card_info[index].hw_type_id){
            case kShaper:       index = Readout_Shaper(config,index,lamData);			break;
            case kGretina:      index = Readout_Gretina(config,index,lamData);			break;
            case kTrigger32:    index = -1; //Readout_TR32_Data(config,index,lamData);	break;
            case kSBCLAM:       index = Readout_LAM_Data(config,index,lamData);			break;
            default:            index = -1;												break;
        }
		return index;
    }
    else return -1;
}

/*************************************************************/
/*             Reads out Shaper cards.                       */
/*************************************************************/

int32_t Readout_Shaper(SBC_crate_config* config,int32_t index, SBC_LAM_Data* lamData)
{
    uint32_t baseAddress            = config->card_info[index].base_add;
    uint32_t conversionRegOffset    = config->card_info[index].deviceSpecificData[1];
    
    char theConversionMask;
    int32_t result    = read_device(vmeAM29Handle,&theConversionMask,1,baseAddress+conversionRegOffset); //byte access, the conversion mask
    if(result == 1 && theConversionMask != 0){

        uint32_t dataId            = config->card_info[index].hw_mask[0];
        uint32_t slot              = config->card_info[index].slot;
        uint32_t crate             = config->card_info[index].crate;
        uint32_t locationMask      = ((crate & 0x01e)<<21) | ((slot & 0x0000001f)<<16);
        uint32_t onlineMask        = config->card_info[index].deviceSpecificData[0];
        uint32_t firstAdcRegOffset = config->card_info[index].deviceSpecificData[2];

        int16_t channel;
        for (channel=0; channel<8; ++channel) {
            if(onlineMask & theConversionMask & (1L<<channel)){
                uint16_t aValue;
                result    = read_device(vmeAM29Handle,(char*)&aValue,2,baseAddress+firstAdcRegOffset+2*channel); //short access, the adc Value
                if(result == 2){
                    if(((dataId) & 0x80000000)){ //short form
                        data[dataIndex++] = dataId | locationMask | ((channel & 0x0000000f) << 12) | (aValue & 0x0fff);
                    }
                    else { //long form
                        data[dataIndex++] = dataId | 2;
                        data[dataIndex++] = locationMask | ((channel & 0x0000000f) << 12) | (aValue & 0x0fff);
                    }
                }
            }
        }
    }
    return config->card_info[index].next_Card_Index;
}            

/*************************************************************/
/*             Reads out Gretina (Mark I) cards.             */
/*************************************************************/

int32_t Readout_Gretina(SBC_crate_config* config,int32_t index, SBC_LAM_Data* lamData)
{

    static TUVMEDevice* vmeReadOutHandle = 0;
    static TUVMEDevice* vmeFIFOStateReadOutHandle = 0;
    static TUVMEDevice* vmeDMADevice = 0;
    static uint32_t fifoState;

    //uint32_t baseAddress      = config->card_info[index].base_add;
    uint32_t fifoStateAddress = config->card_info[index].deviceSpecificData[0];
    uint32_t fifoEmptyMask    = config->card_info[index].deviceSpecificData[1];
    uint32_t fifoAddress      = config->card_info[index].deviceSpecificData[2];
    uint32_t fifoAddressMod   = config->card_info[index].deviceSpecificData[3];
    uint32_t sizeOfFIFO       = config->card_info[index].deviceSpecificData[4];
    uint32_t dataId           = config->card_info[index].hw_mask[0];
    uint32_t slot             = config->card_info[index].slot;
    uint32_t crate            = config->card_info[index].crate;
    uint32_t location         = ((crate&0x0000000f)<<21) | ((slot& 0x0000001f)<<16);

    //read the fifo state
    int32_t result;
    fifoState = 0;
    if (config->card_info[index].add_mod == 0x29) {
        result = read_device(vmeAM29Handle,(char*)&fifoState,2,fifoStateAddress); 
    } 
    else {
        vmeFIFOStateReadOutHandle = vmeAM9Handle; 
        result = read_device(vmeFIFOStateReadOutHandle, (char*)&fifoState, 4, fifoStateAddress);
    }
    
    if (result <= 0) {
        return config->card_info[index].next_Card_Index;
    }
     
    if ((fifoState & fifoEmptyMask) == 0 || (fifoAddressMod == 0x39 && (fifoState & fifoEmptyMask) != 0)) {
        if (fifoAddressMod == 0x39) vmeReadOutHandle = vmeAM39Handle;
        else vmeReadOutHandle = vmeAM9Handle;

        uint32_t numLongs = 0;
		int32_t savedIndex = dataIndex;
        data[dataIndex++] = dataId | 0; //we'll fill in the length later
        data[dataIndex++] = location;
        
        //read the first int32_tword which should be the packet separator: 0xAAAAAAAA
        uint32_t theValue;
        result = read_device(vmeReadOutHandle,(char*)&theValue,4,fifoAddress); 
        
        if (result == 4 && (theValue==0xAAAAAAAA)){
            
            //read the first word of actual data so we know how much to read
            result = read_device(vmeReadOutHandle,(char*)&theValue,4,fifoAddress); 
            
            data[dataIndex++] = theValue;
            uint32_t numLongsLeft  = ((theValue & 0xffff0000)>>16)-1;
            int32_t totalNumLongs  = (numLongs + numLongsLeft);
             

            /* OK, now use dma access. */
            if (fifoAddressMod == 0x39) {
              /* Gretina I card */
              set_dma_no_increment(true);
              vmeDMADevice = get_dma_device(fifoAddress, fifoAddressMod, 4);
            } 
			else {
              /* Gretina IV card */
              set_dma_no_increment(false);
              vmeDMADevice = get_dma_device(fifoAddress, fifoAddressMod, 4);
            }
            if (vmeDMADevice == NULL) {
              return config->card_info[index].next_Card_Index;
            }
			
            result = read_device(vmeDMADevice,(char*)(&data[dataIndex]),numLongsLeft*4, 0); 
            dataIndex += numLongsLeft;
			
            if (result != numLongsLeft*4) {
              return config->card_info[index].next_Card_Index;
            }
            data[savedIndex] |= totalNumLongs; //see, we did fill it in...
		}
		else {
            //oops... really bad -- the buffer read is out of sequence -- dump it all
            uint32_t i = 0;
            while(i < sizeOfFIFO) {
                result = read_device(vmeReadOutHandle,(char*) (&theValue),4,fifoAddress); 
                if (result <= 0) // means the FIFO is empty
                  return config->card_info[index].next_Card_Index;
                if (theValue == 0xAAAAAAAA) break;
                i++;
            }
            //read the first word of actual data so we know how much to read
			//note that we are NOT going to save the data, but we do use the data buffer to hold the garbage
			//we'll reset the index to dump the data later....
            result = read_device(vmeReadOutHandle,(char*)&theValue,4,fifoAddress); 
            uint32_t numLongsLeft  = ((theValue & 0xffff0000)>>16)-1;
             
            /* OK, now use dma access. */
            if (fifoAddressMod == 0x39) {
              /* Gretina I card */
              set_dma_no_increment(true);
              vmeDMADevice = get_dma_device(fifoAddress, fifoAddressMod, 4);
            } 
			else {
              /* Gretina I card */
              set_dma_no_increment(false);
              vmeDMADevice = get_dma_device(fifoAddress, fifoAddressMod, 4);
            }
            if (vmeDMADevice == NULL) {
              return config->card_info[index].next_Card_Index;
            }
            result = read_device(vmeDMADevice,(char*)(&data[dataIndex]),numLongsLeft*4, 0); 
 			dataIndex = savedIndex; //DUMP the data by reseting the data Index back to where it was when we got it.
       }
    }
    return config->card_info[index].next_Card_Index;

}            

/*************************************************************/
/*             Reads out CAEN cards.                         */
/*************************************************************/

int32_t Readout_CAEN(SBC_crate_config* config,int32_t index, SBC_LAM_Data* lamData)
{
  
    /* The deviceSpecificData is as follows:          */ 
    /* 0: statusOne register                          */
    /* 1: statusTwo register                          */
    /* 2: buffer                                      */
    /*
    static SBC_VmeWriteBlockStruct caenStruct = 
        {0x0, 0x39, 0x1, 0x4, 0x0, 0x0}; 
    static int32_t vmeAM39Handle = 0;
    static uint16_t statusOne, statusTwo;
    
    uint32_t baseAddress = config->card_info[index].base_add;
    uint32_t statusOneIndex = 
        baseAddress + config->card_info[index].deviceSpecificData[0];
    uint32_t statusTwoIndex = 
        baseAddress + config->card_info[index].deviceSpecificData[1];
    uint32_t fifoAddress = 
        baseAddress + config->card_info[index].deviceSpecificData[2];
    uint32_t dataId      = config->card_info[index].hw_mask[0];
    uint32_t slot        = config->card_info[index].slot;
    uint32_t crate       = config->card_info[index].crate;
    //uint32_t addMod      = config->card_info[index].add_mod;
    uint32_t location    = ((crate&0x0000000f)<<21) | ((slot& 0x0000001f)<<16);
    

    //read the states
    int32_t result  = vme_read(vmeAM29Handle,fifoAddress,(uint8_t*)&fifoState,2); 
    if (result != 2) {
        return config->card_info[index].next_Card_Index;
    }
    int32_t dataBuffer[0xffff];
   
    caenStruct.address = fifoAddress; 
    vmeAM39Handle = openNewDevice("lsi2", &caenStruct); 

    if (vmeAM39Handle < 0) {
        return config->card_info[index].next_Card_Index;
    }
    closeDevice(vmeAM39Handle);*/
    return config->card_info[index].next_Card_Index;
}

/*************************************************************/
/*             Readout_LAM_Data                                     */
/*************************************************************/
int32_t Readout_LAM_Data(SBC_crate_config* config,int32_t index, SBC_LAM_Data* lamData)
{
    //this is a pseudo object that doesn't read any hardware, it just passes information back to ORCA
    lamData->lamNumber = config->card_info[index].slot;

    SBC_Packet lamPacket;
    lamPacket.cmdHeader.destination              = kSBC_Process;
    lamPacket.cmdHeader.cmdID                  = kSBC_LAM;
    lamPacket.cmdHeader.numberBytesinPayload  = sizeof(SBC_LAM_Data);
    memcpy(&lamPacket.payload, lamData, sizeof(SBC_LAM_Data));
    postLAM(&lamPacket);
    return config->card_info[index].next_Card_Index;
}            

