//
//  ORTimeLinePlot.m
//  Orca
//
//  Created by Mark Howe on 2/20/10.
//  Copyright 2010 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of  
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of1DHisto Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORTimeLinePlot.h"
#import "ORPlotView.h"
#import "ORTimeLine.h"
#import "ORTimeAxis.h"
#import "ORPlotAttributeStrings.h"

@implementation ORTimeLinePlot

#pragma mark ***Data Source Setup
- (void) setDataSource:(id)ds
{
	if( ![ds respondsToSelector:@selector(numberPointsInPlot:)] || 
	    ![ds respondsToSelector:@selector(plotter:index:x:y:)]) {
		ds = nil;
	}
	dataSource = ds;
}

#pragma mark ***Drawing
- (void) drawData
{
	
	ORAxis*    mXScale = [plotView xScale];
	ORAxis*    mYScale = [plotView yScale];
	
	int numPoints = [dataSource numberPointsInPlot:self];
    if(numPoints == 0) return;
		    
	BOOL aLog = [mYScale isLog];
	BOOL aInt = [mYScale integer];
	double aMinPad = [mYScale minPad];
	
	float width		= [plotView bounds].size.width;
	float chanWidth = width / [mXScale valueRange];
	
	NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
	
	NSBezierPath* theDataPath = [NSBezierPath bezierPath];
	double xValue,yValue;
	float xl,yl;
	long i;
	for (i=0; i<numPoints;++i) {
		[dataSource plotter:self index:i x:&xValue y:&yValue];
		float y = [mYScale getPixAbsFast:yValue log:aLog integer:aInt minPad:aMinPad];
		float x = [mXScale getPixAbs:startTime - xValue]-chanWidth/2.;
		if(i!=0){
			[theDataPath moveToPoint:NSMakePoint(xl,yl)];
			[theDataPath lineToPoint:NSMakePoint(xl,y)];
			[theDataPath lineToPoint:NSMakePoint(x,y)];
			xl = x;
			yl = y;
		}
		else {
			[theDataPath moveToPoint:NSMakePoint(0,y)];
			xl = 0;
			yl = y;
		}

	}
	[[self lineColor] set];
	[theDataPath setLineWidth:[self lineWidth]];
	[theDataPath stroke];
}

- (void) drawExtras 
{		
	if([plotView commandKeyIsDown] && showCursorPosition){

		ORTimeAxis*    mXScale = [plotView xScale];
		float height = [plotView bounds].size.height;
		float width  = [plotView bounds].size.width;
		NSFont* font = [NSFont systemFontOfSize:12.0];
		NSDictionary* attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,[NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:.8],NSBackgroundColorAttributeName,nil];
				 
		float secondsInPast = cursorPosition.x;
		float x = [mXScale getPixAbs:secondsInPast];
		
		[[NSColor blackColor] set];
		[NSBezierPath setDefaultLineWidth:.75];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x,0) toPoint:NSMakePoint(x,height)];
		
		NSCalendarDate* date = [NSCalendarDate dateWithTimeIntervalSince1970:(NSTimeInterval)([[NSDate date] timeIntervalSince1970]-secondsInPast)];
		[date setCalendarFormat:@"%m/%d/%y %H:%M:%S"];
		NSString* cursorPositionString = [NSString stringWithFormat:@"%@",date];
		NSAttributedString* s = [[NSAttributedString alloc] initWithString:cursorPositionString attributes:attrsDictionary];
		NSSize labelSize = [s size];
		[s drawAtPoint:NSMakePoint(width - labelSize.width - 10,height-labelSize.height-5)];
		[s release];
	}
}

#pragma mark ***Conversions
- (void) showCrossHairsForEvent:(NSEvent*)theEvent
{
	NSPoint plotPoint = [self convertFromWindowToPlot:[theEvent locationInWindow]];;
	int secondsInPast = plotPoint.x;
	showCursorPosition = YES;
	cursorPosition = NSMakePoint(secondsInPast,0);
	[[plotView xScale] setNeedsDisplay:YES];	
	[plotView setNeedsDisplay:YES];	
}

- (NSPoint) convertFromWindowToPlot:(NSPoint)aWindowLocation
{
	ORAxis* mXScale = [plotView xScale];
	ORAxis* mYScale = [plotView yScale];
	float width		= [plotView bounds].size.width;
	float chanWidth = width / [mXScale valueRange];
	NSPoint p = [plotView convertPoint:aWindowLocation fromView:nil];
	NSPoint result;
	result.x = floor([mXScale getValAbs:p.x + chanWidth/2.]);
	result.y = [mYScale getValAbs:p.x];
	return result;
}
@end					
