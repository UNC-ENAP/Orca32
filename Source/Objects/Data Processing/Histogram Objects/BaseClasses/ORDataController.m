//
//  ORDataController.m
//  Orca
//
//  Created by Mark Howe on Tue Dec 09 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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

#import "ORDataController.h"
#import "ORDataSetModel.h"
#import "ORPlotView.h"
#import "ORAxis.h"
#import "ORCARootServiceDefs.h"

@interface ORDataController (private)
- (void) _clearSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;
@end

@implementation ORDataController

- (id) init
{
	self = [super init];
	RemoveORCARootWarnings; //a #define from ORCARootServiceDefs.h 
	return self;
}

- (void) dealloc 
{
    [super dealloc];
}

- (void) awakeFromNib
{
    NSSize minSize = [[self window] minSize];
    minSize.height = 300;
    [[self window] setMinSize:minSize];
    [super awakeFromNib];
}

- (BOOL) acceptsFirstResponder
{
    return YES;
}

- (id) plotView
{
	return plotView;
}

- (void) flagsChanged:(NSEvent*)inEvent
{
	[[self window] resetCursorRects];
}

// this is needed too because the modifiers can change 
// when it's not main without it being told
- (void) windowDidBecomeMain:(NSNotification*)inNot
{
	[[self window] resetCursorRects];
}	

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(dataSetChanged:)
                         name : ORModelChangedNotification
                       object : self];
    
    [notifyCenter addObserver : self
                     selector : @selector(dataSetRemoved:)
                         name : ORDataSetModelRemoved
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(dataSetChanged:)
                         name : ORDataSetDataChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(drawerDidOpen:)
                         name : NSDrawerDidOpenNotification
                       object : analysisDrawer];
	
	[notifyCenter addObserver : self
                     selector : @selector(drawerDidClose:)
                         name : NSDrawerDidCloseNotification
                       object : analysisDrawer];
	
	[notifyCenter addObserver : self
					 selector : @selector(scaleAction:)
						 name : ORAxisRangeChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(miscAttributesChanged:)
						 name : ORMiscAttributesChanged
					   object : model];
					   
    [notifyCenter addObserver : self
					 selector : @selector(refreshModeChanged:)
						 name : ORDataSetModelRefreshModeChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(pausedChanged:)
						 name : ORDataSetModelPausedChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(calibrationChanged:)
						 name : ORDataSetCalibrationChanged
					   object : model];
	

    [notifyCenter addObserver : self
					 selector : @selector(serviceResponse:)
						 name : ORCARootServiceReponseNotification
					   object : nil];
	
}

- (void) updateWindow
{
	[super updateWindow];
    [self dataSetChanged:nil];
    [self refreshModeChanged:nil];
    [self pausedChanged:nil];
    [self miscAttributesChanged:nil];
}

- (NSTextField*) titleField
{
	return titleField;
}

- (void) serviceResponse:(NSNotification*)aNotification
{
	NSMutableDictionary* reponseInfo = [[aNotification userInfo] objectForKey:ORCARootServiceResponseKey];
	[reponseInfo setObject:[[self window] title] forKey:ORCARootServiceTitleKey];
	[model processResponse:reponseInfo];
}

- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [plotView xScale]){
		ORAxis* axis = [plotView xScale];
		[model setMiscAttributes:[axis attributes] forKey:@"XAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotView yScale]){
		ORAxis* axis = [plotView yScale];
		[model setMiscAttributes:[axis attributes] forKey:@"YAttributes"];
	};
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{
	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"XAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes"];
		if(attrib){
			ORAxis* axis = [plotView xScale];
			[axis setAttributes:attrib];
			[plotView setNeedsDisplay:YES];
			[[plotView xScale] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"YAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes"];
		if(attrib){
			ORAxis* axis = [plotView yScale];
			[axis setAttributes:attrib];
			[plotView setNeedsDisplay:YES];
			[[plotView yScale] setNeedsDisplay:YES];
		}
	}
}

- (void) calibrationChanged:(NSNotification*)aNotification
{
	[[plotView xScale] setNeedsDisplay:YES];
}

- (void) dataSetChanged:(NSNotification*)aNotification
{
    if(!aNotification || [aNotification object] == model || [aNotification object] == self){
        [plotView setNeedsDisplay:YES];
		@synchronized(model){
			[rawDataTable reloadData];
		}
    }
}

- (void) refreshModeChanged:(NSNotification*)aNotification
{
	[refreshModePU selectItemAtIndex:[model refreshMode]];
}

