//
//  ORRunController.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 23 2002.
//  Copyright(c)2002 CENPA, University of Washington. All rights reserved.
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
#import "ORRunController.h"
#import "ORRunModel.h"
#import "StopLightView.h"
#import "ORRunScriptModel.h"

@interface ORRunController (private)
- (void) populatePopups;
@end

@implementation ORRunController

#pragma mark ���Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"RunControl"];
    return self;
}
- (void) dealloc
{
    if(retainingRunNotice)[runModeNoticeView release];
    [super dealloc];
}


- (void) awakeFromNib
{
    [runProgress setStyle:NSProgressIndicatorSpinningStyle];
    [runBar setIndeterminate:NO];
    [super awakeFromNib];
    [self performSelector:@selector(updateWithCurrentRunNumber)withObject:self afterDelay:0];
    [self updateButtons];
}

#pragma mark ���Accessors


#pragma mark ���Interface Management

- (void) subRunCommentChanged:(NSNotification*)aNote
{
	//nothing to do right now
}

- (void) subRunNumberChanged:(NSNotification*)aNote
{
	//nothing to do right now
}
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver: self
                     selector: @selector(timedRunChanged:)
                         name: ORRunTimedRunChangedNotification
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(repeatRunChanged:)
                         name: ORRunRepeatRunChangedNotification
                       object: model];
    
    
    [notifyCenter addObserver: self
                     selector: @selector(timeLimitStepperChanged:)
                         name: ORRunTimeLimitChangedNotification
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(elapsedTimeChanged:)
                         name: ORRunElapsedTimeChangedNotification
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(startTimeChanged:)
                         name: ORRunStartTimeChangedNotification
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(timeToGoChanged:)
                         name: ORRunTimeToGoChangedNotification
                       object: model];

    [notifyCenter addObserver: self
                     selector: @selector(runStatusChanged:)
                         name: ORRunStatusChangedNotification
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(runNumberChanged:)
                         name: ORRunNumberChangedNotification
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(runNumberDirChanged:)
                         name: ORRunNumberDirChangedNotification
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(runModeChanged:)
                         name: ORRunModeChangedNotification
                       object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(runTypeChanged:)
                         name: ORRunTypeChangedNotification
                       object: model];
 
	[notifyCenter addObserver: self
                     selector: @selector(runTypeChanged:)
                         name: ORRunTypeChangedNotification
                       object: model];
	
	
    [notifyCenter addObserver: self
                     selector: @selector(remoteControlChanged:)
                         name: ORRunRemoteControlChangedNotification
                       object: [self document]];
    
    [notifyCenter addObserver: self
                     selector: @selector(runNumberLockChanged:)
                         name: ORRunNumberLock
                       object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(runTypeLockChanged:)
                         name: ORRunTypeLock
                       object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(quickStartChanged:)
                         name: ORRunQuickStartChangedNotification
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(definitionsFileChanged:)
                         name: ORRunDefinitionsFileChangedNotification
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(vetosChanged:)
                         name: ORRunVetosChanged
                       object: nil];

    [notifyCenter addObserver: self
                     selector: @selector(populatePopups)
                         name: ORGroupObjectsAdded
                       object: nil];
	
    [notifyCenter addObserver: self
                     selector: @selector(populatePopups)
                         name: ORGroupObjectsRemoved
                       object: nil];

    [notifyCenter addObserver: self
                     selector: @selector(populatePopups)
                         name: ORScriptIDEModelNameChanged
                       object: nil];

    [notifyCenter addObserver: self
                     selector: @selector(startUpScriptStateChanged:)
                         name: ORRunModelStartScriptStateChanged
                       object: nil];
	
    [notifyCenter addObserver: self
                     selector: @selector(shutDownScriptStateChanged:)
                         name: ORRunModelShutDownScriptStateChanged
                       object: nil];

    [notifyCenter addObserver: self
                     selector: @selector(startUpScriptChanged:)
                         name: ORRunModelStartScriptChanged
                       object: nil];
	
    [notifyCenter addObserver: self
                     selector: @selector(shutDownScriptChanged:)
                         name: ORRunModelShutDownScriptChanged
                       object: nil];	
    [notifyCenter addObserver : self
                     selector : @selector(subRunNumberChanged:)
                         name : ORRunModelSubRunNumberChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(subRunCommentChanged:)
                         name : ORRunModelSubRunCommentChanged
						object: model];
}



