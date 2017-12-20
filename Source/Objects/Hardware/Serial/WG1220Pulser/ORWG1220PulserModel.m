//--------------------------------------------------------
// ORWG1220PulserModel
// Created by Mark  A. Howe on Fri Jul 22 2005 / Julius Hartmann, KIT, Mai 2017
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2005 CENPA, University of Washington. All rights reserved.
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

#pragma mark ***Imported Files

#import "ORWG1220PulserModel.h"
#import "ORSerialPort.h"
#import "ORSerialPortList.h"
#import "ORSerialPort.h"
#import "ORSerialPortAdditions.h"
#import "ORSafeQueue.h"

#pragma mark ***External Strings
NSString* ORWG1220PulserModelVerboseChanged = @"ORWG1220PulserModelVerboseChanged";
NSString* ORWG1220PulserModelFrequencyChanged	= @"ORWG1220PulserModelFrequencyChanged";
NSString* ORWG1220PulserModelDutyCycleChanged	= @"ORWG1220PulserModelDutyCycleChanged";
NSString* ORWG1220PulserModelAmplitudeChanged	= @"ORWG1220PulserModelAmplitudeChanged";
NSString* ORWG1220PulserModelSignalFormChanged = @"ORWG1220PulserModelSignalFormChanged";
NSString* ORWG1220PulserModelSignalFormArbitrary = @"ORWG1220PulserModelSignalFormArbitrary";
NSString* ORWG1220PulserModelSerialPortChanged = @"ORWG1220PulserModelSerialPortChanged";
NSString* ORWG1220PulserModelPortNameChanged   = @"ORWG1220PulserModelPortNameChanged";
NSString* ORWG1220PulserModelPortStateChanged  = @"ORWG1220PulserModelPortStateChanged";
NSString* ORWG1220PulserLock = @"ORWG1220PulserLock";

#define maxReTx 3  // above this number, stop trying to
// retransmit and place an Error.

@interface ORWG1220PulserModel (private)
- (void) processOneCommandFromQueue;
- (void) timeout;
@end

@implementation ORWG1220PulserModel

- (void) dealloc
{
    [portName release];
    if([serialPort isOpen]){
        [serialPort close];
    }
    [serialPort release];
    [cmdQueue release];
	[super dealloc];
}

