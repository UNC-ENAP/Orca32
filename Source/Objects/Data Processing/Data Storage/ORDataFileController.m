//
//  ORDataFileController.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 23 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORDataFileController.h"
#import "ORDataFileModel.h"
#import "ORSmartFolder.h"

enum {
    kData,
    kStatus,
    kConfig
};

@interface ORDataFileController (private)
- (void)_stopSendingSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;
@end

@implementation ORDataFileController

#pragma mark ���Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"DataFile"];
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: @"orca.ORDataFileMode.selectedtab"];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
	
    [[tabView tabViewItemAtIndex:kData] setView:[[model dataFolder]view]];
    [[tabView tabViewItemAtIndex:kStatus] setView:[[model statusFolder]view]];
    [[tabView tabViewItemAtIndex:kConfig] setView:[[model configFolder]view]];
	
    [model setTitles];
    [[model dataFolder] setWindow:[self window]];
    [[model statusFolder] setWindow:[self window]];
    [[model configFolder] setWindow:[self window]];
	
	[[model dataFolder] updateWindow];
	[[model statusFolder] updateWindow];
	[[model configFolder] updateWindow];
	
}

#pragma mark ���Accessors


#pragma  mark ���Actions

- (IBAction) processLimitHighAction:(id)sender
{
	[model setProcessLimitHigh:[sender floatValue]];	
}

- (IBAction) useDatedFileNamesAction:(id)sender
{
	[model setUseDatedFileNames:[sender intValue]];	
}

- (IBAction) useFolderStructureAction:(id)sender
{
	[model setUseFolderStructure:[sender intValue]];	
}

- (IBAction) filePrefixTextFieldAction:(id)sender
{
	[model setFilePrefix:[sender stringValue]];	
}

- (IBAction) maxFileSizeTextFieldAction:(id)sender
{
	[model setMaxFileSize:[sender floatValue]];	
}

- (IBAction) limitSizeAction:(id)sender
{
	[model setLimitSize:[sender intValue]];
	[self lockChanged:nil];	
}

- (IBAction) sizeLimitReachedAction:(id)sender
{
	[model setSizeLimitReachedAction:[[sender selectedCell] tag]];
}

- (IBAction) lockButtonAction:(id)sender
{
    [gSecurity tryToSetLock:ORDataFileLock to:[sender intValue] forWindow:[self window]];
}


- (IBAction) saveConfigurationAction:(id)sender
{
	if([sender state] != [model saveConfiguration]){
	    [[self undoManager] setActionName: @"Set Save Configuration"];
	    [model setSaveConfiguration:[sender state]];
	}
}