- (void) updateWindow
{
    [super updateWindow];
	[self populatePopups];
    [self runStatusChanged:nil];
    [self timeLimitStepperChanged:nil];
    [self timedRunChanged:nil];
    [self repeatRunChanged:nil];
    [self elapsedTimeChanged:nil];
    [self startTimeChanged:nil];
    [self runNumberChanged:nil];
    [self runNumberDirChanged:nil];
    [self runModeChanged:nil];
    [self runTypeChanged:nil];
    [self remoteControlChanged:nil];
    [self runNumberLockChanged:nil];
    [self runTypeLockChanged:nil];
    [self quickStartChanged:nil];
    [self definitionsFileChanged:nil];
	[self startUpScriptStateChanged:nil];
	[self shutDownScriptStateChanged:nil];
	[self startUpScriptChanged:nil];
	[self shutDownScriptChanged:nil];
	[self vetosChanged:nil];
	[self subRunNumberChanged:nil];
	[self subRunCommentChanged:nil];
}



- (void) updateButtons
{
	BOOL anyVetos = [[ORGlobal sharedGlobal] anyVetosInPlace];
	BOOL running  = ([model runningState] == eRunInProgress);
	
	[startUpScripts setEnabled:!running];
	[shutDownScripts setEnabled:!running];
	[openStartScriptButton setEnabled:[model startScript]!=nil]; 
	[openShutDownScriptButton setEnabled:[model shutDownScript]!=nil]; 
	
	[runModeMatrix setEnabled:![model remoteControl] && !running && [model runningState] != eRunStarting && [model runningState] != eRunStopping];

	
    if([model remoteControl]){
        [startRunButton setEnabled:NO];
        [restartRunButton setEnabled:NO];
        [restartRunButton1 setEnabled:NO];
        [subRunButton setEnabled:NO];
        [stopRunButton setEnabled:NO];
        [timedRunCB setEnabled:NO];
        [repeatRunCB setEnabled:NO];
        [timeLimitField setEnabled:NO];
        [timeLimitStepper setEnabled:NO];
        //[runModeMatrix setEnabled:NO];
		[quickStartCB setEnabled:NO];
		[startUpScripts setEnabled:NO];
		[shutDownScripts setEnabled:NO];
    }
    else {
	
		[quickStartCB setEnabled:YES];
		
        if([model runningState] == eRunInProgress){
            [startRunButton setEnabled:NO];
            [restartRunButton setEnabled:YES];
            [restartRunButton1 setEnabled:YES];
            if([model runType] & eSubRunType)[subRunButton setEnabled:YES];
			else [subRunButton setEnabled:NO];
            [stopRunButton setEnabled:YES];
            [timedRunCB setEnabled:NO];
            [timeLimitField setEnabled:NO];
            [timeLimitStepper setEnabled:NO];
            //[runModeMatrix setEnabled:NO];
            [repeatRunCB setEnabled:[model timedRun]];
			[startUpScripts setEnabled:NO];
			[shutDownScripts setEnabled:NO];
        }
        else if([model runningState] == eRunStopped){
            [startRunButton setEnabled:anyVetos?NO:YES];
            [restartRunButton setEnabled:NO];
            [restartRunButton1 setEnabled:NO];
			[subRunButton setEnabled:NO];
			[stopRunButton setEnabled:NO];
            [timedRunCB setEnabled:YES];
            [timeLimitField setEnabled:[model timedRun]];
            [timeLimitStepper setEnabled:[model timedRun]];
           // [runModeMatrix setEnabled:YES];
            [repeatRunCB setEnabled:[model timedRun]];
			[startUpScripts setEnabled:YES];
			[shutDownScripts setEnabled:YES];
        }
        else if([model runningState] == eRunStarting || [model runningState] == eRunStopping){
            [startRunButton setEnabled:NO];
            [restartRunButton setEnabled:NO];
            [restartRunButton1 setEnabled:NO];
			[subRunButton setEnabled:NO];
            [stopRunButton setEnabled:NO];
            [timedRunCB setEnabled:NO];
            [timeLimitField setEnabled:NO];
            [timeLimitStepper setEnabled:NO];
            //[runModeMatrix setEnabled:NO];
            [repeatRunCB setEnabled:NO];
			[startUpScripts setEnabled:NO];
			[shutDownScripts setEnabled:NO];
        }
    }
}

