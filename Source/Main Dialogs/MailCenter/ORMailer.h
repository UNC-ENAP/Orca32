//----------------------------------------------------------
//  ORMailer.h
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

extern NSString *ORMailerUrlType;
extern NSString *ORMailerMailType;

@interface ORMailer : NSObject {
	
	NSString *type;
	NSString *to;
	NSString *cc;
	NSString *subject;
	NSAttributedString *body;
	NSString *from;
	NSModalSession session;
}

+ (ORMailer *)mailer;

// accessors

- (NSString *)type;
- (void)setType:(NSString *)value;

- (NSString *)to;
- (void)setTo:(NSString *)value;

- (NSString *)cc;
- (void)setCc:(NSString *)value;

- (NSString *)subject;
- (void)setSubject:(NSString *)value;

- (NSAttributedString *)body;
- (NSString *)bodyString;
- (void)setBody:(NSAttributedString *)value;

- (NSString *)from;
- (void)setFrom:(NSString *)value;

- (BOOL) send:(NSWindow*) aWindow;

@end
