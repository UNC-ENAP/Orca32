//
//  ORIpeV4FLTModel.m
//  Orca
//
//  Created by Mark Howe on Wed Aug 24 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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

#import "ORIpeV4FLTModel.h"
#import "ORIpeV4SLTModel.h"
#import "ORIpeCrateModel.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORDataTypeAssigner.h"
#import "ORTimeRate.h"
#import "ORTest.h"
#import "SBC_Config.h"
#import "SLTv4_HW_Definitions.h"
#import "ORCommandList.h"

NSString* ORIpeV4FLTModelTargetRateChanged			= @"ORIpeV4FLTModelTargetRateChanged";
NSString* ORIpeV4FLTModelHistMaxEnergyChanged       = @"ORIpeV4FLTModelHistMaxEnergyChanged";
NSString* ORIpeV4FLTModelHistPageABChanged          = @"ORIpeV4FLTModelHistPageABChanged";
NSString* ORIpeV4FLTModelHistLastEntryChanged       = @"ORIpeV4FLTModelHistLastEntryChanged";
NSString* ORIpeV4FLTModelHistFirstEntryChanged      = @"ORIpeV4FLTModelHistFirstEntryChanged";
NSString* ORIpeV4FLTModelHistClrModeChanged			= @"ORIpeV4FLTModelHistClrModeChanged";
NSString* ORIpeV4FLTModelHistModeChanged			= @"ORIpeV4FLTModelHistModeChanged";
NSString* ORIpeV4FLTModelHistEBinChanged			= @"ORIpeV4FLTModelHistEBinChanged";
NSString* ORIpeV4FLTModelHistEMinChanged			= @"ORIpeV4FLTModelHistEMinChanged";
NSString* ORIpeV4FLTModelRunModeChanged				= @"ORIpeV4FLTModelRunModeChanged";
NSString* ORIpeV4FLTModelRunBoxCarFilterChanged		= @"ORIpeV4FLTModelRunBoxCarFilterChanged";
NSString* ORIpeV4FLTModelStoreDataInRamChanged		= @"ORIpeV4FLTModelStoreDataInRamChanged";
NSString* ORIpeV4FLTModelFilterLengthChanged		= @"ORIpeV4FLTModelFilterLengthChanged";
NSString* ORIpeV4FLTModelGapLengthChanged			= @"ORIpeV4FLTModelGapLengthChanged";
NSString* ORIpeV4FLTModelHistNofMeasChanged			= @"ORIpeV4FLTModelHistNofMeasChanged";
NSString* ORIpeV4FLTModelHistMeasTimeChanged		= @"ORIpeV4FLTModelHistMeasTimeChanged";
NSString* ORIpeV4FLTModelHistRecTimeChanged			= @"ORIpeV4FLTModelHistRecTimeChanged";
NSString* ORIpeV4FLTModelPostTriggerTimeChanged		= @"ORIpeV4FLTModelPostTriggerTimeChanged";
NSString* ORIpeV4FLTModelFifoBehaviourChanged		= @"ORIpeV4FLTModelFifoBehaviourChanged";
NSString* ORIpeV4FLTModelAnalogOffsetChanged		= @"ORIpeV4FLTModelAnalogOffsetChanged";
NSString* ORIpeV4FLTModelLedOffChanged				= @"ORIpeV4FLTModelLedOffChanged";
NSString* ORIpeV4FLTModelInterruptMaskChanged		= @"ORIpeV4FLTModelInterruptMaskChanged";
NSString* ORIpeV4FLTModelTModeChanged				= @"ORIpeV4FLTModelTModeChanged";
NSString* ORIpeV4FLTModelHitRateLengthChanged		= @"ORIpeV4FLTModelHitRateLengthChanged";
NSString* ORIpeV4FLTModelTriggersEnabledChanged		= @"ORIpeV4FLTModelTriggersEnabledChanged";
NSString* ORIpeV4FLTModelGainsChanged				= @"ORIpeV4FLTModelGainsChanged";
NSString* ORIpeV4FLTModelThresholdsChanged			= @"ORIpeV4FLTModelThresholdsChanged";
NSString* ORIpeV4FLTModelModeChanged				= @"ORIpeV4FLTModelModeChanged";
NSString* ORIpeV4FLTSettingsLock					= @"ORIpeV4FLTSettingsLock";
NSString* ORIpeV4FLTChan							= @"ORIpeV4FLTChan";
NSString* ORIpeV4FLTModelTestPatternsChanged		= @"ORIpeV4FLTModelTestPatternsChanged";
NSString* ORIpeV4FLTModelGainChanged				= @"ORIpeV4FLTModelGainChanged";
NSString* ORIpeV4FLTModelThresholdChanged			= @"ORIpeV4FLTModelThresholdChanged";
NSString* ORIpeV4FLTModelTriggerEnabledMaskChanged	= @"ORIpeV4FLTModelTriggerEnabledMaskChanged";
NSString* ORIpeV4FLTModelHitRateEnabledMaskChanged	= @"ORIpeV4FLTModelHitRateEnabledMaskChanged";
NSString* ORIpeV4FLTModelHitRateChanged				= @"ORIpeV4FLTModelHitRateChanged";
NSString* ORIpeV4FLTModelTestsRunningChanged		= @"ORIpeV4FLTModelTestsRunningChanged";
NSString* ORIpeV4FLTModelTestEnabledArrayChanged	= @"ORIpeV4FLTModelTestEnabledChanged";
NSString* ORIpeV4FLTModelTestStatusArrayChanged		= @"ORIpeV4FLTModelTestStatusChanged";
NSString* ORIpeV4FLTModelEventMaskChanged			= @"ORIpeV4FLTModelEventMaskChanged";

NSString* ORIpeV4FLTSelectedRegIndexChanged			= @"ORIpeV4FLTSelectedRegIndexChanged";
NSString* ORIpeV4FLTWriteValueChanged				= @"ORIpeV4FLTWriteValueChanged";
NSString* ORIpeV4FLTSelectedChannelValueChanged		= @"ORIpeV4FLTSelectedChannelValueChanged";
NSString* ORIpeV4FLTNoiseFloorChanged				= @"ORIpeV4FLTNoiseFloorChanged";
NSString* ORIpeV4FLTNoiseFloorOffsetChanged			= @"ORIpeV4FLTNoiseFloorOffsetChanged";

static NSString* fltTestName[kNumIpeV4FLTTests]= {
	@"Run Mode",
	@"Ram",
	@"Threshold/Gain",
	@"Speed",
	@"Event",
};

// data for low-level page (IPE V4 electronic definitions)
enum IpeFLTV4Enum{
	kFLTV4StatusReg,
	kFLTV4ControlReg,
	kFLTV4CommandReg,
	kFLTV4VersionReg,
	kFLTV4pVersionReg,
	kFLTV4BoardIDLsbReg,
	kFLTV4BoardIDMsbReg,
	kFLTV4InterruptMaskReg,
	kFLTV4HrMeasEnableReg,
	kFLTV4EventFifoStatusReg,
	kFLTV4PixelSettings1Reg,
	kFLTV4PixelSettings2Reg,
	kFLTV4RunControlReg,
	kFLTV4HistgrSettingsReg,
	kFLTV4AccessTestReg,
	kFLTV4SecondCounterReg,
	kFLTV4HrControlReg,
	kFLTV4HistMeasTimeReg,
	kFLTV4HistRecTimeReg,
	kFLTV4HistNumMeasReg,
	kFLTV4PostTrigger,
	kFLTV4ThresholdReg,
	kFLTV4pStatusA,
	kFLTV4pStatusB,
	kFLTV4pStatusC,
	kFLTV4AnalogOffset,
	kFLTV4GainReg,
	kFLTV4HitRateReg,
	kFLTV4EventFifo1Reg,
	kFLTV4EventFifo2Reg,
	kFLTV4EventFifo3Reg,
	kFLTV4EventFifo4Reg,
	kFLTV4HistPageNReg,
	kFLTV4HistLastFirstReg,
	kFLTV4NumRegs //must be last
};

static IpeRegisterNamesStruct regV4[kFLTV4NumRegs] = {
	//2nd column is PCI register address shifted 2 bits to right (the two rightmost bits are always zero) -tb-
	{@"Status",				0x000000>>2,		-1,				kIpeRegReadable},
	{@"Control",			0x000004>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"Command",			0x000008>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"CFPGAVersion",		0x00000c>>2,		-1,				kIpeRegReadable},
	{@"FPGA8Version",		0x000010>>2,		-1,				kIpeRegReadable},
	{@"BoardIDLSB",         0x000014>>2,		-1,				kIpeRegReadable},
	{@"BoardIDMSB",         0x000018>>2,		-1,				kIpeRegReadable},
	{@"InterruptMask",      0x00001C>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"HrMeasEnable",       0x000024>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"EventFifoStatus",    0x00002C>>2,		-1,				kIpeRegReadable},
	{@"PixelSettings1",     0x000030>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"PixelSettings2",     0x000034>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"RunControl",         0x000038>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"HistgrSettings",     0x00003c>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"AccessTest",         0x000040>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"SecondCounter",      0x000044>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"HrControl",          0x000048>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"HistMeasTime",       0x00004C>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"HistRecTime",        0x000050>>2,		-1,				kIpeRegReadable},
	{@"HistNumMeas",         0x000054>>2,		-1,				kIpeRegReadable},
	{@"PostTrigger",		0x000058>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"Threshold",          0x002080>>2,		-1,				kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsChannel},
	{@"pStatusA",           0x002000>>2,		-1,				kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsChannel},
	{@"pStatusB",           0x006000>>2,		-1,				kIpeRegReadable},
	{@"pStatusC",           0x026000>>2,		-1,				kIpeRegReadable},
	{@"Analog Offset",		0x001000>>2,		-1,				kIpeRegReadable},
	{@"Gain",				0x001004>>2,		-1,				kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsChannel},
	{@"Hit Rate",			0x001100>>2,		-1,				kIpeRegReadable | kIpeRegNeedsChannel},
	{@"Event FIFO1",		0x001800>>2,		-1,				kIpeRegReadable},
	{@"Event FIFO2",		0x001804>>2,		-1,				kIpeRegReadable},
	{@"Event FIFO3",		0x001808>>2,		-1,				kIpeRegReadable | kIpeRegNeedsChannel},
	{@"Event FIFO4",		0x00180C>>2,		-1,				kIpeRegReadable | kIpeRegNeedsChannel},
	{@"HistPageN",			0x00200C>>2,		-1,				kIpeRegReadable},
	{@"HistLastFirst",		0x002044>>2,		-1,				kIpeRegReadable},
};

@interface ORIpeV4FLTModel (private)
- (NSAttributedString*) test:(int)testName result:(NSString*)string color:(NSColor*)aColor;
- (void) enterTestMode;
- (void) leaveTestMode;
- (void) stepNoiseFloor;
@end

@implementation ORIpeV4FLTModel

- (id) init
{
    self = [super init];
	ledOff = YES;
	histMeasTime = 5;
    return self;
}