- (void) startUpScriptChanged:(NSNotification*)aNotification
{
	NSString* selectedItemName = [[model startScript] identifier];
	if(!selectedItemName || ![startUpScripts itemWithTitle:selectedItemName])selectedItemName = @"---";
	[startUpScripts selectItemWithTitle:selectedItemName]; 
	[self updateButtons];
}

- (void) shutDownScriptChanged:(NSNotification*)aNotification
{
	NSString* selectedItemName = [[model shutDownScript] identifier];
	if(!selectedItemName || ![shutDownScripts itemWithTitle:selectedItemName])selectedItemName = @"---";
	[shutDownScripts selectItemWithTitle:selectedItemName]; 
	[self updateButtons];
}

- (void) startUpScriptStateChanged:(NSNotification*)aNotification
{
	[startUpScriptStateField setStringValue:[model startScriptState]];
	[self updateButtons];
}

- (void) shutDownScriptStateChanged:(NSNotification*)aNotification
{
	[shutDownScriptStateField setStringValue:[model shutDownScriptState]];
	[self updateButtons];
}


- (void) runStatusChanged:(NSNotification*)aNotification
{
	if([model runningState] == eRunInProgress){
		[runProgress startAnimation:self];
		if(![model runPaused])[statusField setStringValue:[[ORGlobal sharedGlobal] runModeString]];
		else [statusField setStringValue:@"Paused"];
		[runBar setIndeterminate:!([model timedRun] && ![model remoteControl])];
		[runBar setDoubleValue:0];
		[runBar startAnimation:self];
		[lightBoardView setState:kGoLight];
	}
	else if([model runningState] == eRunStopped){
		[runProgress stopAnimation:self];
		[runBar setDoubleValue:0];
		[runBar stopAnimation:self];
		[runBar setIndeterminate:NO];
		[statusField setStringValue:@"Stopped"];
		[remoteControlCB setEnabled:YES];
		[lightBoardView setState:kStoppedLight];
	}
	else if([model runningState] == eRunStarting || [model runningState] == eRunStopping){
		[runProgress startAnimation:self];
		if([model runningState] == eRunStarting)[statusField setStringValue:@"Starting.."];
		else [statusField setStringValue:@"Stopping.."];
		[lightBoardView setState:kCautionLight];
	}
    [self updateButtons];
    
}

- (void) vetosChanged:(NSNotification*)aNotification
{
	int vetoCount = [[ORGlobal sharedGlobal] vetoCount];
	[vetoCountField setIntValue: vetoCount]; 
	[listVetosButton setHidden:vetoCount==0];
	[vetoedTextField setStringValue:vetoCount?@"Vetoed":@""];
	[self updateButtons];
}

- (void) timeToGoChanged:(NSNotification*)aNotification
{
	if([model timedRun] && ![model remoteControl]){
		int hr,min,sec;
		NSTimeInterval timeToGo = [model timeToGo];
		hr = timeToGo/3600;
		min =(timeToGo - hr*3600)/60;
		sec = timeToGo - hr*3600 - min*60;
		[timeToGoField setStringValue:[NSString stringWithFormat:@"%02d:%02d:%02d",hr,min,sec]];
	}
	else {
		[timeToGoField setStringValue:@"---"];
	}    
}

- (void) runNumberChanged:(NSNotification*)aNotification
{
	[runNumberText setIntValue:[model runNumber]];
	[runNumberStepper setIntValue:[model runNumber]];
	if([[ORGlobal sharedGlobal] runMode] == kNormalRun){
		[runNumberField setStringValue:[model fullRunNumberString]];
	}
	else {
		[runNumberField setStringValue: @"Offline"];
	}
}

- (void) runNumberDirChanged:(NSNotification*)aNotification
{
	if([model dirName]!=nil)[runNumberDirField setStringValue: [model dirName]];
}

- (void) timeLimitStepperChanged:(NSNotification*)aNotification
{
	[self updateStepper:timeLimitStepper setting:[model timeLimit]];
	[self updateIntText:timeLimitField setting:[model timeLimit]];
}


- (void) repeatRunChanged:(NSNotification*)aNotification
{
	[self updateTwoStateCheckbox:repeatRunCB setting:[model repeatRun]];
	[endOfRunStateField setStringValue:[model endOfRunState]];
}



- (void) timedRunChanged:(NSNotification*)aNotification
{
	[self updateTwoStateCheckbox:timedRunCB setting:[model timedRun]];
	[repeatRunCB setEnabled: [model timedRun]];
	[timeLimitField setEnabled:[model timedRun]];
	[timeLimitStepper setEnabled:[model timedRun]];
}


