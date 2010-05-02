//
//  ORProcessHistoryController.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 18 2005.
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


#pragma mark ���Imported Files
#import "ORProcessHistoryController.h"
#import "ORProcessHistoryModel.h"
#import "ORPlotView.h"
#import "ORTimeLinePlot.h"
#import "ORTimeAxis.h"
#import "ORProcessThread.h"

@implementation ORProcessHistoryController

#pragma mark ���Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"ProcessHistory"];
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	[[plotter yScale] setRngLimitsLow:-1000 withHigh:1000 withMinRng:5];
	[[plotter yScale] setRngDefaultsLow:0 withHigh:20];

	[[plotter xScale] setRngLimitsLow:0 withHigh:50000 withMinRng:3];
	[[plotter xScale] setRngDefaultsLow:0 withHigh:50000];
	
	NSColor* theColors[4] = {
		[NSColor redColor],
		[NSColor blueColor],
		[NSColor blackColor],
		[NSColor greenColor],
	};
	int i;
	for(i=0;i<4;i++){
		ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:i andDataSource:self];
		[aPlot setLineColor:theColors[i]];
		[plotter addPlot: aPlot];
		[(ORTimeAxis*)[plotter xScale] setStartTime: [[NSDate date] timeIntervalSince1970]];
		[aPlot release]; 
	}
	
}

#pragma mark ���Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(dataChanged:)
                         name : ORHistoryElementDataChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(scaleAction:)
                         name : ORAxisRangeChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(miscAttributesChanged:)
						 name : ORMiscAttributesChanged
					   object : model];
	
}

- (void) updateWindow
{
	[super updateWindow];
	[self miscAttributesChanged:nil];
}

- (void) scaleAction:(NSNotification*)aNotification
{
	
	if(aNotification == nil || [aNotification object] == [plotter xScale]){
		[model setMiscAttributes:[(ORAxis*)[plotter xScale]attributes] forKey:@"plotterXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter yScale]){
		[model setMiscAttributes:[(ORAxis*)[plotter yScale]attributes] forKey:@"plotterYAttributes"];
	};
	
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{
	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"plotterXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"plotterXAttributes"];
		if(attrib){
			[(ORAxis*)[plotter xScale] setAttributes:attrib];
			[plotter setNeedsDisplay:YES];
			[[plotter xScale] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"plotterYAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"plotterYAttributes"];
		if(attrib){
			[(ORAxis*)[plotter yScale] setAttributes:attrib];
			[plotter setNeedsDisplay:YES];
			[[plotter yScale] setNeedsDisplay:YES];
		}
	}
}

- (void) dataChanged:(NSNotification*)aNotification
{
    if(!scheduledToUpdate){
        [self performSelector:@selector(doUpdate) withObject:nil afterDelay:1.0];
        scheduledToUpdate = YES;
    }
}

- (void) doUpdate
{
    scheduledToUpdate = NO;
	[plotter setNeedsDisplay:YES];
	[[plotter xScale] setNeedsDisplay:YES];
}

#pragma mark ���Plot Data Source
- (int) numberPointsInPlot:(id)aPlotter
{
	return [model numberPointsInPlot:aPlotter];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
	[model plotter:aPlotter index:i x:xValue y:yValue];
}
@end
