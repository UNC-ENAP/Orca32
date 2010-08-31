//
//  KatrinController.m
//  Orca
//
//  Created by Mark Howe on Tue Jun 28 2005.
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
#import "KatrinController.h"
#import "KatrinModel.h"
#import "KatrinConstants.h"
#import "ORColorScale.h"
#import "ORTimeAxis.h"
#import "ORDetectorSegment.h"
#import "ORSegmentGroup.h"
#import "ORPlotView.h"
#import "ORTimeLinePlot.h"
#import "OR1DHistoPlot.h"

@interface KatrinController (private)
- (void) readSecondaryMapFilePanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) saveSecondaryMapFilePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
@end

@implementation KatrinController
#pragma mark ���Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"Katrin"];
    return self;
}

- (void) loadSegmentGroups
{
	//primary group is the focal plane
	if(!segmentGroups)segmentGroups = [[NSMutableArray array] retain];
	ORSegmentGroup* aGroup = [model segmentGroup:0];
	if(![segmentGroups containsObject:aGroup]){
		[segmentGroups addObject:aGroup];
	}
	//secondary group is the veto
	aGroup = [model segmentGroup:1];
	if(![segmentGroups containsObject:aGroup]){
		[segmentGroups addObject:aGroup];
		secondaryGroup = aGroup;
	}

}

- (NSString*) defaultPrimaryMapFilePath
{
	return @"~/FocalPlaneMap";
}
- (NSString*) defaultSecondaryMapFilePath
{
	return @"~/VetoMap";
}


-(void) awakeFromNib
{
	
	detectorSize		= NSMakeSize(675,600);
	slowControlsSize    = NSMakeSize(525,157);
	detailsSize			= NSMakeSize(655,589);
	focalPlaneSize		= NSMakeSize(827,589);
	vetoSize			= NSMakeSize(463,589);
	
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];

	
    [super awakeFromNib];
	
	if([secondaryGroup colorAxisAttributes])[[secondaryColorScale colorAxis] setAttributes:[[[secondaryGroup colorAxisAttributes] mutableCopy] autorelease]];

	[[secondaryColorScale colorAxis] setRngLimitsLow:0 withHigh:128000000 withMinRng:5];
    [[secondaryColorScale colorAxis] setRngDefaultsLow:0 withHigh:128000000];
    [[secondaryColorScale colorAxis] setOppositePosition:YES];
	[[secondaryColorScale colorAxis] setNeedsDisplay:YES];

	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:1 andDataSource:self];
	[aPlot setUseConstantColor:YES];
	[ratePlot addPlot: aPlot];
	[aPlot release];
	
	OR1DHistoPlot* aPlot1 = [[OR1DHistoPlot alloc] initWithTag:11 andDataSource:self];
	[valueHistogramsPlot addPlot: aPlot1];
	[aPlot1 release];
	
	
	[self populateClassNamePopup:secondaryAdcClassNamePopup];
		
}


#pragma mark ���Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
					   
    [notifyCenter addObserver : self
                     selector : @selector(secondaryColorAxisAttributesChanged:)
                         name : ORAxisRangeChangedNotification
                       object : [secondaryColorScale colorAxis]];
    

    [notifyCenter addObserver : self
                     selector : @selector(secondaryAdcClassNameChanged:)
                         name : ORSegmentGroupAdcClassNameChanged
						object: secondaryGroup];


    [notifyCenter addObserver : self
                     selector : @selector(secondaryMapFileChanged:)
                         name : ORSegmentGroupMapFileChanged
						object: secondaryGroup];
	
    [notifyCenter addObserver : self
                     selector : @selector(slowControlIsConnectedChanged:)
                         name : KatrinModelSlowControlIsConnectedChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(slowControlNameChanged:)
                         name : KatrinModelSlowControlNameChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(viewTypeChanged:)
                         name : ORKatrinModelViewTypeChanged
						object: model];
	
	
}

- (void) updateWindow
{
    [super updateWindow];

	//detector
    [self secondaryColorAxisAttributesChanged:nil];

	//hw map
	[self secondaryMapFileChanged:nil];
	[self secondaryAdcClassNameChanged:nil];

	//details
	[secondaryValuesView reloadData];
	
	[self slowControlIsConnectedChanged:nil];
	[self slowControlNameChanged:nil];
	[self viewTypeChanged:nil];
}

- (void) viewTypeChanged:(NSNotification*)aNote
{
	[viewTypePU selectItemAtIndex:[model viewType]];
	[detectorView setViewType:[model viewType]];
	[detectorView makeAllSegments];	
}

#pragma mark ���HW Map Actions

- (IBAction) slowControlNameAction:(id)sender
{
	[model setSlowControlName:[sender stringValue]];	
}

- (IBAction) secondaryAdcClassNameAction:(id)sender
{
	[secondaryGroup setAdcClassName:[sender titleOfSelectedItem]];	
}

