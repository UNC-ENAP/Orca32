//
//  ORAnalysisPanel2D.h
//  testplot
//
//  Created by Mark Howe on Mon, Mar 17 2008.
//  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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


@class ORGate2D;

@interface ORAnalysisPanel2D : NSObject {
    IBOutlet NSView*			view;
    IBOutlet NSTextField*       curveField;
    IBOutlet NSTextField*       gateField;
    IBOutlet NSTextField*       totalSumField;
    IBOutlet NSTextField*       averageField;
    IBOutlet NSTextField*       activeField;
    IBOutlet NSTextField*       gatePeakXField;
    IBOutlet NSTextField*       gatePeakYField;
	
    IBOutlet NSDrawer*		analysisDrawer;
    IBOutlet NSView*		analysisView;

    ORGate2D* gate;
 }

+ (id) panel;

- (id) init;

- (void) setGate:(id)aGate;
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) gateValidChanged:(NSNotification*)aNotification;
- (NSView*) view;

- (void) averageChanged:(NSNotification*)aNote;
- (void) activeGateChanged:(NSNotification*)aNote;
- (void) gateNumberChanged:(NSNotification*)aNote;
- (void) totalSumChanged:(NSNotification*)aNote;
- (void) peakxChanged:(NSNotification*)aNote;
- (void) peakyChanged:(NSNotification*)aNote;



@end

