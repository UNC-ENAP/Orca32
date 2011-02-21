//
//  ORCouchDB.h
//  Orca
//
//  Created by Mark Howe on 02/19/11.
//  Copyright 20011, University of North Carolina
//-------------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina  sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

@interface ORCouchDB : NSObject {
	id					delegate;
	NSOperationQueue*	queue;
	NSString*			host;
	NSString*			database;
	NSUInteger			port;
}
+ (id) couchHost:(NSString*)aHost port:(NSUInteger)aPort database:(NSString*)aDatabase delegate:(id)aDelegate;
- (id) initWithHost:(NSString*)aHost port:(NSUInteger)aPort database:(NSString*)aDatabase delegate:(id)aDelegate;
- (void) dealloc;
- (void) version:(id)aDelegate tag:(NSString*)aTag;
- (void) listDatabases:(id)aDelegate tag:(NSString*)aTag;
- (void) databaseInfo:(id)aDelegate tag:(NSString*)aTag;
- (void) createDatabase:(NSString*)aTag;
- (void) deleteDatabase:(NSString*)aTag;
- (void) addDocument:(NSDictionary*)aDict documentId:(NSString*)anId tag:(NSString*)aTag;
- (void) getDocumentId:(NSString*)anId tag:(NSString*)aTag;
- (void) updateDocument:(NSDictionary*)aDict documentId:(NSString*)anId tag:(NSString*)aTag;

@property (assign)	id					delegate;
@property (retain)	NSOperationQueue*	queue;
@property (copy)	NSString*			host;
@property (copy)	NSString*			database;
@property (assign)  NSUInteger			port;
@end

@interface ORCouchDBOperation : NSOperation
{
	id					delegate;
	NSString*			database;
	NSString*			host;
	NSUInteger			port;
	id					tag;
	NSHTTPURLResponse*	response;
}
- (id) initWithHost:(NSString*)aHost port:(NSInteger)aPort database:(NSString*)database delegate:(id)aDelegate tag:(NSString*)aTag;
- (id) send:(NSString*)httpString;
- (id) send:(NSString*)httpString type:(NSString*)aType;
- (id) send:(NSString*)httpString type:(NSString*)aType body:(NSDictionary*)aBody;
- (void) dealloc;
@end

#pragma mark •••Database API
@interface ORCouchDBCreateDBOp : ORCouchDBOperation
-(void) main;
@end

@interface ORCouchDBDeleteDBOp : ORCouchDBOperation
-(void) main;
@end

@interface ORCouchDBVersionOp :ORCouchDBOperation
- (void) main;
@end

@interface ORCouchDBListDBOp :ORCouchDBOperation
- (void) main;
@end

@interface ORCouchDBInfoDBOp : ORCouchDBOperation
-(void) main;
@end

#pragma mark •••Document API
@interface ORCouchDBPutDocumentOp :ORCouchDBOperation
{
	NSString*     documentId;
	NSDictionary* document;
}
- (void) setDocument:(NSDictionary*)aDocument documentID:(NSString*)anID;
- (void) main;
@end

@interface ORCouchDBUpdateDocumentOp :ORCouchDBPutDocumentOp
- (void) main;
@end

@interface ORCouchDBGetDocumentOp :ORCouchDBOperation
{
	NSString* documentId;
	BOOL getRevisionCount;
	BOOL getInfo;
	NSString* revision;
	
}
- (void) setDocumentId:(NSString*)anID;
- (void) main;
@end


//a thin wrapper around NSOperationQueue to make a shared queue for couch access
@interface ORCouchDBQueue : NSObject {
    NSOperationQueue* queue;
}
+ (ORCouchDBQueue*) sharedCouchDBQueue;
+ (NSOperationQueue*) queue;
- (void) addOperation:(NSOperation*)anOp;
- (NSOperationQueue*) queue;
@end

@interface NSObject (ORCouchDB)
- (void) couchDBResult:(id)aResult tag:(NSString*)aTag;
@end