- (void) dealloc
{	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [testEnabledArray release];
    [testStatusArray release];
	[testSuit release];
	[thresholds release];
	[gains release];
	[totalRate release];
	[super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"IpeV4FLTCard"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORIpeV4FLTController"];
}

- (Class) guardianClass 
{
	return NSClassFromString(@"ORIpeV4CrateModel");
}

- (BOOL) partOfEvent:(short)chan
{
	return (eventMask & (1L<<chan)) != 0;
}

- (int) stationNumber
{
	//is it a minicrate?
	if([[[self crate] class]  isSubclassOfClass: NSClassFromString(@"ORIpeV4MiniCrateModel")]){
		if([self slot]<3)return [self slot]+1;
		else return [self slot]; //there is a gap at slot 3 (for the SLT) -tb-
	}
	//... or a full crate?
	if([[[self crate] class]  isSubclassOfClass: NSClassFromString(@"ORIpeV4CrateModel")]){
		if([self slot]<11)return [self slot]+1;
		else return [self slot]; //there is a gap at slot 11 (for the SLT) -tb-
	}
	//fallback
	return [self slot]+1;
}

- (ORTimeRate*) totalRate   { return totalRate; }
- (short) getNumberRegisters{ return kFLTV4NumRegs; }

#pragma mark •••Accessors
- (int) targetRate { return targetRate; }
- (void) setTargetRate:(int)aTargetRate
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTargetRate:targetRate];
    targetRate = [self restrictIntValue:aTargetRate min:1 max:100];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelTargetRateChanged object:self];
}

- (int) histMaxEnergy { return histMaxEnergy; }
//!< A argument -1 will auto-recalculate the maximum energy which fits still into the histogram. -tb-
- (void) setHistMaxEnergy:(int)aHistMaxEnergy
{
    if(aHistMaxEnergy<0) histMaxEnergy = histEMin + 2048*(1<<histEBin);
    else histMaxEnergy = aHistMaxEnergy;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelHistMaxEnergyChanged object:self];
}

- (int) histPageAB{ return histPageAB; }
- (void) setHistPageAB:(int)aHistPageAB
{
    histPageAB = aHistPageAB;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelHistPageABChanged object:self];
}


- (int) runMode { return runMode; }
- (void) setRunMode:(int)aRunMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRunMode:runMode];
    runMode = aRunMode;
	
	readWaveforms = NO;
	
	switch (runMode) {
		case kIpeFlt_EnergyMode:
			[self setFltRunMode:kIpeFltV4Katrin_Run_Mode];
			break;
			
		case kIpeFlt_EnergyTrace:
			[self setFltRunMode:kIpeFltV4Katrin_Run_Mode];
			readWaveforms = YES;
			break;
			
		case kIpeFlt_Histogram_Mode:
			[self setFltRunMode:kIpeFltV4Katrin_Histo_Mode];
			//TODO: workaround - if set to kFifoStopOnFull the histogramming stops after some seconds - probably a FPGA bug? -tb-
			if(fifoBehaviour == kFifoStopOnFull){
				//NSLog(@"ORIpeV4FLTModel message: due to a FPGA side effect histogramming mode should run with kFifoEnableOverFlow setting! -tb-\n");//TODO: fix it -tb-
				NSLog(@"ORIpeV4FLTModel message: switched FIFO behaviour to kFifoEnableOverFlow (required for histogramming mode)\n");//TODO: fix it -tb-
				[self setFifoBehaviour: kFifoEnableOverFlow];
			}
			break;
			
		default:
			break;
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelRunModeChanged object:self];
}

- (BOOL) noiseFloorRunning { return noiseFloorRunning; }

- (int) noiseFloorOffset { return noiseFloorOffset; }
- (void) setNoiseFloorOffset:(int)aNoiseFloorOffset
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNoiseFloorOffset:noiseFloorOffset];
    noiseFloorOffset = aNoiseFloorOffset;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTNoiseFloorOffsetChanged object:self];
}

- (unsigned long) histLastEntry { return histLastEntry; }
- (void) setHistLastEntry:(unsigned long)aHistLastEntry
{
    histLastEntry = aHistLastEntry;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelHistLastEntryChanged object:self];
}

- (unsigned long) histFirstEntry { return histFirstEntry; }
- (void) setHistFirstEntry:(unsigned long)aHistFirstEntry
{
    histFirstEntry = aHistFirstEntry;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelHistFirstEntryChanged object:self];
}

- (int) histClrMode { return histClrMode; }
- (void) setHistClrMode:(int)aHistClrMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHistClrMode:histClrMode];
    histClrMode = aHistClrMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelHistClrModeChanged object:self];
}

- (int) histMode { return histMode; }
- (void) setHistMode:(int)aHistMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHistMode:histMode];
    histMode = aHistMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelHistModeChanged object:self];
}

- (unsigned long) histEBin { return histEBin; }
- (void) setHistEBin:(unsigned long)aHistEBin
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHistEBin:histEBin];
    histEBin = aHistEBin;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelHistEBinChanged object:self];
    
    //recalc max energy
    [self setHistMaxEnergy: -1];
}

- (unsigned long) histEMin { return histEMin;} 
- (void) setHistEMin:(unsigned long)aHistEMin
{
	[[[self undoManager] prepareWithInvocationTarget:self] setHistEMin:histEMin];
	histEMin = aHistEMin;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelHistEMinChanged object:self];

    //recalc max energy
    [self setHistMaxEnergy: -1];
}

- (unsigned long) histNofMeas { return histNofMeas; }
- (void) setHistNofMeas:(unsigned long)aHistNofMeas
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHistNofMeas:histNofMeas];
    histNofMeas = aHistNofMeas;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelHistNofMeasChanged object:self];
}

- (unsigned long) histMeasTime { return histMeasTime; }
- (void) setHistMeasTime:(unsigned long)aHistMeasTime
{
	if(aHistMeasTime==0) aHistMeasTime=5;
    histMeasTime = aHistMeasTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelHistMeasTimeChanged object:self];
}

- (unsigned long) histRecTime { return histRecTime; }
- (void) setHistRecTime:(unsigned long)aHistRecTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHistRecTime:histRecTime];
    histRecTime = aHistRecTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelHistRecTimeChanged object:self];
}

- (BOOL) runBoxCarFilter { return runBoxCarFilter; }
- (void) setRunBoxCarFilter:(BOOL)aRunBoxCarFilter
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRunBoxCarFilter:runBoxCarFilter];
    runBoxCarFilter = aRunBoxCarFilter;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelRunBoxCarFilterChanged object:self];
}

- (BOOL) storeDataInRam { return storeDataInRam; }
- (void) setStoreDataInRam:(BOOL)aStoreDataInRam
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStoreDataInRam:storeDataInRam];
    storeDataInRam = aStoreDataInRam;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelStoreDataInRamChanged object:self];
}

- (int) filterLength { return filterLength; }
- (void) setFilterLength:(int)aFilterLength
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFilterLength:filterLength];
    filterLength = [self restrictIntValue:aFilterLength min:2 max:8];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelFilterLengthChanged object:self];
}

- (int) gapLength { return gapLength; }
- (void) setGapLength:(int)aGapLength
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGapLength:gapLength];
    gapLength = [self restrictIntValue:aGapLength min:0 max:7];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelGapLengthChanged object:self];
}

- (unsigned long) postTriggerTime { return postTriggerTime; }
- (void) setPostTriggerTime:(unsigned long)aPostTriggerTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPostTriggerTime:postTriggerTime];
    postTriggerTime = [self restrictIntValue:aPostTriggerTime min:6 max:2047];//min 6 is found 'experimental' -tb-
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelPostTriggerTimeChanged object:self];
}

- (int) fifoBehaviour { return fifoBehaviour; }
- (void) setFifoBehaviour:(int)aFifoBehaviour
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFifoBehaviour:fifoBehaviour];
    fifoBehaviour = [self restrictIntValue:aFifoBehaviour min:0 max:1];;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelFifoBehaviourChanged object:self];
}

- (unsigned long) eventMask { return eventMask; }
- (void) eventMask:(unsigned long)aMask
{
	eventMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelEventMaskChanged object:self];
}

- (int) analogOffset{ return analogOffset; }
- (void) setAnalogOffset:(int)aAnalogOffset
{
	
    [[[self undoManager] prepareWithInvocationTarget:self] setAnalogOffset:analogOffset];
    analogOffset = [self restrictIntValue:aAnalogOffset min:0 max:4095];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelAnalogOffsetChanged object:self];
}

- (BOOL) ledOff{ return ledOff; }
- (void) setLedOff:(BOOL)aState
{
    ledOff = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelLedOffChanged object:self];
}

- (unsigned long) interruptMask { return interruptMask; }
- (void) setInterruptMask:(unsigned long)aInterruptMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInterruptMask:interruptMask];
    interruptMask = aInterruptMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelInterruptMaskChanged object:self];
}

- (void) setTotalRate:(ORTimeRate*)newTimeRate
{
	[totalRate autorelease];
	totalRate=[newTimeRate retain];
}

- (unsigned short) hitRateLength { return hitRateLength; }
- (void) setHitRateLength:(unsigned short)aHitRateLength
{	
    [[[self undoManager] prepareWithInvocationTarget:self] setHitRateLength:hitRateLength];
    hitRateLength = [self restrictIntValue:aHitRateLength min:0 max:6]; //0->1sec, 1->2, 2->4 .... 6->32sec

    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelHitRateLengthChanged object:self];
}

- (unsigned long) triggerEnabledMask { return triggerEnabledMask; } 
- (void) setTriggerEnabledMask:(unsigned long)aMask
{
 	[[[self undoManager] prepareWithInvocationTarget:self] setTriggerEnabledMask:triggerEnabledMask];
	triggerEnabledMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelTriggerEnabledMaskChanged object:self];
}

- (unsigned long) hitRateEnabledMask { return hitRateEnabledMask; }
- (void) setHitRateEnabledMask:(unsigned long)aMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setHitRateEnabledMask:hitRateEnabledMask];
    hitRateEnabledMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelHitRateEnabledMaskChanged object:self];
}

- (NSMutableArray*) gains { return gains; }
- (void) setGains:(NSMutableArray*)aGains
{
	[aGains retain];
	[gains release];
    gains = aGains;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelGainsChanged object:self];
}

- (NSMutableArray*) thresholds { return thresholds; }
- (void) setThresholds:(NSMutableArray*)aThresholds
{
	[aThresholds retain];
	[thresholds release];
    thresholds = aThresholds;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelThresholdsChanged object:self];
}

-(unsigned long) threshold:(unsigned short) aChan
{
    return [[thresholds objectAtIndex:aChan] intValue];
}

-(unsigned short) gain:(unsigned short) aChan
{
    return [[gains objectAtIndex:aChan] shortValue];
}

-(void) setThreshold:(unsigned short) aChan withValue:(unsigned long) aThreshold
{
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChan withValue:[self threshold:aChan]];
	aThreshold = [self restrictIntValue:aThreshold min:0 max:0xfffff];
    [thresholds replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aThreshold]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORIpeV4FLTChan];
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORIpeV4FLTModelThresholdChanged
	 object:self
	 userInfo: userInfo];
	
	//ORAdcInfoProviding protocol requirement
	[self postAdcInfoProvidingValueChanged];
}

