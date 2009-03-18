//-------------------------------------------------------------------------
//  RunScriptController.h
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
#import "ORScriptIDEController.h"
#import "ORLineNumberingRulerView.h"
#import "ORRunScriptModel.h"
#import "ORScriptRunner.h"
#import "ORTimedTextField.h"
#import "ORScriptView.h"
#import "ORNodeEvaluator.h"

@interface ORScriptIDEController (private)
- (void) loadFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) saveFileDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
@end

@implementation ORScriptIDEController
-(id)init
{
    self = [super initWithWindowNibName:@"ScriptIDE"];
    return self;
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	[statusField setTimeOut:1.5];
	NSString*   path = [[NSBundle mainBundle] pathForResource: @"OrcaScriptGuide" ofType: @"rtf"];
	[helpView readRTFDFromFile:path];
	//some scripts can't be chained together -- get rid of the button that are not used
	[breakChainButton setTransparent:[model nextScriptConnector]==nil];
}

- (void) setModel:(id)aModel
{
	[scriptView setSelectedRange: NSMakeRange(0,0)];
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"Script: %@",[model identifier]]];
	[[self window] makeFirstResponder:scriptView];
	[breakChainButton setTransparent:[model nextScriptConnector]==nil];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
	[super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORScriptIDEModelLock
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
	
	[notifyCenter addObserver: self 
					 selector: @selector(scriptChanged:) 
						 name: ORScriptIDEModelScriptChanged 
					   object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(commentsChanged:)
                         name : ORScriptIDEModelCommentsChanged
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
                         name : ORScriptIDEModelNameChanged
						object: model];	
	
	[notifyCenter addObserver : self
                     selector : @selector(tableViewSelectionDidChange:)
                         name : NSTableViewSelectionDidChangeNotification
                       object : inputVariablesTableView];
	
    [notifyCenter addObserver : self
                     selector : @selector(textDidChange:)
                         name : NSTextDidChangeNotification
						object: scriptView];	
	
    [notifyCenter addObserver : self
                     selector : @selector(textDidChange:)
                         name : NSTextDidChangeNotification
						object: commentsView];	
	
    [notifyCenter addObserver : self
                     selector : @selector(lastFileChanged:)
                         name : ORScriptIDEModelLastFileChangedChanged
						object: model];	
	
    [notifyCenter addObserver : self
                     selector : @selector(showSuperClassChanged:)
                         name : ORScriptIDEModelShowSuperClassChanged
						object: model];
		
    [notifyCenter addObserver : self
                     selector : @selector(debuggingChanged:)
                         name : ORScriptRunnerDebuggingChanged
						object: [model scriptRunner]];
	
	[notifyCenter addObserver : self
                     selector : @selector(debuggerStateChanged:)
                         name : ORScriptRunnerDebuggerStateChanged
						object: [model scriptRunner]];
	
	[notifyCenter addObserver : self
                     selector : @selector(breakpointsChanged:)
                         name : ORScriptIDEModelBreakpointsChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(breakpointsAction:)
                         name : ORBreakpointsAction
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(breakChainChanged:)
                         name : ORScriptIDEModelBreakChainChanged
						object: model];	
	
    [notifyCenter addObserver : self
                     selector : @selector(displayDictionaryChanged:)
                         name : ORScriptRunnerDisplayDictionaryChanged
						object: [model scriptRunner]];	
	
	
	//we don't want this notification
	[notifyCenter removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
	
}

- (void) updateWindow
{
	[super updateWindow];
	[self scriptChanged:nil];
	[self commentsChanged:nil];
	[self runningChanged:nil];
	[self nameChanged:nil];
	[self lastFileChanged:nil];
	[self showSuperClassChanged:nil];
	[self debuggingChanged:nil];
	[self breakpointsChanged:nil];
	[self breakChainChanged:nil];
	[self displayDictionaryChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORScriptIDEModelLock to:secure];
    [lockButton setEnabled:secure];
	[self lockChanged:nil];
}

#pragma mark •••Interface Management
- (void) displayDictionaryChanged:(NSNotification*)aNote
{
	[outputVariablesTableView reloadData];
}


- (void) breakChainChanged:(NSNotification*)aNote
{
	[breakChainButton setState:[model breakChain]];
}

- (void) breakpointsAction:(NSNotification*)aNote
{
	//mouse went down in the ruler gutter. break points need to be updated in the model
	NSScrollView* scrollView = [scriptView enclosingScrollView];
	id theRuler = [scrollView verticalRulerView];
	if([aNote object] == theRuler){
		NSDictionary* theBreakpoints = [[aNote userInfo] objectForKey:@"lineMarkers"];
		[model setBreakpoints:theBreakpoints];
	}
}

- (void) breakpointsChanged:(NSNotification*)aNote
{
	NSScrollView* scrollView = [scriptView enclosingScrollView];
	id theRuler = [scrollView verticalRulerView];
	[theRuler loadLineMarkers:[model breakpoints]];
}

- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORScriptIDEModelLock];
    [lockButton setState: locked];
	
    [addInputButton setEnabled:!locked];
	[removeInputButton setEnabled:!locked && ([[inputVariablesTableView selectedRowIndexes] count] > 0)];
}