- (void) dataReceived:(NSNotification*)note
{
  //NSLog(@"received something: %@ \n", lastRequest);//lastRequest); , @"test");
  BOOL done = NO;
  if(!lastRequest)
    return;
  if([[note userInfo] objectForKey:@"serialPort"] == serialPort){
    if(!inComingData)inComingData = [[NSMutableData data] retain];
        [inComingData appendData:[[note userInfo] objectForKey:@"data"]];

        while (((char*)[inComingData mutableBytes])[0] != 'X' && [inComingData length] > 0){  //  remove possible error bytes at beginning until 'X';
          // this can occur when the device has sent faulty data.
          NSRange range = NSMakeRange(0, 1);
          [inComingData replaceBytesInRange:range withBytes:NULL length:0];
          if([self verbose]){
            NSLog(@"removed wrong starting Byte! \n");
          }
        }

    if([inComingData length] >= 7) {
       //NSLog(@"lastRequest contains %d bytes", [lastRequest length]);
       char* lastCmd;
       if([lastRequest length] > 7)  // waveform was sent...
       {
         if([self verbose]){
           NSLog(@"respond after set waveform: %@, length: %d \n", inComingData, [inComingData length]);
         }
         NSRange range = NSMakeRange([lastRequest length] - 7, 7);
         lastCmd = (char*) [[lastRequest subdataWithRange:range]bytes];
         if([self verbose]){
           NSLog(@"last command (waveform): %7s \n", lastCmd);
         }
       }
       else{
         lastCmd = (char*)[lastRequest bytes];
       }

       if([self verbose]){
         NSLog(@"last command: %7s \n", lastCmd);
       }

       switch (lastCmd[1]){
         case kWGRemoteCmd:

           if([lastRequest isEqual: inComingData]){
             //NSLog(@"setRemote was successful: %@ \n", inComingData);
             reTxCount = 0;
           }else{
             reTxCount++;
             if([self verbose]){
               NSLog(@"setRemote (WG1220Pulser): wrong data: trying(%d) to retransmit \n", reTxCount); //%@ \n", inComingData);
           }
             [cmdQueue enqueue:lastRequest];
           }
           done = YES;
           break;
         case kWGFreqCmd:
          if(![lastRequest isEqual: inComingData]){
            reTxCount++;
            if([self verbose]){
              NSLog(@"setFrequency (WG1220Pulser): wrong data: trying(%d) to retransmit \n", reTxCount); //received wrong acknowledge: %@ \n", inComingData);
            }
            [cmdQueue enqueue:lastRequest];
          }else {
            //NSLog(@"setFrequency was successful: %@ \n", inComingData);
            reTxCount = 0;
          }
          done = YES;
         break;
        case kWGAttCmd:

          if([lastRequest isEqual: inComingData]){
            reTxCount = 0;
          }else{
            reTxCount++;
            if([self verbose]){
              NSLog(@"setAmplitude (Attenuation) (WG1220Pulser): wrong data: trying(%d) to retransmit \n", reTxCount); //%@ \n", inComingData);
            }
            [cmdQueue enqueue:lastRequest];
          }
          done = YES;
          break;
        case kWGAmpltCmd:
          if([lastRequest isEqual: inComingData]){
            reTxCount = 0;
          }else{
            reTxCount++;
            if([self verbose]){
              NSLog(@"setAmplitude (WG1220Pulser): wrong data: trying(%d) to retransmit \n", reTxCount); //%@ \n", inComingData);
            }
            [cmdQueue enqueue:lastRequest];
          }
          done = YES;
          break;
       case kWGDutyCCmd:
        if([lastRequest isEqual: inComingData]){
          reTxCount = 0;
        }else{
          reTxCount++;
          if([self verbose]){
            NSLog(@"setDutyCycle (WG1220Pulser): wrong data: trying(%d) to retransmit \n", reTxCount);
          }
          [cmdQueue enqueue:lastRequest];
        }
        done = YES;
        break;
      case kWGFormCmd:
        if([lastRequest isEqual: inComingData]){
          reTxCount = 0;
        }else{
          reTxCount++;
          if([self verbose]){
            NSLog(@"setSignalForm (WG1220Pulser): wrong data: trying(%d) to retransmit \n", reTxCount); //%@ \n", inComingData);
            NSLog(@"sent Data: %@ \n", lastRequest);
            NSLog(@"incoming Data: %@ \n", inComingData);
          }
          [cmdQueue enqueue:lastRequest];
        }
        done = YES;
        break;

        case kWGProgModCmd:
        if([self verbose]){
          NSLog(@"kWGProgModCmd: incoming Data: %@ \n", inComingData);
        }
        if(! [[self progModeCmdReturned] isEqual: inComingData]){
          reTxCount++;
          [cmdQueue enqueue:lastRequest];
        }else{
          reTxCount = 0;
        }
        done = YES;
        break;
        case kWGStartProgCmd:
        if([self verbose]){
          NSLog(@"kWGStartProgCmd:incoming Data: %@ \n", inComingData);
        }
        if([lastRequest isEqual: inComingData]){
          reTxCount = 0;
        }else{
          reTxCount++;
          if([self verbose]){
            NSLog(@"start Programming (WG1220Pulser): wrong data: trying(%d) to retransmit \n", reTxCount);
          }
          [cmdQueue enqueue:lastRequest];
        }
        done = YES;
        break;

        case kWGRdyPrgrmCmd:
        if([self verbose]){
          NSLog(@"kWGRdyPrgrmCmd: incoming Data: %@ \n", inComingData);
        }
        if(! [[self isReadyForProgReturned] isEqual: inComingData]){
          reTxCount++;
          [cmdQueue enqueue:lastRequest];
          if([self verbose]){
            NSLog(@"kWGRdyPrgrmCmd not successful. repeating.. \n");
          }
          usleep(1000000);
        }else{
          reTxCount = 0;
          if([self verbose]){
            NSLog(@"kWGRdyPrgrmCmd successful \n");
          }
        }
        done = YES;
        break;
        case kWGStopPrgrmCmd:
        if([self verbose]){
          NSLog(@"kWGStopPrgrmCmd: incoming Data: %@ \n", inComingData);
        }
        NSData* expectedReturn = [NSData dataWithBytes:lastCmd length:7];
        if([expectedReturn isEqual: inComingData]){
          if([self verbose]){
            NSLog(@"kWGStopPrgrmCmd: incoming Data OK \n");
          }
          reTxCount = 0;
        }else{
          //reTxCount++;
          if([self verbose]){
            NSLog(@"ERROR: stop Programming (WG1220Pulser): wrong data; expected: %@  \n", expectedReturn);
          }
          //[cmdQueue enqueue:lastRequest];
        }
        done = YES;
        break;
        case kWGFinPrgrmCmd:
        if([self verbose]){
          NSLog(@"kWGFinPrgrmCmd: incoming Data: %@ \n", inComingData);
        }
        if(! [[self isStoppedProgReturned] isEqual: inComingData]){
          reTxCount++; // = 1;
          [cmdQueue enqueue:lastRequest];
          if([self verbose]){
            NSLog(@"kWGFinPrgrmCmd not successful. repeating.. \n");
          }
          usleep(1000000);
        }else{
          reTxCount = 0;
          if([self verbose]){
            NSLog(@"kWGFinPrgrmCmd successful \n");
          }
        }
        usleep(1000000);
        done = YES;
        break;

        }

       if(done){
               [inComingData release];
               inComingData = nil;
   			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
   			[self setLastRequest:nil];			 //clear the last request
   			[self processOneCommandFromQueue];	 //do the next command in the queue
       }
    }
  }
  return;
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"WG1220Pulser"]];
}