- (IBAction) stopSendingAction:(id)sender
{
    NSBeginAlertSheet(@"Stop Sending Files?",
                      @"Stop",
                      @"Cancel",
                      nil,[self window],
                      self,
                      @selector(_stopSendingSheetDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,
                      @"You can always send them later.");
}
- (void)_stopSendingSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{
	if(returnCode == NSAlertDefaultReturn){
		[[model dataFolder] stopTheQueue];
		[[model statusFolder] stopTheQueue];
		[[model configFolder] stopTheQueue];
    }
}


#pragma mark ���Interface Management

- (void) processLimitHighChanged:(NSNotification*)aNote
{
	[processLimitHighField setFloatValue: [model processLimitHigh]];
}

- (void) useDatedFileNamesChanged:(NSNotification*)aNote
{
	[useDatedFileNamesCB setIntValue: [model useDatedFileNames]];
}

- (void) useFolderStructureChanged:(NSNotification*)aNote
{
	[useFolderStructureCB setIntValue: [model useFolderStructure]];
}

- (void) filePrefixChanged:(NSNotification*)aNote
{
	[filePrefixTextField setStringValue: [model filePrefix]];
}

- (void) maxFileSizeChanged:(NSNotification*)aNote
{
	[maxFileSizeTextField setFloatValue: [model maxFileSize]];
}

- (void) limitSizeChanged:(NSNotification*)aNote
{
	[limitSizeCB setIntValue: [model limitSize]];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [super registerNotificationObservers];
    
	
    [notifyCenter addObserver : self
					 selector : @selector(fileChanged:)
						 name : ORDataFileModelFileSegmentChanged
						object: model];

    [notifyCenter addObserver : self
					 selector : @selector(fileChanged:)
						 name : ORDataFileChangedNotification
						object: model];

    [notifyCenter addObserver : self
					 selector : @selector(fileStatusChanged:)
						 name : ORDataFileStatusChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
					 selector : @selector(fileSizeChanged:)
						 name : ORDataFileSizeChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
					 selector : @selector(saveConfigurationChanged:)
						 name : ORDataSaveConfigurationChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
					 selector : @selector(dirChanged:)
						 name : ORFolderDirectoryNameChangedNotification
						object: [model dataFolder]];
 
	   [notifyCenter addObserver : self
					 selector : @selector(dirChanged:)
						 name : ORDataFileModelUseFolderStructureChanged
						object: model];

	
    [notifyCenter addObserver : self
					 selector : @selector(copyEnabledChanged:)
						 name : ORFolderCopyEnabledChangedNotification
						object: nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(deleteWhenCopiedChanged:)
						 name : ORFolderDeleteWhenCopiedChangedNotification
						object: nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(fileQueueStatusChanged:)
						 name : ORDataFileQueueRunningChangedNotification
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(drawerDidOpen:)
                         name : NSDrawerDidOpenNotification
						object: copyDrawer];
	
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORDataFileLock
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(limitSizeChanged:)
                         name : ORDataFileModelLimitSizeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(maxFileSizeChanged:)
                         name : ORDataFileModelMaxFileSizeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
						object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(filePrefixChanged:)
                         name : ORDataFileModelFilePrefixChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(useFolderStructureChanged:)
                         name : ORDataFileModelUseFolderStructureChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(useDatedFileNamesChanged:)
                         name : ORDataFileModelUseDatedFileNamesChanged
						object: model];


    [notifyCenter addObserver : self
                     selector : @selector(sizeLimitReachedActionChanged:)
                         name : ORDataFileModelSizeLimitReachedActionChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(processLimitHighChanged:)
                         name : ORDataFileModelProcessLimitHighChanged
						object: model];

}

- (void) updateWindow
{
    [super updateWindow];
    [self copyEnabledChanged:nil];
    [self deleteWhenCopiedChanged:nil];
    [self fileQueueStatusChanged:nil];
    [self dirChanged:nil];
    [self fileChanged:nil];
    [self fileStatusChanged:nil];
    [self saveConfigurationChanged:nil];
    [self lockChanged:nil];
	[self limitSizeChanged:nil];
	[self maxFileSizeChanged:nil];
	[self filePrefixChanged:nil];
	[self useFolderStructureChanged:nil];
	[self useDatedFileNamesChanged:nil];
	[self sizeLimitReachedActionChanged:nil];
	[self processLimitHighChanged:nil];
}


#pragma mark ���Interface Management
- (void) drawerDidOpen:(NSNotification *)note
{
	[[model dataFolder]	updateButtons];
	[[model statusFolder] updateButtons];
	[[model configFolder] updateButtons];
}

- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item
{
    int index = [tabView indexOfTabViewItem:item];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"orca.ORDataFileMode.selectedtab"];
	
}


- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORDataFileLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL locked    = [gSecurity isLocked: ORDataFileLock];
	BOOL isRunning = [gOrcaGlobals runInProgress];
    [lockButton setState: locked];
    [saveConfigurationCB setEnabled: !locked];
	[maxFileSizeTextField setEnabled: !(locked || isRunning) && [model limitSize]];
	[limitSizeCB setEnabled: !(locked || isRunning)];
	[sizeLimitActionMatrix setEnabled: !(locked || isRunning) && [model limitSize]];
	[filePrefixTextField setEnabled:!(locked || isRunning)];
	[useFolderStructureCB setEnabled:!(locked || isRunning)];
}