- (void) debuggerStateChanged:(NSNotification*)aNote
{
	int debuggerState = [[model scriptRunner] debuggerState];
	int line = [[model scriptRunner] lastLine];
	NSString* functionName = [[[model scriptRunner] eval] functionName];
	if(debuggerState == kDebuggerPaused) {
		[debugStatusField setStringValue:[NSString stringWithFormat:@"<%@()> Stopped on Line: %d",functionName,line]];
		[pauseButton setImage:[NSImage imageNamed:@"Continue"]];
		[stepButton setEnabled:YES];
		[stepInButton setEnabled:YES];
		[stepOutButton setEnabled:YES];
		unsigned long line = [[model scriptRunner] lastLine]-1;
		[scriptView selectLine:line];
	}
	else if(debuggerState == kDebuggerRunning) {
		[debugStatusField setStringValue:[NSString stringWithFormat:@""]];
		[pauseButton setImage:[NSImage imageNamed:@"Pause"]];
		[stepButton setEnabled:NO];
		[stepInButton setEnabled:NO];
		[stepOutButton setEnabled:NO];
		[scriptView unselectAll];
	}
	[pauseButton setEnabled:[[model scriptRunner] debugging] && [model running]];
	[debuggerTableView reloadData];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[self checkGlobalSecurity];
}

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
	if([aNote object] == scriptView)		[model setScriptNoNote:[scriptView string]];
	else if([aNote object] == commentsView) [model setCommentsNoNote:[commentsView string]];
}

- (void) scriptChanged:(NSNotification*)aNote
{
	[scriptView setString:[model script]];
}

- (void) commentsChanged:(NSNotification*)aNote
{
	[commentsView setString: [model comments]];
}

- (void) debuggingChanged:(NSNotification*)aNote
{	
	NSScrollView* scrollView = [scriptView enclosingScrollView];
	id theRuler = [scrollView verticalRulerView];
	
	[theRuler showBreakpoints:[[model scriptRunner] debugging]];
	
	if([[model scriptRunner] debugging]) [debuggerDrawer open];
	else {
		[debuggerDrawer close];
		[scriptView unselectAll];
	}
	if([model running]){
		[runStatusField setStringValue:[[model scriptRunner] debugging]?@"Debugging":@"Running"];
	}
	[self debuggerStateChanged:aNote];
}


- (void) nameChanged:(NSNotification*)aNote
{
	[nameField setStringValue:[model scriptName]];
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
		[runStatusField setStringValue:[[model scriptRunner] debugging]?@"Debugging":@"Running"];
		
		[runButton setImage:[NSImage imageNamed:@"Stop"]];
		[runButton setAlternateImage:[NSImage imageNamed:@"Stop"]];
		[loadSaveButton setEnabled:NO];
		[loadSaveButton setEnabled:NO];
		[codeHelperPU setEnabled:NO];
		[insertCodeButton setEnabled:NO];
		[addInputButton setEnabled:NO];
		[removeInputButton setEnabled:NO];

	}
	else {
		[statusField setStringValue:@""];
		[runStatusField setStringValue:@""];
		[runButton setImage:[NSImage imageNamed:@"Play"]];
		[runButton setAlternateImage:[NSImage imageNamed:@"Play"]];
		[loadSaveButton setEnabled:YES];
		[scriptView setEditable:YES];
		[codeHelperPU setEnabled:YES];
		[insertCodeButton setEnabled:YES];
		[addInputButton setEnabled:YES];
		[removeInputButton setEnabled:YES];
	}
	[stepButton setEnabled:NO];
	[stepInButton setEnabled:NO];
	[stepOutButton setEnabled:NO];
	[pauseButton setEnabled:[[model scriptRunner] debugging] && [model running]];
}

#pragma mark •••Actions
- (IBAction) clearAllBreakpoints:(id) sender
{
	[model setBreakpoints:nil];
}

- (IBAction) breakChainAction:(id) sender
{
	[model setBreakChain:[sender intValue]];
}

- (IBAction) debuggerAction:(id)sender
{
	BOOL state = [[model scriptRunner] debugging];
	[[model scriptRunner] setDebugging:!state];	
}

- (IBAction) lockAction:(id)sender
{
    [gSecurity tryToSetLock:ORScriptIDEModelLock to:[sender intValue] forWindow:[self window]];
}

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

- (IBAction) parseScript:(id) sender
{
	[statusField setStringValue:@""];	
	[self endEditing];
	[model setScript:[scriptView string]];
	[model parseScript];
	if([model parsedOK])[statusField setStringValue:@"Parsed OK"];
	else [statusField setStringValue:@"ERRORS"];
}

- (IBAction) stepScript:(id) sender
{
	[[model scriptRunner] setDebugMode:kSingleStep];
}

- (IBAction) stepIn:(id) sender
{	
	[[model scriptRunner] setDebugMode:kStepInto];
}

- (IBAction) stepOut:(id) sender
{	
	[[model scriptRunner] setDebugMode:kStepOutof];
}