- (IBAction) readSecondaryMapFileAction:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    NSString* startingDir;
	NSString* fullPath = [[secondaryGroup mapFile] stringByExpandingTildeInPath];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
    }
    [openPanel beginSheetForDirectory:startingDir
                                 file:nil
                                types:nil
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(readSecondaryMapFilePanelDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
}

- (IBAction) saveSecondaryMapFileAction:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save As"];
    [savePanel setCanCreateDirectories:YES];
    
    NSString* startingDir;
    NSString* defaultFile;
    
	NSString* fullPath = [[secondaryGroup mapFile] stringByExpandingTildeInPath];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
        defaultFile = [fullPath lastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
        defaultFile = [self defaultSecondaryMapFilePath];
        
    }
    [savePanel beginSheetForDirectory:startingDir
                                 file:defaultFile
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(saveSecondaryMapFilePanelDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
}

#pragma mark ���Interface Management

- (IBAction) viewTypeAction:(id)sender
{
	[model setViewType:[sender indexOfSelectedItem]];
}

- (void) slowControlNameChanged:(NSNotification*)aNote
{
	[slowControlNameField setStringValue: [model slowControlName]];
}

- (void) slowControlIsConnectedChanged:(NSNotification*)aNote
{
	NSString* s;
	if([model slowControlIsConnected]){
		[slowControlIsConnectedField setTextColor:[NSColor blackColor]];
		[slowControlIsConnectedField1 setTextColor:[NSColor blackColor]];
		s = @"Connected";
	}
	else {
		s = @"NOT Connected";
		[slowControlIsConnectedField setTextColor:[NSColor redColor]];
		[slowControlIsConnectedField1 setTextColor:[NSColor redColor]];
	}	
	[slowControlIsConnectedField setStringValue:s];
	[slowControlIsConnectedField1 setStringValue:s];
}

- (void) specialUpdate:(NSNotification*)aNote
{
	[super specialUpdate:aNote];
	[secondaryValuesView reloadData];
	//if([model viewType] == kUseCrateView){
		[detectorView makeAllSegments];
	//}
}

- (void) setDetectorTitle
{	
	switch([model displayType]){
		case kDisplayRates:			[detectorTitle setStringValue:@"Detector Rate"];	break;
		case kDisplayThresholds:	[detectorTitle setStringValue:@"Thresholds"];		break;
		case kDisplayGains:			[detectorTitle setStringValue:@"Gains"];			break;
		case kDisplayTotalCounts:	[detectorTitle setStringValue:@"Total Counts"];		break;
		default: break;
	}
}

- (void) newTotalRateAvailable:(NSNotification*)aNotification
{
	[super newTotalRateAvailable:aNotification];
	[secondaryRateField setFloatValue:[secondaryGroup rate]];
}

- (void) secondaryColorAxisAttributesChanged:(NSNotification*)aNotification
{
	BOOL isLog = [[secondaryColorScale colorAxis] isLog];
	[secondaryColorAxisLogCB setState:isLog];
	[secondaryGroup setColorAxisAttributes:[[secondaryColorScale colorAxis] attributes]];
}

#pragma mark ���HW Map Interface Management
- (void) secondaryAdcClassNameChanged:(NSNotification*)aNote
{
	[secondaryAdcClassNamePopup selectItemWithTitle: [secondaryGroup adcClassName]];
}

- (void) secondaryMapFileChanged:(NSNotification*)aNote
{
	NSString* s = [secondaryGroup mapFile];
	if(!s) s = @"--";
	[secondaryMapFileTextField setStringValue: s];
}

- (void) mapFileRead:(NSNotification*)aNote
{
	[super mapFileRead:aNote];
    if(aNote == nil || [aNote object] == model){
        [secondaryTableView reloadData];
        [secondaryValuesView reloadData];
    }
}

- (void) mapLockChanged:(NSNotification*)aNotification
{
	[super mapLockChanged:aNotification];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[model experimentDetectorLock]];
    //BOOL runningOrLocked = [gSecurity runInProgressOrIsLocked:ORPrespectrometerLock];
    BOOL locked = [gSecurity isLocked:[model experimentMapLock]];
    [mapLockButton setState: locked];
    
    if(locked){
		[secondaryTableView deselectAll:self];
	}
    [readSecondaryMapFileButton setEnabled:!lockedOrRunningMaintenance];
    [saveSecondaryMapFileButton setEnabled:!lockedOrRunningMaintenance];
	[secondaryAdcClassNamePopup setEnabled:!lockedOrRunningMaintenance]; 
}

#pragma mark ���Details Interface Management
- (void) detailsLockChanged:(NSNotification*)aNotification
{
	[super detailsLockChanged:aNotification];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[model experimentDetailsLock]];
    BOOL locked = [gSecurity isLocked:[model experimentDetailsLock]];

	[detailsLockButton setState: locked];
    [initButton setEnabled: !lockedOrRunningMaintenance];

	if(locked){
		[secondaryValuesView deselectAll:self];
	}

}

