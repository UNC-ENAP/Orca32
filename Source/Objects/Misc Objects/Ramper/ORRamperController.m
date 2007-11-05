//
//  ORRamperController.m
//  test
//
//  Created by Mark Howe on 3/29/07.
//  Copyright 2007 CENPA, University of Washington. All rights reserved.
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


#import "ORRamperController.h"
#import "ORRamperModel.h"
#import "ORAxis.h"
#import "ORHWWizard.h"
#import "ORReadOutList.h"
#import "ORRampItem.h"
#import "ZFlowLayout.h"

#define ORHardwareWizardItem @"ORHardwareWizardItem"

@implementation ORRamperController
- (id) init
{
    self = [super initWithWindowNibName:@"Ramper"];
    return self;
}

- (void) dealloc
{
	NSArray* allViews = [rampItemContentView subviews];
	[allViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[rampItemControllers release];
	[super dealloc];
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	NSMutableArray* rampItems = [model rampItems];
	NSEnumerator* e = [rampItems objectEnumerator];
	ORRampItem* anItem;
	while(anItem = [e nextObject]){
		[self addRampItem:anItem];
	}
}

#pragma mark ���Interface Management
- (ORRampItem*) selectedRampItem
{
	return [model selectedRampItem];
}

- (NSView*) rampItemContentView
{
    return rampItemContentView;
}


- (void) addRampItem:(ORRampItem*)anItem
{
	if(!rampItemControllers)rampItemControllers = [[NSMutableArray alloc] init];

	ORRampItemController* itemController = [anItem makeController:self];
	NSView*     newView = [itemController view];
	[rampItemControllers addObject:itemController];
	[rampItemContentView setSizing:ZMakeFlowLayoutSizing( [newView frame].size, 5, 0, YES )];
	[rampItemContentView addSubview: newView];
}

- (void) removeRampItem:(ORRampItem*)anItem
{
	NSEnumerator* e = [rampItemControllers objectEnumerator];
	ORRampItemController* itemController;
	NSSize itemSize;
	while(itemController = [e nextObject]){
		if([itemController model] == anItem){
			[itemController retain];
			[rampItemControllers removeObject:itemController];
			NSView* aView = [itemController view];
			[rampItemContentView setSizing:ZMakeFlowLayoutSizing( [aView frame].size, 5, 0, YES )];
			itemSize = [aView frame].size;
			[aView removeFromSuperview];
			[itemController release];
			break;
		}
	}
}

- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
		
    [notifyCenter addObserver : self
                     selector : @selector(listLockChanged:)
                         name : ORRamperObjectListLock
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(listLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];

    [notifyCenter addObserver : self
					 selector : @selector(rampItemAdded:)
						 name : ORRamperItemAdded
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(rampItemRemoved:)
						 name : ORRamperItemRemoved
					   object : model];

    [notifyCenter addObserver : self
                     selector : @selector(downRampPathChanged:)
                         name : ORRampItemDownRampPathChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(downRateChanged:)
                         name : ORRampItemDownRateChanged
                       object : nil];

    [notifyCenter addObserver : self
					 selector : @selector(updateView:)
						 name : ORRampItemRunningChanged
					   object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(updateView:)
                         name : ORRampItemForceUpdate
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(updateView:)
                         name : ORRamperNeedsUpdate
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(numberRunningChanged:)
                         name : ORRampItemRunningChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(selectionChanged:)
                         name : ORRamperSelectionChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(selectionChanged:)
                         name : ORRampItemCrateNumberChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(selectionChanged:)
                         name : ORRampItemCardNumberChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(selectionChanged:)
                         name : ORRampItemChannelNumberChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(selectionChanged:)
                         name : ORRampItemTargetNameChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(selectionChanged:)
                         name : ORRampItemTargetChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(globalEnabledChanged:)
                         name : ORRampItemGlobalEnabledChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(currentValueChanged:)
                         name : ORRampItemCurrentValueChanged
                       object : nil];


}

- (void) updateWindow
{
	[super updateWindow];
	[self downRampPathChanged:nil];
	[self downRateChanged:nil];
	[self numberRunningChanged:nil];
	[self globalEnabledChanged:nil];
	[self selectionChanged:nil];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"Ramper %d",[model uniqueIdNumber]]];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORRamperObjectListLock to:secure];
    [listLockButton setEnabled:secure];
}

