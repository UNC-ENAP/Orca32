//
//  SNOPController.m
//  Orca
//
//  Created by Mark Howe on Tue Apr 20, 2010.
//  Copyright (c) 2010  University of North Carolina. All rights reserved.
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
#import "SNOPController.h"
#import "SNOPModel.h"
#import "ORColorScale.h"
#import "ORAxis.h"
#import "ORDetectorSegment.h"

@implementation SNOPController
#pragma mark ���Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"SNOP"];
    return self;
}


- (NSString*) defaultPrimaryMapFilePath
{
	return @"~/SNOP";
}


-(void) awakeFromNib
{
	detectorSize		= NSMakeSize(620,595);
	detailsSize		= NSMakeSize(450,589);
	focalPlaneSize		= NSMakeSize(450,589);
	couchDBSize		= NSMakeSize(450,500);
	monitoringSize		= NSMakeSize(620,595);
	slowControlSize		= NSMakeSize(620,595);
	
	blankView = [[NSView alloc] init];
	[self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];

	[super awakeFromNib];
}


#pragma mark ���Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];

    [notifyCenter addObserver : self
                     selector : @selector(viewTypeChanged:)
                         name : ORSNOPModelViewTypeChanged
			object: model];
}

- (void) updateWindow
{
	[super updateWindow];
	[self viewTypeChanged:nil];
}

- (void) viewTypeChanged:(NSNotification*)aNote
{
	[viewTypePU selectItemAtIndex:[model viewType]];
	[detectorView setViewType:[model viewType]];
	[detectorView makeAllSegments];	
}

- (void) morcaUserNameChanged:(NSNotification*)aNote
{
    
}

- (void) morcaPasswordChanged:(NSNotification*)aNote
{
    
}

- (void) morcaDBNameChanged:(NSNotification*)aNote
{
    
}

- (void) morcaPortChanged:(NSNotification*)aNote
{
    
}

- (void) morcaIPAddressChanged:(NSNotification*)aNote
{
    
}

- (void) morcaIsVerboseChanged:(NSNotification*)aNote
{
    
}

- (void) morcaIsWithinRunChanged:(NSNotification*)aNote
{
    
}

- (void) morcaUpdateRateChanged:(NSNotification*)aNote
{
    
}

- (void) morcaStatusChanged:(NSNotification*)aNote
{
    
}

#pragma mark ���Interface Management
- (IBAction) viewTypeAction:(id)sender
{
	[model setViewType:[sender indexOfSelectedItem]];
}

- (IBAction)morcaUserNameAction:(id)sender {
}

- (IBAction)morcaPasswordAction:(id)sender {
}

- (IBAction)morcaDBNameAction:(id)sender {
}

- (IBAction)morcaPortAction:(id)sender {
}

- (IBAction)morcaIPAddressAction:(id)sender {
}

- (IBAction)morcaClearHistoryAction:(id)sender {
}

- (IBAction)morcaFutonAction:(id)sender {
}

- (IBAction)morcaTestAction:(id)sender {
}

- (IBAction)morcaPingAction:(id)sender {
}

- (IBAction)morcaUpdateNowAction:(id)sender {
}

- (IBAction)morcaStartAction:(id)sender {
}

- (IBAction)morcaStopAction:(id)sender {
}

- (IBAction)morcaIsVerboseAction:(id)sender {
}

- (IBAction)morcaUpdateRateAction:(id)sender {
}

- (IBAction)morcaUpdateWithinRunAction:(id)sender {
}


- (void) specialUpdate:(NSNotification*)aNote
{
	[super specialUpdate:aNote];
	[detectorView makeAllSegments];
}

- (void) setDetectorTitle
{	
	switch([model displayType]){
		case kDisplayRates:		[detectorTitle setStringValue:@"Detector Rate"];	break;
		case kDisplayThresholds:	[detectorTitle setStringValue:@"Thresholds"];		break;
		case kDisplayTotalCounts:	[detectorTitle setStringValue:@"Total Counts"];		break;
		default: break;
	}
}

#pragma mark ���Details Interface Management
- (void) detailsLockChanged:(NSNotification*)aNotification
{
	[super detailsLockChanged:aNotification];
	BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[model experimentDetailsLock]];
	BOOL locked = [gSecurity isLocked:[model experimentDetailsLock]];

	[detailsLockButton setState: locked];
	[initButton setEnabled: !lockedOrRunningMaintenance];
}

#pragma mark ���Table Data Source

- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)tabViewItem
{
	
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:detectorSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 1){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:detailsSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 2){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:focalPlaneSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 3){
	    [[self window] setContentView:blankView];
	    [self resizeWindowToSize:couchDBSize];
	    [[self window] setContentView:tabView];
    }
/*
    else if([tabView indexOfTabViewItem:tabViewItem] == 4){
	    [[self window] setContentView:blankView];
	    [self resizeWindowToSize:monitoringSize];
	    [[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 5){
	    [[self window] setContentView:blankView];
	    [self resizeWindowToSize:slowControlSize];
	    [[self window] setContentView:tabView];
    }
*/	
	int index = [tabView indexOfTabViewItem:tabViewItem];
	[[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"orca.SNOPController.selectedtab"];
}

@end
