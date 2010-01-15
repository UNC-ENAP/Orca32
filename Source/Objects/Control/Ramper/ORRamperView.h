//
//  ORRamperView.h
//  test
//
//  Created by Mark Howe on 3/28/07.
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

@class ORWayPoint;
@class ORRamperController;

@interface ORRamperView : NSView {
	IBOutlet id xAxis;
	IBOutlet id yAxis;
	IBOutlet ORRamperController* dataSource;

	NSGradient*			gradient;
	ORWayPoint* selectedWayPoint;	//x in non-converted time, y in y-axis coords
	NSImage* rightTargetBug;
	float xLowConstraint;
	float yLowConstraint;
	float xHighConstraint;
	float yHighConstraint;
	BOOL mouseIsDown;
}

@end