- (void) sizeLimitReachedActionChanged:(NSNotification*)note
{
	[sizeLimitActionMatrix selectCellWithTag:[model sizeLimitReachedAction]];
}

- (void) fileChanged:(NSNotification*)note
{
	if([model fileName]!=nil)[fileTextField setStringValue: [model fileName]];
	[self fileStatusChanged:nil];
}

- (void) copyEnabledChanged:(NSNotification*)note
{
    if(note == nil || [note object] == [model dataFolder]){
		[copyDataField setStringValue:[[model dataFolder]copyEnabled]?@"YES":@"NO"];
    }
    if(note == nil || [note object] == [model statusFolder]){
		[copyStatusField setStringValue:[[model statusFolder]copyEnabled]?@"YES":@"NO"];
    }
    if(note == nil || [note object] == [model configFolder]){
		[copyConfigField setStringValue:[[model configFolder]copyEnabled]?@"YES":@"NO"];
    }
}

- (void) deleteWhenCopiedChanged:(NSNotification*)note
{
    if(note == nil || [note object] == [model dataFolder]){
		[deleteDataField setStringValue:[[model dataFolder]deleteWhenCopied]?@"YES":@"NO"];
    }
    if(note == nil || [note object] == [model statusFolder]){
		[deleteStatusField setStringValue:[[model statusFolder]deleteWhenCopied]?@"YES":@"NO"];
    }
    if(note == nil || [note object] == [model configFolder]){
		[deleteConfigField setStringValue:[[model configFolder]deleteWhenCopied]?@"YES":@"NO"];
    }
}

- (void) fileQueueStatusChanged:(NSNotification*)note
{
    if(note == nil || [note object] == [model dataFolder]){
		[queueDataField setStringValue:[[model dataFolder]queueStatusString]];
    }
    if(note == nil || [note object] == [model statusFolder]){
		[queueStatusField setStringValue:[[model statusFolder]queueStatusString]];
    }
    if(note == nil || [note object] == [model configFolder]){
		[queueConfigField setStringValue:[[model configFolder]queueStatusString]];
    }
    
    [stopSendingButton setEnabled: [[model dataFolder]queueIsRunning] || 
		[[model statusFolder]queueIsRunning] ||
		[[model configFolder]queueIsRunning]];
}



- (void) dirChanged:(NSNotification*)note
{    
    ORSmartFolder* theDataFolder = [model dataFolder];
    if(note==nil || [note object] == theDataFolder || [note object] == model){
		if([theDataFolder finalDirectoryName]!=nil)[dirTextField setStringValue: [theDataFolder finalDirectoryName]];
    }
}

- (void) fileStatusChanged:(NSNotification*)note
{
	if([model filePointer]){
		[statusTextField setStringValue: @"Running / File Is Open"];			
	}
	else {
		[statusTextField setStringValue: @"Not Running"];			
	}
}

- (void) fileSizeChanged:(NSNotification*)note
{
	unsigned long theSize = [model dataFileSize];
	if(theSize<1000)[sizeTextField setStringValue: [NSString stringWithFormat:@"%d Bytes",[model dataFileSize]]];
	else if(theSize<100000)[sizeTextField setStringValue: [NSString stringWithFormat:@"%.2f KB",[model dataFileSize]/1000.]];
	else if(theSize<1000000000)[sizeTextField setStringValue: [NSString stringWithFormat:@"%.2f MB",[model dataFileSize]/1000000.]];
	else [sizeTextField setStringValue: [NSString stringWithFormat:@"%.2f GB",[model dataFileSize]/1000000000.]];
}

- (void) saveConfigurationChanged:(NSNotification*)note
{
	[saveConfigurationCB setState:[model saveConfiguration]];
}



@end

