//----------------------------------------------------------
//  ORBugReporter.h
//
//  Created by Mark Howe on Thurs Mar 20, 2008.
//  Copyright  © 2008 CENPA. All rights reserved.
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

#pragma mark •••Imported Files
#import "ORBugReporter.h"
#import <Message/NSMailDelivery.h>

@implementation ORBugReporter

#pragma mark ***Accessors
- (id)init
{
    self = [super initWithWindowNibName:@"BugReporter"];
    return self;
}

- (void) awakeFromNib
{

	CFBundleRef localInfoBundle = CFBundleGetMainBundle();
	NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
	CFBundleGetLocalInfoDictionary( localInfoBundle );
	NSString* bugMan = [infoDictionary objectForKey:@"ReportBugsTo"];

	[[mailForm cellWithTag:0] setStringValue:bugMan];
	[[mailForm cellWithTag:2] setStringValue:@"Orca Bug"];
}

//this method is needed so the global menu commands will be passes on correctly.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)window
{
    return [[NSApp delegate]  undoManager];
}

#pragma mark •••Actions
- (IBAction) showBugReporter:(id)sender
{
    [[self window] makeKeyAndOrderFront:nil];
}

- (IBAction) send:(id)sender
{
	if(![[self window] makeFirstResponder:[self window]]){
		[[self window] endEditingFor:nil];		
	}
	
	BOOL okToSend = YES;
	if(![[mailForm cellWithTag:0] stringValue] || [[[mailForm cellWithTag:0] stringValue] rangeOfString:@"@"].location == NSNotFound){
		okToSend = NO;
		NSRunAlertPanel(@"Mail Center",@"No Destination Address Given", nil, nil, nil);
	}
	if(okToSend){
		if([[[mailForm cellWithTag:2] stringValue] length] == 0){
			int choice = NSRunAlertPanel(@"Bug Center",@"\nNo Subject...",@"Cancel",@"Send Anyway",nil);
			if(choice != NSAlertAlternateReturn){		
				okToSend = NO;
			}
		}
	}
	
	if(okToSend){
	
		NSString* s = [bodyField string];
		unsigned major,minor,bugFix;
		[NSApp getSystemVersionMajor:&major
							minor:&minor
						   bugFix:&bugFix];


		CFBundleRef localInfoBundle = CFBundleGetMainBundle();
		NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
		
		CFBundleGetLocalInfoDictionary( localInfoBundle );
		
		NSString* versionString = [infoDictionary objectForKey:@"CFBundleVersion"];

		s = [s stringByAppendingFormat:@"\n\n-----------------------------------------\n"];
		s = [s stringByAppendingFormat:@"MacOS %u.%u.%u\n",major,minor,bugFix];
		s = [s stringByAppendingFormat:@"Orca Version : %@\n",versionString];

		BOOL foundOne = NO;
		NSArray* theNames = [[NSHost currentHost] names];
		NSEnumerator* e = [theNames objectEnumerator];
		id aName;
		while(aName = [e nextObject]){
			NSArray* parts = [aName componentsSeparatedByString:@"."];
			if([parts count] >= 3){
				s = [s stringByAppendingFormat:@"Machine : %@\n",aName];
				foundOne = YES;
				break;
			}
		}
		if(!foundOne) s = [s stringByAppendingFormat:@"Machine : %@\n",[[NSHost currentHost] names]];
		
		s = [s stringByAppendingFormat:@"Submitted by : %@\n",[[infoForm cellWithTag:0] stringValue]];
		s = [s stringByAppendingFormat:@"Institution : %@\n",[[infoForm cellWithTag:1] stringValue]];

		[bodyField setString:s];


		NSData* theRTFDData = [bodyField RTFDFromRange:NSMakeRange(0,[s length])];

		NSDictionary* attrib;
		NSMutableAttributedString* theContent = [[NSMutableAttributedString alloc] initWithRTFD:theRTFDData documentAttributes:&attrib];
		
		NSMutableDictionary* headerDict = [NSMutableDictionary dictionary];
		[headerDict setObject:[[mailForm cellWithTag:0] stringValue]  forKey:@"To"];
		NSString* processedCCString = [[[[mailForm cellWithTag:1] stringValue] componentsSeparatedByString:@","] componentsJoinedByString:@""];
		NSArray* ccArray = [processedCCString componentsSeparatedByString:@" "];
		[headerDict setObject:ccArray  forKey:@"Cc"];
		[headerDict setObject:[[mailForm cellWithTag:2] stringValue]  forKey:@"Subject"];
		
		@synchronized([NSApp delegate]){
			[NSMailDelivery deliverMessage:theContent headers:headerDict format:NSMIMEMailFormat protocol:nil];	
		}
		[theContent release];
		
		[[self window] performClose:self];
	}
}

@end
