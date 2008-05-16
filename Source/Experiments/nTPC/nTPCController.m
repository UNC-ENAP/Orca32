//
//  nTPCController.m
//  Orca
//
//  Created by Mark Howe on Wed Aug 15 2007.
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
#import "nTPCController.h"
#import "nTPCModel.h"
#import "nTPCConstants.h"
#import "ORColorScale.h"
#import "ORAxis.h"
#import "ORDetectorSegment.h"
#import "ORSegmentGroup.h"
#import "ORDetectorView.h"

@interface nTPCController (private)
- (void) readSecondaryMapFilePanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) saveSecondaryMapFilePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
@end

@implementation nTPCController
#pragma mark ���Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"nTPC"];
    return self;
}

- (void) loadSegmentGroups
{
	//primary group are the anode wires
	if(!segmentGroups)segmentGroups = [[NSMutableArray array] retain];
	ORSegmentGroup* aGroup = [model segmentGroup:0];
	if(![segmentGroups containsObject:aGroup]){
		[segmentGroups addObject:aGroup];
	}
	//secondary group cathod wires
	aGroup = [model segmentGroup:1];
	if(![segmentGroups containsObject:aGroup]){
		[segmentGroups addObject:aGroup];
		secondaryGroup = aGroup;
	}

}

- (NSString*) defaultPrimaryMapFilePath
{
	return @"~/AnodeWireMap";
}
- (NSString*) defaultSecondaryMapFilePath
{
	return @"~/CathodWireMap";
}


-(void) awakeFromNib
{
	
	[anodeScale setRngLimitsLow:0 withHigh:127 withMinRng:127];
    [anodeScale setRngDefaultsLow:0 withHigh:127];

	[cathodeScale setRngLimitsLow:0 withHigh:63 withMinRng:63];
    [cathodeScale setRngDefaultsLow:0 withHigh:63];

	[self populateClassNamePopup:secondaryAdcClassNamePopup];
    [super awakeFromNib];
		
}


#pragma mark ���Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    

    [notifyCenter addObserver : self
                     selector : @selector(secondaryAdcClassNameChanged:)
                         name : ORSegmentGroupAdcClassNameChanged
						object: secondaryGroup];


    [notifyCenter addObserver : self
                     selector : @selector(secondaryMapFileChanged:)
                         name : ORSegmentGroupMapFileChanged
						object: secondaryGroup];
}

- (void) updateWindow
{
    [super updateWindow];
	
	//hw map
	[self secondaryMapFileChanged:nil];
	[self secondaryAdcClassNameChanged:nil];

	//details
	[secondaryValuesView reloadData];
}

#pragma mark ���HW Map Actions
- (IBAction) clrSelectionAction:(id)sender
{
	[detectorView clrSelection];
}

- (IBAction) viewDialogAction:(id)sender
{
	[detectorView showSelectedDialog];
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
- (void) specialUpdate:(NSNotification*)aNote
{
	[super specialUpdate:aNote];
	[secondaryValuesView reloadData];
}

- (void) setDetectorTitle
{	
	switch([model displayType]){
		case kDisplayEvents:		[detectorTitle setStringValue:@"Displaying Events"];			break;
		case kDisplayRates:			[detectorTitle setStringValue:@"Displaying Detector Rate"];		break;
		case kDisplayThresholds:	[detectorTitle setStringValue:@"Displaying Thresholds"];		break;
		case kDisplayGains:			[detectorTitle setStringValue:@"Displaying Gains"];				break;
		default: break;
	}
}

- (void) newTotalRateAvailable:(NSNotification*)aNotification
{
	[super newTotalRateAvailable:aNotification];
	[secondaryRateField setFloatValue:[secondaryGroup rate]];
}

#pragma mark ���HW Map Interface Management
- (void) selectionChanged:(NSNotification*)aNote
{
	[clrSelectionButton setEnabled:[model somethingSelected]];

	if([[[model segmentGroup:[detectorView selectedSet]] segment:[detectorView selectedPath]] hardwarePresent]){
		[showDialogButton setEnabled:[model somethingSelected]];
	}
	else [showDialogButton setEnabled:NO];
}

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


- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item
{
    int index = [tabView indexOfTabViewItem:item];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"orca.nTPCController.selectedtab"];
}

@end

@implementation nTPCController (Private)
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