- (void) setGain:(unsigned short) aChan withValue:(unsigned short) aGain
{
	if(aGain>0xfff) aGain = 0xfff;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setGain:aChan withValue:[self gain:aChan]];
	[gains replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aGain]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORIpeV4FLTChan];
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORIpeV4FLTModelGainChanged
	 object:self
	 userInfo: userInfo];
	
	//ORAdcInfoProviding protocol requirement
	[self postAdcInfoProvidingValueChanged];
}

-(BOOL) triggerEnabled:(unsigned short) aChan
{
	if(aChan<kNumV4FLTChannels)return (triggerEnabledMask >> aChan) & 0x1;
	else return NO;
}

-(void) setTriggerEnabled:(unsigned short) aChan withValue:(BOOL) aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerEnabled:aChan withValue:(triggerEnabledMask>>aChan)&0x1];
	if(aState) triggerEnabledMask |= (1L<<aChan);
	else triggerEnabledMask &= ~(1L<<aChan);
	
    [[NSNotificationCenter defaultCenter]postNotificationName:ORIpeV4FLTModelTriggerEnabledMaskChanged object:self];
	[self postAdcInfoProvidingValueChanged];
}

- (BOOL) hitRateEnabled:(unsigned short) aChan
{
 	if(aChan<kNumV4FLTChannels)return (hitRateEnabledMask >> aChan) & 0x1;
	else return NO;
}

- (void) setHitRateEnabled:(unsigned short) aChan withValue:(BOOL) aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHitRateEnabled:aChan withValue:(hitRateEnabledMask>>aChan)&0x1];
	if(aState) hitRateEnabledMask |= (1L<<aChan);
	else hitRateEnabledMask &= ~(1L<<aChan);
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelHitRateEnabledMaskChanged object:self];
}

- (int) fltRunMode { return fltRunMode; }
- (void) setFltRunMode:(int)aMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFltRunMode:fltRunMode];
    fltRunMode = aMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelModeChanged object:self];
}

- (void) enableAllHitRates:(BOOL)aState
{
	[self setHitRateEnabledMask:aState?0xffffff:0x0];
}

- (void) enableAllTriggers:(BOOL)aState
{
	[self setTriggerEnabledMask:aState?0xffffff:0x0];
}

- (void) setHitRateTotal:(float)newTotalValue
{
	hitRateTotal = newTotalValue;
	if(!totalRate){
		[self setTotalRate:[[[ORTimeRate alloc] init] autorelease]];
	}
	[totalRate addDataToTimeAverage:hitRateTotal];
}

- (float) hitRateTotal 
{ 
	return hitRateTotal; 
}

- (float) hitRate:(unsigned short)aChan
{
	if(aChan<kNumV4FLTChannels){
		return hitRate[aChan];
	}
	else return 0.0;
}



- (float) rate:(int)aChan { return [self hitRate:aChan]; }
- (BOOL) hitRateOverFlow:(unsigned short)aChan
{
	if(aChan<kNumV4FLTChannels)return hitRateOverFlow[aChan];
	else return NO;
}

- (unsigned short) selectedChannelValue { return selectedChannelValue; }
- (void) setSelectedChannelValue:(unsigned short) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedChannelValue:selectedChannelValue];
    selectedChannelValue = aValue;
    [[NSNotificationCenter defaultCenter]	 postNotificationName:ORIpeV4FLTSelectedChannelValueChanged	 object:self];
}

- (unsigned short) selectedRegIndex { return selectedRegIndex; }
- (void) setSelectedRegIndex:(unsigned short) anIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRegIndex:selectedRegIndex];
    selectedRegIndex = anIndex;
    [[NSNotificationCenter defaultCenter]	 postNotificationName:ORIpeV4FLTSelectedRegIndexChanged	 object:self];
}

- (unsigned long) writeValue { return writeValue; }
- (void) setWriteValue:(unsigned long) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:[self writeValue]];
    writeValue = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTWriteValueChanged object:self];
}

- (NSString*) getRegisterName: (short) anIndex
{
    return regV4[anIndex].regName;
}

- (unsigned long) getAddressOffset: (short) anIndex
{
    return( regV4[anIndex].addressOffset );
}

- (short) getAccessType: (short) anIndex
{
	return regV4[anIndex].accessType;
}

- (void) setToDefaults
{
	int i;
	for(i=0;i<kNumV4FLTChannels;i++){
		[self setThreshold:i withValue:17000];
		[self setGain:i withValue:0];
	}
	[self setRunBoxCarFilter:YES];
	[self setGapLength:0];
	[self setFilterLength:6];
	[self setFifoBehaviour:kFifoEnableOverFlow];// kFifoEnableOverFlow or kFifoStopOnFull
	[self setPostTriggerTime:300]; // max. filter length should fit into the range -tb-
	
	[self setHistMeasTime:	5];
}

#pragma mark •••HW Access
- (unsigned long) readBoardIDLow
{
	unsigned long value = [self readReg:kFLTV4BoardIDLsbReg];
	return value;
}

- (unsigned long) readBoardIDHigh
{
	unsigned long value = [self readReg:kFLTV4BoardIDMsbReg];
	return value;
}

- (int) readSlot
{
	return ([self readReg:kFLTV4BoardIDMsbReg]>>24) & 0x1F;
}

- (unsigned long)  readVersion
{	
	return [self readReg: kFLTV4VersionReg];
}

- (unsigned long)  readpVersion
{	
	return [self readReg: kFLTV4pVersionReg];
}

- (unsigned long)  readSeconds
{	
	return [self readReg: kFLTV4SecondCounterReg];
}

- (void)  writeSeconds:(unsigned long)aValue
{	
	return [self writeReg: kFLTV4SecondCounterReg value:aValue];
}

- (void) setTimeToMacClock
{
	NSTimeInterval theTimeSince1970 = [NSDate timeIntervalSinceReferenceDate];
	[self writeSeconds:(unsigned long)theTimeSince1970];
}

- (int) readMode
{
	return ([self readControl]>>16) & 0xf;
}

- (void) loadThresholdsAndGains
{
	//use the command list to load all the thresholds and gains with one PMC command packet
	int i;
	ORCommandList* aList = [ORCommandList commandList];
	for(i=0;i<kNumV4FLTChannels;i++){
		unsigned long thres;
		if( !(triggerEnabledMask & (0x1<<i)) )	thres = 0xfffff;
		else									thres = [self threshold:i];
		[aList addCommand: [self writeRegCmd:kFLTV4ThresholdReg channel:i value:thres & 0xFFFFF]];
		[aList addCommand: [self writeRegCmd:kFLTV4GainReg channel:i value:[self gain:i] & 0xFFF]];
	}
	[aList addCommand: [self writeRegCmd:kFLTV4CommandReg value:kIpeFlt_Cmd_LoadGains]];
	
	[self executeCommandList:aList];
    
    //TODO: now we should wait 180 usec or check the busy flag before other write/read accesses -tb-
    // (usually (but not guaranteed!) access via TCP/IP is slow enought to produce a 180 usec timeout)
}

- (int) restrictIntValue:(int)aValue min:(int)aMinValue max:(int)aMaxValue
{
	if(aValue<aMinValue)	  return aMinValue;
	else if(aValue>aMaxValue) return aMaxValue;
	else					  return aValue;
}

- (float) restrictFloatValue:(int)aValue min:(float)aMinValue max:(float)aMaxValue
{
	if(aValue<aMinValue)	  return aMinValue;
	else if(aValue>aMaxValue) return aMaxValue;
	else					  return aValue;
}

- (void) enableStatistics
{
#if (0)
    unsigned long aValue;
	bool enabled = true;
	unsigned long adc_guess = 150;			// This are parameter that work with the standard Auger-type boards
	unsigned long n = 65000;				// There is not really a need to make them variable. ak 7.10.07
	
    aValue =     (  ( (unsigned long) (enabled  &   0x1) ) << 31)
	| (  ( (unsigned long) (adc_guess   & 0x3ff) ) << 16)
	|    ( (unsigned long) ( (n-1)  & 0xffff) ) ; // 16 bit !
	
	// Broadcast to all channel	(pseudo channel 0x1f)     
	[self writeReg:kFLTStaticSetReg channel:0x1f value:aValue]; 
	
	// Save parameter for calculation of mean and variance
	statisticOffset = adc_guess;
	statisticN = n;
#endif
}


- (void) getStatistics:(int)aChannel mean:(double *)aMean  var:(double *)aVar 
{
#if (0)
    unsigned long data;
	signed long sum;
    unsigned long sumSq;
	
    // Read Statistic parameter
    data = [self  readReg:kFLTStaticSetReg channel:aChannel];
	statisticOffset = (data  >> 16) & 0x3ff;
	statisticN = (data & 0xffff) +1;
	
	
    // Read statistics
	// The sum is a 25bit signed number.
	sum = [self readReg:kFLTSumXReg channel:aChannel];
	// Move the sign
	sum = (sum & 0x01000000) ? (sum | 0xFE000000) : (sum & 0x00FFFFFF);
	
    // Read the sum of squares	
	sumSq = [self readReg:kFLTSumX2Reg channel:aChannel];
	
	//NSLog(@"data = %x Offset = %d, n = %d, sum = %08x, sum2 = %08x\n", data, statisticOffset, statisticN, sum, sumSq);
	
	// Calculate mean and variance
	if (statisticN > 0){
		*aMean = (double) sum / statisticN + statisticOffset;
		*aVar = (double) sumSq / statisticN 
		- (double) sum / statisticN * sum / statisticN;
    } else {
		*aMean = -1; 
		*aVar = -1;
	}
#endif
}


- (void) initBoard
{
	[self writeControl];
	[self writeReg: kFLTV4HrControlReg value:hitRateLength];
	[self writeReg: kFLTV4PostTrigger  value:postTriggerTime];
	[self loadThresholdsAndGains];
	[self writeReg:kFLTV4AnalogOffset  value:analogOffset];
	[self writeTriggerControl];			//TODO:   (for v4 this needs to be implemented by DENIS)-tb- //set trigger mask
	[self writeHitRateMask];			//set hitRage control mask
	[self enableStatistics];			//TODO: OBSOLETE -tb- enable hardware ADC statistics, ak 7.1.07
	
	if(fltRunMode == kIpeFltV4Katrin_Histo_Mode){
		[self writeHistogramControl];
	}
}

- (unsigned long) readStatus
{
	return [self readReg: kFLTV4StatusReg ];
}

- (unsigned long) readControl
{
	return [self readReg: kFLTV4ControlReg];
}


//TODO: better use the STANDBY flag of the FLT -tb- 2010-01-xx     !!!!!!!!!!!!!!!!!
- (void) writeRunControl:(BOOL)startSampling
{
	unsigned long aValue = 
	((filterLength & 0xf)<<8)		| 
	((gapLength & 0xf)<<4)			| 
	// -tb- ((runBoxCarFilter & 0x1)<<2)	|
	((startSampling & 0x1)<<3)		|		// run trigger unit
	((startSampling & 0x1)<<2)		|		// run filter unit
	((startSampling & 0x1)<<1)      |		// start ADC sampling
	 (startSampling & 0x1);					// store data in QDRII RAM
	
	[self writeReg:kFLTV4RunControlReg value:aValue];					
}

