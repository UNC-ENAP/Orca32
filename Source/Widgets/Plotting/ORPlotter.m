//
//  ORPlotter.m
//  Orca
//
//  Created by Mark Howe on 6/25/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
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

#import "ORPlotter.h"
#import "CTGradient.h"
#import "ORFlippedView.h"

NSString* ORPlotterBackgroundColor	= @"ORPlotterBackgroundColor";
NSString* ORPlotterGridColor		= @"ORPlotterGridColor";

@implementation ORPlotter
-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [gradient release];
    [super dealloc];
}

#pragma mark •••Accessors
- (NSMutableDictionary *)attributes 
{
    return attributes; 
}

- (void)setAttributes:(NSMutableDictionary *)anAttributes 
{
    [anAttributes retain];
    [attributes release];
    attributes = anAttributes;
}

- (ORAxis*) xScale
{
    return mXScale;
}
- (void) setXScale:(ORAxis*)newXScale
{
    [mXScale autorelease];
    mXScale=[newXScale retain];
}

- (ORAxis*) yScale
{
    return mYScale;
}
- (void) setYScale:(ORAxis*)newYScale
{
    [mYScale autorelease];
    mYScale=[newYScale retain];
}

- (BOOL) useGradient
{
	return [[attributes objectForKey:@"useGradient"] boolValue];
}

- (void) setUseGradient:(BOOL)aFlag
{
    [attributes setObject:[NSNumber numberWithBool:aFlag] forKey:@"useGradient"];	
	[self setNeedsDisplay:YES];
}


- (BOOL) analyze
{
    return analyze;
}

- (void) setAnalyze:(BOOL)newAnalyze
{
    analyze=newAnalyze;
    if(analyze)[self analyze:self];
}

- (IBAction) analyze:(id)sender
{
    [self doAnalysis];
}

- (void) doAnalysis
{
	//subclasses can override
}

- (void)setBackgroundColor:(NSColor *)aColor
{
    [attributes setObject:[NSArchiver archivedDataWithRootObject:aColor] forKey:ORPlotterBackgroundColor];
	[gradient release];
	gradient = nil;
    [self setNeedsDisplay:YES];
    //[mYScale setNeedsDisplay:YES];
    //[mXScale setNeedsDisplay:YES];
}

-(NSColor*)backgroundColor
{
	NSData* d = [attributes objectForKey:ORPlotterBackgroundColor];
	if(!d)return [NSColor whiteColor];
    else return [NSUnarchiver unarchiveObjectWithData:d];
}

- (void)setGridColor:(NSColor *)aColor
{
    [attributes setObject:[NSArchiver archivedDataWithRootObject:aColor] forKey:ORPlotterGridColor];
    [self setNeedsDisplay:YES];
    [mYScale setNeedsDisplay:YES];
    [mXScale setNeedsDisplay:YES];
}

-(NSColor*)gridColor
{
	NSData* d = [attributes objectForKey:ORPlotterGridColor];
	if(!d) return [NSColor grayColor];
    else return [NSUnarchiver unarchiveObjectWithData:d];
}

- (BOOL)isOpaque
{
    return YES;
}

- (id)dataSource
{
    return mDataSource;
}

#pragma mark •••Drawing
- (void) drawBackground
{
	NSRect bounds = [self bounds];

	if([self useGradient]){
		if(!gradient){
			float red,green,blue,alpha;
			NSColor* color = [self backgroundColor];
			color = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
			[color getRed:&red green:&green blue:&blue alpha:&alpha];
			
			red *= .75;
			green *= .75;
			blue *= .75;
			//alpha = .75;
			
			NSColor* endingColor = [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:alpha];
			
			[gradient release];
			gradient = [[CTGradient gradientWithBeginningColor:color endingColor:endingColor] retain];
		}
		[gradient fillRect:bounds angle:270.];
	}
	else {
		[[self backgroundColor] set];
		[NSBezierPath fillRect:bounds];
	}
	[[NSColor darkGrayColor] set];
	[NSBezierPath strokeRect:bounds];
}

#pragma mark •••SubClasses Will Override
- (void)setDataSource:(id)d
{
	//subclasses need to override
}

- (void) initCurves
{
	//subclasses need to override
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder *)coder
{
    self =  [super initWithCoder:coder];
    [[self undoManager] disableUndoRegistration];
    if([coder allowsKeyedCoding]){
        [self setAttributes:[coder decodeObjectForKey:@"attributes"]];
    }
    else {
        [self setAttributes:[coder decodeObject]];
    }
	
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    if([coder allowsKeyedCoding]){
        [coder encodeObject:attributes forKey:@"attributes"];
    }
    else {
        [coder encodeObject:attributes];
    }
}

@end
