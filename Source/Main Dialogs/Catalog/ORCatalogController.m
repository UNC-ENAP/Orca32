//
//  ORCatalogController.m
//  Orca
//
//  Created by Mark Howe on Thu Nov 28 2002.
//  Copyright � 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORCatalogController.h"

static ORCatalogController* sharedInstance = nil;

@implementation ORCatalogController

#pragma mark ���Inialization

+ (id) sharedCatalogController
{
	if(!sharedInstance){
		sharedInstance = [[ORCatalogController alloc] init];
	}
    return sharedInstance;
}


-(id)init
{
    self = [super initWithWindowNibName:@"Catalog"];
    if (self) {
        [self setWindowFrameAutosaveName:@"Catalog"];
    }
    return self;
}

- (void) dealloc
{
    sharedInstance = nil;
	[super dealloc];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)window
{
    return [[[NSApp delegate]document]  undoManager];
}

- (IBAction) saveDocument:(id)sender
{
    [[[NSApp delegate]document] saveDocument:sender];
}

- (IBAction) saveDocumentAs:(id)sender
{
    [[[NSApp delegate]document] saveDocumentAs:sender];
}


@end
