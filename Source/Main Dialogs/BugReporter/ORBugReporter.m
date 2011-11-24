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
#import "ORMailer.h"
#import "ORAlarmCollection.h"
#import "ORProcessModel.h"

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
	
	[categoryMatrix selectCellWithTag:3];
	[bodyField setString:@""];

}

//this method is needed so the global menu commands will be passes on correctly.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)window
{
    return [[NSApp delegate]  undoManager];
}

#pragma mark •••Actions
- (IBAction) showBugReporter:(id)sender
{
	[bodyField setString:@""];
    [[self window] makeKeyAndOrderFront:nil];
}

- (IBAction) send:(id)sender
{
	if(![[self window] makeFirstResponder:[self window]]){
		[[self window] endEditingFor:nil];		
	}

	NSString* s = [bodyField string];
	NSString* startString = [s copy];
	unsigned major,minor,bugFix;
	[NSApp getSystemVersionMajor:&major
						minor:&minor
					   bugFix:&bugFix];


	CFBundleRef localInfoBundle = CFBundleGetMainBundle();
	NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
	
	CFBundleGetLocalInfoDictionary( localInfoBundle );
	
	NSString* versionString = [infoDictionary objectForKey:@"CFBundleVersion"];

	s = [s stringByAppendingFormat:@"\n\n-----------------------------------------\n"];
	switch([[categoryMatrix selectedCell] tag]){
		case 0:	s = [s stringByAppendingFormat:@"Bug Category: Crasher\n"]; break;
		case 1:	s = [s stringByAppendingFormat:@"Bug Category: Critical\n"]; break;
		case 2:	s = [s stringByAppendingFormat:@"Bug Category: Annoying\n"]; break;
		case 3:	s = [s stringByAppendingFormat:@"Bug Category: Minor\n"]; break;
		default:s = [s stringByAppendingFormat:@"Bug Category: Feature Request\n"]; break;
	}
	s = [s stringByAppendingFormat:@"-----------------------------------------\n"];
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
	
	NSData* theRTFDData = [bodyField RTFDFromRange:NSMakeRange(0,[[bodyField string] length])];;

	NSDictionary* attrib;
	NSMutableAttributedString* theContent = [[NSMutableAttributedString alloc] initWithRTFD:theRTFDData documentAttributes:&attrib];
	
	ORMailer* mailer = [ORMailer mailer];
	[mailer setTo:		[[mailForm cellWithTag:0] stringValue]];
	[mailer setCc:		[[mailForm cellWithTag:1] stringValue]];
	[mailer setSubject:	[[mailForm cellWithTag:2] stringValue]];
	[mailer setBody:	theContent];
	[theContent release];
	
	
	[bodyField setString:startString];
	[startString release];
	[mailer send:self];

}

- (void) mailSent:(NSString*)to
{
	NSLog(@"Bug report sent to: %@\n",to);
	[[self window] performClose:self];
}

- (IBAction) startDebugging:(id)sender
{
     
    NSString* body = [NSString stringWithString:   @"----------------------------------------------------------------------------------------------------\n"];
    body           = [body stringByAppendingString:@"An ORCA debugging session has begun on\n"];
    body           = [body stringByAppendingFormat:@"\n%@\n\n",computerName()];
    body           = [body stringByAppendingString:@"If is possible that erroneous alarm emails may be generated during this process.\n"];
    body           = [body stringByAppendingString:@"You should receive another email when normal operations resume.\n"];
    body           = [body stringByAppendingString:@"----------------------------------------------------------------------------------------------------\n"];
    body           = [body stringByAppendingString:@"This message has been sent to the following people:\n"];
    NSArray* addresses = [self allEMailLists];
    for(id anAddress in addresses){
        body           = [body stringByAppendingFormat:@"%@\n",anAddress];
    }

    body           = [body stringByAppendingString:@"You have received this message because you are in one of ORCA's Alarm or Process email lists\n"];
	
    body           = [body stringByAppendingString:@"If you believe you have received this message in error, contact some of the other people in the list to be removed.\n"];
    
   body           = [body stringByAppendingString:@"----------------------------------------------------------------------------------------------------\n"];    
    
	NSMutableAttributedString* theContent = [[NSMutableAttributedString alloc] initWithString:body];
    for(id anAddress in addresses){
        ORMailer* mailer = [ORMailer mailer];
        [mailer setTo:		anAddress];
        [mailer setSubject:	@"ORCA Debugging Session In Progress"];
        [mailer setBody:	theContent];
        [mailer send:self];
    }
    [theContent release];
}

- (IBAction) stopDebugging:(id)sender
{
    
    NSString* body = [NSString stringWithString:   @"----------------------------------------------------------------------------------------------------\n"];
    body           = [body stringByAppendingString:@"An ORCA debugging session has ended on:\n"];
    body           = [body stringByAppendingFormat:@"\n%@\n\n",computerName()];
    body           = [body stringByAppendingString:@"Normal operations have resumed. You should pay full attention to all alarms.\n"];
    body           = [body stringByAppendingString:@"----------------------------------------------------------------------------------------------------\n"];
    body           = [body stringByAppendingString:@"This message has been sent to the following people:\n"];
    NSArray* addresses = [self allEMailLists];
    for(id anAddress in addresses){
        body           = [body stringByAppendingFormat:@"%@\n",anAddress];
    }
    body           = [body stringByAppendingString:@"You have received this message because you are in one of ORCA's Alarm or Process email lists\n"];
	
    body           = [body stringByAppendingString:@"If you believe you have received this message in error, contact some of the other people in the list to be removed.\n"];
    body           = [body stringByAppendingString:@"----------------------------------------------------------------------------------------------------\n"];  
	NSMutableAttributedString* theContent = [[NSMutableAttributedString alloc] initWithString:body];
    for(id anAddress in addresses){
        ORMailer* mailer = [ORMailer mailer];
        [mailer setTo:		anAddress];
        [mailer setSubject:	@"ORCA Debugging Session Ended"];
        [mailer setBody:	theContent];
        [mailer send:self];
    }
    [theContent release];
}

- (NSArray*) allEMailLists
{
    NSMutableArray* allEMails = [NSMutableArray array];
    [self putAlarmEMailsIntoArray:allEMails];
        
    NSArray* allProcesses = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORProcessModel")];
    for(id aProcess in allProcesses){
        [self putProcess:aProcess eMailsIntoArray:allEMails];
    }
    
    return allEMails;
}


- (void) putAlarmEMailsIntoArray:(NSMutableArray*)anArray
{
    NSArray* eMails = [[ORAlarmCollection sharedAlarmCollection] eMailList];
    for(id anEMail in eMails){
        id address = [anEMail mailAddress];
        if(![anArray containsObject:address]){
            [anArray addObject:address];
        }
    }
}

- (void) putProcess:(id)aProcess eMailsIntoArray:(NSMutableArray*)anArray;
{
    NSArray* eMails = [aProcess emailList];

    for(id anEMail in eMails){
        if(![anArray containsObject:anEMail]){
            [anArray addObject:anEMail];
        }
    }
}

@end