- (IBAction) pauseScript:(id) sender
{
	if([[model scriptRunner] debugMode] == kPauseHere) [[model scriptRunner] setDebugMode:kRunToBreakPoint];
	else [[model scriptRunner] setDebugMode:kPauseHere];
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
	[[self window] setTitle:[NSString stringWithFormat:@"Script: %@",[model scriptName]]];
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

- (IBAction) addInput:(id)sender
{
	[model addInputValue];
	[inputVariablesTableView reloadData];
}

- (IBAction) removeInput:(id)sender
{
	NSIndexSet* indexSet = [inputVariablesTableView selectedRowIndexes];
	int i;
	int last = [indexSet lastIndex];
	for(i=last;i!=NSNotFound;i = [indexSet indexLessThanIndex:i]){
		[model removeInputValue:i];
	}
	[inputVariablesTableView reloadData];
}

- (IBAction) insertCode:(id) sender
{
	NSString* stringToInsert = @"";
	switch ([codeHelperPU indexOfSelectedItem]) {
		case 0: stringToInsert = @"function <name> {\n}";	break;
		case 1: stringToInsert = @"for(<var> = <start> ; <var> < <end> ; <var>++) {\n}";	break;
		case 2: stringToInsert = @"while (<condition>) {\n}";	break;
		case 3: stringToInsert = @"do {\n}while(<condition>);";	break;
		case 4: stringToInsert = @"if (<condition>) {\n}";	break;
		case 5: stringToInsert = @"if (<condition>) {\n}\nelse {\n}";	break;
		case 6: stringToInsert = @"switch (<condition>) {\n\t case <item>:\n\t\t<statement>\n\tbreak;\n\tdefault:\n\t\t<statement>\n\tbreak;\n}";	break;
		case 7: stringToInsert = @"case <item>:\n\t\t<statement>\n\tbreak;";	break;
		default:break;
	}
	if([stringToInsert length]){
		[scriptView insertText:stringToInsert];
	}
}

- (int) numberOfRowsInTableView:(NSTableView *)aTable
{
	if(aTable == inputVariablesTableView)		return ([[model inputValues] count]);
	else if(aTable == outputVariablesTableView)	return ([[[model scriptRunner] displayDictionary] count]);
	else if(aTable == debuggerTableView)		return ([[model evaluator] symbolTableCount]);
	else return 0;
}

- (id) tableView:(NSTableView *)aTable objectValueForTableColumn:(NSTableColumn *)aCol row:(int)aRow
{
	id anArray;
	if(aTable == inputVariablesTableView){
		anArray= [model inputValues];
		return [[anArray objectAtIndex:aRow] objectForKey:[aCol identifier]];
	}
	else if(aTable == outputVariablesTableView){
		anArray= [[model scriptRunner] displayDictionary];
		NSArray* keyArray = [anArray allKeys];
		if([[aCol identifier] isEqualToString:@"name"])		   return [keyArray objectAtIndex:aRow];
		else if([[aCol identifier] isEqualToString:@"value"]){
			id theValue =  [anArray objectForKey:[keyArray objectAtIndex:aRow]];
			return theValue;
		}
		else if([[aCol identifier] isEqualToString:@"iValueHex"]){
			id aValue = [anArray objectForKey:[keyArray objectAtIndex:aRow]];
			return [NSString stringWithFormat:@"0x%08x",[aValue longValue]];
		}
		else return nil;
	}
	
	else if(aTable == debuggerTableView) {
		if([[aCol identifier] isEqualToString:@"Name"]) return [[model evaluator] symbolNameForIndex:aRow];
		else {
			id aValue = [[model evaluator] symbolValueForIndex:aRow];
			if([aValue isKindOfClass:[OrcaObject class]]) return [NSString stringWithFormat:@"<%@>",[aValue className]];
			else if([aValue isKindOfClass:[NSArray class]]) return [NSString stringWithFormat:@"<%@>",[aValue className]];
			else return aValue;
		}
	}
	else return nil;
}

- (void) tableView:(NSTableView*)aTable setObjectValue:(id)aData forTableColumn:(NSTableColumn*)aCol row:(int)aRow
{
	if(aTable == inputVariablesTableView) {
		[[[model inputValues] objectAtIndex:aRow] setObject: aData forKey:[aCol identifier]];	
	}
	else if(aTable == debuggerTableView) {
		if([[aCol identifier] isEqualToString:@"Value"]){
			//what is the type? Just check for all numbers;
			id oldValue = [[model evaluator] symbolValueForIndex:aRow];
			if([oldValue isKindOfClass:[NSDecimalNumber class]] ){				
				NSDecimalNumber* aNumber = [NSDecimalNumber decimalNumberWithString:aData];
				if(![aNumber isEqualToNumber:[NSDecimalNumber notANumber]]){
					[[model evaluator] setValue:aNumber forIndex:aRow];
				}
			}
			else if([oldValue isKindOfClass:[NSString class]] ){
				[[model evaluator] setValue:aData forIndex:aRow];
			}
			//else don't allow changes
		}
	}
 
}

@end

@implementation ORScriptIDEController (private)
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

