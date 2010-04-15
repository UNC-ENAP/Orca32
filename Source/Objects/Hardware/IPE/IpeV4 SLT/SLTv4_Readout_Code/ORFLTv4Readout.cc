#include "ORFLTv4Readout.hh"
#include "SLTv4_HW_Definitions.h"

#ifndef PMC_COMPILE_IN_SIMULATION_MODE
	#define PMC_COMPILE_IN_SIMULATION_MODE 0
#endif

#if PMC_COMPILE_IN_SIMULATION_MODE
    #warning MESSAGE: ORFLTv4Readout - PMC_COMPILE_IN_SIMULATION_MODE is 1
#else
    //#warning MESSAGE: ORFLTv4Readout - PMC_COMPILE_IN_SIMULATION_MODE is 0
	#include "katrinhw4/subrackkatrin.h"
#endif



#if !PMC_COMPILE_IN_SIMULATION_MODE
// (this is the standard code accessing the v4 crate-tb-)
//----------------------------------------------------------------

extern hw4::SubrackKatrin* srack; 

void readSltSecSubsec(uint32_t & sec, uint32_t & subsec)
{
    uint32_t subsecreg;
    subsecreg    = srack->theSlt->subSecCounter->read();
    sec             = srack->theSlt->secCounter->read();
    subsec   = ((subsecreg>>11)&0x3fff)*2000   +  (subsecreg & 0x7ff);//TODO: move this to the fdhwlib -tb-
}

