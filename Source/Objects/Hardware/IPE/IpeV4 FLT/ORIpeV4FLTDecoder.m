//
//  ORIpeV4FLTDecoder.m
//  Orca
//
//  Created by Mark Howe on 10/18/05.
//  Copyright 2004 CENPA, University of Washington. All rights reserved.
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


#import "ORIpeV4FLTDecoder.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORIpeV4FLTDefs.h"
#import "SLTv4_HW_Definitions.h"

@implementation ORIpeV4FLTDecoderForEnergy

//-------------------------------------------------------------
/** Data format for energy mode:
 *
 <pre>
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^-----------------------data id
                  ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs
 
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^--------------------------------spare
		 ^ ^^^---------------------------crate
			  ^ ^^^^---------------------card
                     ^^^^ ^^^^ ----------channel
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx sec
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx subSec
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx 
           ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ channel Map (24bit, 1 bit set denoting the channel number)  
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx 
                  ^^-------------------- time precision(2 bit)
                     ^^^^ ^^------------ number of page in hardware buffer (0..63, 6 bit)
                            ^^ ^^^^ ^^^^ eventID (0..511, 10 bit!)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx energy
 </pre>
 *
 */
//-------------------------------------------------------------


- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
{
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length	= ExtractLength(ptr[0]);								 
	unsigned char crate		= ShiftAndExtract(ptr[1],21,0xf);
	unsigned char card		= ShiftAndExtract(ptr[1],16,0x1f);
	unsigned char chan		= ShiftAndExtract(ptr[1],8,0xff);
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
	NSString* channelKey	= [self getChannelKey: chan];	
		
	//channel by channel histograms
	unsigned long energy = ptr[6]; ///*16; removed the /16 for Brandon... may leave it out
	[aDataSet histogram:energy 
				numBins:65535 
				 sender:self  
			   withKeys: @"FLT",@"Energy",crateKey,stationKey,channelKey,nil];
	
	//accumulated card level histograms
	[aDataSet histogram:energy 
				numBins:65535 
				 sender:self  
			   withKeys: @"FLT",@"Total Card Energy",crateKey,stationKey,nil];
	
	//accumulated crate level histograms
	[aDataSet histogram:energy
				numBins:65535 
				 sender:self  
			   withKeys: @"FLT",@"Total Crate Energy",crateKey,nil];
	
	
	
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Katrin FLT Energy Record\n\n";    
    NSString* crate = [NSString stringWithFormat:@"Crate      = %d\n",ShiftAndExtract(ptr[1],21,0xf)];
    NSString* card  = [NSString stringWithFormat:@"Station    = %d\n",ShiftAndExtract(ptr[1],16,0x1f)];
    NSString* chan  = [NSString stringWithFormat:@"Channel    = %d\n",ShiftAndExtract(ptr[1],8,0xff)];
		
	
	NSCalendarDate* theDate = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)ptr[2]];
	NSString* eventDate     = [NSString stringWithFormat:@"Date       = %@\n", [theDate descriptionWithCalendarFormat:@"%m/%d/%y"]];
	NSString* eventTime     = [NSString stringWithFormat:@"Time       = %@\n", [theDate descriptionWithCalendarFormat:@"%H:%M:%S"]];
	
	NSString* seconds		= [NSString stringWithFormat:@"Seconds    = %d\n",     ptr[2]];
	NSString* subSec        = [NSString stringWithFormat:@"SubSeconds = %d\n",     ptr[3]];
	NSString* chMap	    	= [NSString stringWithFormat:@"Channelmap = 0x%06x\n", ptr[4]];	
    NSString* nPages		= [NSString stringWithFormat:@"Stored Pg  = %d\n",     ptr[5]];
	
	NSString* energy        = [NSString stringWithFormat:@"Energy     = %d\n",     ptr[6]];

	
    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@",title,crate,card,chan,
			energy,eventDate,eventTime,seconds,subSec,nPages,chMap];               
    	
}
@end

@implementation ORIpeV4FLTDecoderForWaveForm

