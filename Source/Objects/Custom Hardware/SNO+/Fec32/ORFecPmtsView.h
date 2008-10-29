//
//  ORFecPmtsView.h
//  Orca
//
//  Created by Mark Howe on 10/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
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

@interface ORFecPmtsView : NSView {
	IBOutlet id controller;
	IBOutlet id anchorView; //view to draw pmt lines to/from
	NSBezierPath* topPath[32];
	NSBezierPath* bodyPath[32];	
	NSBezierPath* clickPath[32];

}
- (void) drawPMT:(int)index at:(NSPoint)neckPoint direction:(float)angle ;
- (void) drawSwitch:(int)index at:(NSPoint)switchPoint direction:(float)angle;

@end
