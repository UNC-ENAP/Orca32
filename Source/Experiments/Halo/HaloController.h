//
//  HaloController.h
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

#import "ORExperimentController.h"
#import "HaloDetectorView.h"

@class ORColorScale;
@class ORSegmentGroup;

@interface HaloController : ORExperimentController {
 
    IBOutlet NSTextField*	detectorTitle;
    IBOutlet NSPopUpButton*	viewTypePU;

	NSView *blankView;
    NSSize detectorSize;
    NSSize detailsSize;
    NSSize focalPlaneSize;
}

#pragma mark ���Initialization
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) loadSegmentGroups;

- (IBAction) viewTypeAction:(id)sender;

#pragma mark ���Details Interface Management
- (void) setDetectorTitle;
- (void) viewTypeChanged:(NSNotification*)aNote;
- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)tabViewItem;

@end
@interface ORDetectorView (Halo)
- (void) setViewType:(int)aState;
@end