//-------------------------------------------------------------
/** Data format for waveform
 *
 <pre>  
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^-----------------------data id
 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs
 
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^--------------------------------spare
 ^ ^^^---------------------------crate
 ^ ^^^^---------------------card
 ^^^^ ^^^^-----------channel
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx sec
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx subSec
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx 
 ^^^^ ^^^^------------------------------ channel (0..22)
 ^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ channel Map (22bit, 1 bit set denoting the channel number)  
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx 
 ^ ------------------------------------- flag to indicate that the ADC have been swapped
 ^ ^^^^ ^^^^-------------------- number of page in hardware buffer
 ^^ ^^^^ ^^^^ eventID (0..1024)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx energy
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx eventFlags
                 ^^^ ^^^^ ^^^^-----------traceStart16 (first trace value in short array, 11 bit, 0..2047)
                                 ^-------append flag is in this record (append to previous record)
                                  ^------append next waveform record
                                    ^^^^-number which defines the content of the record (kind of version number)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx not yet defined ...
 TBD
 followed by waveform data (up to 2048 16-bit words)
 <pre>  
 */ 
//-------------------------------------------------------------


- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{

	unsigned long* ptr = (unsigned long*)someData;
	unsigned long length	= ExtractLength(ptr[0]);
	unsigned char crate		= ShiftAndExtract(ptr[1],21,0xf);
	unsigned char card		= ShiftAndExtract(ptr[1],16,0x1f);
	unsigned char chan		= ShiftAndExtract(ptr[1],8,0xff);
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
	NSString* channelKey	= [self getChannelKey: chan];	

	//channel by channel histograms
	unsigned long energy = ptr[6]; ///*16; removed the /16 for Brandon... may leave it out
	[aDataSet histogram:energy 
				numBins:65535 
				 sender:self  
			   withKeys: @"FLT",@"Energy",crateKey,stationKey,channelKey,nil];
	
	//accumulated card level histograms
	[aDataSet histogram:energy 
				numBins:65535 
				 sender:self  
			   withKeys: @"FLT",@"Total Card Energy",crateKey,stationKey,nil];
	
	//accumulated crate level histograms
	[aDataSet histogram:energy
				numBins:65535 
				 sender:self  
			   withKeys: @"FLT",@"Total Crate Energy",crateKey,nil];

	// Set up the waveform
	NSData* waveFormdata = [NSData dataWithBytes:someData length:length*sizeof(long)];

	[aDataSet loadWaveform: waveFormdata					//pass in the whole data set
					offset: 9*sizeof(long)					// Offset in bytes (past header words)
				    unitSize: sizeof(short)					// unit size in bytes
					mask:	0x0FFF							// when displayed all values will be masked with this value
					sender: self 
					withKeys: @"FLT", @"Waveform",crateKey,stationKey,channelKey,nil];
										
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{

    NSString* title= @"Ipe FLT Waveform Record\n\n";
	++ptr;		//skip the first word (dataID and length)
    
    NSString* crate = [NSString stringWithFormat:@"Crate      = %d\n",(*ptr>>21) & 0xf];
    NSString* card  = [NSString stringWithFormat:@"Station    = %d\n",(*ptr>>16) & 0x1f];
    NSString* chan  = [NSString stringWithFormat:@"Channel    = %d\n",(*ptr>>8) & 0xff];

    return [NSString stringWithFormat:@"%@%@%@%@",title,crate,card,chan]; 
}

@end

@implementation ORIpeV4FLTDecoderForHitRate

//-------------------------------------------------------------
/** Data format for hit rate mode:
 *
 <pre>
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^-----------------------data id
                  ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs
 
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^--------------------------------spare
         ^ ^^^---------------------------crate
              ^ ^^^^---------------------card
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx sec
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx hitRate length
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx total hitRate
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx 
      ^^^^ ^^^^-------------------------- channel (0..22)
			       ^--------------------- overflow  
				     ^^^^ ^^^^ ^^^^ ^^^^- hitrate
 ...more 
 </pre>
 *
 */
//-------------------------------------------------------------


- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length	= ExtractLength(ptr[0]);
	unsigned char crate		= ShiftAndExtract(ptr[1],21,0xf);
	unsigned char card		= ShiftAndExtract(ptr[1],16,0x1f);
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
	unsigned long seconds	= ptr[2];
	unsigned long hitRateTotal = ptr[4];
	int i;
	int n = length - 5;
	for(i=0;i<n;i++){
		int chan = ShiftAndExtract(ptr[5+i],20,0xff);
		NSString* channelKey	= [self getChannelKey:chan];
		unsigned long hitRate = ShiftAndExtract(ptr[5+i],0,0xffff);
		if(hitRate)[aDataSet histogram:hitRate
							   numBins:65536 
								sender:self  
							  withKeys: @"FLT",@"HitrateHistogram",crateKey,stationKey,channelKey,nil];

	    [aDataSet loadData2DX:card y:chan z:hitRate size:25  sender:self  withKeys:@"FLT",@"HitRate_2D",crateKey, nil];
	    [aDataSet sumData2DX:card y:chan z:hitRate size:25  sender:self  withKeys:@"FLT",@"HitRateSum_2D",crateKey, nil];
	}
	
	[aDataSet loadTimeSeries: hitRateTotal
                      atTime:seconds
					  sender:self  
					withKeys: @"FLT",@"HitrateTimeSeries",crateKey,stationKey,nil];
	
	
	
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Katrin FLT Hit Rate Record\n\n";
    NSString* crate = [NSString stringWithFormat:@"Crate      = %d\n",ShiftAndExtract(ptr[1],21,0xf)];
    NSString* card  = [NSString stringWithFormat:@"Station    = %d\n",ShiftAndExtract(ptr[1],16,0x1f)];
    return [NSString stringWithFormat:@"%@%@%@",title,crate,card];
}
@end


