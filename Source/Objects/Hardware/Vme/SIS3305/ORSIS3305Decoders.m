//
//  ORSIS3305Decoders.m
//  Orca
//
//  Created by Mark A. Howe on Wednesday 9/30/08.
//  Copyright (c) 2008 CENPA. University of Washington. All rights reserved.
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

#import "ORSIS3305Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"
#import "ORSIS3305Model.h"


@implementation ORSIS3305DecoderForWaveform
//------------------------------------------------------------------
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^^ ^^^^ ^^-----------------------data id
//                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^--------------------------------most  sig bits of num records lost
//------------------------------^^^^-^^^--least sig bits of num records lost
//        ^ ^^^---------------------------crate
//             ^ ^^^^---------------------card
//                    ^^^^ ^^^^-----------channel
//                                      ^--buffer wrap mode
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx-length of waveform (longs)
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx-length of energy   (longs)
// ---- followed by the data record as read 
//from hardware. see the manual. Be careful-- the new 15xx firmware data structure 
//is slightly diff (two extra words -- if the buffer wrap bit is set)
// ---- should end in 0xdeadbeef
//------------------------------------------------------------------
#define kPageLength (65*1024)

const unsigned short kchannelModeAndEventID[16][16] = {
    {0,1,2,3,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 0: 4x1.25 w/ FIFO
    {0,1,2,3,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 1: 4x1.25 w/ FIFO
    {0,1,2,3,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 2: 4x1.25 w/ FIFO
    {0,1,2,3,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 3: 4x1.25 w/ FIFO
    
    {0xF,0xF,0xF,0xF,0,2,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 4: 2x2.5 w/ FIFO
    {0xF,0xF,0xF,0xF,1,2,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 5: 2x2.5 w/ FIFO
    {0xF,0xF,0xF,0xF,0,3,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 6: 2x2.5 w/ FIFO
    {0xF,0xF,0xF,0xF,1,3,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 7: 2x2.5 w/ FIFO
    
    {0xF,0xF,0xF,0xF,0xF,0xF,0xF,0,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 8
    {0xF,0xF,0xF,0xF,0xF,0xF,0xF,1,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode 9
    {0xF,0xF,0xF,0xF,0xF,0xF,0xF,2,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode A
    {0xF,0xF,0xF,0xF,0xF,0xF,0xF,3,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode B
    {0xF,0xF,0xF,0xF,0xF,0xF,0xF,0,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode C
    {0xF,0xF,0xF,0xF,0xF,0xF,0xF,1,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode D
    {0xF,0xF,0xF,0xF,0xF,0xF,0xF,2,0xF,0xF,0xF,0xF,0xF,0xF,0xF},  // channel mode E
    {0xF,0xF,0xF,0xF,0xF,0xF,0xF,3,0xF,0xF,0xF,0xF,0xF,0xF,0xF}  // channel mode F
};


- (id) init
{
    self = [super init];
    getRatesFromDecodeStage = YES;
    return self;
}

- (void) dealloc
{
	[actualSIS3305Cards release];
    [super dealloc];
}


- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    
    unsigned long* ptr	= (unsigned long*)someData;

    // extract things from the Orca header
	unsigned long length = ExtractLength(ptr[0]);        // the length in longs of the full *read* record (may contain multiple waveforms), with Orca header
	unsigned int crate	 = ShiftAndExtract(ptr[1],28,0xf);
	unsigned int card	 = ShiftAndExtract(ptr[1],20,0x1f);

    // extract group level things from the SIS header

    unsigned short  channelMode = ShiftAndExtract(ptr[1],16, 0xF);
    unsigned int    group       = ShiftAndExtract(ptr[1],12, 0x1);
    unsigned short  rate        = ShiftAndExtract(ptr[1], 8, 0xF);
    unsigned short  savingMode  = ShiftAndExtract(ptr[1], 4, 0xF);
    BOOL            wrapMode    = ShiftAndExtract(ptr[1], 0, 0x1);
    
    unsigned long dataLength = ptr[2];      // SIS header + data length of single record, in longs
    
	long sisHeaderLength;
	if(wrapMode)sisHeaderLength = 16;
	else		sisHeaderLength = 4;
    unsigned long orcaHeaderLength = 4;
    
    unsigned short numEvents = floor((length-orcaHeaderLength)/dataLength);
    unsigned long numEventsFromHeader = ptr[3]&0xFFFF;
    
    if (numEvents != numEventsFromHeader)
    {
        NSLogColor([NSColor redColor], @"SIS3305: Number of events incorrectly determined in at least one location!");
    }

    unsigned long waveformLength = dataLength-sisHeaderLength; // this is the waveform + sisheader.Each long word is 3 10 bit adc samples
    unsigned long* dataPtr       = ptr + orcaHeaderLength;   // hold on to this here

    
    unsigned short n;
    for(n=0;n<numEvents;n++)
    {
//        NSLog(@"Group %d    n = %d (decoder)\n",group,n);
        dataLength = (dataPtr[3]&0xFFFF)*4;      // SIS header + data length, in longs

        unsigned long* nextRecordPtr = dataPtr + sisHeaderLength + dataLength; // take you to the start of the next SIS header
        
        // extract things from the SIS header
        unsigned short      eventID = ShiftAndExtract(dataPtr[0], 28, 0xF);
        unsigned long       timestampLow = dataPtr[1];
        unsigned long       timestampHigh = dataPtr[0]&0xFFFF;
//        unsigned long long  timestamp = timestampLow | (timestampHigh << 31);

        // Biggest pre-computed value  is 31 - if you see this in the data, there IS an error somewhere (only 8 channels...)
        // each of the possible decoding options should handle assigning the channel independently.
        unsigned short channel = 31;
        NSString* channelKey = [self getChannelKey: channel];;
        
        NSString* crateKey		= [self getCrateKey: crate];
        NSString* cardKey		= [self getCardKey: card];
        NSMutableData*  recordAsData = [NSMutableData dataWithCapacity:(waveformLength*3*8)];

        if(waveformLength /*&& (waveformLength == (length - 3))*/)
        { // this is a sanity check that we have data and it is the size we expect
            if(wrapMode)
            {
                return (unsigned long)(-1);
              
                channel = (kchannelModeAndEventID[channelMode][eventID] + (group*4));
                channelKey    = [self getChannelKey: channel];

                unsigned long nof_wrap_samples = dataPtr[6] ;
                if(nof_wrap_samples <= waveformLength*3)
                {
                    unsigned long wrap_start_index = dataPtr[7] ;
                    unsigned short* dataPtr			  = (unsigned short*)[recordAsData bytes];
                    unsigned short* ushort_buffer_ptr = (unsigned short*) &dataPtr[8];
                    int i;
                    unsigned long j	=	wrap_start_index;
                    for (i=0;i<nof_wrap_samples;i++)
                    {
                        if(j >= nof_wrap_samples ) j=0;
                        dataPtr[i] = ushort_buffer_ptr[j++];
                    }
                }
               
            }
            else if((savingMode == 4) && (channelMode < 4)){  // 1.25 Gsps Event fifo mode with all four channels potentially enabled
                channel = ((dataPtr[0]>>28)&0xF) + (group*4);
                channelKey    = [self getChannelKey: channel];
                
                unsigned long* lptr = (unsigned long*)&dataPtr[sisHeaderLength]; // skip ORCA header + SIS header
                
                int i=0;
                unsigned short* waveData = (unsigned short*)[recordAsData mutableBytes];
                int waveformIndex = 0;
                // here `i` increments through each long word in the data
                for(i=0;i<waveformLength;i++){
                    waveData[waveformIndex++] = (lptr[i]>>20)   &0x3ff; // sample (3*i + waveformIndex)
                    waveData[waveformIndex++] = (lptr[i]>>10)   &0x3ff;
                    waveData[waveformIndex++] = (lptr[i])       &0x3ff;
                }
            
            }
            else if(savingMode == 1){   // 2.5 Gsps Event FIFO mode
                channel = ((dataPtr[0]>>28)&0xF)+ (group*4);

                channelKey    = [self getChannelKey: channel];
                
                unsigned long sisDataLength = 8*(dataPtr[3]&0xFFFF); // # longs SIS header claims are in waveform

                [recordAsData setLength:3*2*length];
                unsigned long* lptr = (unsigned long*)&dataPtr[sisHeaderLength]; //ORCA header + SIS header
                int i = 0;
                unsigned short* waveData = (unsigned short*)[recordAsData bytes];
                int waveformIndex = 0;
                unsigned short k = 0;
                //            for(i=0;i<2*waveformLength/3;i++){
                for(i=0;i<(sisDataLength*3);i+=7) { // sisDataLength*3 = number samples in waveform
                    // lptr[i] is at the first word of the 8x32-bit data block
                    for (k=0; k<4; k++ )
                    {
                        waveData[waveformIndex++] = (lptr[0+i+k]>>20)   &0x3ff;   // sample 1
                        waveData[waveformIndex++] = (lptr[4+i+k]>>20)   &0x3ff;   // sample 2
                        waveData[waveformIndex++] = (lptr[0+i+k]>>10)   &0x3ff;   // sample 3
                        waveData[waveformIndex++] = (lptr[4+i+k]>>10)   &0x3ff;   // sample 4
                        waveData[waveformIndex++] = (lptr[0+i+k])       &0x3ff;   // sample 5
                        waveData[waveformIndex++] = (lptr[4+i+k])       &0x3ff;   // sample 6
                    }
                }
                
            }   // end if( savingMode == 1)
            //        unsigned short* waveData = (unsigned short*)[recordAsData bytes];
            //        NSLog(@"         waveData[0,10,20,100] = (%d,%d,%d,%d)\n",waveData[0],waveData[10],waveData[20],waveData[100]);
            
        }
            if(recordAsData)[aDataSet loadWaveform:recordAsData
                                            offset: 0 //bytes!
                                          unitSize: sizeof( unsigned short ) //unit size in bytes! 10 bits needs 2 bytes
                                            sender: self
                                          withKeys: @"SIS3305", @"Waveform",crateKey,cardKey,channelKey,nil];

        
        dataPtr = nextRecordPtr;
//        NSLog(@"    Decoded %d/%d events so far\n",n+1,numEvents);
    }// end of loop over numEvents
    return length; //must return number of longs
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
	
 //   unsigned long length= ExtractLength(ptr[0]);
    unsigned int crateNum	= ShiftAndExtract(ptr[1],28,0xf);
    unsigned int cardNum	= ShiftAndExtract(ptr[1],20,0x1f);
    unsigned short channelModeNum = ShiftAndExtract(ptr[1], 16, 0xF);
    unsigned int groupNum	= ShiftAndExtract(ptr[1],12,0xf);
    unsigned short rateNum = ShiftAndExtract(ptr[1], 8, 0xF);
    unsigned short savingModeNum = ShiftAndExtract(ptr[1], 4, 0xF);
 //   BOOL wrapMode		= ShiftAndExtract(ptr[1],0,0x1);
    
    
//	 ptr++;
    NSString* title= @"SIS3305 Waveform Record\n\n";
    NSString* crate = [NSString stringWithFormat:@"Crate = %d\n",crateNum];
    NSString* card  = [NSString stringWithFormat:@"Card  = %d\n",cardNum];
    NSString* group  = [NSString stringWithFormat:@"Group  = %d\n",groupNum];
    NSString* rate  = [NSString stringWithFormat:@"Rate  = %d\n",rateNum];
    NSString* savingMode  = [NSString stringWithFormat:@"SavingMode  = %d\n",savingModeNum];
    NSString* channelMode  = [NSString stringWithFormat:@"Channel Mode  = %d\n",channelModeNum];

	 
    unsigned long timestampLow = ptr[4];
    unsigned long timestampHigh = ptr[3]&0xFFFF;
    unsigned long long timestamp = timestampLow | (timestampHigh << 31);
    NSString* timeStamp = [NSString stringWithFormat:@"Timestamp:\n  0x%llx\n",timestamp];
    
    
    NSString* rawHeader = @"Raw header:\n";
    unsigned int i;
    for(i=0;i<4;i++){
        NSString* tmp = [NSString stringWithFormat:@"%03d: 0x%08lx \n",i,(*ptr++)];
        rawHeader = [rawHeader stringByAppendingString:tmp];
    }
    rawHeader = [rawHeader stringByAppendingString:@"\n"];

    
    
    NSString* raw = @"Raw data:\n";
    for(i=0;i<100;i++){
        NSString* tmp1 = [NSString stringWithFormat:@"%03d: 0x%04lx, ",i,(((*ptr++)>>20)&0x3ff)];
        NSString* tmp2 = [NSString stringWithFormat:@"0x%04lx, ",(((*ptr++)>>10)&0x3ff)];
        NSString* tmp3 = [NSString stringWithFormat:@"0x%04lx \n",(((*ptr++)>>00)&0x3ff)];
        raw = [raw stringByAppendingString:[tmp1 stringByAppendingString:[tmp2 stringByAppendingString:tmp3]]];
    }

    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@",title,crate,card,group,rate,savingMode,channelMode,timeStamp,rawHeader,raw];
    
}
@end


