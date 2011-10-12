//
//  ORCompositePlotView.m
//  Orca
//
//  Created by Mark Howe on 2/20/10.
//  Copyright 2010 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of  
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORComposite2DPlotView.h"
#import "ORAxis.h"
#import "ORPlotView.h"
#import "ORColorScale.h"

@implementation ORComposite2DPlotView

@synthesize zAxis,colorScale,zLogButton;

- (void) dealloc
{
	[zAxis release];
	[zLogButton release];
	[colorScale release];
	[super dealloc];
}

- (void) setUpViews
{
	//set up the *rough* positions of the various parts
	[self makeYAxis];
	[self makeXAxis];
	[self makeZAxis];
	[self makeColorScale];
	[self makePlotView];
	
	[plotView setXScale:xAxis];
	[plotView setYScale:yAxis];
	[plotView setZScale:zAxis];
	[plotView setColorScale:colorScale];
	[colorScale setColorAxis:zAxis];
	
	[yAxis setViewToScale:plotView];
	[xAxis setViewToScale:plotView];
	[zAxis setViewToScale:plotView];
	
	[self adjustPositionsAndSizes];
	
	[zLogButton setIntValue:[zAxis isLog]];
}

- (void) adjustPositionsAndSizes
{	
	NSRect xAxisRect = [xAxis bounds];
	NSRect yAxisRect = [yAxis bounds];
	NSRect zAxisRect = [zAxis bounds];
	NSRect colorScaleRect = [colorScale bounds];
	
	float widthOfYAxis		= yAxisRect.size.width;
	float widthOfZAxis		= zAxisRect.size.width;
	float widthOfColorScale	= colorScaleRect.size.width;
	float heightOfXAxis		= xAxisRect.size.height;
	
	//adjust position of colorscale to be on the right, against the top and bottom, adjust again later
	[colorScale setFrame:NSMakeRect([self bounds].size.width-[colorScale bounds].size.width,
							   heightOfXAxis,
							   [colorScale bounds].size.width,
							   [self bounds].size.height-heightOfXAxis) ];
	

	//adjust position of zAxis to be on the left, against the top
	[zAxis setFrame:NSMakeRect([colorScale frame].origin.x-widthOfZAxis - 1,
							   heightOfXAxis,
							   widthOfZAxis,
							   [self bounds].size.height-heightOfXAxis) ];
	
	
	//adjust position of yAxis to be on the left, against the top
	[yAxis setFrame:NSMakeRect(0,
							   heightOfXAxis,
							   widthOfYAxis,
							   [self bounds].size.height-heightOfXAxis) ];
	
	//adjust position of xAxis to be on the right, against the bottom
	[xAxis setFrame:NSMakeRect(widthOfYAxis-[xAxis lowOffset]+1 , 
							   [yAxis lowOffset]-1 , 
							   [self bounds].size.width-widthOfYAxis+[xAxis lowOffset]- widthOfColorScale -  widthOfZAxis, 
							   heightOfXAxis) ];
	
	
	[plotView setFrame:NSMakeRect(widthOfYAxis+1, 
								  heightOfXAxis+[yAxis lowOffset], 
								  [xAxis highOffset]-[xAxis lowOffset], 
								  [yAxis highOffset]-[yAxis lowOffset]) ];

	//final tweak to make the colorscale line up
	[colorScale setFrame:NSMakeRect([colorScale frame].origin.x,
									[zAxis frame].origin.y + [zAxis lowOffset],
									[colorScale bounds].size.width,
									[zAxis highOffset]-[zAxis lowOffset]) ];
	
}

- (void) makeColorScale
{
	//do the yAxis -- frame size will be fixed when we know more
	NSRect plotRect = [self bounds];
	ORColorScale* aColorScale = [[ORColorScale alloc] initWithFrame:NSMakeRect(0,0, 10, plotRect.size.height)];
	[aColorScale setAutoresizingMask:NSViewHeightSizable | NSViewMinXMargin];
	[self addSubview:aColorScale];
	self.colorScale = aColorScale;
	[aColorScale release];
}

- (void) makeZAxis
{
	//do the yAxis -- frame size will be fixed when we know more
	NSRect plotRect = [self bounds];
	ORAxis* anAxis = [[ORAxis alloc] initWithFrame:NSMakeRect(0,0, 50, plotRect.size.height)];
	[anAxis setAutoresizingMask:NSViewHeightSizable | NSViewMinXMargin];
	[self addSubview:anAxis];
	self.zAxis = anAxis;
	[anAxis release];
}

- (void) setShowGrid:(BOOL)aState		{ [plotView setShowGrid:aState];}
- (IBAction) setLogZ:(id)sender			{ [zAxis setLog:[sender intValue]]; }
- (IBAction) autoScaleZ:(id)sender		{ [plotView autoScaleZ:sender]; }
- (IBAction) shiftUp:(id)sender			{ [yAxis shiftLeft:sender]; }
- (IBAction) shiftDown:(id)sender		{ [yAxis shiftRight:sender]; }

@end