#if 0

@implementation ORIpeV4FLTDecoderForHistogram

//-------------------------------------------------------------
/** Data format for waveform
 *
 <pre>  
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^-----------------------data id
 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs
 
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^--------------------------------spare
 ^ ^^^---------------------------crate
 ^ ^^^^---------------------card
 ^^^^ ^^^^-----------channel
 followed by waveform data (n x 1024 16-bit words)
 </pre>
 *
 */
//-------------------------------------------------------------


- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length	= ExtractLength(*ptr);	 //get length from first word
	
	++ptr;											//crate, card,channel from second word
	unsigned char crate		= (*ptr>>21) & 0xf;
	unsigned char card		= (*ptr>>16) & 0x1f;
	unsigned char chan		= (*ptr>>8) & 0xff;
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
	NSString* channelKey	= [self getChannelKey: chan];
	
	// Set up the waveform
	NSData* waveFormdata = [NSData dataWithBytes:someData length:length*sizeof(long)];
	
	[aDataSet loadWaveform: waveFormdata					//pass in the whole data set
					offset: 2*sizeof(long)					// Offset in bytes (2 header words)
				  unitSize: sizeof(short)					// unit size in bytes
					  mask:	0x0FFF							// when displayed all values will be masked with this value
					sender: self 
				  withKeys: @"FLT", @"Waveform",crateKey,stationKey,channelKey,nil];
	
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
	
    NSString* title= @"Ipe FLT Waveform Record\n\n";
	++ptr;		//skip the first word (dataID and length)
    
    NSString* crate = [NSString stringWithFormat:@"Crate      = %d\n",(*ptr>>21) & 0xf];
    NSString* card  = [NSString stringWithFormat:@"Station    = %d\n",(*ptr>>16) & 0x1f];
    NSString* chan  = [NSString stringWithFormat:@"Channel    = %d\n",(*ptr>>8) & 0xff];
	
    return [NSString stringWithFormat:@"%@%@%@%@",title,crate,card,chan]; 
}
@end


#else


@implementation ORIpeV4FLTDecoderForHistogram

//-------------------------------------------------------------
/** Data format for hardware histogram
  *
<pre>  
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^-----------------------data id
                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs

xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^--------------------------------spare
        ^ ^^^---------------------------crate
             ^ ^^^^---------------------card
			        ^^^^ ^^^^-----------channel
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx readoutSec
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx refreshTime  (was recordingTimeSec)
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx firstBin
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx lastBin
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx histogramLength
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx maxHistogramLength
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx binSize
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx offsetEMin
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx histogramID
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx histogramInfo (some flags; some spare for future extensions)
                                      ^-pageAB flag
</pre>

  * For more infos: see
  * readOutHistogramDataV3:(ORDataPacket*)aDataPacket userInfo:(id)userInfo (in model)
  *
  */
//-------------------------------------------------------------


- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    //debug output -tb-
    //NSLog(@"  ORKatrinFLTDecoderForHistogram::decodeData:\n");
    
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length	= ExtractLength(*ptr);	 //get length from first word

	++ptr;											//crate, card,channel from second word
	unsigned char crate		= (*ptr>>21) & 0xf;
	unsigned char card		= (*ptr>>16) & 0x1f;
	unsigned char chan		= (*ptr>>8) & 0xff;
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* stationKey	= [self getStationKey: card];	
	NSString* channelKey	= [self getChannelKey: chan];
		
	++ptr;		//point to event struct
	
	
	katrinV4HistogramDataStruct* ePtr = (katrinV4HistogramDataStruct*) ptr;
    #if 0 //debug output -tb-
	NSLog(@"Keys:%@ %@ %@ %@ %@ \n", @"FLT",@"HitrateTimeSerie",crateKey,stationKey,channelKey);
	NSLog(@"  readoutSec = %d \n", ePtr->readoutSec);
	//NSLog(@"  recordingTimeSec = %d \n", ePtr->recordingTimeSec);
	NSLog(@"  refreshTimeSec = %d \n", ePtr->recordingTimeSec);
	NSLog(@"  firstBin = %d \n", ePtr->firstBin);
	NSLog(@"  lastBin = %d \n", ePtr->lastBin);
	NSLog(@"  histogramLength = %d \n", ePtr->histogramLength);
	NSLog(@"  maxHistogramLength = %d \n", ePtr->maxHistogramLength);
	NSLog(@"  binSize = %d \n", ePtr->binSize);
	NSLog(@"  offsetEMin = %d \n", ePtr->offsetEMin);
    #endif

    ptr = ptr + (sizeof(katrinV4HistogramDataStruct)/sizeof(long));// points now to the histogram data -tb-
    
    #if 0
    {
        // this is really brute force, but probably we want the second version (see below) ... -tb-
        // this counts every single event in the histogram as one event in data monitor -tb-
        int i;
        unsigned long aValue;
        unsigned long aBin;
        for(i=0; i< ePtr->histogramLength;i++){
            aValue=*(ptr+i);
            aBin = i+ (ePtr->firstBin);
            //if(aValue) NSLog(@"  Bin %i = %d \n", aBin,aValue);
            #if 1
            int j;
            for(j=0;j<aValue;j++){
                //NSLog(@"  Fill Bin %i = %d times \n", aBin,aValue);
                [aDataSet histogram:aBin 
                            numBins:2048 
                             sender:self  
                           withKeys: @"FLT",
                 @"Histogram (all counts)", // use better name -tb-
                 crateKey,stationKey,channelKey,nil];
            }
            #endif
        }
    }
    #endif
    

    #if 1
    // this counts one histogram as one event in data monitor -tb-
    if(ePtr->histogramLength){
        int numBins = 2048; //TODO: this has changed for V4 !!!! -tb-512;
        unsigned long data[numBins];// v3: histogram length is 512 -tb-
        int i;
        for(i=0; i< numBins;i++) data[i]=0;
        for(i=0; i< ePtr->histogramLength;i++){
            data[i+(ePtr->firstBin)]=*(ptr+i);
            //NSLog(@"Decoder: HistoEntry %i: bin %i val %i\n",i,i+(ePtr->firstBin),data[i+(ePtr->firstBin)]);
        }
        NSMutableArray*  keyArray = [NSMutableArray arrayWithCapacity:5];
        [keyArray insertObject:@"FLT" atIndex:0];
        [keyArray insertObject:@"Energy Histogram (HW)" atIndex:1]; //TODO: 1. use better name 2. keep memory clean -tb-
        [keyArray insertObject:crateKey atIndex:2];
        [keyArray insertObject:stationKey atIndex:3];
        [keyArray insertObject:channelKey atIndex:4];
        
        [aDataSet mergeHistogram:  data  
                         numBins:  numBins  // is fixed in the current FPGA version -tb- 2008-03-13 
                    withKeyArray:  keyArray];
    }
    #endif
    
    
    
    #if 0
    // test - ok  -tb-
    {        
        NSMutableArray*  keyArray = [NSMutableArray arrayWithCapacity:5];
        [keyArray insertObject:@"FLT" atIndex:0];
        [keyArray insertObject:@"Histogram (loadHistogram test)" atIndex:1];
        [keyArray insertObject:crateKey atIndex:2];
        [keyArray insertObject:stationKey atIndex:3];
        [keyArray insertObject:channelKey atIndex:4];
        
        [aDataSet loadHistogram:  ptr 
                        numBins:        ePtr->histogramLength 
                   withKeyArray:   keyArray];
    }
    #endif
    
    
    
    

    
    
    #if 0
    {
        // this is very similar to the first version (with speed up improvement 2008-08-05),
        // but probably it is usefull as it is in 'energy mode' units ... -tb-
        int i;
        //first compute the sum of events:
        unsigned int sumEvents=0;
        for(i=0; i< ePtr->histogramLength;i++){
            sumEvents += *(ptr+i);
        }
        unsigned long energy;
        //energy= ( ((ePtr->firstBin) << (ePtr->binSize))/2 )   + ePtr->offsetEMin;
        //energy= ( ((ePtr->firstBin) << (ePtr->binSize))/4 )   + ePtr->offsetEMin;// since 2009 May: /4 instead of /2, see getHistoEnergyOfBin of ORKatrinFLTDecoder.m
        energy= ( ((ePtr->firstBin) << (ePtr->binSize-2)) )   + ePtr->offsetEMin;// since 2009 May: /4 instead of /2, see getHistoEnergyOfBin of ORKatrinFLTDecoder.m
                       // maybe I should use getHistoEnergyOfBin here (then need to include header) ... -tb-
        int stepSize;
        stepSize = 1 << (ePtr->binSize -2);// again: see  getHistoEnergyOfBin of ORKatrinFLTDecoder.m

        [aDataSet mergeEnergyHistogram: ptr
                          numBins: ePtr->histogramLength  
                          maxBins: 65536  //32768
                         firstBin: energy   
                         stepSize: stepSize
                           counts: sumEvents
                         withKeys: @"FLT",
                                   @"Energy Histogram (HW, energy mode units)", // use better name -tb-
                                   crateKey,stationKey,channelKey,nil];
        
    }
    #endif
    

    return length; //must return number of longs processed.
}