- (void) writeControl
{
	unsigned long aValue =	((fltRunMode & 0xf)<<16) | 
	((fifoBehaviour & 0x1)<<24) |
	((ledOff & 0x1)<<1 );
	[self writeReg: kFLTV4ControlReg value:aValue];
}

- (void) writeHistogramControl
{
	[self writeReg:kFLTV4HistMeasTimeReg value:histMeasTime];
	unsigned long aValue = ((histClrMode & 0x1)<<29) | ((histMode & 0x1)<<28) | ((histEBin & 0xf)<<20) | histEMin;
	[self writeReg:kFLTV4HistgrSettingsReg value:aValue];
}

- (unsigned long) regAddress:(int)aReg channel:(int)aChannel
{
	return ([self stationNumber] << 17) | (aChannel << 12)   | regV4[aReg].addressOffset; //TODO: the channel ... -tb-   | ((aChannel&0x01f)<<kIpeFlt_ChannelAddress)
}

- (unsigned long) regAddress:(int)aReg
{
	
	return ([self stationNumber] << 17) |  regV4[aReg].addressOffset; //TODO: NEED <<17 !!! -tb-
}

- (unsigned long) adcMemoryChannel:(int)aChannel page:(int)aPage
{
	//TODO:  replace by V4 code -tb-
    //adc access now is very different from v3 -tb-
	return 0;
    //TODO: obsolete (v3) -tb-
	return ([self slot] << 24) | (0x2 << kIpeFlt_AddressSpace) | (aChannel << kIpeFlt_ChannelAddress)	| (aPage << kIpeFlt_PageNumber);
}

- (unsigned long) readReg:(int)aReg
{
	return [self read: [self regAddress:aReg]];
}

- (unsigned long) readReg:(int)aReg channel:(int)aChannel
{
	return [self read:[self regAddress:aReg channel:aChannel]];
}

- (void) writeReg:(int)aReg value:(unsigned long)aValue
{
	[self write:[self regAddress:aReg] value:aValue];
}

- (void) writeReg:(int)aReg channel:(int)aChannel value:(unsigned long)aValue
{
	[self write:[self regAddress:aReg channel:aChannel] value:aValue];
}

- (void) writeThreshold:(int)i value:(unsigned int)aValue
{
	aValue &= 0xfffff;
	[self writeReg: kFLTV4ThresholdReg channel:i value:aValue];
}

- (unsigned int) readThreshold:(int)i
{
	return [self readReg:kFLTV4ThresholdReg channel:i] & 0xfffff;
}

- (void) writeGain:(int)i value:(unsigned short)aValue
{
	aValue &= 0xfff;
	[self writeReg:kFLTV4GainReg channel:i value:aValue]; 
}

- (unsigned short) readGain:(int)i
{
	return [self readReg:kFLTV4GainReg channel:i] & 0xfff;
}

- (void) writeTestPattern:(unsigned long*)mask length:(int)len
{
	[self rewindTestPattern];
	[self writeNextPattern:0];
	int i;
	for(i=0;i<len;i++){
		[self writeNextPattern:mask[i]];
		NSLog(@"%d: %@\n",i,mask[i]?@".":@"-");
	}
	[self rewindTestPattern];
}

- (void) rewindTestPattern
{
#if (0)
    //TODO: obsolete (v3) -tb-
	[self writeReg:kFLTTestPulsMemReg value: kIpeFlt_TP_Control | kIpeFlt_TestPattern_Reset];
	
#endif
}

- (void) writeNextPattern:(unsigned long)aValue
{
#if (0)
    //TODO: obsolete (v3) -tb-
	[self writeReg:kFLTTestPulsMemReg value:aValue];
#endif
}

- (void) clear:(int)aChan page:(int)aPage value:(unsigned short)aValue
{
	unsigned long aPattern;
	
	aPattern =  aValue;
	aPattern = ( aPattern << 16 ) + aValue;
	
	// While emulating the block transfer by a loop of single transfers
	// it is nec. to increment the address pointer by 2
	[self clearBlock:[self adcMemoryChannel:aChan page:aPage]
			 pattern:aPattern
			  length:kIpeFlt_Page_Size / 2
		   increment:2];
}

- (void) writeMemoryChan:(int)aChan page:(int)aPage pageBuffer:(unsigned short*)aPageBuffer
{
	[self writeBlock: [self adcMemoryChannel:aChan page:aPage] 
		  dataBuffer: (unsigned long*)aPageBuffer
			  length: kIpeFlt_Page_Size/2
		   increment: 2];
}

- (void) readMemoryChan:(int)aChan page:(int)aPage pageBuffer:(unsigned short*)aPageBuffer
{
	
	[self readBlock: [self adcMemoryChannel:aChan page:aPage]
		 dataBuffer: (unsigned long*)aPageBuffer
			 length: kIpeFlt_Page_Size/2
		  increment: 2];
}

- (unsigned long) readMemoryChan:(int)aChan page:(int)aPage
{
	return [self read:[self adcMemoryChannel:aChan page:aPage]];
}

- (void) writeHitRateMask
{
	[self writeReg:kFLTV4HrMeasEnableReg value:hitRateEnabledMask];
}

- (unsigned long) readHitRateMask
{
	return [self readReg:kFLTV4HrMeasEnableReg] & 0xffffff;
}

- (void) writeInterruptMask
{
	[self writeReg:kFLTV4InterruptMaskReg value:interruptMask];
}


//TODO: TBD after firmware update -tb- 2010-01-28
- (void) disableAllTriggers
{
	[self writeReg:kFLTV4PixelSettings1Reg value:0x0];
	[self writeReg:kFLTV4PixelSettings2Reg value:0xffffff];
}

//TODO: TBD after firmware update -tb- 2010-01-28
- (void) writeTriggerControl  //TODO: must be handled by readout, single pixels cannot be disabled for KATRIN ; this is fixed now, remove workaround after all crates are updated -tb-
{
    //PixelSetting....
	//2,1:
	//0,0 Normal
	//0,1 test pattern
	//1,0 always 0
	//1,1 always 1
	[self writeReg:kFLTV4PixelSettings1Reg value:0]; //must be handled by readout, single pixels cannot be disabled for KATRIN - OK, FIRMWARE FIXED -tb-
	uint32_t mask = (~triggerEnabledMask) & 0xffffff;
	[self writeReg:kFLTV4PixelSettings2Reg value: mask];
}

- (void) readHitRates
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readHitRates) object:nil];
	
	@try {
		
		BOOL oneChanged = NO;
		float newTotal = 0;
		int chan;
        int hitRateLengthSec = 1<<hitRateLength;
		float freq = 1.0/((double)hitRateLengthSec);
				
		unsigned long location = (([self crateNumber]&0x1e)<<21) | ([self stationNumber]& 0x0000001f)<<16;
		unsigned long data[5 + kNumV4FLTChannels];
		
		//combine all the hitrate read commands into one command packet
		ORCommandList* aList = [ORCommandList commandList];
		for(chan=0;chan<kNumV4FLTChannels;chan++){
			if(hitRateEnabledMask & (1L<<chan)){
				[aList addCommand: [self readRegCmd:kFLTV4HitRateReg channel:chan]];
			}
		}
		
		[self executeCommandList:aList];
		
		//put the synchronized around this code to test if access to the hitrates is thread safe
		//pull out the result
		int dataIndex = 0;
		for(chan=0;chan<kNumV4FLTChannels;chan++){
			if(hitRateEnabledMask & (1L<<chan)){
				unsigned long aValue = [aList longValueForCmd:dataIndex];
				BOOL overflow = (aValue >> 31) & 0x1;
				aValue = aValue & 0xffff;
				if(aValue != hitRate[chan] || overflow != hitRateOverFlow[chan]){
					if (hitRateLengthSec!=0)	hitRate[chan] = aValue * freq;
					//if (hitRateLengthSec!=0)	hitRate[chan] = aValue; 
					else					    hitRate[chan] = 0;
					
					if(hitRateOverFlow[chan])hitRate[chan] = 0;
					hitRateOverFlow[chan] = overflow;
					
					oneChanged = YES;
				}
				if(!hitRateOverFlow[chan]){
					newTotal += hitRate[chan];
				}
				data[dataIndex + 5] = ((chan&0xff)<<20) | ((overflow&0x1)<<16) | aValue;// the hitrate may have more than 16 bit in the future -tb-
				dataIndex++;
			}
		}
		
		if(dataIndex>0){
			time_t	ut_time;
			time(&ut_time);

			data[0] = hitRateId | (dataIndex + 5); 
			data[1] = location;
			data[2] = ut_time;	
			data[3] = hitRateLengthSec;	
			data[4] = newTotal;
			[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
																object:[NSData dataWithBytes:data length:sizeof(long)*(dataIndex + 5)]];
			
		}
		
		[self setHitRateTotal:newTotal];
		
		if(oneChanged){
		    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelHitRateChanged object:self];
		}
	}
	@catch(NSException* localException) {
	}
	
	[self performSelector:@selector(readHitRates) withObject:nil afterDelay:(1<<[self hitRateLength])];
}

//------------------
//command Lists
- (void) executeCommandList:(ORCommandList*)aList
{
	[[[self crate] adapter] executeCommandList:aList];
}

- (id) readRegCmd:(unsigned long) aRegister channel:(short) aChannel
{
	unsigned long theAddress = [self regAddress:aRegister channel:aChannel];
	return [[[self crate] adapter] readHardwareRegisterCmd:theAddress];		
}

- (id) readRegCmd:(unsigned long) aRegister
{
	return [[[self crate] adapter] readHardwareRegisterCmd:[self regAddress:aRegister]];		
}

- (id) writeRegCmd:(unsigned long) aRegister channel:(short) aChannel value:(unsigned long)aValue
{
	unsigned long theAddress = [self regAddress:aRegister channel:aChannel];
	return [[[self crate] adapter] writeHardwareRegisterCmd:theAddress value:aValue];		
}

- (id) writeRegCmd:(unsigned long) aRegister value:(unsigned long)aValue
{
	return [[[self crate] adapter] writeHardwareRegisterCmd:[self regAddress:aRegister] value:aValue];		
}
//------------------


- (void) readHistogrammingStatus
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readHistogrammingStatus) object:nil];

    int histoUpdateRate = 1; // sec
    unsigned long recTime = [self readReg:kFLTV4HistRecTimeReg];
    unsigned long histoID = [self readReg:kFLTV4HistNumMeasReg];
    unsigned long pageAB  = ([self readReg:kFLTV4StatusReg] >>28) & 0x1;
    
    //DEBUG OUTPUT - NSLog(@"HistoStatus: recTime: %i  histoID: %i, pageAB: %i \n",recTime,histoID, pageAB);
    [self setHistRecTime: recTime];
    [self setHistNofMeas: histoID];
    [self setHistPageAB: pageAB];
    
	[self performSelector:@selector(readHistogrammingStatus) withObject:nil afterDelay:histoUpdateRate];
}



- (NSString*) rateNotification
{
	return ORIpeV4FLTModelHitRateChanged;
}