- (void) makeMainController
{
	[self linkToController:@"ORWG1220PulserController"];
}

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

    [notifyCenter addObserver : self
                     selector : @selector(dataReceived:)
                         name : ORSerialPortDataReceived
                       object : nil];
}

- (NSString*) helpURL
{
	return @"RS232/WG1220Pulser.html";
}

#pragma mark ***Accessors

- (BOOL) verbose
{
    return verbose;
}

- (void) setVerbose:(BOOL)aVerbose
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVerbose:verbose];

    verbose = aVerbose;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORWG1220PulserModelVerboseChanged object:self];
}

- (void) setLastRequest:(NSData*)aRequest
{
	[aRequest retain];
	[lastRequest release];
	lastRequest = aRequest;
}

- (float) frequency
{
    return frequency;
}

- (void) setFrequency:(float)aFrequency
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFrequency:frequency];
    frequency = aFrequency;

  [self setRemote];

  [self writeData:[self frequencyCommand: aFrequency]];

  [self setLocal];

  [[NSNotificationCenter defaultCenter] postNotificationName:ORWG1220PulserModelFrequencyChanged object:self];
}

- (int) dutyCycle
{
    return dutyCycle;
}

- (void) setDutyCycle:(int)aDutyCycle
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDutyCycle:dutyCycle];
    dutyCycle = aDutyCycle;


	if (dutyCycle < 1)  dutyCycle = 1;
	if (dutyCycle > 99)  dutyCycle = 99;

  [self setRemote];

  [self writeData:[self dutyCycleCommand]];

  [self setLocal];

  [[NSNotificationCenter defaultCenter] postNotificationName:ORWG1220PulserModelDutyCycleChanged object:self];
}

- (float) amplitude
{
    return amplitude;
}
- (void) commitAmplitude
{
  [self setRemote];

  if(amplitude <= dampedMax){ // set attenuation first to avoid short amplitude peak
    [self writeData:[self attenuationCommand: amplitude]];
    [self writeData:[self amplitudeCommand: amplitude]];
  }else { // set amplitude first to avoid possible short amplitude peak when attenuation is switched off
    [self writeData:[self amplitudeCommand: amplitude]];
    [self writeData:[self attenuationCommand: amplitude]];
  }


  [self setLocal];
}
- (void) setAmplitude:(float)aAmplitude
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAmplitude:amplitude];

    amplitude = aAmplitude;



    [[NSNotificationCenter defaultCenter] postNotificationName:ORWG1220PulserModelAmplitudeChanged object:self];
}

- (int) signalForm
{
    return signalForm;
}



- (void) setSignalForm:(int)aSignalForm
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSignalForm:signalForm];
	signalForm = aSignalForm;

  [self setRemote];

  [self writeData:[self signalFormCommand: signalForm]];

  [self setLocal];

    if (signalForm == Arbitrary){
      //NSLog(@"setSignalForm: arbitrary \n");
      [[NSNotificationCenter defaultCenter] postNotificationName:ORWG1220PulserModelSignalFormArbitrary object:self];
    }else {
      //NSLog(@"setSignalForm: not arbitrary \n");
      [[NSNotificationCenter defaultCenter] postNotificationName:ORWG1220PulserModelSignalFormChanged object:self];
    }
}

