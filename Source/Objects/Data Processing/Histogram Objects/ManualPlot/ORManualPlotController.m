
//
//  ORManualPlotController.m
//  Orca
//
//  Created by Mark Howe on Fri Apr 27 2009.
//  Copyright (c) 2009 CENPA, University of Washington. All rights reserved.
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

#pragma mark •••Imported Files
#import "ORManualPlotController.h"
#import "ORManualPlotModel.h"
#import "ORPlotView.h"
#import "ORXYPlot.h"
#import "ORCalibration.h"
#import "OR1dRoiController.h"
#import "OR1dFitController.h"

@interface ORManualPlotController (private)
- (void) selectWriteFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) _calibrationDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;
@end

@implementation ORManualPlotController

#pragma mark •••Initialization
- (id) init
{
    self = [super initWithWindowNibName:@"ManualPlot"];
    return self;
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	
	ORXYPlot* aPlot;
	aPlot = [[ORXYPlot alloc] initWithTag:0 andDataSource:self];
	[aPlot setRoi: [[model rois:0] objectAtIndex:0]];
	[aPlot setLineColor:[NSColor redColor]];
	[plotView addPlot: aPlot];
	[aPlot release];
	
	aPlot = [[ORXYPlot alloc] initWithTag:1 andDataSource:self];
	[aPlot setRoi: [[model rois:1] objectAtIndex:0]];
	[aPlot setLineColor:[NSColor blueColor]];
	[aPlot setShowSymbols:YES];
	[aPlot setShowLine:YES];
	[plotView addPlot: aPlot];
	[aPlot release];
	
	roiController = [[OR1dRoiController panel] retain];
	[roiView addSubview:[roiController view]];
	
	fitController = [[OR1dFitController panel] retain];
	[fitView addSubview:[fitController view]];
	
	[self plotOrderDidChange:plotView];
}

- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
    
    [notifyCenter addObserver: self
                     selector: @selector(dataChanged:)
                         name: ORManualPlotDataChanged
                       object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(colKeyChanged:)
                         name : ORManualPlotModelColKeyChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(col0TitleChanged:)
                         name : ORManualPlotModelCol0TitleChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(col1TitleChanged:)
                         name : ORManualPlotModelCol1TitleChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(col2TitleChanged:)
                         name : ORManualPlotModelCol2TitleChanged
						object: model];	
	
    [notifyCenter addObserver : self
                     selector : @selector(drawDidOpen:)
                         name : NSDrawerDidOpenNotification
						object: nil];	
	
}


- (void) updateWindow
{
	[super updateWindow];
	[self col0TitleChanged:nil];
	[self col1TitleChanged:nil];
	[self col2TitleChanged:nil];
	[self colKeyChanged:nil];
}

#pragma mark •••Interface Management

- (void) drawDidOpen:(NSNotification*)aNote
{
	if([aNote object] == [self analysisDrawer])[dataDrawer close:nil];
	else if([aNote object] == dataDrawer)[[self analysisDrawer] close:nil];
}

- (void) colKeyChanged:(NSNotification*)aNote
{
	[col0KeyPU selectItemAtIndex: [model col0Key]];
	[col1KeyPU selectItemAtIndex: [model col1Key]];
	[col2KeyPU selectItemAtIndex: [model col2Key]];
	[self refreshPlot:nil];
}


- (void) col0TitleChanged:(NSNotification*)aNotification
{
	NSString* title = [model col0Title];
	if(!title)title = @"Col 0";
	[[[dataTableView tableColumnWithIdentifier:@"0"] headerCell] setTitle:title];
	[col0LabelField setStringValue:title];
	[dataTableView reloadData];
	[self refreshPlot:nil];
}

- (void) col1TitleChanged:(NSNotification*)aNotification
{
	NSString* title = [model col1Title];
	if(!title)title = @"Col 1";
	[[[dataTableView tableColumnWithIdentifier:@"1"] headerCell] setTitle:title];
	[col1LabelField setStringValue:title];
	[dataTableView reloadData];
	[self refreshPlot:nil];
}

- (void) col2TitleChanged:(NSNotification*)aNotification
{
	NSString* title = [model col2Title];
	if(!title)title = @"Col 2";
	[[[dataTableView tableColumnWithIdentifier:@"2"] headerCell] setTitle:title];
	[col2LabelField setStringValue:title];
		
	[dataTableView reloadData];
	[self refreshPlot:nil];
}

- (void) dataChanged:(NSNotification*)aNotification
{
	[dataTableView reloadData];
	[plotView setNeedsDisplay:YES];
}