#pragma mark ���Table Data Source
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row
{
	if(tableView == secondaryTableView){
		return ![gSecurity isLocked:[model experimentMapLock]];
	}
	else if(tableView == secondaryValuesView){
		return ![gSecurity isLocked:[model experimentDetailsLock]];
	}
	else return [super tableView:tableView shouldSelectRow:row];
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
	if(aTableView == secondaryTableView || aTableView == secondaryValuesView){
		return [secondaryGroup segment:rowIndex objectForKey:[aTableColumn identifier]];
	}
	else return  [super tableView:aTableView objectValueForTableColumn:aTableColumn row:rowIndex];
}

// just returns the number of items we have.
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if( aTableView == secondaryTableView || 
		aTableView == secondaryValuesView)	return [secondaryGroup numSegments];
	else								return [super numberOfRowsInTableView:aTableView];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	ORDetectorSegment* aSegment;
	if(aTableView == secondaryTableView){
		aSegment = [secondaryGroup segment:rowIndex];
		[aSegment setObject:anObject forKey:[aTableColumn identifier]];
		[secondaryGroup configurationChanged:nil];
	}
	else if(aTableView == secondaryValuesView){
		aSegment = [secondaryGroup segment:rowIndex];
		if([[aTableColumn identifier] isEqualToString:@"threshold"]){
			[aSegment setThreshold:anObject];
		}
		else if([[aTableColumn identifier] isEqualToString:@"gain"]){
			[aSegment setGain:anObject];
		}
	}
	else [super tableView:aTableView setObjectValue:anObject forTableColumn:aTableColumn row:rowIndex];
}

- (void) tableView:(NSTableView*)tv didClickTableColumn:(NSTableColumn *)tableColumn
{
//    NSImage *sortOrderImage = [tv indicatorImageInTableColumn:tableColumn];
//    NSString *columnKey = [tableColumn identifier];
    // If the user clicked the column which already has the sort indicator
    // then just flip the sort order.
    
//    if (sortOrderImage || columnKey == [[Prespectrometer sharedInstance] sortColumn]) {
//        [[Prespectrometer sharedInstance] setSortIsDescending:![[Prespectrometer sharedInstance] sortIsDescending]];
//    }
//    else {
///        [[Prespectrometer sharedInstance] setSortColumn:columnKey];
//    }
  //  [self updateTableHeaderToMatchCurrentSort];
    // now do it - doc calls us back when done
//    [[Prespectrometer sharedInstance] sort];
//    [tv reloadData];
}

//- (void) updateTableHeaderToMatchCurrentSort
//{
//    BOOL isDescending = [[Prespectrometer sharedInstance] sortIsDescending];
//    NSString *key = [[Prespectrometer sharedInstance] sortColumn];
//    NSArray *a = [focalPlaneTableView tableColumns];
//    NSTableColumn *column = [focalPlaneTableView tableColumnWithIdentifier:key];
//    unsigned i = [a count];
    
//    while (i-- > 0) [focalPlaneTableView setIndicatorImage:nil inTableColumn:[a objectAtIndex:i]];
    
//    if (key) {
//        [focalPlaneTableView setIndicatorImage:(isDescending ? ascendingSortingImage:descendingSortingImage) inTableColumn:column];
        
//        [focalPlaneTableView setHighlightedTableColumn:column];
//    }
//    else {
//        [focalPlaneTableView setHighlightedTableColumn:nil];
//    }
//}


- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)tabViewItem
{
	float toolBarOffset = 0;
	BOOL toolBarVisible = [[[self window] toolbar] isVisible];
	if(toolBarVisible){
		switch([[[self window] toolbar] sizeMode]){
			case NSToolbarSizeModeRegular:	toolBarOffset = 60; break;
			case NSToolbarSizeModeSmall:	toolBarOffset = 50; break;
			default:						toolBarOffset = 60; break;
		}
	}
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
		[[self window] setContentView:blankView];
		NSSize newSize = detectorSize;
		newSize.height += toolBarOffset;
		[self resizeWindowToSize:newSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 1){
		[[self window] setContentView:blankView];
		NSSize newSize = slowControlsSize;
		newSize.height += toolBarOffset;
		[self resizeWindowToSize:newSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 2){
		[[self window] setContentView:blankView];
		NSSize newSize = detailsSize;
		newSize.height += toolBarOffset;
		[self resizeWindowToSize:newSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 3){
		[[self window] setContentView:blankView];
		NSSize newSize = focalPlaneSize;
		newSize.height += toolBarOffset;
		[self resizeWindowToSize:newSize];
		[[self window] setContentView:tabView];
    }
	else if([tabView indexOfTabViewItem:tabViewItem] == 4){
		[[self window] setContentView:blankView];
		NSSize newSize = vetoSize;
		newSize.height += toolBarOffset;
		[self resizeWindowToSize:newSize];
		[[self window] setContentView:tabView];
    }
	int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"orca.KatrinController.selectedtab"];
}

@end

@implementation KatrinController (Private)
- (void)readSecondaryMapFilePanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        [secondaryGroup setMapFile:[[[sheet filenames] objectAtIndex:0] stringByAbbreviatingWithTildeInPath]];
		[secondaryGroup readMap];
		[secondaryTableView reloadData];

    }
}
- (void)saveSecondaryMapFilePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        [secondaryGroup saveMapFileAs:[sheet filename]];
    }
}
@end