//
//  ORFilterController.m
//  Orca
//
//  Created by Mark Howe on Wed Nov 20 2002.
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


#pragma mark •••Imported Files
#import "ORFilterController.h"
#import "ORFilterModel.h"
#import "ORTimedTextField.h"
#import "ORScriptView.h"
#import "ORScriptRunner.h"
#import "ORPlotter1D.h"

@implementation ORFilterController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"Filter"];
	return self;
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	[panelView addSubview:argsView];
	[statusField setTimeOut:1.5];
	NSString*   path = [[NSBundle mainBundle] pathForResource: @"FilterScriptGuide" ofType: @"rtf"];
	[helpView readRTFDFromFile:path];
	[scriptView setSyntaxDefinitionFilename:@"FilterSyntaxDefinition"];
	[scriptView recolorCompleteFile:self];
}


#pragma mark •••Accessors

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
	[super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

	[notifyCenter addObserver: self 
					 selector: @selector(scriptChanged:) 
						 name: ORFilterScriptChanged 
					   object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(nameChanged:)
                         name : ORFilterNameChanged
						object: model];	

    [notifyCenter addObserver : self
                     selector : @selector(argsChanged:)
                         name : ORFilterArgsChanged
						object: model];	

    [notifyCenter addObserver : self
                     selector : @selector(textDidChange:)
                         name : NSTextDidChangeNotification
						object: scriptView];	

    [notifyCenter addObserver : self
                     selector : @selector(lastFileChanged:)
                         name : ORFilterLastFileChangedChanged
						object: model];	

    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORFilterLock
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
					   
   [notifyCenter addObserver : self
                     selector : @selector(displayValuesChanged:)
                         name : ORFilterDisplayValuesChanged
                       object : model];
   [notifyCenter addObserver : self
                     selector : @selector(timerEnabledChanged:)
                         name : ORFilterTimerEnabledChanged
                       object : model];

   [notifyCenter addObserver : self
                     selector : @selector(updateTiming:)
                         name : ORFilterUpdateTiming
                       object : model];

	//we don't want this notification
	[notifyCenter removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
}




- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORFilterLock to:secure];
    [lockButton setEnabled:secure];
}

- (IBAction) lockAction:(id)sender
{
    [gSecurity tryToSetLock:ORFilterLock to:[sender intValue] forWindow:[self window]];
}


#pragma mark •••Interface Management
- (void) updateWindow
{
    [super updateWindow];
	[self scriptChanged:nil];
	[self argsChanged:nil];
	[self lastFileChanged:nil];
	[self displayValuesChanged:nil];
	[self timerEnabledChanged:nil];
}

- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORFilterLock];
    [lockButton setState: locked];
    
}

- (void) updateTiming:(NSNotification*)aNote
{
	[timePlot setNeedsDisplay:YES];
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

- (void) timerEnabledChanged:(NSNotification*)aNote
{
	[timerEnabledCB setState:[model timerEnabled]];
	[timePlot setNeedsDisplay:YES];
}

- (void) scriptChanged:(NSNotification*)aNote
{
	[scriptView setString:[model script]];
}

- (void) argsChanged:(NSNotification*)aNote;
{
	int i;
	for(i=0;i<kNumScriptArgs;i++){
		[[argsMatrix cellWithTag:i] setObjectValue:[model arg:i]];
	}
}


- (void) displayValuesChanged:(NSNotification*)aNote;
{
	int i;
	for(i=0;i<kNumDisplayValues;i++){
		[[displayValuesMatrix cellWithTag:i] setObjectValue:[model displayValue:i]];
	}
}


#pragma mark •••Data Source Methods

- (IBAction) enableTimer:(id)sender
{
	[model setTimerEnabled:[sender state]];
}

- (IBAction) listMethodsAction:(id) sender
{
	NSString* theClassName = [classNameField stringValue];
	if([theClassName length]){
		NSLog(@"\n%@\n",listMethods(NSClassFromString(theClassName)));
	}
}

- (IBAction) cancelLoadSaveAction:(id)sender
{
	[loadSaveView orderOut:self];
	[[NSApplication sharedApplication]  endSheet:loadSaveView];
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

- (int) numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
    return kFilterTimeHistoSize;
}

- (float) plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x
{
	return [model processingTimeHist:x];
}


@end

@implementation ORFilterController (private)
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