#pragma mark •••archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	
    [self setTargetRate:[decoder decodeIntForKey:@"targetRate"]];
    [self setHistClrMode:		[decoder decodeIntForKey:@"histClrMode"]];
    [self setHistMode:			[decoder decodeIntForKey:@"histMode"]];
    [self setHistEBin:			[decoder decodeInt32ForKey:@"histEBin"]];
    [self setHistEMin:			[decoder decodeInt32ForKey:@"histEMin"]];
	[self setRunMode:			[decoder decodeIntForKey:@"runMode"]];
    [self setRunBoxCarFilter:	[decoder decodeBoolForKey:@"runBoxCarFilter"]];
    [self setStoreDataInRam:	[decoder decodeBoolForKey:@"storeDataInRam"]];
    [self setFilterLength:		[decoder decodeIntForKey:@"filterLength"]];
    [self setGapLength:			[decoder decodeIntForKey:@"gapLength"]];
    [self setHistNofMeas:		[decoder decodeInt32ForKey:@"histNofMeas"]];
    [self setHistMeasTime:		[decoder decodeInt32ForKey:@"histMeasTime"]];
    [self setPostTriggerTime:	[decoder decodeInt32ForKey:@"postTriggerTime"]];
    [self setFifoBehaviour:		[decoder decodeIntForKey:@"fifoBehaviour"]];
    [self setAnalogOffset:		[decoder decodeIntForKey:@"analogOffset"]];
    [self setInterruptMask:		[decoder decodeInt32ForKey:@"interruptMask"]];
    [self setHitRateEnabledMask:[decoder decodeInt32ForKey:@"hitRateEnabledMask"]];
    [self setTriggerEnabledMask:[decoder decodeInt32ForKey:@"triggerEnabledMask"]];
    [self setHitRateLength:		[decoder decodeIntForKey:@"ORIpeV4FLTModelHitRateLength"]];
    [self setGains:				[decoder decodeObjectForKey:@"gains"]];
    [self setThresholds:		[decoder decodeObjectForKey:@"thresholds"]];
    [self setTotalRate:			[decoder decodeObjectForKey:@"totalRate"]];
	[self setTestEnabledArray:	[decoder decodeObjectForKey:@"testsEnabledArray"]];
	[self setTestStatusArray:	[decoder decodeObjectForKey:@"testsStatusArray"]];
    [self setWriteValue:		[decoder decodeIntForKey:@"writeValue"]];
    [self setSelectedRegIndex:  [decoder decodeIntForKey:@"selectedRegIndex"]];
    [self setSelectedChannelValue:  [decoder decodeIntForKey:@"selectedChannelValue"]];
	
	int i;
	if(!thresholds){
		[self setThresholds: [NSMutableArray array]];
		for(i=0;i<kNumV4FLTChannels;i++) [thresholds addObject:[NSNumber numberWithInt:50]];
	}
	if([thresholds count]<kNumV4FLTChannels){
		for(i=[thresholds count];i<kNumV4FLTChannels;i++) [thresholds addObject:[NSNumber numberWithInt:50]];
	}
	
	if(!gains){
		[self setGains: [NSMutableArray array]];
		for(i=0;i<kNumV4FLTChannels;i++) [gains addObject:[NSNumber numberWithInt:100]];
	}
	if([gains count]<kNumV4FLTChannels){
		for(i=[gains count];i<kNumV4FLTChannels;i++) [gains addObject:[NSNumber numberWithInt:50]];
	}
	
	if(!testStatusArray){
		[self setTestStatusArray: [NSMutableArray array]];
		for(i=0;i<kNumIpeV4FLTTests;i++) [testStatusArray addObject:@"--"];
	}
	
	if(!testEnabledArray){
		[self setTestEnabledArray: [NSMutableArray array]];
		for(i=0;i<kNumIpeV4FLTTests;i++) [testEnabledArray addObject:[NSNumber numberWithBool:YES]];
	}
	
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	
    [encoder encodeInt:targetRate			forKey:@"targetRate"];
    [encoder encodeInt:histClrMode			forKey:@"histClrMode"];
    [encoder encodeInt:histMode				forKey:@"histMode"];
    [encoder encodeInt32:histEBin			forKey:@"histEBin"];
    [encoder encodeInt32:histEMin			forKey:@"histEMin"];
    [encoder encodeInt:runMode				forKey:@"runMode"];
    [encoder encodeBool:runBoxCarFilter		forKey:@"runBoxCarFilter"];
    [encoder encodeBool:storeDataInRam		forKey:@"storeDataInRam"];
    [encoder encodeInt:filterLength			forKey:@"filterLength"];
    [encoder encodeInt:gapLength			forKey:@"gapLength"];
    [encoder encodeInt32:histNofMeas		forKey:@"histNofMeas"];
    [encoder encodeInt32:histMeasTime		forKey:@"histMeasTime"];
    [encoder encodeInt32:histRecTime		forKey:@"histRecTime"];
    [encoder encodeInt32:postTriggerTime	forKey:@"postTriggerTime"];
    [encoder encodeInt:fifoBehaviour		forKey:@"fifoBehaviour"];
    [encoder encodeInt:analogOffset			forKey:@"analogOffset"];
    [encoder encodeInt32:interruptMask		forKey:@"interruptMask"];
    [encoder encodeInt32:hitRateEnabledMask	forKey:@"hitRateEnabledMask"];
    [encoder encodeInt32:triggerEnabledMask	forKey:@"triggerEnabledMask"];
    [encoder encodeInt:hitRateLength		forKey:@"ORIpeV4FLTModelHitRateLength"];
    [encoder encodeObject:gains				forKey:@"gains"];
    [encoder encodeObject:thresholds		forKey:@"thresholds"];
    [encoder encodeObject:totalRate			forKey:@"totalRate"];
    [encoder encodeObject:testEnabledArray	forKey:@"testEnabledArray"];
    [encoder encodeObject:testStatusArray	forKey:@"testStatusArray"];
    [encoder encodeInt:writeValue           forKey:@"writeValue"];	
    [encoder encodeInt:selectedRegIndex  	forKey:@"selectedRegIndex"];	
    [encoder encodeInt:selectedChannelValue	forKey:@"selectedChannelValue"];	
}

#pragma mark Data Taking
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) aDataId
{
    dataId = aDataId;
}

- (unsigned long) waveFormId { return waveFormId; }
- (void) setWaveFormId: (unsigned long) aWaveFormId
{
    waveFormId = aWaveFormId;
}

- (unsigned long) hitRateId { return hitRateId; }
- (void) setHitRateId: (unsigned long) aDataId
{
    hitRateId = aDataId;
}

- (unsigned long) histogramId { return histogramId; }
- (void) setHistogramId: (unsigned long) aDataId
{
    histogramId = aDataId;
}

- (void) setDataIds:(id)assigner
{
    dataId      = [assigner assignDataIds:kLongForm];
    hitRateId   = [assigner assignDataIds:kLongForm];
    waveFormId  = [assigner assignDataIds:kLongForm];
    histogramId  = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
    [self setHitRateId:[anotherCard hitRateId]];
    [self setWaveFormId:[anotherCard waveFormId]];
    [self setHistogramId:[anotherCard histogramId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORIpeV4FLTDecoderForEnergy",			@"decoder",
								 [NSNumber numberWithLong:dataId],		@"dataId",
								 [NSNumber numberWithBool:NO],			@"variable",
								 [NSNumber numberWithLong:7],			@"length",
								 nil];
	
    [dataDictionary setObject:aDictionary forKey:@"IpeV4FLTEnergy"];
    
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORIpeV4FLTDecoderForWaveForm",			@"decoder",
				   [NSNumber numberWithLong:waveFormId],	@"dataId",
				   [NSNumber numberWithBool:YES],			@"variable",
				   [NSNumber numberWithLong:-1],			@"length",
				   nil];
	
    [dataDictionary setObject:aDictionary forKey:@"IpeV4FLTWaveForm"];
	
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORIpeV4FLTDecoderForHitRate",			@"decoder",
				   [NSNumber numberWithLong:hitRateId],		@"dataId",
				   [NSNumber numberWithBool:YES],			@"variable",
				   [NSNumber numberWithLong:-1],			@"length",
				   nil];
	
    [dataDictionary setObject:aDictionary forKey:@"IpeV4FLTHitRate"];
	
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORIpeV4FLTDecoderForHistogram",		@"decoder",
				   [NSNumber numberWithLong:histogramId],	@"dataId",
				   [NSNumber numberWithBool:YES],			@"variable",
				   [NSNumber numberWithLong:-1],			@"length",
				   nil];
	
    [dataDictionary setObject:aDictionary forKey:@"IpeV4FLTHistogram"];
	
    return dataDictionary;
}


//what is the event dictionary? -tb-
- (void) appendEventDictionary:(NSMutableDictionary*)anEventDictionary topLevel:(NSMutableDictionary*)topLevel
{
	NSDictionary* aDictionary;
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   [NSNumber numberWithLong:dataId],				@"dataId",
				   [NSNumber numberWithLong:kNumV4FLTChannels],		@"maxChannels",
				   nil];
	
	[anEventDictionary setObject:aDictionary forKey:@"IpeV4FLT"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    //TO DO....other things need to be added here.....
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:thresholds										forKey:@"thresholds"];
    [objDictionary setObject:gains											forKey:@"gains"];
    [objDictionary setObject:[NSNumber numberWithInt:runMode]				forKey:@"runMode"];
    [objDictionary setObject:[NSNumber numberWithLong:hitRateEnabledMask]	forKey:@"hitRateEnabledMask"];
    [objDictionary setObject:[NSNumber numberWithLong:triggerEnabledMask]	forKey:@"triggerEnabledMask"];
    [objDictionary setObject:[NSNumber numberWithLong:postTriggerTime]		forKey:@"postTriggerTime"];
    [objDictionary setObject:[NSNumber numberWithLong:fifoBehaviour]		forKey:@"fifoBehaviour"];
    [objDictionary setObject:[NSNumber numberWithLong:analogOffset]			forKey:@"analogOffset"];
    [objDictionary setObject:[NSNumber numberWithLong:hitRateLength]		forKey:@"hitRateLength"];
    [objDictionary setObject:[NSNumber numberWithLong:gapLength]			forKey:@"gapLength"];
    [objDictionary setObject:[NSNumber numberWithLong:filterLength]			forKey:@"filterLength"];
	return objDictionary;
}

- (BOOL) bumpRateFromDecodeStage:(short)channel
{
    if(channel>=0 && channel<kNumV4FLTChannels){
		++eventCount[channel];
	}
    return YES;
}

- (unsigned long) eventCount:(int)aChannel
{
    return eventCount[aChannel];
}

- (void) clearEventCounts
{
    int i;
    for(i=0;i<kNumV4FLTChannels;i++){
		eventCount[i]=0;
    }
}

