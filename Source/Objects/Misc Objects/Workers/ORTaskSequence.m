//
//  ORTaskSequence.m
//  Orca
//
//  Created by Mark Howe on 2/24/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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


#import "ORTaskSequence.h"
#import "ANSIEscapeHelper.h"

@interface ORTaskSequence (private)
- (void) _launch;
@end

@implementation ORTaskSequence
+ (id) taskSequenceWithDelegate:(id)aDelegate
{
	return [[[ORTaskSequence alloc] initWithDelegate:aDelegate] autorelease];
}

- (id) initWithDelegate:(id)aDelegate
{
	self = [super init];
	tasks = [[NSMutableArray alloc] init];
	verbose = YES;
	textToDelegate = NO;
	//normally we would not retain our delegate, but in this case we have to make sure that the delegate 
	//doesn't go away before we are done.
	delegate = [aDelegate retain];
	return self;
}

- (void) dealloc
{
	[tasks release];
	[super dealloc];
}

- (void) addTask:(NSString*)aTaskPath  arguments:(NSArray*)theParams
{
	//if(verbose)NSLog(@"adding Task %@ %@\n",aTaskPath,theParams);
	NSTask* theTask = [[NSTask alloc] init];
	[theTask setLaunchPath:aTaskPath];
	[theTask setArguments: theParams];
	[tasks addObject:theTask];
	[theTask release];
}

- (void) addTaskObj:(id)aTask
{
	[tasks addObject:aTask];
}

- (void) launch
{
    // Reset errors and launch
    sawErrors = NO;
	[self retain];
	[self _launch];
}

- (void) setVerbose:(BOOL)flag
{
	verbose = flag;
}

- (void) setTextToDelegate:(BOOL)flag
{
	textToDelegate = flag;
}

- (BOOL) sawErrors
{
    return sawErrors;
}

- (void) taskCompleted: (NSNotification*)aNote
{
    if ([[aNote object] respondsToSelector:@selector(terminationStatus)] &&
        [[aNote object] terminationStatus] != 0) sawErrors = YES;
	[self performSelector:@selector(movetoNextTask:) withObject:aNote afterDelay:.2];
}

- (void) movetoNextTask:(NSNotification*)aNote
{
	if([delegate respondsToSelector:@selector(taskFinished:)]){
		[delegate taskFinished:[aNote object]];
	}
	[tasks removeObject:[aNote object]];
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self name:NSFileHandleReadCompletionNotification object:nil];
	[nc removeObserver:self name:NSTaskDidTerminateNotification object:nil];
	[self _launch];
}

- (void) taskDataAvailable:(NSNotification*)aNotification
{
	NSData* incomingData   = [[aNotification userInfo] valueForKey:NSFileHandleNotificationDataItem];
    if (incomingData && [incomingData length]) {
		NSString *incomingText = [[[NSString alloc] initWithData:incomingData encoding:NSASCIIStringEncoding] autorelease];
		incomingText = [incomingText removeNLandCRs];
		if(verbose){
            ANSIEscapeHelper* helper = [[[ANSIEscapeHelper alloc] init] autorelease];
            [helper setFont:[NSFont fontWithName:@"Courier New" size:12]];
            NSAttributedString* str = [helper attributedStringWithANSIEscapedString:
                                       [NSString stringWithFormat:@"%@\n",incomingText]];
            NSLogAttr(str);
        }
		if(textToDelegate && incomingText){
			if([delegate respondsToSelector:@selector(taskData:)]){
				[delegate taskData:incomingText];
			}
		}
		[[aNotification object] readInBackgroundAndNotify];  // go back for more.
	}
}
@end


@implementation ORTaskSequence (private)
- (void) _launch
{
	if([tasks count]){
		NSTask* theTask = [tasks objectAtIndex:0];
		NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];

		if(![theTask respondsToSelector:@selector(taskDataAvailable:)]){
			NSPipe *newPipe = [NSPipe pipe];
			NSFileHandle *readHandle = [newPipe fileHandleForReading];


			[nc addObserver:self 
				   selector:@selector(taskDataAvailable:) 
					   name:NSFileHandleReadCompletionNotification 
					 object:readHandle];


			[readHandle readInBackgroundAndNotify];

			[theTask setStandardOutput:newPipe];
			[theTask setStandardError:newPipe];
		}
		[nc addObserver : self
			   selector : @selector(taskCompleted:)
				   name : NSTaskDidTerminateNotification
				 object : theTask];
		
		//if(verbose)NSLog(@"launching: %@\n",theTask);
		[theTask launch];
	}
	else {
		[delegate tasksCompleted:self];
		[delegate release];
		delegate = nil;
		[self autorelease];
	}
}
@end
