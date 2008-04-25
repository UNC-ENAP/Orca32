//-------------------------------------------------------------------------
//  ScriptTaskController.h
//
//  Created by Mark A. Howe on Tuesday 12/26/2006.
//  Copyright (c) 2006 CENPA, University of Washington. All rights reserved.
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import <Cocoa/Cocoa.h>
#import "ORScriptTaskController.h"
#import "ORScriptTaskModel.h"
#import "ORScriptRunner.h"
#import "ORTimedTextField.h"
#import "ORScriptView.h"

@interface ORScriptTaskController (private)
- (void) loadFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) saveFileDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
@end

@implementation ORScriptTaskController
-(id)init
{
    self = [super initWithWindowNibName:@"ScriptTask"];
    return self;
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	[panelView addSubview:argsView];
	[statusField setTimeOut:1.5];
	NSString*   path = [[NSBundle mainBundle] pathForResource: @"OrcaScriptGuide" ofType: @"rtf"];
	[helpView readRTFDFromFile:path];
}

- (void) setModel:(id)aModel
{
	[scriptView setSelectedRange: NSMakeRange(0,0)];
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"Script Task: %@",[model scriptName]]];
	[[self window] makeFirstResponder:scriptView];
}

#pragma mark ���Notifications
- (void) registerNotificationObservers
{
	[super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

	[notifyCenter addObserver: self 
					 selector: @selector(scriptChanged:) 
						 name: ORScriptTaskScriptChanged 
					   object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(runningChanged:)
                         name : ORScriptRunnerRunningChanged
						object: [model scriptRunner]];	

    [notifyCenter addObserver : self
                     selector : @selector(errorChanged:)
                         name : ORScriptRunnerParseError
						object: [model scriptRunner]];	

    [notifyCenter addObserver : self
                     selector : @selector(nameChanged:)
                         name : ORScriptTaskNameChanged
						object: model];	

    [notifyCenter addObserver : self
                     selector : @selector(argsChanged:)
                         name : ORScriptTaskArgsChanged
						object: model];	

    [notifyCenter addObserver : self
                     selector : @selector(textDidChange:)
                         name : NSTextDidChangeNotification
						object: scriptView];	

    [notifyCenter addObserver : self
                     selector : @selector(breakChainChanged:)
                         name : ORScriptTaskBreakChainChanged
						object: model];	

    [notifyCenter addObserver : self
                     selector : @selector(lastFileChanged:)
                         name : ORScriptTaskLastFileChangedChanged
						object: model];	

	//we don't want this notification
	[notifyCenter removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
    [notifyCenter addObserver : self
                     selector : @selector(showSuperClassChanged:)
                         name : ORScriptTaskModelShowSuperClassChanged
						object: model];

}

- (void) updateWindow
{
	[super updateWindow];
	[self scriptChanged:nil];
	[self runningChanged:nil];
	[self nameChanged:nil];
	[self argsChanged:nil];
	[self lastFileChanged:nil];
	[self breakChainChanged:nil];
	[self showSuperClassChanged:nil];
}

#pragma mark ���Interface Management

- (void) showSuperClassChanged:(NSNotification*)aNote
{
	[showSuperClassButton setIntValue: [model showSuperClass]];
}

- (void) lastFileChanged:(NSNotification*)aNote
{
	[lastFileField setStringValue:[[model lastFile] stringByAbbreviatingWithTildeInPath]];
	[lastFileField1 setStringValue:[[model lastFile] stringByAbbreviatingWithTildeInPath]];
}

- (void) textDidChange:(NSNotification*)aNote
{
	[model setScriptNoNote:[scriptView string]];
}

- (void) breakChainChanged:(NSNotification*)aNote
{
	[breakChainButton setState:[model breakChain]];
}

- (void) scriptChanged:(NSNotification*)aNote
{
	[scriptView setString:[model script]];
}

- (void) nameChanged:(NSNotification*)aNote
{
	[nameField setStringValue:[model scriptName]];
}

- (void) argsChanged:(NSNotification*)aNote;
{
	int i;
	for(i=0;i<kNumScriptArgs;i++){
		[[argsMatrix cellWithTag:i] setObjectValue:[model arg:i]];
	}
}

- (void) errorChanged:(NSNotification*)aNote
{
	int lineNumber = [[[aNote userInfo] objectForKey:@"ErrorLocation"] intValue];
	[scriptView goToLine:lineNumber];
}

- (void) runningChanged:(NSNotification*)aNote
{
	if([model running]){
		[statusField setStringValue:@"Started"];
		[runStatusField setStringValue:@"Running"];
		
		[runButton setImage:[NSImage imageNamed:@"Stop"]];
		[runButton setAlternateImage:[NSImage imageNamed:@"Stop"]];
		[loadSaveButton setEnabled:NO];
	}
	else {
		[statusField setStringValue:@""];
		[runStatusField setStringValue:@""];
		[runButton setImage:[NSImage imageNamed:@"Play"]];
		[runButton setAlternateImage:[NSImage imageNamed:@"Play"]];
		[loadSaveButton setEnabled:YES];
	}
}

#pragma mark ���Actions

- (void) showSuperClassAction:(id)sender
{
	[model setShowSuperClass:[sender intValue]];	
}

- (IBAction) listMethodsAction:(id) sender
{
	NSString* theClassName = [classNameField stringValue];
	if([theClassName length]){
		NSLog(@"\n%@\n",listMethodWithOptions(NSClassFromString(theClassName),YES,[model showSuperClass]));
	}
}

- (IBAction) cancelLoadSaveAction:(id)sender
{
	[loadSaveView orderOut:self];
	[[NSApplication sharedApplication]  endSheet:loadSaveView];
}

- (IBAction) breakChainAction:(id) sender
{
	[model setBreakChain:[sender intValue]];
}

- (IBAction) parseScript:(id) sender
{
	[statusField setStringValue:@""];	
	[self endEditing];
	[model setScript:[scriptView string]];
	[model parseScript];
	if([model parsedOK])[statusField setStringValue:@"Parsed OK"];
	else [statusField setStringValue:@"ERRORS"];
}
	
- (IBAction) runScript:(id) sender
{
	[statusField setStringValue:@""];	
	[self endEditing];
	[model setScript:[scriptView string]];
	BOOL showError;
	if(![model running]) showError = YES;
	else showError = NO;
	[model runScript];
	if(showError){
		if([model parsedOK])[statusField setStringValue:@"Parsed OK"];
		else [statusField setStringValue:@"ERRORS"];
	}
}

- (IBAction) nameAction:(id) sender
{
	[model setScriptName:[sender stringValue]];
	[[self window] setTitle:[NSString stringWithFormat:@"Script: %@",[sender stringValue]]];
}

- (IBAction) argAction:(id) sender
{
	int i = [[sender selectedCell] tag];
	NSDecimalNumber* n;
	NSString* s = [[sender selectedCell] stringValue];
	if([s rangeOfString:@"x"].location != NSNotFound || [s rangeOfString:@"X"].location != NSNotFound){
		unsigned long num = strtoul([s cStringUsingEncoding:NSASCIIStringEncoding],0,16);
		n = (NSDecimalNumber*)[NSDecimalNumber numberWithUnsignedLong:num];
	}
	else n = [NSDecimalNumber decimalNumberWithString:s];
	[model setArg:i withValue:n];
}

- (IBAction) loadSaveAction:(id)sender
{
	[[NSApplication sharedApplication] beginSheet:loadSaveView
								   modalForWindow:[self window]
									modalDelegate:self
								   didEndSelector:NULL
									  contextInfo:NULL];
	[lastFileField setStringValue:[[model lastFile] stringByAbbreviatingWithTildeInPath]];
}


- (IBAction) loadFileAction:(id) sender
{
	[loadSaveView orderOut:self];
	[[NSApplication sharedApplication]  endSheet:loadSaveView];
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    NSString* startingDir;
	NSString* fullPath = [[model lastFile] stringByExpandingTildeInPath];
    if(fullPath) startingDir = [fullPath stringByDeletingLastPathComponent];
    else		 startingDir = NSHomeDirectory();

    [openPanel beginSheetForDirectory:startingDir
                                 file:nil
                                types:nil
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(loadFileDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
}

- (IBAction) saveAsFileAction:(id) sender
{
	[loadSaveView orderOut:self];
	[[NSApplication sharedApplication]  endSheet:loadSaveView];
	NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save As"];
    [savePanel setCanCreateDirectories:YES];
    
    NSString* startingDir;
    NSString* defaultFile;
    
	NSString* fullPath = [[model lastFile] stringByExpandingTildeInPath];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
        defaultFile = [fullPath lastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
        defaultFile = @"Untitled";
    }
	
    [savePanel beginSheetForDirectory:startingDir
                                 file:defaultFile
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(saveFileDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
}

- (IBAction) saveFileAction:(id) sender
{
	[loadSaveView orderOut:self];
	[[NSApplication sharedApplication]  endSheet:loadSaveView];
	if(![model lastFile]){
		[self saveAsFileAction:nil];
	}
	else [model saveFile];
}

@end

@implementation ORScriptTaskController (private)
- (void)loadFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        [model loadScriptFromFile:[[[sheet filenames] objectAtIndex:0]stringByAbbreviatingWithTildeInPath]];
    }
}

- (void)saveFileDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        [model saveScriptToFile:[sheet filename]];
    }
}
@end