//! Write 1 to all reset/clear flags of the FLTv4 command register.
- (void) reset 
{
	[self writeReg:kFLTV4CommandReg value:kIpeFlt_Reset_All];
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{	
	firstTime = YES;
	
    [self clearExceptionCount];
	[self clearEventCounts];
	
    //----------------------------------------------------------------------------------------
    // Add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORIpeV4FLTModel"];    
    //----------------------------------------------------------------------------------------	
	
	//check which mode to use
	BOOL ratesEnabled = NO;
	int i;
	for(i=0;i<kNumV4FLTChannels;i++){
		if([self hitRateEnabled:i]){
			ratesEnabled = YES;
			break;
		}
	}
	
    //if([[userInfo objectForKey:@"doinit"]intValue]){
	[self setLedOff:NO];
	[self writeRunControl:YES]; // writes to run control register (was NO, but this causes the first few noise events -tb-)
	[self reset];               // Write 1 to all reset/clear flags of the FLTv4 command register.
	[self initBoard];           // writes control reg + hr control reg + PostTrigg + thresh+gains + offset + triggControl + hr mask + enab.statistics
	//}
	
	
	if(ratesEnabled){
		[self performSelector:@selector(readHitRates) 
				   withObject:nil
				   afterDelay: (1<<[self hitRateLength])];		//start reading out the rates
	}
		
	if(runMode == kIpeFlt_Histogram_Mode){
		//start polling histogramming mode status
		[self performSelector:@selector(readHistogrammingStatus) 
				   withObject:nil
				   afterDelay: 1];		//start reading out histogram timer and page toggle
	}
	
	[self writeRunControl:YES];
	[self writeSeconds:0];

}


//**************************************************************************************
// Function:	

// Description: Read data from a card
//***************************************************************************************
-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{	
	if(firstTime){
		firstTime = NO;
		NSLogColor([NSColor redColor],@"Readout List Error: FLT %d must be a child of an SLT in the readout list\n",[self stationNumber]);
	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	//[self writeRunControl:NO];// let it run, see runTaskStarted ... -tb-
	[self setLedOff:YES];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readHitRates) object:nil];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readHistogrammingStatus) object:nil];
	int chan;
	for(chan=0;chan<kNumV4FLTChannels;chan++){
		hitRate[chan] = 0;
	}
	[self setHitRateTotal:0];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelHitRateChanged object:self];
}

#pragma mark •••SBC readout control structure... Till, fill out as needed
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id	= kFLTv4;					//unique identifier for readout hw
	configStruct->card_info[index].hw_mask[0] 	= dataId;					//record id for energies
	configStruct->card_info[index].hw_mask[1] 	= waveFormId;				//record id for the waveforms
	configStruct->card_info[index].hw_mask[2] 	= histogramId;				//record id for the histograms
	configStruct->card_info[index].slot			= [self stationNumber];		//the PMC readout uses col 0 thru n
	configStruct->card_info[index].crate		= [self crateNumber];
	
	configStruct->card_info[index].deviceSpecificData[0] = postTriggerTime;	//needed to align the waveforms
	
	unsigned long eventTypeMask = 0;
	if(readWaveforms) eventTypeMask |= kReadWaveForms;
	configStruct->card_info[index].deviceSpecificData[1] = eventTypeMask;	
	configStruct->card_info[index].deviceSpecificData[2] = fltRunMode;	
	
    //"first time" flag (needed for histogram mode)
	unsigned long runFlagsMask = 0;
	runFlagsMask |= kFirstTimeFlag;          //bit 16 = "first time" flag
    if(runMode == kIpeFlt_EnergyMode | runMode == kIpeFlt_EnergyTrace)
        runFlagsMask |= kSyncFltWithSltTimerFlag;//bit 17 = "sync flt with slt timer" flag
    
	configStruct->card_info[index].deviceSpecificData[3] = runFlagsMask;	
//NSLog(@"RunFlags 0x%x\n",configStruct->card_info[index].deviceSpecificData[3]);

    //for all daq modes
	configStruct->card_info[index].deviceSpecificData[4] = triggerEnabledMask;	
    //the daq mode (should replace the flt mode)
    configStruct->card_info[index].deviceSpecificData[5] = runMode;//the daqRunMode

	configStruct->card_info[index].num_Trigger_Indexes = 0;					//we can't have children
	configStruct->card_info[index].next_Card_Index 	= index+1;	

	
	return index+1;
}

#pragma mark •••HW Wizard
-(BOOL) hasParmetersToRamp
{
	return YES;
}

- (int) numberOfChannels
{
    return kNumV4FLTChannels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Run Mode"];
    [p setFormat:@"##0" upperLimit:2 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setRunMode:) getMethod:@selector(runMode)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold"];
    [p setFormat:@"##0" upperLimit:0xfffff lowerLimit:0 stepSize:1 units:@"raw"];
    [p setSetMethod:@selector(setThreshold:withValue:) getMethod:@selector(threshold:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Gain"];
    [p setFormat:@"##0" upperLimit:0xfff lowerLimit:0 stepSize:1 units:@"raw"];
    [p setSetMethod:@selector(setGain:withValue:) getMethod:@selector(gain:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Trigger Enable"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setTriggerEnabled:withValue:) getMethod:@selector(triggerEnabled:)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"HitRate Enable"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setHitRateEnabled:withValue:) getMethod:@selector(hitRateEnabled:)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Post Trigger Delay"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:2047 units:@"x50ns"];
    [p setSetMethod:@selector(setPostTriggerTime:) getMethod:@selector(postTriggerTime)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Fifo Behavior"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setFifoBehaviour:) getMethod:@selector(fifoBehaviour)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Analog Offset"];
    [p setFormat:@"##0" upperLimit:4095 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setAnalogOffset:) getMethod:@selector(analogOffset)];
    [a addObject:p];			

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Hit Rate Length"];
    [p setFormat:@"##0" upperLimit:4095 lowerLimit:255 stepSize:1 units:@""];
    [p setSetMethod:@selector(setHitRateLength:) getMethod:@selector(hitRateLength)];
    [a addObject:p];			

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Gap Length"];
    [p setFormat:@"##0" upperLimit:7 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setGapLength:) getMethod:@selector(gapLength)];
    [a addObject:p];			

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"FilterLength"];
    [p setFormat:@"##0" upperLimit:7 lowerLimit:2 stepSize:1 units:@""];
    [p setSetMethod:@selector(setFilterLength:) getMethod:@selector(filterLength)];
    [a addObject:p];			
	
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setName:@"Init"];
    [p setSetMethodSelector:@selector(initBoard)];
    [a addObject:p];
    
    return a;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORIpeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Station" className:@"ORIpeV4FLTModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORIpeV4FLTModel"]];
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    if([param isEqualToString:@"Threshold"])				return  [[cardDictionary objectForKey:@"thresholds"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Gain"])				return [[cardDictionary objectForKey:@"gains"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Trigger Enabled"])		return [[cardDictionary objectForKey:@"triggersEnabled"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"HitRate Enabled"])		return [[cardDictionary objectForKey:@"hitRatesEnabled"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Post Trigger Time"])	return [cardDictionary objectForKey:@"postTriggerTime"];
    else if([param isEqualToString:@"Run Mode"])			return [cardDictionary objectForKey:@"runMode"];
    else if([param isEqualToString:@"Fifo Behaviour"])		return [cardDictionary objectForKey:@"fifoBehaviour"];
    else if([param isEqualToString:@"Analog Offset"])		return [cardDictionary objectForKey:@"analogOffset"];
    else if([param isEqualToString:@"Hit Rate Length"])		return [cardDictionary objectForKey:@"hitRateLength"];
    else if([param isEqualToString:@"Gap Length"])			return [cardDictionary objectForKey:@"gapLength"];
    else if([param isEqualToString:@"Filter Length"])		return [cardDictionary objectForKey:@"filterLength"];
    else return nil;
}

#pragma mark •••AdcInfo Providing
- (void) postAdcInfoProvidingValueChanged
{
	//this notification is be picked up by high-level objects like the 
	//Katrin U/I that displays all the thresholds and gains in the system
	[[NSNotificationCenter defaultCenter] postNotificationName:ORAdcInfoProvidingValueChanged object:self];
}

- (BOOL) onlineMaskBit:(int)bit
{
	return [self triggerEnabled:bit];
}

#pragma mark •••Reporting
- (void) testReadHisto
{
	unsigned long hControl = [self readReg:kFLTV4HistgrSettingsReg];
	unsigned long pStatusA = [self readReg:kFLTV4pStatusA];
	unsigned long pStatusB = [self readReg:kFLTV4pStatusB];
	unsigned long pStatusC = [self readReg:kFLTV4pStatusC];
	unsigned long f3	   = [self readReg:kFLTV4HistNumMeasReg];
	NSLog(@"EMin: 0x%08x\n",  hControl & 0x7FFFF);
	NSLog(@"EBin: 0x%08x\n",  (hControl>>20) & 0xF);
	NSLog(@"HM: %d\n",  (hControl>>28) & 0x1);
	NSLog(@"CM: %d\n",  (hControl>>29) & 0x1);
	NSLog(@"page Changes: 0x%08x\n",  f3 & 0x3F);
	NSLog(@"A: 0x%08x fid:%d hPg:%i\n", (pStatusA>>12) & 0xFF, pStatusA>>28, (pStatusA&0x10)>>4);
	NSLog(@"B: 0x%08x fid:%d hPg:%i\n", (pStatusB>>12) & 0xFF, pStatusB>>28, (pStatusB&0x10)>>4);
	NSLog(@"C: 0x%08x fid:%d hPg:%i\n", (pStatusC>>12) & 0xFF, pStatusC>>28, (pStatusC&0x10)>>4);
	NSLog(@"Meas Time: 0x%08x\n", [self readReg:kFLTV4HistMeasTimeReg]);
	NSLog(@"Rec Time : 0x%08x\n", [self readReg:kFLTV4HistRecTimeReg]);
	NSLog(@"Page Number : 0x%08x\n", [self readReg:kFLTV4HistPageNReg]);
	
	int i;
	for(i=0;i<kNumV4FLTChannels;i++){
		unsigned long firstLast = [self readReg:kFLTV4HistLastFirstReg channel:i];
		unsigned long first = firstLast & 0xffff;
		unsigned long last = (firstLast >>16) & 0xffff;
		NSLog(@"%d: 0x%08x 0x%08x\n",i,first, last);
	}
}

- (void) printEventFIFOs
{
	unsigned long status = [self readReg: kFLTV4StatusReg];
	int fifoStatus = (status>>24) & 0xf;
	if(fifoStatus != 0x03){
		
		NSLog(@"fifoStatus: 0x%0x\n",(status>>24)&0xf);
		
		unsigned long aValue = [self readReg: kFLTV4EventFifoStatusReg];
		NSLog(@"aValue: 0x%0x\n", aValue);
		NSLog(@"Read: %d\n", (aValue>>16)&0x3ff);
		NSLog(@"Write: %d\n", (aValue>>0)&0x3ff);
		
		unsigned long eventFifo1 = [self readReg: kFLTV4EventFifo1Reg];
		unsigned long channelMap = (eventFifo1>>10)&0xfffff;
		NSLog(@"Channel Map: 0x%0x\n",channelMap);
		
		unsigned long eventFifo2 = [self readReg: kFLTV4EventFifo2Reg];
		unsigned long sec =  ((eventFifo1&0x3ff)<<5) | ((eventFifo2>>27)&0x1f);
		NSLog(@"sec: %d %d\n",((eventFifo2>>27)&0x1f),eventFifo1&0x3ff);
		NSLog(@"Time: %d\n",sec);
		
		int i;
		for(i=0;i<kNumV4FLTChannels;i++){
			if(channelMap & (1<<i)){
				unsigned long eventFifo3 = [self readReg: kFLTV4EventFifo3Reg channel:i];
				unsigned long energy     = [self readReg: kFLTV4EventFifo4Reg channel:i];
				NSLog(@"channel: %d page: %d energy: %d\n\n",i, eventFifo3 & 0x3f, energy);
			}
		}
		NSLog(@"-------\n");
	}
	else NSLog(@"FIFO empty\n");
}

- (void) printPStatusRegs
{
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	unsigned long pAData = [self readReg:kFLTV4pStatusA];
	unsigned long pBData = [self readReg:kFLTV4pStatusB];
	unsigned long pCData = [self readReg:kFLTV4pStatusC];
	NSLogFont(aFont,@"----------------------------------------\n");
	NSLogFont(aFont,@"PStatus      A          B         C\n");
	NSLogFont(aFont,@"----------------------------------------\n");
	NSLogFont(aFont,@"Filter:  %@   %@   %@\n", (pAData>>2)&0x1 ? @" InValid": @"   OK   ",
			  (pBData>>2)&0x1 ? @" InValid": @"   OK   ",
			  (pCData>>2)&0x1 ? @" InValid": @"   OK   ");
	
	NSLogFont(aFont,@"PLL1  :  %@   %@   %@\n", (pAData>>8)&0x1 ? @"Unlocked": @"  Locked",
			  (pBData>>8)&0x1 ? @"Unlocked": @"  Locked",
			  (pCData>>8)&0x1 ? @"Unlocked": @"  Locked");
	
	NSLogFont(aFont,@"PLL2  :  %@   %@   %@\n", (pAData>>9)&0x1 ? @"Unlocked": @"  Locked",
			  (pBData>>9)&0x1 ? @"Unlocked": @"  Locked",
			  (pCData>>9)&0x1 ? @"Unlocked": @"  Locked");
	
	NSLogFont(aFont,@"QDR-II:  %@   %@   %@\n", (pAData>>10)&0x1 ? @"Unlocked": @"  Locked",
			  (pBData>>10)&0x1 ? @"Unlocked": @"  Locked",
			  (pCData>>10)&0x1 ? @"Unlocked": @"  Locked");
	
	NSLogFont(aFont,@"QDR-Er:  %@   %@   %@\n", (pAData>>11)&0x1 ? @"   Error": @"  Clear ",
			  (pBData>>11)&0x1 ? @"   Error": @"  Clear ",
			  (pCData>>11)&0x1 ? @"   Error": @"  Clear ");
	
	NSLogFont(aFont,@"----------------------------------------\n");
}

- (NSString*) boardTypeName:(int)aType
{
	switch(aType){
		case 0:  return @"FZK HEAT";	break;
		case 1:  return @"FZK KATRIN";	break;
		case 2:  return @"FZK USCT";	break;
		case 3:  return @"ITALY HEAT";	break;
		default: return @"UNKNOWN";		break;
	}
}
- (NSString*) fifoStatusString:(int)aType
{
	switch(aType){
		case 0x3:  return @"Empty";			break;
		case 0x2:  return @"Almost Empty";	break;
		case 0x4:  return @"Almost Full";	break;
		case 0xc:  return @"Full";			break;
		default:   return @"UNKNOWN";		break;
	}
}

- (void) printVersions
{
	unsigned long data;
	data = [self readVersion];
	if(0x1f000000 == data){
		NSLogColor([NSColor redColor],@"FLTv4: Could not access hardware, no version register read!\n");
		return;
	}
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"CFPGA Version %u.%u.%u.%u\n",((data>>28)&0xf),((data>>16)&0xfff),((data>>8)&0xff),((data>>0)&0xff));
	data = [self readpVersion];
	NSLogFont(aFont,@"FPGA8 Version %u.%u.%u.%u\n",((data>>28)&0xf),((data>>16)&0xfff),((data>>8)&0xff),((data>>0)&0xff));

	switch ( ((data>>28)&0xf) ) {
		case 1: //AUGER
			NSLogFont(aFont,@"    This is a Auger FLTv4 firmware configuration!\n");
			break;
		case 2: //KATRIN
			NSLogFont(aFont,@"    This is a KATRIN FLTv4 firmware configuration!\n");
			break;
		default:
			NSLogFont(aFont,@"    This is a Unknown FLTv4 firmware configuration!\n");
			break;
	}
}