- (void) pausedChanged:(NSNotification*)aNotification
{
	[refreshButton setEnabled:![model paused]];
	[pausedField setStringValue:[model paused]?@"Paused":@""];
	[pauseButton setTitle:[model paused]?@"Update":@"Pause"];
}

- (void) dataSetRemoved:(NSNotification*)aNote
{
    if([aNote object] == model){
        [[self window] close];
    }
}

- (void)drawerDidOpen:(NSNotification *)aNotification
{
    if([aNotification object] == analysisDrawer){
        [plotView enableCursorRects];  
		[plotView becomeFirstResponder];
        [plotView setNeedsDisplay:YES];    
    }
}

- (void)drawerDidClose:(NSNotification *)aNotification
{
    if([aNotification object] == analysisDrawer){
		[plotView disableCursorRects];    
		[plotView setNeedsDisplay:YES];  
    }
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    if([aModel fullName]){
        [[self window] setTitle:[aModel fullName]];
        [titleField setStringValue:[aModel fullNameWithRunNumber]];
    }
}

#pragma mark •••Accessors
- (id) analysisDrawer
{
	return analysisDrawer;
}
- (BOOL) analysisDrawerIsOpen
{
	return [analysisDrawer state] == NSDrawerOpenState;
}

- (void) openAnalysisDrawer
{
	[analysisDrawer open];
}

- (void) closeAnalysisDrawer
{
	[analysisDrawer close];
}
- (IBAction) refreshModeAction:(id)sender 
{
	[model setRefreshMode:[sender indexOfSelectedItem]];
}

- (IBAction) pauseAction:(id)sender 
{
	[model setPaused:[sender intValue]];
}

- (IBAction)clear:(NSToolbarItem*)item 
{
    NSBeginAlertSheet(@"Clear Counts",
                      @"Cancel",
                      @"Yes/Clear It",
                      nil,[self window],
                      self,
                      @selector(_clearSheetDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"Really Clear them? You will not be able to undo this.");
}

- (IBAction)doAnalysis:(NSToolbarItem*)item
{
	[analysisDrawer toggle:self];
}

- (IBAction) toggleRaw:(NSToolbarItem*)item
{
	int index = [rawDataTabView indexOfTabViewItem:[rawDataTabView selectedTabViewItem]];
	int maxIndex = [rawDataTabView numberOfTabViewItems];
	index++;
	if(index>=maxIndex)index = 0;
	[rawDataTabView selectTabViewItemAtIndex:index];
}

- (IBAction) printDocument:(id)sender
{
	NSPrintInfo* printInfo = [NSPrintInfo sharedPrintInfo];
	NSPrintOperation* printOp = [NSPrintOperation printOperationWithView:plotterGroupView printInfo:printInfo];
#if MAC_OS_X_VERSION_10_5 <= MAC_OS_X_VERSION_MIN_ALLOWED
    [printOp setShowPanels:YES];
#endif
	[printOp runOperation];
}

- (IBAction) hideShowControls:(id)sender
{
	
    unsigned int oldResizeMask = [containingView autoresizingMask];
    [containingView setAutoresizingMask:NSViewMinYMargin];
	
    NSRect aFrame = [NSWindow contentRectForFrameRect:[[self window] frame] 
											styleMask:[[self window] styleMask]];
    NSSize minSize = [[self window] minSize];
    if([hideShowButton state] == NSOnState){
        aFrame.size.height += 85;
        minSize.height = 300;
    }
    else {
        aFrame.size.height -= 85;
        minSize.height = 300-85;
    }
    [[self window] setMinSize:minSize];
    [self resizeWindowToSize:aFrame.size];
    [containingView setAutoresizingMask:oldResizeMask];
}

//scripting helper
- (void) savePlotToFile:(NSString*)aFile
{
	aFile = [aFile stringByExpandingTildeInPath];
	NSFileManager* fm = [NSFileManager defaultManager];
	if([fm fileExistsAtPath:aFile]){
		[fm removeItemAtPath:aFile error:nil];
	}
	NSData* pdfData = [plotView plotAsPDFData];
	[pdfData writeToFile:aFile atomically:NO];
}
@end
@implementation ORDataController (private)

- (void) _clearSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{
    if(returnCode == NSAlertAlternateReturn){
        [model clear];
        [plotView setNeedsDisplay:YES];
		[rawDataTable reloadData];
    }
}
@end

@implementation NSObject (ORDataController_Cat)
- (int) numberBins
{
    return 0;
}

- (long) value:(unsigned short)aChan;
{
    return 0;
}
@end

