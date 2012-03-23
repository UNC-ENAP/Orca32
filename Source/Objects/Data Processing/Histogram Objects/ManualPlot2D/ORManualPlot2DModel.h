//
//  ORManualPlot2DModel.h
//  Orca
//
//  Created by Mark Howe on Fri Mar 23,2012.
//  Copyright (c) 2012  University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina  sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------#define kManualPlot2DMacol0Keys 3

@interface ORManualPlot2DModel : OrcaObject  
{
	NSLock*			dataSetLock;
	unsigned short  numberBinsPerSide;
    unsigned long*  histogram; //actually a 2D array stuffed into a 1D
    BOOL			scheduledForUpdate;
    NSString*		xTitle;
    NSString*		yTitle;
    NSString*		plotTitle;
    unsigned short      minX,maxX,minY,maxY;
	NSMutableArray* rois;
}

- (void) freeHistogram;
- (void) clear;

#pragma mark ***Accessors
- (void)			setNumberBinsPerSide:(unsigned short)bins;
- (unsigned long)	valueAtX:(unsigned short)aXBin y:(unsigned short)aYBin;
- (void)			setBinAtX:(int)anX y:(int)aY to:(unsigned long)aValue;
- (void)			incrementBinAtX:(int)aXBin y:(int)aYBin by:(unsigned long)aValue;
- (NSString*)		xTitle;
- (void)			setXTitle:(NSString*)aString;
- (NSString*)		yTitle;
- (void)			setYTitle:(NSString*)aString;
- (NSString*)		plotTitle;
- (void)			setPlotTitle:(NSString*)aString;
- (NSMutableArray*) rois;

#pragma mark •••Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark •••Data Source Methods
- (unsigned long*) getDataSetAndNumBinsPerSize:(unsigned short*)value;
- (void) getXMin:(unsigned short*)aMinX xMax:(unsigned short*)aMaxX yMin:(unsigned short*)aMinY yMax:(unsigned short*)aMaxY;
- (unsigned long*) plotter:(id)aPlotter numberBinsPerSide:(unsigned short*)xValue;
- (void) plotter:(id)aPlotter xMin:(unsigned short*)aMinX xMax:(unsigned short*)aMaxX yMin:(unsigned short*)aMinY yMax:(unsigned short*)aMaxY;
@end

extern NSString* ORManualPlot2DLock;
extern NSString* ORManualPlot2DDataChanged;
extern NSString* ORManualPlot2DModelXTitleChanged;
extern NSString* ORManualPlot2DModelYTitleChanged;
extern NSString* ORManualPlot2DModelPlotTitleChanged;