- (void) elapsedTimeChanged:(NSNotification*)aNotification
{

	[elapsedTimeField setStringValue:[model elapsedTimeString]];
	[endOfRunStateField setStringValue:[model endOfRunState]];
	
	if([model timedRun]){
		double timeLimit = [model timeLimit];
		double elapsedTime = [model elapsedTime];
		[runBar setDoubleValue:100*elapsedTime/timeLimit];
	}
	
}

- (void) startTimeChanged:(NSNotification*)aNotification
{
	[timeStartedField setObjectValue:[model startTime]];
}

- (void) runModeChanged:(NSNotification *)notification
{
    [runModeMatrix selectCellWithTag: [[ORGlobal sharedGlobal] runMode]];
    if([[ORGlobal sharedGlobal] runMode] == kNormalRun){
        [runModeNoticeView selectTabViewItemAtIndex:1];
    }
    else {
        [runModeNoticeView selectTabViewItemAtIndex:0];
    }
    [self runNumberChanged:nil];
}

- (void) runTypeChanged:(NSNotification *)notification
{
	unsigned long runType = [model runType];
	int i;
	for(i=0;i<32;i++){
		[[runTypeMatrix cellWithTag:i] setState:(runType &(1L<<i))!=0];
	}
	[usingSubRunsField setStringValue:([model runType] & eSubRunType)?@"YES":@"NO"];
	[restartButtonsTab selectTabViewItemAtIndex:([model runType] & eSubRunType)?0:1];
}

- (void) remoteControlChanged:(NSNotification *)notification
{
	[self updateTwoStateCheckbox:remoteControlCB setting:[model remoteControl]];
	[self updateButtons];
}

- (void) quickStartChanged:(NSNotification *)notification
{
	[self updateTwoStateCheckbox:quickStartCB setting:[model quickStart]];
	[self updateButtons];
}

- (void) definitionsFileChanged:(NSNotification *)notification
{
	NSString* path = [[model definitionsFilePath]stringByAbbreviatingWithTildeInPath];
	if(path == nil){
		path = @"---";
	}
	[definitionsFileTextField setStringValue:path];
	
	[self setupRunTypeNames];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORRunNumberLock to:secure];
    [gSecurity setLock:ORRunTypeLock to:secure];
    [runNumberLockButton setEnabled:secure];
    [runTypeLockButton setEnabled:secure];
}

- (void) runNumberLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORRunNumberLock];
    [runNumberLockButton setState: locked];
    [runNumberStepper setEnabled: !locked];
    [runNumberText setEnabled: !locked];
    [runNumberDirButton setEnabled: !locked];
}

- (void) runTypeLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORRunTypeLock];
    [runTypeLockButton setState: locked];
    [runTypeMatrix setEnabled: !locked];
    [runDefinitionsButton setEnabled:!locked];
    [clearAllTypesButton setEnabled:!locked];
}

#pragma  mark ���Actions

- (IBAction) openStartScript:(id)sender
{
	[[model startScript] makeMainController];
}

- (IBAction) openShutDownScript:(id)sender
{
	[[model shutDownScript] makeMainController];
}


- (IBAction) startRunAction:(id)sender
{
	if([[model document] isDocumentEdited]){
		[[model document] afterSaveDo:@selector(startRun) withTarget:self];
        [[model document] saveDocument:[self document]];
    }
	else [self startRun];
}

- (void) startRun
{
	[self endEditing];
	[statusField setStringValue:@"Starting..."];
	[startRunButton setEnabled:NO];
	[restartRunButton setEnabled:NO];
	[restartRunButton1 setEnabled:NO];
	[subRunButton setEnabled:NO];
	[stopRunButton setEnabled:NO];
	[model performSelector:@selector(startRun)withObject:nil afterDelay:.1];
}

- (IBAction) newRunAction:(id)sender
{
    [self endEditing];
    [statusField setStringValue:@"Restart..."];
    [startRunButton setEnabled:NO];
    [restartRunButton setEnabled:NO];
    [restartRunButton1 setEnabled:NO];
 	[subRunButton setEnabled:NO];
	[stopRunButton setEnabled:NO];
    [model setForceRestart:YES];
    [model setPrepareForNewSubRun:NO];
    [model performSelector:@selector(stopRun) withObject:nil afterDelay:0];
}