bool ORFLTv4Readout::Readout(SBC_LAM_Data* lamData)
{
    //this data must be constant during a run
    static uint32_t histoBinWidth = 0;
    static uint32_t histoEnergyOffset = 0;
    static uint32_t histoRefreshTime = 0;
    
    //
    uint32_t dataId     = GetHardwareMask()[0];//this is energy record
    uint32_t waveformId = GetHardwareMask()[1];
    uint32_t histogramId = GetHardwareMask()[2];
    uint32_t col        = GetSlot() - 1; //GetSlot() is in fact stationNumber, which goes from 1 to 24 (slots go from 0-9, 11-20)
    uint32_t crate      = GetCrate();
    uint32_t location   = ((crate & 0x01e)<<21) | (((col+1) & 0x0000001f)<<16);
    
    uint32_t postTriggerTime = GetDeviceSpecificData()[0];
    uint32_t eventType  = GetDeviceSpecificData()[1];
    uint32_t fltRunMode = GetDeviceSpecificData()[2];
    uint32_t runFlags   = GetDeviceSpecificData()[3];
    uint32_t triggerEnabledMask = GetDeviceSpecificData()[4];
    uint32_t daqRunMode = GetDeviceSpecificData()[5];
    


    if(srack->theFlt[col]->isPresent()){
    
        #if 1
        //check timing
        //TODO: hmm, this should be done even before SLT releases inhibit ... -tb-
        if(runFlags & kSyncFltWithSltTimerFlag){
            GetDeviceSpecificData()[3] &= ~(kSyncFltWithSltTimerFlag);
            uint32_t sltsubsec;
            uint32_t sltsec1;
            uint32_t sltsec2;
            uint32_t fltsec;
            sltsubsec   = srack->theSlt->subSecCounter->read();
            sltsec1      = srack->theSlt->secCounter->read();
            fltsec      = srack->theFlt[col]->secondCounter->read();
            sltsubsec   = srack->theSlt->subSecCounter->read();
            sltsec2      = srack->theSlt->secCounter->read();
            int i;
            for(i=0; i<10; i++){
                if(sltsec1==fltsec && sltsec2==fltsec) break;//to be sure that the second strobe was not between reading sltsec1 and sltsec2
                sltsubsec   = srack->theSlt->subSecCounter->read();
                sltsec1      = srack->theSlt->secCounter->read();
                srack->theFlt[col]->secondCounter->write(sltsec1);
                fltsec      = srack->theFlt[col]->secondCounter->read();
                sltsubsec   = srack->theSlt->subSecCounter->read();
                sltsec2      = srack->theSlt->secCounter->read();
                //debug fprintf(stdout,"ORFLTv4Readout.cc: Syncronizing FLT %i to secCounter %li!\n",col+1,sltsec1);fflush(stdout);
            }
        }
        #endif
        #if 0 // a temporary test -tb-
        {
            static int once=1;
            if(once){
            once=0;
            uint32_t sltsec;
            uint32_t sltsec1;
            uint32_t sltsec2;
            uint32_t sltsubsec;
            uint32_t sltsubsec1;
            uint32_t sltsubsec2;
            uint32_t fltsec,fltsec1;
            sltsubsec   = srack->theSlt->subSecCounter->read();
            sltsec1=sltsec      = srack->theSlt->secCounter->read();
            while(sltsec1 == sltsec){
                sltsubsec   = srack->theSlt->subSecCounter->read();
                sltsec      = srack->theSlt->secCounter->read();
            }
            fltsec1=fltsec = srack->theFlt[col]->secondCounter->read();
            fprintf(stdout,"slt strobe:slt sec %i  slt sub  %i  fltsec:  %i\n",sltsec,sltsubsec,fltsec);
            while(fltsec1==fltsec){
                fltsec = srack->theFlt[col]->secondCounter->read();
            }
                sltsubsec   = srack->theSlt->subSecCounter->read();
                sltsec      = srack->theSlt->secCounter->read();
            fprintf(stdout,"FLT strobe:slt sec %i  slt sub  %i  fltsec:  %i\n",sltsec,sltsubsec,fltsec);
            fflush(stdout);
            sleep(1);
            }
        }
        #endif
        
        
        //READOUT MODES (energy, energy+trace, histogram)
        ////////////////////////////////////////////////////
        
        
        // --- ENERGY MODE ------------------------------
        if(daqRunMode == kIpeFlt_EnergyMode){  //then fltRunMode == kIpeFltV4Katrin_Run_Mode
            //uint32_t status         = srack->theFlt[col]->status->read();
            uint32_t fifoStatus;// = (status >> 24) & 0xf;
            uint32_t fifoFlags;// =   FF, AF, AE, EF
            
            //TO DO... the number of events to read could (should) be made variable <-- depending on the readptr/witeptr -tb-
            uint32_t eventN;
            for(eventN=0;eventN<10;eventN++){
                hw4::FltKatrinEventFIFOStatus* eventFIFOStatus = (hw4::FltKatrinEventFIFOStatus*)srack->theFlt[col]->eventFIFOStatus;//TODO: typing error in fdhwlib - remove cast after correction -tb-
                //fifoStatus = srack->theFlt[col]->eventFIFOStatus->read();//reads to cache
                fifoStatus = eventFIFOStatus->read();//reads to cache
                //uint32_t fifoEmptyFlag = (fifoStatus>>28)&1;//srack->theFlt[col]->eventFIFOStatus->emptyFlag->getCache();
                uint32_t fifoEmptyFlag = eventFIFOStatus->emptyFlag->getCache();
                //not needed for now - uint32_t fifoAlmostFull = eventFIFOStatus->almostFullFlag->getCache();//TODO: then we should read more than 10 events? -tb-
                //not needed for now - uint32_t fifoFullFlag = eventFIFOStatus->fullFlag->getCache();//TODO: then we should clear the fifo and leave? -tb-

                if(!fifoEmptyFlag){
                    //should be something in the fifo, check the read/write pointers and read and package up to 10 events.
                    //uint32_t writeptr = fifoStatus & 0x3ff;      //srack->theFlt[col]->eventFIFOStatus->writePointer->getCache();
                    //uint32_t readptr = (fifoStatus >>16) & 0x3ff;//srack->theFlt[col]->eventFIFOStatus->readPointer->getCache();
                    uint32_t writeptr = eventFIFOStatus->writePointer->getCache();
                    uint32_t readptr  = eventFIFOStatus->readPointer->getCache();
                    uint32_t diff = (writeptr-readptr+1024) % 512;
					fifoFlags = (eventFIFOStatus->fullFlag->getCache()			<< 3) |
								(eventFIFOStatus->almostFullFlag->getCache()	<< 2) |
								(eventFIFOStatus->almostEmptyFlag->getCache()	<< 1) |
								(eventFIFOStatus->emptyFlag->getCache());
                    //depending on 'diff' the loop should start here -tb-
                    
                    if(diff>0){
                        hw4::FltKatrinEventFIFO1 *eventFIFO1 = srack->theFlt[col]->eventFIFO1;
                        hw4::FltKatrinEventFIFO2 *eventFIFO2 = srack->theFlt[col]->eventFIFO2;
                        eventFIFO1->read();
                        eventFIFO2->read();
                        //uint32_t chmap = f1 >> 8;
                        uint32_t chmap = eventFIFO1->channelMap->getCache();
                        uint32_t evsec      = (eventFIFO1->sec12downto5->getCache()<<5) | (eventFIFO2->sec4downto0->getCache());//( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
                        uint32_t evsubsec   = eventFIFO2->subSec->getCache();//(f2 >> 2) & 0x1ffffff; // 25 bit
                                //evsubsec   = srack->theSlt->subSecCounter->read();
                                //evsec      = srack->theSlt->secCounter->read();
                        uint32_t precision  = eventFIFO2->timePrecision->getCache();
                        uint32_t eventchan, eventchanmask;
                        for(eventchan=0;eventchan<kNumChan;eventchan++){
                            eventchanmask = (0x1L << eventchan);
                            if((chmap & eventchanmask) && (triggerEnabledMask & eventchanmask)){
                                //fprintf(stdout,"  -->EVENT FLT %2i, chan %2i: ",col,eventchan);fflush(stdout);
                                uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(eventchan);
                                uint32_t f4            = srack->theFlt[col]->eventFIFO4->read(eventchan);
                                uint32_t pagenr        = f3 & 0x3f;
                                uint32_t energy        = f4 ;
                                
                                ensureDataCanHold(7); 
                                data[dataIndex++] = dataId | 7;    
                                data[dataIndex++] = location | eventchan<<8;
                                data[dataIndex++] = evsec;        //sec
                                data[dataIndex++] = evsubsec;     //subsec
                                data[dataIndex++] = chmap;
                                data[dataIndex++] = readptr | (pagenr<<10) | (precision<<16)  | (fifoFlags <<20);  //event flags: event ID=read ptr (10 bit); pagenr (6 bit); fifoFlags (4 bit)
                                data[dataIndex++] = energy;
                            }
                        }
                    }
                }//if(!fifoEmptyFlag)...
                else break;//fifo is empty, leave ...
            }//for(eventN=0; ...
        }
        // --- ENERGY+TRACE MODE ------------------------------
        else if(daqRunMode == kIpeFlt_EnergyTrace){  //then fltRunMode == kIpeFltV4Katrin_Run_Mode
            //uint32_t status         = srack->theFlt[col]->status->read();
            uint32_t fifoStatus;// = (status >> 24) & 0xf;
            
            //TO DO... the number of events to read could (should) be made variable <-- depending on the readptr/witeptr -tb-
            uint32_t eventN;
            for(eventN=0;eventN<10;eventN++){
                hw4::FltKatrinEventFIFOStatus* eventFIFOStatus = (hw4::FltKatrinEventFIFOStatus*)srack->theFlt[col]->eventFIFOStatus;//TODO: typing error in fdhwlib - remove cast after correction -tb-
                //fifoStatus = srack->theFlt[col]->eventFIFOStatus->read();//reads to cache
                fifoStatus = eventFIFOStatus->read();//reads to cache
                //uint32_t fifoEmptyFlag = (fifoStatus>>28)&1;//srack->theFlt[col]->eventFIFOStatus->emptyFlag->getCache();
                uint32_t fifoEmptyFlag = eventFIFOStatus->emptyFlag->getCache();
                uint32_t fifoAlmostFull = eventFIFOStatus->almostFullFlag->getCache();
                if(!fifoEmptyFlag){
                    
                    //should be something in the fifo, check the read/write pointers and read and package up to 10 events.
                    //uint32_t writeptr = fifoStatus & 0x3ff;      //srack->theFlt[col]->eventFIFOStatus->writePointer->getCache();
                    //uint32_t readptr = (fifoStatus >>16) & 0x3ff;//srack->theFlt[col]->eventFIFOStatus->readPointer->getCache();
                    uint32_t writeptr = eventFIFOStatus->writePointer->getCache();
                    uint32_t readptr  = eventFIFOStatus->readPointer->getCache();
                    uint32_t diff = (writeptr-readptr+1024) % 512;
                    
                    //depending on 'diff' the loop should start here -tb-
                    
                    if(diff>0){
                        hw4::FltKatrinEventFIFO1 *eventFIFO1 = srack->theFlt[col]->eventFIFO1;
                        hw4::FltKatrinEventFIFO2 *eventFIFO2 = srack->theFlt[col]->eventFIFO2;
                        eventFIFO1->read();
                        eventFIFO2->read();
                        //uint32_t chmap = f1 >> 8;
                        uint32_t chmap = eventFIFO1->channelMap->getCache();
                        uint32_t evsec      = (eventFIFO1->sec12downto5->getCache()<<5) | (eventFIFO2->sec4downto0->getCache());//( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
                        uint32_t evsubsec   = eventFIFO2->subSec->getCache();//(f2 >> 2) & 0x1ffffff; // 25 bit
                        uint32_t adcoffset  = evsubsec & 0x7ff; // cut 11 ls bits (equal to % 2048)                                //evsubsec   = srack->theSlt->subSecCounter->read();
                                //evsec      = srack->theSlt->secCounter->read();
                        uint32_t precision  = eventFIFO2->timePrecision->getCache();
                        uint32_t sltsubsec;
                        uint32_t sltsec;
                        int32_t timediff2slt;
                        uint32_t eventchan, eventchanmask;
                        for(eventchan=0;eventchan<kNumChan;eventchan++){
                            eventchanmask = (0x1L << eventchan);
                            if((chmap & eventchanmask) && (triggerEnabledMask & eventchanmask)){
                                uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(eventchan);
                                uint32_t f4            = srack->theFlt[col]->eventFIFO4->read(eventchan);
                                uint32_t pagenr        = f3 & 0x3f;
                                uint32_t energy        = f4 ;
                                //fprintf(stdout,"  -->EVENT FLT %2i, chan %2i: page %i\n",col,eventchan,pagenr);fflush(stdout);
                                uint32_t eventFlags=0;//append page, append next page
                                uint32_t wfRecordVersion=0;//length: 4 bit (0..15) 0x1=raw trace, full length
                                uint32_t traceStart16;//start of trace in short array
                                
                                wfRecordVersion = 0x1 ;//0x1=raw trace, full length, no additional analysis (use if fifo is almost full)
                                
                                #if 0
                                //check timing
                                readSltSecSubsec(sltsec,sltsubsec);
                                timediff2slt = (sltsec-evsec)*(int32_t)20000000 + ((int32_t)sltsubsec-(int32_t)evsubsec);//in 50ns units
//fprintf(stdout,"FLT%i>%i,%i<Timediff ev2slttime is %i (sec slt %i  ev %i) (subsec slt %i  ev  %i))   \n\r",col+1,readptr,writeptr,timediff2slt,sltsec,evsec,sltsubsec,evsubsec); fflush(stdout);
//fprintf(stdout,"-----------------------------                                  \n\r"); fflush(stdout);
                                #endif

                                uint32_t waveformLength = 2048; 
                                static uint32_t waveformBuffer32[64*1024];
                                static uint32_t shipWaveformBuffer32[64*1024];
                                static uint16_t *waveformBuffer16 = (uint16_t *)(waveformBuffer32);
                                static uint16_t *shipWaveformBuffer16 = (uint16_t *)(shipWaveformBuffer32);
                                uint32_t searchTrig,triggerPos = 0xffffffff;
                                int32_t appendFlagPos = -1;
                                
                                srack->theSlt->pageSelect->write(0x100 | pagenr);
                                
                                uint32_t adccount;
								//read raw trace
								for(adccount=0; adccount<1024;adccount++){
									shipWaveformBuffer32[adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
								}
                                if(wfRecordVersion == 0x1){
                                     //search trigger flag (usually in the same or adcoffset+2 bin 2009-12-15)
                                    searchTrig=adcoffset; //+2;
                                    searchTrig = searchTrig & 0x7ff;
                                    if(shipWaveformBuffer16[searchTrig] & 0x08000) triggerPos = searchTrig;
                                    searchTrig = (searchTrig+1) & 0x7ff;
                                    if(shipWaveformBuffer16[searchTrig] & 0x08000) triggerPos = searchTrig;
                                    searchTrig = (searchTrig+1) & 0x7ff;
                                    if(shipWaveformBuffer16[searchTrig] & 0x08000) triggerPos = searchTrig;
                                    searchTrig = (searchTrig+1) & 0x7ff;
                                    if(shipWaveformBuffer16[searchTrig] & 0x08000) triggerPos = searchTrig;
                                    searchTrig = (searchTrig+1) & 0x7ff;
                                    if(shipWaveformBuffer16[searchTrig] & 0x08000) triggerPos = searchTrig;
                                    //printf("FLT%i: FOund triggerPos %i , diff> %i<  (adcoffset was %i, searchtrig %i)\n",col+1,triggerPos,triggerPos-adcoffset, adcoffset,searchTrig);
									//printf("FLT%i: FOund triggerPos %i , diff> %i<  \n",col+1,triggerPos,triggerPos-adcoffset);fflush(stdout);
                                    //uint32_t copyindex = (adcoffset + postTriggerTime) % 2048;
#if 0  //TODO: testcode - I will remove it later -tb-
             fprintf(stdout,"triggerPos is %x (%i)  (last search pos %i)\n",triggerPos,triggerPos,searchTrig);fflush(stdout);
             fprintf(stdout,"srack->theFlt[col]->postTrigTime->read() %x \n",srack->theFlt[col]->postTrigTime->read());fflush(stdout);
           if(srack->theFlt[col]->postTrigTime->read() == 0x12c){
           for(adccount=0; adccount<2*1024;adccount++){
                   uint16_t adcval = shipWaveformBuffer16[adccount] & 0xffff;
                        if(adcval & 0xf000){
                         fprintf(stdout,"adcval[%i] has flags %x \n",adccount,adcval);fflush(stdout);
                        }
           }
           }
#endif
                                    traceStart16 = (triggerPos + postTriggerTime ) % 2048;
                                }
                                else {
                                    //search trigger pos
                                    for(adccount=0; adccount<1024;adccount++){
                                        uint32_t adcval = waveformBuffer32[adccount];
                                        #if 1
                                        uint32_t adcval1 = adcval & 0xffff;
                                        uint32_t adcval2 = (adcval >> 16) & 0xffff;
                                        if(adcval1 & 0x8000) triggerPos = adccount*2;
                                        if(adcval2 & 0x8000) triggerPos = adccount*2+1;
                                        if(adcval1 & 0x2000) appendFlagPos = adccount*2;
                                        if(adcval2 & 0x2000) appendFlagPos = adccount*2+1;
                                        #endif
                                    }
                                    //printf("FLT%i:triggerPos %i\n",col+1, triggerPos);
                                    //set append page flag
                                    if(appendFlagPos>=0) eventFlags |= 0x20;
                                    //uint32_t copyindex = (triggerPos + 1024) % 2048; //<- this aligns the trigger in the middle (from Mark)
                                    //uint32_t copyindex = (triggerPos + postTriggerTime) % 2048 ;// this was the workaround without time info -tb-
                                    traceStart16 = (adcoffset + postTriggerTime) % 2048 ;
                                 }
                                
                                //ship data record
                                ensureDataCanHold(9 + waveformLength/2); 
                                data[dataIndex++] = waveformId | (9 + waveformLength/2);    
                                //printf("FLT%i: waveformId is %i  loc+ev.chan %i\n",col+1,waveformId,  location | eventchan<<8);
                                data[dataIndex++] = location | eventchan<<8;
                                data[dataIndex++] = evsec;        //sec
                                data[dataIndex++] = evsubsec;     //subsec
                                data[dataIndex++] = chmap;
                                data[dataIndex++] = (readptr & 0x3ff) | ((pagenr & 0x3f)<<10) | ((precision & 0x3)<<16);        //event ID:read ptr (10 bit); pagenr (6 bit)
                                data[dataIndex++] = energy;
                                data[dataIndex++] = ((traceStart16 & 0x7ff)<<8) | eventFlags | (wfRecordVersion & 0xf);
                                //data[dataIndex++] = 0;    //spare to remain byte compatible with the v3 record
                                data[dataIndex++] = postTriggerTime /*for debugging -tb-*/   ;    //spare to remain byte compatible with the v3 record
                                
                                //TODO: SHIP TRIGGER POS and POSTTRIGG time !!! -tb-
                                
                                //ship waveform
                                uint32_t waveformLength32=waveformLength/2; //the waveform length is variable    
                                for(uint32_t i=0;i<waveformLength32;i++){
                                    data[dataIndex++] = shipWaveformBuffer32[i];
                                }
                                
                            }
                        }
                    }
                }//if(!fifoEmptyFlag)...
                else break;//fifo is empty, leave loop ...
            }//for(eventN=0; ...
        }
        // --- HISTOGRAM MODE ------------------------------
        else if(fltRunMode == kIpeFltV4Katrin_Histo_Mode) {    //then fltRunMode == kIpeFltV4Katrin_Histo_Mode
                // buffer some data:
                hw4::FltKatrin *currentFlt = srack->theFlt[col];
                //hw4::SltKatrin *currentSlt = srack->theSlt;
                uint32_t pageAB,oldpageAB;
                //uint32_t pStatus[3];
                //fprintf(stdout,"FLT %i:runFlags %x\n",col+1, runFlags );fflush(stdout);    
                //fprintf(stdout,"FLT %i:runFlags %x  pn 0x%x\n",col+1, runFlags,srack->theFlt[col]->histNofMeas->read() );fflush(stdout); 
                //sleep(1);   
                if(runFlags & kFirstTimeFlag){// firstTime   
                    //make some plausability checks
                    currentFlt->histogramSettings->read();//read to cache
                    if(currentFlt->histogramSettings->histModeStopUncleared->getCache() ||
                       currentFlt->histogramSettings->histClearModeManual->getCache()){
                        fprintf(stdout,"ORFLTv4Readout.cc: WARNING: histogram readout is designed for continous and auto-clear mode only! Change your FLTv4 settings!\n");
                        fflush(stdout);
                    }
                    //store some static data which is constant during run
                    histoBinWidth       = currentFlt->histogramSettings->histEBin->getCache();
                    histoEnergyOffset   = currentFlt->histogramSettings->histEMin->getCache();
                    histoRefreshTime    = currentFlt->histMeasTime->read();
					//set page manager to automatic mode
					//srack->theSlt->pageSelect->write(0x100 | 3); //TODO: this flips the two parts of the histogram - FPGA bug? -tb-
					srack->theSlt->pageSelect->write((long unsigned int)0x0);
                    //clear histogram (probably not really necessary with "automatic clear" -tb-) 
                    srack->theFlt[col]->command->resetPages->write(1);
                    //init page AB flag
                    pageAB = srack->theFlt[col]->status->histPageAB->read();
                    GetDeviceSpecificData()[3]=pageAB;
                    //debug: fprintf(stdout,"FLT %i: first cycle\n",col+1);fflush(stdout);
                    //debug: //sleep(1);
                }
                else{//check timing
                    //pagenr=srack->theFlt[col]->histNofMeas->read() & 0x3f;
                    //srack->theFlt[col]->periphStatus->readBlock((long unsigned int*)pStatus);//TODO: fdhwlib will change to uint32_t in the future -tb-
                    //pageAB = (pStatus[0] & 0x10) >> 4;
                    oldpageAB = GetDeviceSpecificData()[3]; //
                    //pageAB = (srack->theFlt[col]->periphStatus->read(0) & 0x10) >> 4;
                    //pageAB = srack->theFlt[col]->periphStatus->histPageAB->read(0);
                    pageAB = srack->theFlt[col]->status->histPageAB->read();
                    //fprintf(stdout,"FLT %i: oldpage  %i currpagenr %i\n",col+1, oldpagenr, pagenr  );fflush(stdout);  
                    //              sleep(1);
                    
                    if(oldpageAB != pageAB){
                        //debug: fprintf(stdout,"FLT %i:toggle now from %i to page %i\n",col+1, oldpageAB, pageAB  );fflush(stdout);    
                        GetDeviceSpecificData()[3] = pageAB; 
                        //read data
                        uint32_t chan=0;
                        uint32_t readoutSec;
                        unsigned long totalLength;
                        uint32_t last,first;
                        uint32_t fpgaHistogramID;
                        static uint32_t shipHistogramBuffer32[2048];
                        fpgaHistogramID     = currentFlt->histNofMeas->read();;
                        // CHANNEL LOOP ----------------
                        for(chan=0;chan<kNumChan;chan++) {//read out histogram
                            if( !(triggerEnabledMask & (0x1L << chan)) ) continue; //skip channels with disabled trigger
                            currentFlt->histLastFirst->read(chan);//read to cache ...
                            //last = (lastFirst >>16) & 0xffff;
                            //first = lastFirst & 0xffff;
                            last  = currentFlt->histLastFirst->histLastEntry->getCache(chan);
                            first = currentFlt->histLastFirst->histFirstEntry->getCache(chan);
                            //debug: fprintf(stdout,"FLT %i: ch %i:first %i, last %i \n",col+1,chan,first,last);fflush(stdout);
                            
                            #if 1  //READ OUT HISTOGRAM -tb- -------------
							{
								//read sec
								readoutSec=currentFlt->secondCounter->read();
                                //prepare data record
                                katrinV4HistogramDataStruct theEventData;
                                theEventData.readoutSec = readoutSec;
                                theEventData.refreshTimeSec =  histoRefreshTime;//histoRunTime;   
								
								//read out histogram
								if(last<first){
									//no events, write out empty histogram -tb-
									theEventData.firstBin  = 2047;//histogramDataFirstBin[chan];//read in readHistogramDataForChan ... [self readFirstBinForChan: chan];
									theEventData.lastBin   = 0;//histogramDataLastBin[chan]; //                "                ... [self readLastBinForChan:  chan];
									theEventData.histogramLength =0;
								}
								else{
									//read histogram block
									srack->theFlt[col]->histogramData->readBlockAutoInc(chan,  (long unsigned int*)shipHistogramBuffer32, 0, 2048);
									theEventData.firstBin  = 0;//histogramDataFirstBin[chan];//read in readHistogramDataForChan ... [self readFirstBinForChan: chan];
									theEventData.lastBin   = 2047;//histogramDataLastBin[chan]; //                "                ... [self readLastBinForChan:  chan];
									theEventData.histogramLength =2048;
								}
							
                                //theEventData.histogramLength = theEventData.lastBin - theEventData.firstBin +1;
                                //if(theEventData.histogramLength < 0){// we had no counts ...
                                //    theEventData.histogramLength = 0;
                                //}
                                theEventData.maxHistogramLength = 2048; // needed here? is already in the header! yes, the decoder needs it for calibration of the plot -tb-
                                theEventData.binSize    = histoBinWidth;        
                                theEventData.offsetEMin = histoEnergyOffset;
                                theEventData.histogramID    = fpgaHistogramID;
                                theEventData.histogramInfo  = pageAB & 0x1;//one bit
                                
                                //ship data record
                                totalLength = 2 + (sizeof(katrinV4HistogramDataStruct)/sizeof(long)) + theEventData.histogramLength;// 2 = header + locationWord
                                ensureDataCanHold(totalLength); 
                                data[dataIndex++] = histogramId | totalLength;    
                                data[dataIndex++] = location | chan<<8;
                                int32_t checkDataIndexLength = dataIndex;
                                data[dataIndex++] = theEventData.readoutSec;
                                data[dataIndex++] = theEventData.refreshTimeSec;
                                data[dataIndex++] = theEventData.firstBin;
                                data[dataIndex++] = theEventData.lastBin;
                                data[dataIndex++] = theEventData.histogramLength;
                                data[dataIndex++] = theEventData.maxHistogramLength;
                                data[dataIndex++] = theEventData.binSize;
                                data[dataIndex++] = theEventData.offsetEMin;
                                data[dataIndex++] = theEventData.histogramID;// don't confuse with Orca data ID 'histogramID' -tb-
                                data[dataIndex++] = theEventData.histogramInfo;
                                if( ((dataIndex-checkDataIndexLength)*sizeof(int32_t)) != sizeof(katrinV4HistogramDataStruct) ) fprintf(stdout,"ORFLTv4Readout: WARNING: bad record size!\n");
                                fflush(stdout);   
                                int i;
								if(theEventData.histogramLength>0){
									for(i=0; i<theEventData.histogramLength;i++)
										data[dataIndex++] = shipHistogramBuffer32[i];
								}
								//debug: fprintf(stdout," Shipping histogram with ID %i\n",histogramID);     fflush(stdout);   
                            }
                            #endif
                            
                        }
                    } 
                }
        }
        // --- BAD MODE ------------------------------
        else{
            fprintf(stdout,"ORFLTv4Readout.cc: WARNING: received unknown DAQ mode!\n"); fflush(stdout);
        }

    }
    return true;
    
}

#if 1 //Test to prepare single histogram readout -tb-
//TODO: using this inhibits stopping a waveform run (?) -tb-
bool ORFLTv4Readout::Stop()
{
	//-tb- a test:
	//fprintf(stdout,"ORFLTv4Readout.cc: This is bool ORFLTv4Readout::Stop() for slot %i (ct is %i)!\n",GetSlot()); fflush(stdout);
    // it seems to me that nobody cares when I return false; -tb-
	return true;
}
#endif

#if (0)
//maybe read hit rates in the pmc at some point..... here's how....
//read hitrates
{
    int col,row;
    for(col=0; col<20;col++){
        if(srack->theFlt[col]->isPresent()){
            //fprintf(stdout,"FLT %i:",col);
            for(row=0; row<24;row++){
                int hitrate = srack->theFlt[col]->hitrate->read(row);
                //if(row<5) fprintf(stdout," %i(0x%x),",hitrate,hitrate);
            }
            //fprintf(stdout,"\n");
            //fflush(stdout);
            
        }
    }

    return true; 
}
#endif


#else //of #if !PMC_COMPILE_IN_SIMULATION_MODE
// (here follow the 'simulation' versions of all functions -tb-)
//----------------------------------------------------------------

bool ORFLTv4Readout::Readout(SBC_LAM_Data* lamData)
{
    //
    uint32_t dataId     = GetHardwareMask()[0];//this is energy record
    uint32_t waveformId = GetHardwareMask()[1];
    uint32_t histogramId = GetHardwareMask()[2];
    uint32_t col        = GetSlot() - 1; //the mac slots go from 1 to n
    uint32_t crate        = GetCrate();
    uint32_t location   = ((crate & 0x01e)<<21) | (((col+1) & 0x0000001f)<<16);
    
    uint32_t postTriggerTime = GetDeviceSpecificData()[0];
    uint32_t eventType  = GetDeviceSpecificData()[1];
    uint32_t fltRunMode = GetDeviceSpecificData()[2];
    uint32_t runFlags   = GetDeviceSpecificData()[3];
    uint32_t triggerEnabledMask = GetDeviceSpecificData()[4];
    uint32_t daqRunMode = GetDeviceSpecificData()[5];
    
    return true;
}

bool ORFLTv4Readout::Stop()
{
	return true;
}


#endif //of #if !PMC_COMPILE_IN_SIMULATION_MODE ... #else ...
//----------------------------------------------------------------





//dumpster
        #if 0
            uint32_t status         = srack->theFlt[col]->status->read();
            uint32_t  fifoStatus = (status >> 24) & 0xf;
            
            if(fifoStatus != kFifoEmpty){
                //TO DO... the number of events to read could (should) be made variable 
                uint32_t eventN;
                for(eventN=0;eventN<10;eventN++){
                    
                    //should be something in the fifo, check the read/write pointers and read and package up to 10 events.
                    uint32_t fstatus = srack->theFlt[col]->eventFIFOStatus->read();
                    uint32_t writeptr = fstatus & 0x3ff;
                    uint32_t readptr = (fstatus >>16) & 0x3ff;
                    uint32_t diff = (writeptr-readptr+1024) % 512;
                    
                    if(diff>0){
                        uint32_t f1 = srack->theFlt[col]->eventFIFO1->read();
                        uint32_t chmap = f1 >> 8;
                        uint32_t f2 = srack->theFlt[col]->eventFIFO2->read();
                        uint32_t eventchan;
                        for(eventchan=0;eventchan<kNumChan;eventchan++){
                            if(chmap & (0x1L << eventchan)){
                                //fprintf(stdout,"  -->EVENT FLT %2i, chan %2i: ",col,eventchan);fflush(stdout);
                                uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(eventchan);
                                uint32_t f4            = srack->theFlt[col]->eventFIFO4->read(eventchan);
                                uint32_t pagenr        = f3 & 0x3f;
                                uint32_t energy        = f4 ;
                                uint32_t evsec        = ( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
                                uint32_t evsubsec    = (f2 >> 2) & 0x1ffffff; // 25 bit
                                
                                uint32_t waveformLength = 2048; 
                                if(eventType & kReadWaveForms){
                                    ensureDataCanHold(9 + waveformLength/2); 
                                    data[dataIndex++] = waveformId | (9 + waveformLength/2);    
                                }
                                else {
                                    ensureDataCanHold(7); 
                                    data[dataIndex++] = dataId | 7;    
                                }
                                

                                data[dataIndex++] = location | eventchan<<8;
                                data[dataIndex++] = evsec;        //sec
                                data[dataIndex++] = evsubsec;    //subsec
                                data[dataIndex++] = chmap;
                                data[dataIndex++] = pagenr;        //was listed as the event ID... put in the pagenr for now 
                                data[dataIndex++] = energy;
                                
                                if(eventType & kReadWaveForms){
                                    static uint32_t waveformBuffer32[64*1024];
                                    static uint32_t shipWaveformBuffer32[64*1024];
                                    static uint16_t *waveformBuffer16 = (uint16_t *)(waveformBuffer32);
                                    static uint16_t *shipWaveformBuffer16 = (uint16_t *)(shipWaveformBuffer32);
                                    uint32_t triggerPos = 0;
                                    
                                    srack->theSlt->pageSelect->write(0x100 | pagenr);
                                    
                                    uint32_t adccount;
                                    for(adccount=0; adccount<1024;adccount++){
                                        uint32_t adcval = srack->theFlt[col]->ramData->read(eventchan,adccount);
                                        waveformBuffer32[adccount] = adcval;
#if 1 //TODO: WORKAROUND - align according to the trigger flag - in future we will use the timestamp, when Denis has fixed it -tb-
                                        uint32_t adcval1 = adcval & 0xffff;
                                        uint32_t adcval2 = (adcval >> 16) & 0xffff;
                                        if(adcval1 & 0x8000) triggerPos = adccount*2;
                                        if(adcval2 & 0x8000) triggerPos = adccount*2+1;
#endif
                                    }
                                    uint32_t copyindex = (triggerPos + 1024) % 2048; // + postTriggerTime;
                                    uint32_t i;
                                    for(i=0;i<waveformLength;i++){
                                        shipWaveformBuffer16[i] = waveformBuffer16[copyindex];
                                        copyindex++;
                                        copyindex = copyindex % 2048;
                                    }
                                    
                                    //simulation mode
                                    if(0){
                                        for(i=0;i<waveformLength;i++){
                                            shipWaveformBuffer16[i]= (i>100)*i;
                                        }
                                    }
                                    //ship waveform
                                    uint32_t waveformLength32=waveformLength/2; //the waveform length is variable    
                                    data[dataIndex++] = 0;    //spare to remain byte compatible with the v3 record
                                    data[dataIndex++] = 0;    //spare to remain byte compatible with the v3 record
                                    for(i=0;i<waveformLength32;i++){
                                        data[dataIndex++] = shipWaveformBuffer32[i];
                                    }
                                }
                            }
                        }
                    }
                    else break;
                }
            }
            #endif