- (void) refreshModeChanged:(NSNotification*)aNotification
{
	//we don't have refresh modes
}
- (void) pausedChanged:(NSNotification*)aNotification
{
	//we don't have paused modes
}

#pragma mark •••Actions
- (IBAction) copy:(id)sender
{
	[plotView copy:sender];
}

- (IBAction) refreshPlot:(id)sender
{
	int col0Key = [model col0Key];
	NSString* title;
	if(col0Key > 2) title = @"Index";
	else title = [[[dataTableView tableColumnWithIdentifier:[NSString stringWithFormat:@"%d",col0Key]] headerCell] title];
	[[plotView xScale] setLabel:title];
	
	title = @"";
	int col1Key = [model col1Key];
	int col2Key = [model col2Key];
	[y1LengendField setStringValue:@""];
	[y2LengendField setStringValue:@""];
	if(col1Key <= 2) {
		NSString* s = [[[dataTableView tableColumnWithIdentifier:[NSString stringWithFormat:@"%d",col1Key]] headerCell] title];
		title = [title stringByAppendingString:s];
		[y1LengendField setStringValue:s];
	}
	if(col2Key <= 2) {
		if([title length])title = [title stringByAppendingString:@" , "];
		NSString* s = [[[dataTableView tableColumnWithIdentifier:[NSString stringWithFormat:@"%d",col2Key]] headerCell] title];
		title = [title stringByAppendingString:s];
		[y2LengendField setStringValue:s];
	}
	if([title length]==0)title = @"Index";
	
	[[plotView yScale] setLabel:title];
	[plotView setNeedsDisplay:YES];
}

- (IBAction) col2KeyAction:(id)sender
{
	[model setCol2Key:[sender indexOfSelectedItem]];	
}

- (IBAction) col1KeyAction:(id)sender
{
	[model setCol1Key:[sender indexOfSelectedItem]];	
}

- (IBAction) col0KeyAction:(id)sender
{
	[model setCol0Key:[sender indexOfSelectedItem]];	
}

- (IBAction) writeDataFileAction:(id)sender
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save As"];
    [savePanel setCanCreateDirectories:YES];
    
    [savePanel beginSheetForDirectory:NSHomeDirectory()
                                 file:@"Untitled"
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(selectWriteFileDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
	
}
- (IBAction) calibrate:(id)sender
{
	NSDictionary* aContextInfo = [NSDictionary dictionaryWithObjectsAndKeys: model, @"ObjectToCalibrate",
								  model , @"ObjectToUpdate",
								  nil];
	calibrationPanel = [[ORCalibrationPane calibrateForWindow:[self window] 
												modalDelegate:self 
											   didEndSelector:@selector(_calibrationDidEnd:returnCode:contextInfo:)
												  contextInfo:aContextInfo] retain];
	
}

#pragma mark •••Data Source
- (BOOL) plotterShouldShowRoi:(id)aPlot
{
	if([analysisDrawer state] == NSDrawerOpenState)return YES;
	else return NO;
}

- (NSMutableArray*) roiArrayForPlotter:(id)aPlot
{
	return [model rois:[aPlot tag]];
}

- (int) numberOfRowsInTableView:(NSTableView *)tableView
{
	return [model numPoints];
}

- (void) plotOrderDidChange:(id)aPlotView
{
	id topRoi = [(ORPlotWithROI*)[aPlotView topPlot] roi];
	[roiController setModel:topRoi];
	[fitController setModel:[topRoi fit]];
	int i;
	for(i=0;i<2;i++){
		int tag = [[aPlotView plot:i] tag];
		id aPlot = [aPlotView plot:i];
		NSColor* theColor;
		if(aPlot != [aPlotView topPlot])theColor = [[aPlot lineColor] highlightWithLevel:.5];
		else							theColor = [aPlot lineColor];
		if(tag == 1) [y1LengendField setTextColor:theColor];
		else [y2LengendField setTextColor:theColor];

		if(tag == 0) [y2LengendField setTextColor:theColor];
		else [y1LengendField setTextColor:theColor];
	}
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	return [model dataAtRow:row column:[[tableColumn identifier] intValue]];
}

- (int) numberPointsInPlot:(id)aPlotter
{
	return [model numPoints];
}

- (BOOL) plotter:(id)aPlotter index:(unsigned long)index x:(double*)xValue y:(double*)yValue
{
	return [model dataSet:[aPlotter tag] index:index x:xValue y:yValue];
}

@end

@implementation ORManualPlotController (private)
- (void) selectWriteFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        [model writeDataToFile:[[sheet filenames] objectAtIndex:0]];
    }
}

- (void) _calibrationDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{
	[calibrationPanel release];
	calibrationPanel = nil;
}

@end