- (IBAction) newSubRunAction:(id)sender
{
    [self endEditing];
    [statusField setStringValue:@"Restart..."];
    [startRunButton setEnabled:NO];
    [restartRunButton setEnabled:NO];
    [restartRunButton1 setEnabled:NO];
	[subRunButton setEnabled:NO];
    [stopRunButton setEnabled:NO];
    [model setForceRestart:YES];
    [model setPrepareForNewSubRun:YES];
    [model performSelector:@selector(stopRun) withObject:nil afterDelay:0];
}


- (IBAction) stopRunAction:(id)sender
{
    [self endEditing];
    [statusField setStringValue:@"Stopping..."];
    [model performSelector:@selector(haltRun)withObject:nil afterDelay:.1];
}

- (IBAction) remoteControlAction:(id)sender
{
    if([model remoteControl] != [sender intValue]){
        [[self undoManager] setActionName: @"Set Run Remote Control"];
        [model setRemoteControl:[sender intValue]];
        if(![model remoteControl]){
            [model setRemoteInterface:NO];
        }
    }
}

- (IBAction) quickStartCBAction:(id)sender
{
    if([model quickStart] != [sender intValue]){
        [[self undoManager] setActionName: @"Set Quick Start"];
        [model setQuickStart:[sender intValue]];
    }
}

- (IBAction) timeLimitStepperAction:(id)sender
{
    if([model timeLimit] != [sender intValue]){
        [[self undoManager] setActionName: @"Set Run Time Limit"];
        [model setTimeLimit:[sender intValue]];
    }
}

- (IBAction) timeLimitTextAction:(id)sender
{
    if([model timeLimit] != [sender intValue]){
        [[self undoManager] setActionName: @"Set Run Time Limit"];
        [model setTimeLimit:[sender intValue]];
    }
}


- (IBAction) timedRunCBAction:(id)sender
{
    if([model timedRun] != [sender intValue]){
        [[self undoManager] setActionName: @"Set Timed Run"];
        [model setTimedRun:[sender intValue]];
    }
}

- (IBAction) repeatRunCBAction:(id)sender
{
    if([model repeatRun] != [sender intValue]){
        [[self undoManager] setActionName: @"Set Repeat Run"];
        [model setRepeatRun:[sender intValue]];
    }
}

- (IBAction) runNumberAction:(id)sender
{
    if([sender intValue] != [model runNumber]){
        [[self undoManager] setActionName: @"Set Run Number"];
        [model setRunNumber:[sender intValue]];
    }
}

- (IBAction) runModeAction:(id)sender
{
    int tag = [[runModeMatrix selectedCell] tag];
    if(tag != [[ORGlobal sharedGlobal] runMode]){
        [[self undoManager] setActionName: @"Set Run Mode"];
		[model setOfflineRun:tag];
    }
}

- (IBAction) chooseDir:(id)sender
{

    NSString* startDir = NSHomeDirectory(); //default to home
    if([model definitionsFilePath]){
        startDir = [[model definitionsFilePath]stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    [openPanel beginSheetForDirectory:startDir
                                 file:nil
                                types:nil
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
}
- (void) openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        NSString* dirName = [[[sheet filenames] objectAtIndex:0] stringByAbbreviatingWithTildeInPath];
        [model setDirName:dirName];
    }
}

- (IBAction) definitionsFileAction:(id)sender
{
    NSString* startDir = NSHomeDirectory(); //default to home
    if([model definitionsFilePath]){
        startDir = [[model definitionsFilePath]stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }



    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    [openPanel beginSheetForDirectory:startDir
                                 file:nil
                                types:nil
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(definitionsPanelDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
}


- (void) definitionsPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        [model setDefinitionsFilePath:[[sheet filenames] objectAtIndex:0]];
        if(![model readRunTypeNames]){
            NSLogColor([NSColor redColor],@"Unable to parse <%@> as a run type def file.\n",[[[sheet filenames] objectAtIndex:0] stringByAbbreviatingWithTildeInPath]);
            NSLogColor([NSColor redColor],@"File must be list of items of the form: itemNumber,itemName\n");	
            [model setDefinitionsFilePath:nil];
        }
        else {
            [self definitionsFileChanged:nil];
        }
    }
}


- (IBAction) runTypeAction:(id)sender
{
    short i = [[sender selectedCell] tag];
    BOOL state  = [[sender selectedCell] state];
    unsigned long currentRunMask = [model runType];
    if(state)currentRunMask |= (1L<<i);
    else      currentRunMask &= ~(1L<<i);
    
    [model setRunType:currentRunMask];
}

- (IBAction) clearRunTypeAction:(id)sender
{
    [model setRunType:0L];
}

- (IBAction) runNumberLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORRunNumberLock to:[sender intValue] forWindow:[runNumberDrawer parentWindow]];
}