- (BOOL) portWasOpen
{
    return portWasOpen;
}

- (void) setPortWasOpen:(BOOL)aPortWasOpen
{
    portWasOpen = aPortWasOpen;
}

- (NSString*) portName
{
    return portName;
}

- (void) setPortName:(NSString*)aPortName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPortName:portName];

    if(![aPortName isEqualToString:portName]){
        [portName autorelease];
        portName = [aPortName copy];

        BOOL valid = NO;
        NSEnumerator *enumerator = [ORSerialPortList portEnumerator];
        ORSerialPort *aPort;
        while (aPort = [enumerator nextObject]) {
            if([portName isEqualToString:[aPort name]]){
                [self setSerialPort:aPort];
                if(portWasOpen){
                    [self openPort:YES];
                 }
                valid = YES;
                break;
            }
        }
        if(!valid){
            [self setSerialPort:nil];
        }
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:ORWG1220PulserModelPortNameChanged object:self];
}

- (ORSerialPort*) serialPort
{
    return serialPort;
}

- (void) setSerialPort:(ORSerialPort*)aSerialPort
{
    [aSerialPort retain];
    [serialPort release];
    serialPort = aSerialPort;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORWG1220PulserModelSerialPortChanged object:self];
}

- (void) openPort:(BOOL)state
{
    if(state) {
        [serialPort open];
		[serialPort setSpeed:57600];
		[serialPort setParityNone];
		[serialPort setStopBits2:NO];
		[serialPort setDataBits:8];
 		[serialPort commitChanges];
    [serialPort setDelegate:self];
    }
    else      [serialPort close];
    portWasOpen = [serialPort isOpen];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORWG1220PulserModelPortStateChanged object:self];

}

//put our parameters into any run header
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
    [objDictionary setObject:NSStringFromClass([self class]) forKey:@"Class Name"];

    [objDictionary setObject:[NSNumber numberWithInt:signalForm]	forKey:@"signalForm"];
    [objDictionary setObject:[NSNumber numberWithInt:amplitude]	forKey:@"amplitude"];
    [objDictionary setObject:[NSNumber numberWithInt:dutyCycle]		forKey:@"dutyCycle"];
    [objDictionary setObject:[NSNumber numberWithFloat:frequency]	forKey:@"frequency"];

	[dictionary setObject:objDictionary forKey:[self identifier]];
	return objDictionary;
}

- (NSString*) waveformFile
{
    return waveformFile;
}

- (void) setWaveformFile:(NSString*)aFile{
  waveformFile = [aFile copy];
}