- (void) printStatusReg
{
	unsigned long status = [self readStatus];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"FLT %d status Reg (address:0x%08x): 0x%08x\n", [self stationNumber],[self regAddress:kFLTV4StatusReg],status);
	NSLogFont(aFont,@"Power           : %@\n",	((status>>0) & 0x1) ? @"FAILED":@"OK");
	NSLogFont(aFont,@"PLL1            : %@\n",	((status>>1) & 0x1) ? @"UNLOCKED":@"OK");
	NSLogFont(aFont,@"PLL2            : %@\n",	((status>>2) & 0x1) ? @"UNLOCKED":@"OK");
	NSLogFont(aFont,@"10MHz Phase     : %@\n",	((status>>3) & 0x1) ? @"UNLOCKED":@"OK");
	NSLogFont(aFont,@"Firmware Type   : %@\n",	[self boardTypeName:((status>>4) & 0x3)]);
	NSLogFont(aFont,@"Hardware Type   : %@\n",	[self boardTypeName:((status>>6) & 0x3)]);
	NSLogFont(aFont,@"Busy            : %@\n",	((status>>8) & 0x1) ? @"BUSY":@"IDLE");
	NSLogFont(aFont,@"Interrupt Srcs  : 0x%x\n",	(status>>16) &0xff);
	NSLogFont(aFont,@"FIFO Status     : %@\n",	[self fifoStatusString:((status>>24) & 0xf)]);
	NSLogFont(aFont,@"Histo Toggle Bit: %d\n",	((status>>28) & 0x1));
	NSLogFont(aFont,@"Histo Toggle Clr: %d\n",	((status>>29) & 0x1));
	NSLogFont(aFont,@"IRQ             : %d\n",	((status>>31) & 0x1));
}

- (void) printValueTable
{
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,   @"chan | HitRate  | Gain | Threshold\n");
	NSLogFont(aFont,   @"----------------------------------\n");
	unsigned long aHitRateMask = [self readHitRateMask];

	//grab all the thresholds and gains using one command packet
	int i;
	ORCommandList* aList = [ORCommandList commandList];
	for(i=0;i<kNumV4FLTChannels;i++){
		[aList addCommand: [self readRegCmd:kFLTV4GainReg channel:i]];
		[aList addCommand: [self readRegCmd:kFLTV4ThresholdReg channel:i]];
	}
	
	[self executeCommandList:aList];
	
	for(i=0;i<kNumV4FLTChannels;i++){
		NSLogFont(aFont,@"%4d | %@ | %4d | %4d \n",i,(aHitRateMask>>i)&0x1 ? @" Enabled":@"Disabled",[aList longValueForCmd:i*2],[aList longValueForCmd:1+i*2]);
	}
	NSLogFont(aFont,   @"---------------------------------\n");
}

- (void) printStatistics
{
	//TODO:  replace by V4 code -tb-
	NSLog(@"FLTv4: printStatistics not implemented \n");//TODO: needs implementation -tb-
	return;
    int j;
	double mean;
	double var;
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
    NSLogFont(aFont,@"Statistics      :\n");
	for (j=0;j<kNumV4FLTChannels;j++){
		[self getStatistics:j mean:&mean var:&var];
		NSLogFont(aFont,@"  %2d -- %10.2f +/-  %10.2f\n", j, mean, var);
	}
}

- (void) findNoiseFloors
{
	if(noiseFloorRunning){
		noiseFloorRunning = NO;
	}
	else {
		noiseFloorState = 0;
		noiseFloorRunning = YES;
		[self performSelector:@selector(stepNoiseFloor) withObject:self afterDelay:0];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTNoiseFloorChanged object:self];
}

- (NSString*) noiseFloorStateString
{
	if(!noiseFloorRunning) return @"Idle";
	else switch(noiseFloorState){
		case 0: return @"Initializing"; 
		case 1: return @"Setting Thresholds";
		case 2: return @"Integrating";
		case 3: return @"Finishing";
		default: return @"?";
	}	
}
- (unsigned long) thresholdForDisplay:(unsigned short) aChan
{
	return [self threshold:aChan];
}
- (unsigned short) gainForDisplay:(unsigned short) aChan
{
	return [self gain:aChan];
}
@end

@implementation ORIpeV4FLTModel (tests)
#pragma mark •••Accessors
- (BOOL) testsRunning { return testsRunning; }
- (void) setTestsRunning:(BOOL)aTestsRunning
{
    testsRunning = aTestsRunning;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelTestsRunningChanged object:self];
}

- (NSMutableArray*) testEnabledArray { return testEnabledArray; }
- (void) setTestEnabledArray:(NSMutableArray*)aTestEnabledArray
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTestEnabledArray:testEnabledArray];
    
    [aTestEnabledArray retain];
    [testEnabledArray release];
    testEnabledArray = aTestEnabledArray;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelTestEnabledArrayChanged object:self];
}

- (NSMutableArray*) testStatusArray { return testStatusArray; }
- (void) setTestStatusArray:(NSMutableArray*)aTestStatusArray
{
    [aTestStatusArray retain];
    [testStatusArray release];
    testStatusArray = aTestStatusArray;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelTestStatusArrayChanged object:self];
}

- (NSString*) testStatus:(int)index
{
	if(index<[testStatusArray count])return [testStatusArray objectAtIndex:index];
	else return @"---";
}

- (BOOL) testEnabled:(int)index
{
	if(index<[testEnabledArray count])return [[testEnabledArray objectAtIndex:index] boolValue];
	else return NO;
}

- (void) runTests
{
	if(!testsRunning){
		@try {
			[self setTestsRunning:YES];
			NSLog(@"Starting tests for FLT station %d\n",[self stationNumber]);
			
			//clear the status text array
			int i;
			for(i=0;i<kNumIpeV4FLTTests;i++){
				[testStatusArray replaceObjectAtIndex:i withObject:@"--"];
			}
			
			//create the test suit
			if(testSuit)[testSuit release];
			testSuit = [[ORTestSuit alloc] init];
			if([self testEnabled:0]) [testSuit addTest:[ORTest testSelector:@selector(modeTest) tag:0]];
			if([self testEnabled:1]) [testSuit addTest:[ORTest testSelector:@selector(ramTest) tag:1]];
			if([self testEnabled:2]) [testSuit addTest:[ORTest testSelector:@selector(thresholdGainTest) tag:2]];
			if([self testEnabled:3]) [testSuit addTest:[ORTest testSelector:@selector(speedTest) tag:3]];
			if([self testEnabled:4]) [testSuit addTest:[ORTest testSelector:@selector(eventTest) tag:4]];
			
			[testSuit runForObject:self];
		}
		@catch(NSException* localException) {
		}
	}
	else {
		NSLog(@"Tests for FLT (station: %d) stopped manually\n",[self stationNumber]);
		[testSuit stopForObject:self];
	}
}

