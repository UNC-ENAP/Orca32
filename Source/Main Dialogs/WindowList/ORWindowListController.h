//
//  ORWindowListController.h
//  Orca
//
//  Created by Mark Howe on Fri Mar 8 2007.
//  Copyright (c) 2007 CENPA, University of Washington. All rights reserved.
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

@interface ORWindowListController : NSWindowController {
	IBOutlet NSView* listView;
}

#pragma mark ���Initialization
+ (id) sharedWindowListController;
- (id) init;
- (NSButton*) addButtonForWindow:(NSWindow*)aWindow  index:(int)index;
- (void) setUpControls;
- (void) resizeWindowToSize:(NSSize)newSize;
- (void) windowClosing:(NSNotification*)aNote;
- (void) windowOpening:(NSNotification*)aNote;
- (IBAction) bringToFront:(id)sender;
@end