- (NSString*) dataRecordDescription:(unsigned long*)ptr
{

    NSString* title= @"Katrin FLT Histogram Record\n\n";
	++ptr;		//skip the first word (dataID and length)
    
    NSString* crate = [NSString stringWithFormat:@"Crate      = %d\n",(*ptr>>21) & 0xf];
    NSString* card  = [NSString stringWithFormat:@"Station    = %d\n",(*ptr>>16) & 0x1f];
    NSString* chan  = [NSString stringWithFormat:@"Channel    = %d\n",(*ptr>>8) & 0xff];
	++ptr;		//point to next structure

	katrinV4HistogramDataStruct* ePtr = (katrinV4HistogramDataStruct*)ptr;			//recast to event structure

    #if 0
    //debug output
	NSLog(@" readoutSec = %d \n", ePtr->readoutSec);
	//NSLog(@" recordingTimeSec = %d \n", ePtr->recordingTimeSec);
	NSLog(@" refreshTimeSec = %d \n", ePtr->refreshTimeSec);
	NSLog(@" firstBin = %d \n", ePtr->firstBin);
	NSLog(@" lastBin = %d \n", ePtr->lastBin);
	NSLog(@" histogramLength = %d \n", ePtr->histogramLength);
    #endif
	
	NSString* readoutSec	= [NSString stringWithFormat:@"ReadoutSec = %d\n",ePtr->readoutSec];
	//NSString* recordingTimeSec	= [NSString stringWithFormat:@"recordingTimeSec = %d\n",ePtr->recordingTimeSec];
	NSString* refreshTimeSec	= [NSString stringWithFormat:@"refreshTimeSec = %d\n",ePtr->refreshTimeSec];
	NSString* firstBin	= [NSString stringWithFormat:@"firstBin = %d\n",ePtr->firstBin];
	NSString* lastBin	= [NSString stringWithFormat:@"lastBin = %d\n",ePtr->lastBin];
	NSString* histogramLength	= [NSString stringWithFormat:@"histogramLength = %d\n",ePtr->histogramLength];
	NSString* maxHistogramLength	= [NSString stringWithFormat:@"maxHistogramLength = %d\n",ePtr->maxHistogramLength];
	NSString* binSize	= [NSString stringWithFormat:@"binSize = %d\n",ePtr->binSize];
	NSString* offsetEMin	= [NSString stringWithFormat:@"offsetEMin = %d\n",ePtr->offsetEMin];
	NSString* histIDInfo	= [NSString stringWithFormat:@"ID = %d.%c\n",ePtr->histogramID,(ePtr->histogramInfo&0x1)?'B':'A'];


    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@",title,crate,card,chan,
	                       readoutSec,refreshTimeSec,firstBin,lastBin,histogramLength,
                           maxHistogramLength,binSize,offsetEMin,histIDInfo]; 
}



@end


#endif