- (void) loadValuesFromFile{
  NSString* contents = [NSString stringWithContentsOfFile:waveformFile encoding:NSASCIIStringEncoding error:nil];
  contents = [contents stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
	NSArray* lines = [contents componentsSeparatedByString:@"\n"];
  if(!arbWaveform){arbWaveform = [[NSMutableArray alloc] init];}
  else{[arbWaveform removeAllObjects];}
	for(id aLine in lines){
    aLine = [aLine stringByReplacingOccurrencesOfString:@" " withString:@""];
        if ([aLine length] > 0){
          [arbWaveform addObject: [NSNumber numberWithFloat:[aLine floatValue]]];
          // if (! [arbWaveform count] % 1000){// debug
          //   unsigned int entry = [arbWaveform count];
          //   NSlog(@"lineNr: %d line: %@  as float: %f transformed: %f \n", entry, aLine, [aLine floatValue], arbWaveform[entry-1]);
          // }
        }
  }
  unsigned int entries = [arbWaveform count];
  if([self verbose]){
    NSLog(@"Waveform data (%d Entries): \n", entries);
    NSLog(@"last two entries: %f %f \n\n", [arbWaveform[entries - 2] floatValue], [arbWaveform[entries - 1] floatValue]);
  }
}
- (void) commitWaveform{
  unsigned int entries = [arbWaveform count];
  if(entries < 4 || entries > 32768){
    NSLog(@"Warning: Number of datapoints: %d cannot commit waveform! (min 4, max 32768; ASCII float list separated by newlines) \n");
    return;
  }
    if([self verbose]){
      NSLog(@"commiting data to Pulser... (%d points) \n", entries);
    }
    [self setRemote];
    [self writeData:[self progModeCommand]];  // enter programming mode of the WG1220
    [self writeData:[self startProgCommand]];  // enter programming mode of the WG1220 part 2
    // Start-Ready-Abfrage: 'X','b',0,HIBYTE(an),LOBYTE(an),knr,CRC
    [self writeData:[self checkReadyForProg:entries]];  // enter programming mode of the WG1220 part 3
    // the above command will be repeated by dataRecived if not yet ready
    NSMutableData* waveformData = [[NSMutableData alloc] init];
    [waveformData appendData: [self WGBytesFromFloat]];
    [waveformData appendData: [self stopProgCommand]]; // concatenate with NSMutableData to get an acknowledge (of the next commmand)
    if([self verbose]){
      NSLog(@"Waveform Data to send: %@ \n", waveformData);
    }
    [self writeData: waveformData];
    [waveformData release]; //must release everything that is alloc'ed MAH 12/20/17
    //[self stopProgCommand];  // finishing programming mode 1
    [self writeData:[self checkStoppedProg:entries]];  // finishing programming mode 2
    [self setLocal];
}

#pragma mark *** Commands

- (void)serialPortWriteProgress:(NSDictionary *)dataDictionary
{  // this function is required to writeDataInBackground via Serial Port
}

- (void) writeData:(NSData*)someData
{
  //NSLog(@"queing...\n");
	if(!cmdQueue)cmdQueue = [[ORSafeQueue alloc] init];
	[cmdQueue enqueue:someData];
	//[[NSNotificationCenter defaultCenter] postNotificationName:ORPacModelQueCountChanged object: self];
	if(!lastRequest)[self processOneCommandFromQueue];
}

- (void) setRemote{
  unsigned char cmdData[7];
  cmdData[0] = 'X'; cmdData[1] = kWGRemoteCmd; cmdData[2] = '0';
  cmdData[3] = cmdData[4] = cmdData[5] = '0';
  cmdData[6] =  'R';
  [self writeData:[NSData dataWithBytes:cmdData length:7]];
}

- (void) setLocal{
  unsigned char cmdData[7];
  cmdData[0] = 'X'; cmdData[1] = kWGRemoteCmd; cmdData[2] = '1';
  cmdData[3] = cmdData[4] = cmdData[5] = '1';
  cmdData[6] =  'R';
  [self writeData:[NSData dataWithBytes:cmdData length:7]];
}

- (NSData*) progModeCommand{
  unsigned char cmdData[7];
  cmdData[0] = 'X'; cmdData[1] = kWGProgModCmd;
  cmdData[2] = cmdData[3] = cmdData[4] = cmdData[5] = '0';
  cmdData[6] =  67;
  return [NSData dataWithBytes:cmdData length:7];
}

- (NSData*) progModeCmdReturned{  // this resembles the expected reply for the above command.
  // Used to check if the device has responded as expected.
  unsigned char cmdData[7];
  cmdData[0] = 'X'; cmdData[1] = kWGProgModCmd;
  cmdData[2] = 'f';  // matching the WG1220 documentation..
  cmdData[3] = 'a';
  cmdData[4] = 'i';
  cmdData[5] = 'l';
  cmdData[6] =  65;
  return [NSData dataWithBytes:cmdData length:7];
}

- (NSData*) startProgCommand{
  unsigned char cmdData[7];
  cmdData[0] = 'X'; cmdData[1] = kWGStartProgCmd;  // 'B'
  cmdData[2] = cmdData[3] = 0;
  cmdData[4] = 3;  // sync position low byte
  cmdData[5] = 1;  // channel nr.
  cmdData[6] = cmdData[1] ^  cmdData[2] ^ cmdData[3] ^ cmdData[4] ^ cmdData[5];
  return [NSData dataWithBytes:cmdData length:7];
}

- (NSData*) checkReadyForProg:(int) nPoints{  // Start-Ready-request: 'X','b',0,HIBYTE(an),LOBYTE(an),knr,CRC
  unsigned char cmdData[7];
  cmdData[0] = 'X'; cmdData[1] = kWGRdyPrgrmCmd;  // 'b'
  cmdData[2] = '0';
  cmdData[3] = nPoints >> 8;
  cmdData[4] = nPoints & 0xFF;
  cmdData[5] = 1;  // channel nr.
  cmdData[6] = cmdData[1] ^  cmdData[2] ^ cmdData[3] ^ cmdData[4] ^ cmdData[5];
  return [NSData dataWithBytes:cmdData length:7];
}

- (NSData*) isReadyForProgReturned{  // this is expected from the device when it signals redyness for the next command
  unsigned char cmdData[7];
  unsigned int nPoints = [arbWaveform count];
  cmdData[0] = 'X'; cmdData[1] = kWGRdyPrgrmCmd;  // 'b'
  cmdData[2] = '0';
  cmdData[3] = nPoints >> 8;
  cmdData[4] = nPoints & 0xFF;
  cmdData[5] = 1; // ready-byte
  cmdData[6] = cmdData[1] ^  cmdData[2] ^ cmdData[3] ^ cmdData[4] ^ cmdData[5];
  return [NSData dataWithBytes:cmdData length:7];
}

- (NSData*) WGBytesFromFloat{
  // only the upper 12 Bit of a 16 Bit Point are used by the 12-Bit WG1220. max Voltages: 0x0000:-10 (-1) V  0xFFF0:10(1)V ;
  // min Voltages:0.2(0.02)V normal output (with attenuation)
  unsigned nPoints = [arbWaveform count];
 // NSPredicate *bPredicate = [NSPredicate predicateWithFormat:@"SELF beginswith[c] 'b'"];
  NSPredicate *pred = [NSPredicate predicateWithFormat:@"floatValue > 1.0 || floatValue < -1.0"];
  //filteredArr = [arbWaveform filteredArrayUsingPredicate:pred];
  bool damp_output = ![[arbWaveform filteredArrayUsingPredicate:pred] count];  // no value above
    // 2.0 V? then the -20dB filter should be used and all values multiplied by 10.
  // are amplitudes in range?
  pred = [NSPredicate predicateWithFormat:@"floatValue > 10.0 || floatValue < -10.0"];
  if([[arbWaveform filteredArrayUsingPredicate:pred] count]){
    NSLog(@"Error: Waveform contains entries with an amplitude larger than 10.0 V! \n");
    return [NSData dataWithBytes:arbWaveBytes length:0];
  }

  if([self verbose]){
    NSLog(@"arbWaveform count: %d \n", [arbWaveform count]);
    NSLog(damp_output ? @"output will be damped (for more precision)! \n" : @"output will not be damped! \n");
  }

  int ivalue;
  int point = 0;
  //NSLog(@"arbWaveBytes[0] size: %d \n", sizeof(arbWaveBytes[0]));
  for(NSNumber* value in arbWaveform){
    float fvalue = [value floatValue];
    if(damp_output)  // everything reduced by factor 10
      fvalue *= 10.0;  // compensated by multiplying everything with 10
    fvalue += 10.0;  // -10...+10V -> 0...20
    ivalue = fvalue * 65535 / 20.0;
    arbWaveBytes[point*2] = ivalue & 0xF0;  // from 16 Bits, only 12 upper are used
    arbWaveBytes[point*2+1] = ivalue >> 8;
    //NSLog(@"added Value (%f) #%d: LSB: %X (%X) MSB: %X (%X) \n", fvalue, point, ivalue & 0xF0, arbWaveBytes[point*2], ivalue >> 8, arbWaveBytes[point*2+1]);
    point++;

  }
    //NSLog(@"Data to be returned: %@ \n", [NSData dataWithBytes:arbWaveBytes length:nPoints * 2]);
  return [NSData dataWithBytes:arbWaveBytes length:nPoints * 2];
}

- (NSData*) stopProgCommand{  // Stop programming of arbitrary waveform
  unsigned char cmdData[7];
  cmdData[0] = 'X'; cmdData[1] = kWGStopPrgrmCmd;  // 'U'
  cmdData[2] = cmdData[3] = 0;
  cmdData[4] = 3;  // sync position low byte
  cmdData[5] = 1;  // channel nr.
  cmdData[6] = cmdData[1] ^  cmdData[2] ^ cmdData[3] ^ cmdData[4] ^ cmdData[5];
  return [NSData dataWithBytes:cmdData length:7];
}
- (NSData*) checkStoppedProg:(int) nPoints{  // Poll if device is ready after arbitrary waveform transfer is completed
  unsigned char cmdData[7];
  cmdData[0] = 'X'; cmdData[1] = kWGFinPrgrmCmd;  // 'u'
  cmdData[2] = '0';
  cmdData[3] = nPoints >> 8;
  cmdData[4] = nPoints & 0xFF;
  cmdData[5] = 1;  // channel nr.
  cmdData[6] = cmdData[1] ^  cmdData[2] ^ cmdData[3] ^ cmdData[4] ^ cmdData[5];
  return [NSData dataWithBytes:cmdData length:7];
}

- (NSData*) isStoppedProgReturned{  // this is expected from the device when it signals redyness for the next command
  unsigned char cmdData[7];
  unsigned int nPoints = [arbWaveform count];
  cmdData[0] = 'X'; cmdData[1] = kWGFinPrgrmCmd;  // 'u'
  cmdData[2] = '0';
  cmdData[3] = nPoints >> 8;
  cmdData[4] = nPoints & 0xFF;
  cmdData[5] = 1; // ready-byte
  cmdData[6] = cmdData[1] ^  cmdData[2] ^ cmdData[3] ^ cmdData[4] ^ cmdData[5];
  return [NSData dataWithBytes:cmdData length:7];
}

- (NSData*) attenuationCommand:(float) aamplitude
{
  unsigned char cmdData[7];
  NSString* attenuationInfo = [NSString stringWithFormat:@"set this string"];
  if (aamplitude <= dampedMax){
    cmdData[2] = '1';
    attenuationInfo = [NSString stringWithFormat:@"attenuated"];
  }
  else if( aamplitude > dampedMax){
    cmdData[2] = '2';
    attenuationInfo = [NSString stringWithFormat:@"not attenuated"];
  }
  if (aamplitude == 0){
    cmdData[2] = '0';
    attenuationInfo = [NSString stringWithFormat:@"off"];
  }

  cmdData[0] = 'X';
  cmdData[1] = kWGAttCmd;

  cmdData[3] = 0;
  cmdData[4] = 0;
  cmdData[5] = 0;
  cmdData[6] = cmdData[1] ^  cmdData[2] ^ cmdData[3] ^ cmdData[4] ^ cmdData[5];

  return [NSData dataWithBytes:cmdData length:7];

}

- (NSData*) amplitudeCommand:(float) aamplitude
{

  unsigned char cmdData[7];
  if (aamplitude > VMax) {
    aamplitude = VMax;
  }
  if (aamplitude < VMin){
    aamplitude = VMin;
  }

  int intamplitude;
  if (aamplitude <= dampedMax){
    intamplitude = aamplitude * 10000;
  }else
  {
    intamplitude = aamplitude * 1000;
  }

  cmdData[0] = 'X';
  cmdData[1] = kWGAmpltCmd;
  cmdData[2] = intamplitude >> 8;
  cmdData[3] = intamplitude & 0xFF;
  cmdData[4] = 0;
  cmdData[5] = 0x80;
  cmdData[6] = cmdData[1] ^  cmdData[2] ^ cmdData[3] ^ cmdData[4] ^ cmdData[5];

  //NSLog(@"Amplitude command: amplitude: %f, intamplitude: %d, Amplitude is in %s range, checksum: 0x%x \n",
    //    aamplitude, intamplitude, aamplitude <= 2.0 ? "low" : "high", cmdData[6]);
  return [NSData dataWithBytes:cmdData length:7];

}

- (NSData*) dutyCycleCommand
{
  unsigned char cmdData[7];

  cmdData[0] = 'X';
  cmdData[1] = kWGDutyCCmd;
  cmdData[2] = dutyCycle;
  cmdData[3] = cmdData[4] = '0';
  cmdData[5] = 0x80;
  cmdData[6] = cmdData[1] ^  cmdData[2] ^ cmdData[3] ^ cmdData[4] ^ cmdData[5];
  return [NSData dataWithBytes:cmdData length:7];
}

- (NSData*) frequencyCommand:(float) afrequency
{
  unsigned char cmdData[7];

  if(afrequency < 1) afrequency = 1;
  if(afrequency > 10000000) afrequency = 10000000.0;
  int digits = floor(log10(afrequency)) + 1;
  // the WG1220 expects a 4 digit Mantissa and an exponent. It divides
  // the Mantissa by 1000.
  float decPointShift = pow(10.0, 4 - digits);
  int intfrequency = afrequency * decPointShift;

  cmdData[0] = 'X';
  cmdData[1] = 'F';
  cmdData[2] = intfrequency >> 8;
  cmdData[3] = intfrequency & 0xFF;
  cmdData[4] = digits - 1;
  cmdData[5] = 0x80;
  cmdData[6] = cmdData[1] ^  cmdData[2] ^ cmdData[3] ^ cmdData[4] ^ cmdData[5];

  //NSLog(@"Frequency command: frequency: %f, intfrequency: %d, exponent: %d, checksum: 0x%x \n",
  //      afrequency, intfrequency, digits - 1, cmdData[6]);
  return [NSData dataWithBytes:cmdData length:7];
}

- (NSData*) signalFormCommand:(enum SignalForms) aCommand
{
  unsigned char cmdData[7];

  cmdData[0] = 'X';
  cmdData[1] = kWGFormCmd;

  cmdData[3] ='0';

  switch (aCommand){
    case Sine:
      cmdData[2] = 'S'; break;
    case Rectangular:
      cmdData[2] = 'R'; break;
    case Triangular:
      cmdData[2] = 'T'; break;
    // case DC:
    //   cmdData[2] = 'G'; break;
    case Arbitrary:
      cmdData[2] = 'D';
      cmdData[3] = 1; break;
    // case Noise:
    //   cmdData[2] = 'N'; break;

    default: cmdData[2] = 'S';

  }

  cmdData[4] = '0';
  cmdData[5] = 0x80;

  cmdData[6] = cmdData[1] ^  cmdData[2] ^ cmdData[3] ^ cmdData[4] ^ cmdData[5];
  return [NSData dataWithBytes:cmdData length:7];
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder  // todo: function needed?
{
    self = [super initWithCoder:decoder];

    [[self undoManager] disableUndoRegistration];
    reTxCount = 0;  // no retransmit until first error or timeout
    //[self setPulserVersion:[decoder decodeIntForKey:@"pulserVersion"]];
	[self setSignalForm:[decoder decodeIntForKey:@"signalForm"]];  // todo (necessary?)
    // [self setFrequency:	[decoder decodeFloatForKey:@"frequency"]];
    // [self setDutyCycle:	[decoder decodeIntForKey:@"dutyCycle"]];
    // [self setAmplitude:	[decoder decodeIntForKey:@"amplitude"]];
    [[self undoManager] enableUndoRegistration];
    [self registerNotificationObservers];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder  // todo: function needed?
{
    [super encodeWithCoder:encoder];
    //[encoder encodeInt:pulserVersion	forKey:@"pulserVersion"];
    [encoder encodeInt:signalForm	    forKey:@"signalForm"];
    [encoder encodeFloat:frequency	    forKey:@"frequency"];
    [encoder encodeInt:dutyCycle	    forKey:@"dutyCycle"];
    [encoder encodeInt:amplitude	    forKey:@"amplitude"];
}
@end

@implementation ORWG1220PulserModel (private)

- (void) timeout
{
	@synchronized (self){
    reTxCount++;  // schedule retransmission
    if([self verbose]){
      NSLog(@"Warning: timeout (WG1220Pulser)! trying(%d) retransmit. \n", reTxCount);  //Request was: %@ \n", lastRequest);
    }

    [cmdQueue enqueue:lastRequest];
		//[[NSNotificationCenter defaultCenter] postNotificationName:ORPacModelQueCountChanged object: self];
		[self processOneCommandFromQueue];	 //do the next command in the queue
	}
}

- (void) processOneCommandFromQueue
{
  usleep(1000);
  NSData* cmdData;
  if([cmdQueue count] > 0){
    if(reTxCount == 0){
      cmdData = [cmdQueue dequeue];
    }else if (reTxCount <= maxReTx){ // the last command is reappended to the queue..
      cmdData = [cmdQueue dequeueFromBottom];
    }else{
      NSLog(@"ERROR: failed to validate Data Transmission. Emptying remaining commands to WG1220Pulser... \n");
     [cmdQueue removeAllObjects];
     [self setLastRequest:nil];
     reTxCount = 0;
     return;
    }

    //lastRequest = cmdData; //[self setLastRequest:cmdData];
    [self setLastRequest:cmdData];
    [serialPort writeDataInBackground:cmdData];
    float delay = 10.0;
    unsigned int cmdLength = [cmdData length];
    if(cmdLength > 7){
      delay +=2;
      delay += cmdLength / 2000;  // todo: check if additional time is sufficient for max data points (32768)
    }
    [self performSelector:@selector(timeout) withObject:nil afterDelay:delay];
  }
  return;
}
@end