- (IBAction) runTypeLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORRunTypeLock to:[sender intValue] forWindow:[runTypeDrawer parentWindow]];
}

- (IBAction) listVetoAction:(id)sender
{
	[[ORGlobal sharedGlobal] listVetoReasons];
}

- (IBAction) selectStartUpScript:(id)sender
{
	NSString* name = [sender titleOfSelectedItem];
	NSArray* runScripts = [[model document] collectObjectsOfClass:[ORRunScriptModel class]];
	ORRunScriptModel* obj;
	NSEnumerator* e = [runScripts objectEnumerator];
	ORRunScriptModel* selectedObj = nil;
	while(obj = [e nextObject]){
		if([name isEqualToString:[obj identifier]]){
			selectedObj = obj;
			break;
		}
	}
	[model setStartScript:selectedObj];
}

- (IBAction) selectShutDownScript:(id)sender
{
	NSString* name = [sender titleOfSelectedItem];
	NSArray* runScripts = [[model document] collectObjectsOfClass:[ORRunScriptModel class]];
	ORRunScriptModel* obj;
	NSEnumerator* e = [runScripts objectEnumerator];
	ORRunScriptModel* selectedObj = nil;
	while(obj = [e nextObject]){
		if([name isEqualToString:[obj identifier]]){
			selectedObj = obj;
			break;
		}
	}
	[model setShutDownScript:selectedObj];
}

- (void) updateWithCurrentRunNumber
{
    [model getCurrentRunNumber];
    [self updateWindow];
}

- (void) drawerWillOpen:(NSNotification *)notification
{
    [model getCurrentRunNumber];
    [self updateWindow];
}

- (void) drawerDidOpen:(NSNotification *)notification
{
    if([notification object] == runNumberDrawer){
        [runNumberButton setTitle:@"Close"];
        [runTypeDrawer close];
    }
    else {
        [runTypeButton setTitle:@"Close"];
        [runNumberDrawer close];
    }
}

- (void) drawerDidClose:(NSNotification *)notification
{
    if([notification object] == runNumberDrawer){
        [runNumberButton setTitle:@"Run Number..."];
    }
    else {
        [runTypeButton setTitle:@"Run Type..."];
    }
}

- (void) setupRunTypeNames
{
    NSArray* theNames = [model runTypeNames];
    int n = [theNames count];
    int i;
    if(n){
        for(i=2;i<n;i++){
            [[runTypeMatrix cellWithTag:i] setTitle:[theNames objectAtIndex:i]];
        }
    }
    else {
        for(i=2;i<32;i++){
            [[runTypeMatrix cellWithTag:i] setTitle:[NSString stringWithFormat:@"Bit %d",i]];
        }
    }
}
@end

@implementation ORRunController (private)
- (void) populatePopups
{
	[[model undoManager] disableUndoRegistration];
	
	[startUpScripts removeAllItems];
	[shutDownScripts removeAllItems];
	[startUpScripts addItemWithTitle:@"---"];
	[shutDownScripts addItemWithTitle:@"---"];
	NSArray* runScripts = [[model document] collectObjectsOfClass:[ORRunScriptModel class]];
	ORRunScriptModel* obj;
	NSEnumerator* e = [runScripts objectEnumerator];
	while(obj = [e nextObject]){
		[startUpScripts addItemWithTitle:[obj identifier]]; 
		[shutDownScripts addItemWithTitle:[obj identifier]]; 
	}
	
	NSString* selectedItemName = [[model startScript] identifier];
	if(!selectedItemName || ![startUpScripts itemWithTitle:selectedItemName])selectedItemName = @"---";
	[startUpScripts selectItemWithTitle:selectedItemName]; 
	[self selectStartUpScript:startUpScripts];
	
	selectedItemName = [[model shutDownScript] identifier];
	if(!selectedItemName || ![shutDownScripts itemWithTitle:selectedItemName])selectedItemName = @"---";
	[shutDownScripts selectItemWithTitle:selectedItemName]; 
	[self selectShutDownScript:shutDownScripts];

	[[model undoManager] enableUndoRegistration];
}

@end

