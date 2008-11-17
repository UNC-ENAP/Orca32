//----------------------------------------------------------
//  ORMailer.m
//
//  Created by Mark Howe on Wed Apr 9, 2008.
//  Copyright  © 2002 CENPA. All rights reserved.
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

#import "ORMailer.h"

#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
#import <Message/NSMailDelivery.h>
#endif

@interface ORMailer (private)
- (void) sendUrlEmail;
- (void) sendMailEmail;
- (void) noSubjectSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;
- (void) noAddressSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;
- (BOOL) addressOK;
- (BOOL) subjectOK;
- (void) sendit;
@end

@implementation ORMailer

NSString *ORMailerUrlType  = @"ORMailerURLType";
NSString *ORMailerMailType = @"ORMailerNSMailDeliveryType";

+ (ORMailer *) mailer {
	return [[[ORMailer alloc] init] autorelease];
}

- (id)init 
{	
	self = [super init];
	[self setTo:@""];
	[self setCc:@""];
	[self setSubject:@""];
	[self setFrom:@""];
	[self setBody:[[[NSAttributedString alloc] initWithString:@""] autorelease]];
	[self setType: ORMailerMailType];
	return self;
}

- (void)dealloc 
{
	[type release];
	[to release];
	[cc release];
	[subject release];
	[body release];
	[from release];
	[super dealloc];
}

// accessors
- (NSString *)type 
{
	return type;
}

- (void) setType:(NSString *)value 
{
    [type release];
    type = [value copy];
}

- (NSString *)to 
{
	return to;
}

- (void)setTo:(NSString *)value 
{
    [to release];
    to = [value copy];
}

- (NSString *)cc 
{
	return cc;
}

- (void)setCc:(NSString *)value 
{
    [cc release];
    cc = [value copy];
}

- (NSString *)subject 
{
	return subject;
}

- (void)setSubject:(NSString *)value 
{
    [subject release];
    subject = [value copy];
}

- (NSAttributedString *)body 
{
	return body;
}

- (NSString *)bodyString 
{
	return [body string];
}

- (void)setBody:(NSAttributedString *)value 
{
    [body release];
    body = [value copy];
}

- (NSString *)from 
{
	return from;
}

- (void)setFrom:(NSString *)value 
{
	[from release];
	from = [value copy];
}

- (void) send:(id)aDelegate
{
	delegate = aDelegate;
	if ([type isEqualToString:ORMailerUrlType]) {
		[self sendUrlEmail];
	}
	if ([type isEqualToString:ORMailerMailType]) {
		[self sendMailEmail];
	}
	// better not get here
}

- (NSArray *)ccArray {
	NSArray *array = [[self cc] componentsSeparatedByString:@","];
	return array;
}
@end

@implementation ORMailer (private)

- (void) sendUrlEmail
{
	NSString *encodedSubject	= [NSString stringWithFormat:@"SUBJECT=%@",[subject stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
	NSString *encodedBody		= [NSString stringWithFormat:@"BODY=%@",[[self bodyString] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
	NSString *encodedTo			= [to stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
	NSString *encodedURLString	= [NSString stringWithFormat:@"mailto:%@?%@&%@", encodedTo, encodedSubject, encodedBody];
	NSURL *mailtoURL			= [NSURL URLWithString:encodedURLString];
	@synchronized([NSApp delegate]){
		[[NSWorkspace sharedWorkspace] openURL:mailtoURL];
		if([delegate respondsToSelector:@selector(mailSent)]){
			[delegate performSelector:@selector(mailSent) withObject:nil afterDelay:0];
		}
	}
}

- (BOOL) addressOK
{
	return [to length]!=0 && [to rangeOfString:@"@"].location != NSNotFound;
}

- (BOOL) subjectOK
{
	return [subject length]!=0;
}

- (void) sendMailEmail
{
	if ([self addressOK]){
		if([self subjectOK]){
			[self sendit];
		}
		else {
			NSBeginAlertSheet(@"ORCA Mail",
				  @"Cancel",
				  @"Send Anyway",
				  nil,
				  [delegate window],
				  self,
				  @selector(noSubjectSheetDidEnd:returnCode:contextInfo:),
				  nil,
				  nil,@"No Subject...");		
		}
	}
	else {
		NSBeginAlertSheet(@"ORCA Mail",
			  @"OK",
			  nil,
			  nil,
			  [delegate window],
			  self,
			  @selector(noAddressSheetDidEnd:returnCode:contextInfo:),
			  nil,
			  nil,@"No Destination Address Given");
	}
}

- (void) noAddressSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{

}

- (void) noSubjectSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{
	if(returnCode == NSAlertAlternateReturn){
		[self sendit];
	}
}

- (void) sendit
{
	@synchronized([NSApp delegate]){
#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
		BOOL configured = [NSMailDelivery hasDeliveryClassBeenConfigured];
		if(configured){
			NSMutableDictionary *headersDict = [NSMutableDictionary dictionary];
			[headersDict setObject:to forKey:@"To"];
			[headersDict setObject:cc forKey:@"Cc"];
			[headersDict setObject:subject forKey:@"Subject"];
			[NSMailDelivery deliverMessage:body
										headers:headersDict
										format:NSMIMEMailFormat
									protocol:nil];
			NSLog(@"email sent to: %@\n",to);
			if([delegate respondsToSelector:@selector(mailSent)]){
				[delegate performSelector:@selector(mailSent) withObject:nil afterDelay:0];
			}
			
		}
		else {
			NSBeginAlertSheet(@"ORCA Mail",
					  @"OK",
					  nil,
					  nil,
					  nil,
					  self,
					  nil,
					  nil,
					  nil,@"e-mail could NOT be sent because eMail delivery has not been configured in Mail.app");

			NSLogColor([NSColor redColor], @"e-mail could NOT be sent because eMail delivery has not been configured in Mail.app\n");
		}
#else
		NSString*   mailScriptPath = [[NSBundle mainBundle] pathForResource: @"MailScript" ofType: @"txt"];
		NSMutableString* script = [NSMutableString stringWithContentsOfFile:mailScriptPath];
		[script replaceOccurrencesOfString:@"</subject/>" withString:subject options:NSLiteralSearch range:NSMakeRange(0,[script length])];
		[script replaceOccurrencesOfString:@"</body/>" withString:[body string] options:NSLiteralSearch range:NSMakeRange(0,[script length])];
		[script replaceOccurrencesOfString:@"</address/>" withString:to options:NSLiteralSearch range:NSMakeRange(0,[script length])];
		NSFileManager* fm = [NSFileManager defaultManager];
		NSString* tempFile = [@"~/aMailScript" stringByExpandingTildeInPath];
		if([fm fileExistsAtPath:tempFile])[fm removeFileAtPath:tempFile handler:nil];
		[fm createFileAtPath:tempFile contents:[script dataUsingEncoding:NSASCIIStringEncoding] attributes:nil];
		[NSTask launchedTaskWithLaunchPath:@"/usr/bin/osascript" arguments:[NSArray arrayWithObject:tempFile]];
		NSLog( @"e-mail may have been sent to %@\n",to);

#endif
		
	}
}

@end