- (void) downRateChanged:(NSNotification*)aNote
{
	[downRateTextField setFloatValue:[[model selectedRampItem] downRate]];
}

- (void) downRampPathChanged:(NSNotification*)aNote
{
	[downRampPathMatrix selectCellWithTag:[[model selectedRampItem] downRampPath]];
}

- (void) listLockChanged:(NSNotification*)aNote
{
    BOOL locked = [gSecurity isLocked:ORRamperObjectListLock];
    [listLockButton setState: locked];
    
    [self setButtonStates];
}

- (void) globalEnabledChanged:(NSNotification*)aNote
{
	[self setButtonStates];
}

- (void) numberRunningChanged:(NSNotification*)aNote
{
	[numberRunningField setIntValue:[model runningCount]];
	[self setButtonStates];
}

- (void) rampItemAdded:(NSNotification*)aNote
{
	ORRampItem* aRampItem = [[aNote userInfo] objectForKey:@"RampItem"];
	[self addRampItem:aRampItem];
}

- (void) rampItemRemoved:(NSNotification*)aNote
{
	ORRampItem* aRampItem = [[aNote userInfo] objectForKey:@"RampItem"];
	[self removeRampItem:aRampItem];
}

- (void) selectionChanged:(NSNotification*)aNote
{
	[self setButtonStates];
	ORRampItem* item = [model selectedRampItem];
	[titleField setStringValue:[NSString stringWithFormat:@"%@",[item itemName]]];
}

- (void) setButtonStates
{
	BOOL locked = [gSecurity isLocked:ORRamperObjectListLock];
	BOOL lockedOrRunning = locked | [[model selectedRampItem] isRunning];
	[downRampPathMatrix setEnabled:!lockedOrRunning];
	[downRateTextField setEnabled:!lockedOrRunning];
	[linearButton setEnabled:!lockedOrRunning];
	[logButton setEnabled:!lockedOrRunning];
	[scaleToMaxButton setEnabled:!lockedOrRunning];
	[scaleToTargetButton setEnabled:!lockedOrRunning];
	int enabledCount = [model enabledCount];
	[startButton setEnabled:enabledCount>0];
	[stopButton setEnabled:enabledCount>0];
}


- (void) rescaleTo:(float)aMax scaleTarget:(BOOL)scaleTarget
{

}

- (void) updateView:(NSNotification*)aNote
{
	[ramperView setNeedsDisplay:YES];
}

- (void) currentValueChanged:(NSNotification*)aNote
{
	if([aNote object] == [model selectedRampItem]){
		[ramperView setNeedsDisplay:YES];
	}
}

- (id) model
{
	return model;
}

- (ORAxis*) xAxis
{
	return xAxis;
}

- (ORAxis*) yAxis
{
	return yAxis;
}

- (IBAction) startGlobalAction:(id)sender
{
	[model startGlobalRamp];
}

- (IBAction) stopGlobalAction:(id)sender
{
	[model stopGlobalRamp];
}

- (IBAction) downRampPathAction:(id)sender
{
	[[model selectedRampItem]  setDownRampPath: [[sender selectedCell] tag]];	
}

- (IBAction) downRateTextFieldAction:(id)sender
{
	[[model selectedRampItem]  setDownRate:[sender floatValue]];	
}

- (IBAction) rescaleToMax:(id)sender
{
    [[model selectedRampItem]  rescaleToMax];
	[ramperView setNeedsDisplay:YES];
}

- (IBAction) rescaleToTarget:(id)sender
{
    [[model selectedRampItem]  rescaleToTarget];
	[ramperView setNeedsDisplay:YES];
}

- (IBAction) listLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORRamperObjectListLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) makeLinear:(id)sender
{
	[[model selectedRampItem]  makeLinear];
	[ramperView setNeedsDisplay:YES];
}

- (IBAction) makeLog:(id)sender
{
	[[model selectedRampItem]  makeLog];
	[ramperView setNeedsDisplay:YES];
}

- (IBAction) panic:(id)sender
{
    NSBeginAlertSheet(@"Global Panic!",@"Cancel",@"YES/Do Panic",nil,[self window],self,@selector(sheetDidEnd:returnCode:contextInfo:),nil,nil, @"REALLY Panic all enabled parameters to zero?\nIs this really what you want?");
}

- (void) sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode == NSAlertAlternateReturn){
		[model startGlobalPanic];
	}
}
@end

