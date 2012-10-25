/***************************************************************************
    OREdelweissFLTDefs.h  -  description

    begin                : Tue Jul 18 2000
    copyright            : (C) 2000 by Andreas Kopmann
    email                : kopmann@hpe.fzk.de
 ***************************************************************************/

//Adress model
#define kIpeFlt_AddressSpace 21		// Address Space Switch bits 22..21 (shortend!)
#define kIpeFlt_ChannelAddress 16   // Channel Address      bits 20..16
#define kIpeFlt_PageNumber 10		// Page Number          bits 14..10
#define kIpeFlt_RegId 0				// Register Id          bits 14.. 0



//TODO: for EW: 6 or 36??? -tb-
#define kNumV4FLTChannels 24

#define kIpeFlt_Page_Size 1000

#define kIpeFlt_Pages 64

// Control register bits
#define kEWFlt_ControlReg_VetoFlag_Shift	31
#define kEWFlt_ControlReg_VetoFlag_Mask		0x1
#define kEWFlt_ControlReg_SelectFiber_Shift	28
#define kEWFlt_ControlReg_SelectFiber_Mask	0x7
#define kEWFlt_ControlReg_StatusLatency_Shift	25
#define kEWFlt_ControlReg_StatusLatency_Mask	0x7
#define kEWFlt_ControlReg_FiberEnable_Shift	16
#define kEWFlt_ControlReg_FiberEnable_Mask	0x3f
#define kEWFlt_ControlReg_BBv1_Shift		8
#define kEWFlt_ControlReg_BBv1_Mask			0x3f
#define kEWFlt_ControlReg_ModeFlags_Shift	4
#define kEWFlt_ControlReg_ModeFlags_Mask	0x3
#define kEWFlt_ControlReg_tpix_Shift	6
#define kEWFlt_ControlReg_tpix_Mask	0x1



// Position of the bit fields
#define kIpeFlt_Cntl_InterruptMask_Shift	8
#define kIpeFlt_Cntl_InterruptMask_Mask		0xff

#define kIpeFlt_Cntl_LedOff_Shift			17
#define kIpeFlt_Cntl_LedOff_Mask				0x1

#define kIpeFlt_Cntl_HitRateLength_Shift	18   
#define kIpeFlt_Cntl_HitRateLength_Mask		0x7 

#define kIpeFlt_Cntl_ErrFlag_Shift			21   
#define kIpeFlt_Cntl_ErrFlag_Mask			0x1 

#define kIpeFlt_Cntl_Mode_Shift				16
#define kIpeFlt_Cntl_Mode_Mask				0x1

#define kIpeFlt_Cntl_Version_Shift			23
#define kIpeFlt_Cntl_Version_Mask			0xf

#define kIpeFlt_Cntl_CardID_Shift			27
#define kIpeFlt_Cntl_CardID_Mask			0x1f


#define kIpeFlt_Cntl_InterruptSources_Shift	0
#define kIpeFlt_Cntl_InterruptSources_Mask	0xff

//command register
#define kIpeFlt_Cmd_resync	                0x1
#define kIpeFlt_Cmd_TrigEvCountRes          (0x1 << 16)
#define kIpeFlt_Cmd_SWTrig	                (0x1 << 31)

#define kIpeFlt_Periph_CoinTme_Shift		0
#define kIpeFlt_Periph_CoinTme_Mask			0x1ff

#define kIpeFlt_Periph_Mode_Shift			14
#define kIpeFlt_Periph_Mode_Mask			0x1

#define kIpeFlt_Periph_LedOff_Shift			15
#define kIpeFlt_Periph_LedOff_Mask			0x1

#define kIpeFlt_Periph_ThresDelta_Shift		16
#define kIpeFlt_Periph_ThresDelta_Mask		0xf

#define kIpeFlt_Periph_Integration_Shift	20
#define kIpeFlt_Periph_Integration_Mask		0xf

#if 0 //moved to SLTv4_HW_Definitions.h - names have changed -tb-
//run modes set by user in popup
#define kIpeFlt_EnergyMode		0
#define kIpeFlt_EnergyTrace		1
#define kIpeFlt_Histogram_Mode	2
#endif

#define kIpeFlt_Intack				0x40000000
#define kIpeFlt_READ				0x80000000
#define kIpeFlt_TP_Control			0x02000000
#define kIpeFlt_TP_End				0x01000000
#define kIpeFlt_Ec2					0x00800000
#define kIpeFlt_Ec1					0x00400000
#define kIpeFlt_PatternMask			0xffffffff // 22bit + Multiplicity
#define kIpeFlt_TestPattern_Reset	0x00000010

//#define kIpeFlt_Reset_All			0x18010 I added the resetPage flag -tb-
//#define kIpeFlt_Reset_All			0x38010

#define kSetStandBy		1
#define kReleaseStandBy 0

#define kFifoEnableOverFlow 0
#define kFifoStopOnFull     1

#define SELECT_ALL_CHANNELS ( 0x1F <<16) // ak, 7.10.07

typedef struct {
	unsigned long channelMap; // 8bit channel + 24 channelMap
	unsigned long threshold;   
	unsigned long hitrate;
} ipeFltHitRateDataStruct;

#if 0
typedef struct { // -tb- 2008-02-27
	long readoutSec;
	long recordingTimeSec;  //! this holds the refresh time -tb-
	long firstBin;
	long lastBin;
	long histogramLength; //don't use unsigned! - it may become negative, at least temporaryly -tb-
    long maxHistogramLength;
    long binSize;
    long offsetEMin;
} ipcFltV4HistogramDataStruct;
#endif