- (void) runningTest:(int)aTag status:(NSString*)theStatus
{
	[testStatusArray replaceObjectAtIndex:aTag withObject:theStatus];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelTestStatusArrayChanged object:self];
}


#pragma mark •••Tests
- (void) modeTest
{
	int testNumber = 0;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	
	savedMode = fltRunMode;
	@try {
		BOOL passed = YES;
		int i;
		for(i=0;i<4;i++){
			fltRunMode = i;
			[self writeControl];
			if([self readMode] != i){
				[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
				passed = NO;
				break;
			}
			if(passed){
				fltRunMode = savedMode;
				[self writeControl];
				if([self readMode] != savedMode){
					[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
					passed = NO;
				}
			}
		}
		if(passed){
			[self test:testNumber result:@"Passed" color:[NSColor passedColor]];
		}
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
	}
	
	[testSuit runForObject:self]; //do next test
}


- (void) ramTest
{
	int testNumber = 1;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	@try {
		[self test:testNumber result:@"TBD" color:[NSColor passedColor]];
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
	}		
	
	[testSuit runForObject:self]; //do next test
}

- (void) thresholdGainTest
{
	int testNumber = 2;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	
	@try {
		[self enterTestMode];
		unsigned long aPattern[4] = {0x3fff,0x0,0x2aaa,0x1555};
		int chan;
		BOOL passed = YES;
		int testIndex;
		//thresholds first
		for(testIndex = 0;testIndex<4;testIndex++){
			unsigned short thePattern = aPattern[testIndex];
			for(chan=0;chan<kNumV4FLTChannels;chan++){
				[self writeThreshold:chan value:thePattern];
			}
			
			for(chan=0;chan<kNumV4FLTChannels;chan++){
				if([self readThreshold:chan] != thePattern){
					[self test:testNumber result:@"FAILED" color:[NSColor passedColor]];
					NSLog(@"Error: Threshold (pattern: 0x%0x) FLT %d chan %d does not work\n",thePattern,[self stationNumber],chan);
					passed = NO;
					break;
				}
			}
		}
		if(passed){		
			unsigned long gainPattern[4] = {0xfff,0x0,0xaaa,0x555};
			
			//now gains
			for(testIndex = 0;testIndex<4;testIndex++){
				unsigned short thePattern = gainPattern[testIndex];
				for(chan=0;chan<kNumV4FLTChannels;chan++){
					[self writeGain:chan value:thePattern];
				}
				
				for(chan=0;chan<kNumV4FLTChannels;chan++){
					unsigned short theValue = [self readGain:chan];
					if(theValue != thePattern){
						[self test:testNumber result:@"FAILED" color:[NSColor passedColor]];
						NSLog(@"Error: Gain (pattern: 0x%0x!=0x%0x) FLT %d chan %d does not work\n",thePattern,theValue,[self stationNumber],chan);
						passed = NO;
						break;
					}
				}
			}
		}
		if(passed){	
			unsigned long offsetPattern[4] = {0xfff,0x0,0xaaa,0x555};
			for(testIndex = 0;testIndex<4;testIndex++){
				unsigned short thePattern = offsetPattern[testIndex];
				[self writeReg:kFLTV4AnalogOffset value:thePattern];
				unsigned short theValue = [self readReg:kFLTV4AnalogOffset];
				if(theValue != thePattern){
					NSLog(@"Error: Offset (pattern: 0x%0x!=0x%0x) FLT %d does not work\n",thePattern,theValue,[self stationNumber]);
					passed = NO;
					break;
				}
			}
		}
		
		if(passed) [self test:testNumber result:@"Passed" color:[NSColor passedColor]];
		
		[self loadThresholdsAndGains]; //put the old values back
		
		[self leaveTestMode];
		
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
	}		
	
	[testSuit runForObject:self]; //do next test
}

- (void) speedTest
{
	int testNumber = 3;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	ORTimer* aTimer = [[ORTimer alloc] init];
	[aTimer start];
	
	@try {
		BOOL passed = YES;
		int numLoops = 250;
		int numPatterns = 4;
		int j;
		for(j=0;j<numLoops;j++){
			unsigned long aPattern[4] = {0xfffffff,0x00000000,0xaaaaaaaa,0x55555555};
			int i;
			for(i=0;i<numPatterns;i++){
				[self writeReg:kFLTV4AccessTestReg value:aPattern[i]];
				unsigned long aValue = [self readReg:kFLTV4AccessTestReg];
				if(aValue!=aPattern[i]){
					NSLog(@"Error: Comm Check (pattern: 0x%0x!=0x%0x) FLT %d does not work\n",aPattern,aValue,[self stationNumber]);
					passed = NO;				
				}
			}
			if(!passed)break;
		}
		[aTimer stop];
		if(passed){
			int totalOps = numLoops*numPatterns*2;
			double secs = [aTimer seconds];
			[self test:testNumber result:[NSString stringWithFormat:@"%.2f/s",totalOps/secs] color:[NSColor passedColor]];
			NSLog(@"Speed Test For FLT %d : %d accesses in %.3f sec\n",[self stationNumber], totalOps,secs);
		}
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
	}	
	@finally {
		[aTimer release];
	}
	
	[testSuit runForObject:self]; //do next test
}

- (void) eventTest
{
	int testNumber = 4;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	
	@try {
		[self test:testNumber result:@"TBD" color:[NSColor passedColor]];
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
		
	}		
	
	[testSuit runForObject:self]; //do next test
}

- (int) compareData:(unsigned short*) data
			pattern:(unsigned short*) pattern
			  shift:(int) shift
				  n:(int) n 
{
	int i, j;
	
	// Check for errors
	for (i=0;i<n;i++) {
		if (data[i]!=pattern[(i+shift)%n]) {
			for (j=(i/4);(j<i/4+3) && (j < n/4);j++){
				NSLog(@"%04x: %04x %04x %04x %04x - %04x %04x %04x %04x \n",j*4,
					  data[j*4],data[j*4+1],data[j*4+2],data[j*4+3],
					  pattern[(j*4+shift)%n],  pattern[(j*4+1+shift)%n],
					  pattern[(j*4+2+shift)%n],pattern[(j*4+3+shift)%n]  );
				return i; // check only for one error in every page!
			}
		}
	}
	
	return n;
}

@end

@implementation ORIpeV4FLTModel (private)

- (void) stepNoiseFloor
{
	[[self undoManager] disableUndoRegistration];
	int i;
	BOOL atLeastOne;
    @try {
		switch(noiseFloorState){
			case 0:
				//disable all channels
				for(i=0;i<kNumV4FLTChannels;i++){
					oldEnabled[i]   = [self hitRateEnabled:i];
					oldThreshold[i] = [self threshold:i];
					[self setThreshold:i withValue:0x7fff];
					newThreshold[i] = 0x7fff;
				}
				atLeastOne = NO;
				for(i=0;i<kNumV4FLTChannels;i++){
					if(oldEnabled[i]){
						noiseFloorLow[i]			= 0;
						noiseFloorHigh[i]		= 0x7FFF;
						noiseFloorTestValue[i]	= 0x7FFF/2;              //Initial probe position
						[self setThreshold:i withValue:noiseFloorHigh[i]];
						atLeastOne = YES;
					}
				}
				
				[self initBoard];
				
				if(atLeastOne)	noiseFloorState = 1;
				else			noiseFloorState = 4; //nothing to do
			break;
				
			case 1:
				for(i=0;i<kNumV4FLTChannels;i++){
					if([self hitRateEnabled:i]){
						if(noiseFloorLow[i] <= noiseFloorHigh[i]) {
							[self setThreshold:i withValue:noiseFloorTestValue[i]];
							
						}
						else {
							newThreshold[i] = MAX(0,noiseFloorTestValue[i] + noiseFloorOffset);
							[self setThreshold:i withValue:0x7fff];
							hitRateEnabledMask &= ~(1L<<i);
						}
					}
				}
				[self initBoard];
				
				if(hitRateEnabledMask)	noiseFloorState = 2;	//go check for data
				else					noiseFloorState = 3;	//done
			break;
				
			case 2:
				//read the hitrates
				[self readHitRates];
				
				for(i=0;i<kNumV4FLTChannels;i++){
					if([self hitRateEnabled:i]){
						if([self hitRate:i] > targetRate){
							//the rate is too high, bump the threshold up
							[self setThreshold:i withValue:0x7fff];
							noiseFloorLow[i] = noiseFloorTestValue[i] + 1;
						}
						else noiseFloorHigh[i] = noiseFloorTestValue[i] - 1;									//no data so continue lowering threshold
						noiseFloorTestValue[i] = noiseFloorLow[i]+((noiseFloorHigh[i]-noiseFloorLow[i])/2);     //Next probe position.
					}
				}
				
				[self initBoard];
				
				noiseFloorState = 1;
				break;
								
			case 3: //finish up	
				//load new results
				for(i=0;i<kNumV4FLTChannels;i++){
					[self setHitRateEnabled:i withValue:oldEnabled[i]];
					[self setThreshold:i withValue:newThreshold[i]];
				}
				[self initBoard];
				noiseFloorRunning = NO;
			break;
		}
		if(noiseFloorRunning){
			float timeToWait;
			if(noiseFloorState==2)	timeToWait = pow(2.,hitRateLength)* 1.5;
			else					timeToWait = 0.2;
			[self performSelector:@selector(stepNoiseFloor) withObject:self afterDelay:timeToWait];
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTNoiseFloorChanged object:self];
    }
	@catch(NSException* localException) {
        int i;
        for(i=0;i<kNumV4FLTChannels;i++){
            [self setHitRateEnabled:i withValue:oldEnabled[i]];
            [self setThreshold:i withValue:oldThreshold[i]];
			//[self reset];
			[self initBoard];
        }
		NSLog(@"FLT4 LED threshold finder quit because of exception\n");
    }
	[[self undoManager] enableUndoRegistration];
}


- (NSAttributedString*) test:(int)testIndex result:(NSString*)result color:(NSColor*)aColor
{
	NSLogColor(aColor,@"%@ test %@\n",fltTestName[testIndex],result);
	id theString = [[NSAttributedString alloc] initWithString:result 
												   attributes:[NSDictionary dictionaryWithObject: aColor forKey:NSForegroundColorAttributeName]];
	
	[self runningTest:testIndex status:theString];
	return [theString autorelease];
}

- (void) enterTestMode
{
	//put into test mode
	savedMode = fltRunMode;
	fltRunMode = kIpeFltV4Katrin_Test_Mode;
	[self writeControl];
	if([self readMode] != kIpeFltV4Katrin_Test_Mode){
		NSLogColor([NSColor redColor],@"Could not put FLT %d into test mode\n",[self stationNumber]);
		[NSException raise:@"Ram Test Failed" format:@"Could not put FLT %d into test mode\n",[self stationNumber]];
	}
}

- (void) leaveTestMode
{
	fltRunMode = savedMode;
	[self writeControl];
}
@end