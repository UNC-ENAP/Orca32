//
//  ORReplayDataController.m
//  Orca
//
//  Created by Rielage on Thu Oct 02 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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
#import "ORReplayDataController.h"
#import "ORReplayDataModel.h"
#import "ORHeaderItem.h"
#import "ORDataSet.h"

@interface ORReplayDataController (private)
- (void) openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) saveListDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) loadListDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) addDirectoryContents:(NSString*)path toArray:(NSMutableArray*)anArray;
- (void) processFileList:(NSArray*)filenames;
@end

@implementation ORReplayDataController

#pragma mark ���Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"ReplayData"];
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super dealloc];
}

- (void) awakeFromNib
{
    [fileListView registerForDraggedTypes: [NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
	[progressIndicatorBottom setIndeterminate:NO];
    [super awakeFromNib];    
}

#pragma mark ���Accessors


#pragma  mark ���Actions
- (IBAction) selectButtonAction:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel setPrompt:@"Choose"];
    //see if we can use the last dir for a starting point...
    NSString* startDir = NSHomeDirectory(); //default to home
    if([model lastFilePath]){
        startDir = [[model lastFilePath] stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }
    
    [openPanel beginSheetForDirectory:startDir
                                 file:nil
                                types:nil
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
    
}

- (IBAction)delete:(id)sender
{
    [self removeItemAction:nil];
}

- (IBAction)cut:(id)sender
{
    [self removeItemAction:nil];
}

- (IBAction) removeItemAction:(id)sender
{ 
    [model removeFilesWithIndexes:[fileListView selectedRowIndexes]];
    
    [fileListView reloadData];
    [fileListView deselectAll:self];
}


- (IBAction) replayButtonAction:(id)sender
{
    if(![model isReplaying]){
        [model replayFiles];
        [selectButton setEnabled:NO];
    }
    else {
        [model stopReplay];
    }
}

- (IBAction) saveListAction:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save"];
    //see if we can use the last dir for a starting point...
    NSString* startDir = NSHomeDirectory(); //default to home
    if([model lastListPath]){
        startDir = [[model lastListPath] stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }
    [savePanel beginSheetForDirectory:startDir
								 file:nil
					   modalForWindow:[self window]
						modalDelegate:self
					   didEndSelector:@selector(saveListDidEnd:returnCode:contextInfo:)
						  contextInfo:nil];
    
}

- (IBAction) loadListAction:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel setPrompt:@"Choose"];
    //see if we can use the last dir for a starting point...
    NSString* startDir = NSHomeDirectory(); //default to home
    if([model lastListPath]){
        startDir = [[model lastListPath] stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }
    
    [openPanel beginSheetForDirectory:startDir
                                 file:nil
                                types:nil
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(loadListDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
	
}


#pragma mark ���Interface Management
- (void) registerNotificationObservers
{
	[super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
                     selector : @selector(fileListChanged:)
                         name : ORReplayFileListChangedNotification
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(started:)
                         name : ORReplayRunningNotification
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(stopped:)
                         name : ORReplayStoppedNotification
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(reading:)
                         name : ORReplayReadingNotification
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(reading:)
                         name : ORReplayReadingNotification
                        object: model];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(parsing:)
                         name : ORReplayParseStartedNotification
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(fileChanged:)
                         name : ORRelayFileChangedNotification
                        object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(processing:)
                         name : ORReplayProcessingStartedNotification
                        object: model];

	[notifyCenter addObserver : self
                     selector : @selector(tableViewSelectionDidChange:)
                         name : NSTableViewSelectionDidChangeNotification
                        object: nil];

}

- (void) updateWindow
{
    [self fileListChanged:nil];
    [self fileChanged:nil];
	[workingOnField setStringValue:@""];
}


- (void)started:(NSNotification *)aNotification
{
	[fileListView setEnabled:NO];
	[replayButton setEnabled:YES];
	[selectButton setEnabled:NO];
	[replayButton setTitle:@"Stop"];
	[progressIndicator startAnimation:self];
	[progressField setStringValue:@"In Progress"];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateProgress) object:nil];
}

- (void) updateProgress
{
    double total = [model totalLength];
    double current = [model lengthDecoded];
    
    if(total>0)[progressIndicatorBottom setDoubleValue:100. - (100.*current/(double)total)];
    [self performSelector:@selector(updateProgress) withObject:nil afterDelay:0.1];
}

- (void)stopped:(NSNotification *)aNotification
{
	[fileListView setEnabled:YES];
	[replayButton setEnabled:YES];
	[selectButton setEnabled:YES];
	[replayButton setTitle:@"Start Replay"];
	[progressIndicator stopAnimation:self];
	[progressField setStringValue:@""];
	[workingOnField setStringValue:@""];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateProgress) object:nil];
	[progressIndicatorBottom setDoubleValue:0.0];
	[progressIndicatorBottom stopAnimation:self];
}

- (void) updateProgressBottom 
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateProgressBottom) object:nil];
	[progressIndicatorBottom setDoubleValue:0];
	[self performSelector:@selector(updateProgressBottom) withObject:nil afterDelay:.2];
}

- (void) reading:(NSNotification *)aNotification
{
	[progressField setStringValue:@"Reading"];
	NSString* theFileName = [model fileToReplay];
	if(theFileName)[workingOnField setStringValue:[NSString stringWithFormat:@"Reading:%@",[theFileName stringByAbbreviatingWithTildeInPath]]];
	else [workingOnField setStringValue:@""];
	[progressIndicatorBottom setIndeterminate:YES];
	[progressIndicatorBottom startAnimation:self];
}

- (void) parsing:(NSNotification *)aNotification
{
	[progressField setStringValue:@"Parsing"];
	NSString* theFileName = [model fileToReplay];
	if(theFileName)[workingOnField setStringValue:[NSString stringWithFormat:@"Parsing:%@",[theFileName stringByAbbreviatingWithTildeInPath]]];
	else [workingOnField setStringValue:@""];
	[progressIndicatorBottom setIndeterminate:NO];
	[progressIndicatorBottom setDoubleValue:0];
	[self performSelector:@selector(updateProgress) withObject:nil afterDelay:0.0];
}

- (void) processing:(NSNotification *)aNotification
{
	[progressField setStringValue:@"Processing"];
	NSString* theFileName = [model fileToReplay];
	if(theFileName)[workingOnField setStringValue:[NSString stringWithFormat:@"Processing:%@",[theFileName stringByAbbreviatingWithTildeInPath]]];
	else [workingOnField setStringValue:@""];
	[progressIndicatorBottom setIndeterminate:NO];
	[progressIndicatorBottom setDoubleValue:0];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateProgressBottom) object:nil];
	[self performSelector:@selector(updateProgress) withObject:nil afterDelay:0.1];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if([aNotification object] == fileListView){
		if(![model isReplaying]){
			[self loadHeader];
		}
	}
}

- (void) loadHeader
{
    int n = [fileListView numberOfSelectedRows];
    if(n <= 1){
        int index;
        if(n == 1)index = [fileListView selectedRow];
        else index = 0;
        [model readHeaderForFileIndex:index];
        if([[model filesToReplay] count]){
            [viewHeaderFile setStringValue:[[[model filesToReplay] objectAtIndex:index] stringByAbbreviatingWithTildeInPath]];
        }
        else [viewHeaderFile setStringValue:@"---"];
        [model readHeaderForFileIndex:index];
		
        [headerView reloadData];
    }
}

#pragma mark ���Interface Management
- (void) fileChanged:(NSNotification *)aNotification
{
	NSString* theFileName = [model fileToReplay];
	if(theFileName)[workingOnField setStringValue:[NSString stringWithFormat:@"Processing:%@",[theFileName stringByAbbreviatingWithTildeInPath]]];
	else [workingOnField setStringValue:@""];
}

- (void) fileListChanged:(NSNotification*)note
{
	[self loadHeader];
}

- (void) drawerDidOpen:(NSNotification *)notification
{
    [viewHeaderButton setTitle:@"Close"];
    [self loadHeader];
    [headerView reloadData];	
}

- (void) drawerDidClose:(NSNotification *)notification
{
    [viewHeaderButton setTitle:@"View Header"];
}



#pragma mark ���Data Source Methods

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item 
{
    if(outlineView == headerView){
        if(!item) return [[model header] count];
        else      return [item count]; 
    }
    else return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item 
{
    if(outlineView == headerView){
        if(!item) return [[model header] count]>0;
        else      return [item count]>0;
    }
    else return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item 
{
    if(outlineView == headerView){
        if(!item) return [[model header] childAtIndex:index];
        else      return [item childAtIndex:index];
    }
    else return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item 
{
    if(outlineView == headerView){
        if([[tableColumn identifier] isEqualToString:@"LevelName"]){
            if(item==0) return [[model header] name];
            else        return [item name];
        }
        else if([[tableColumn identifier] isEqualToString:@"Value"]){
            if(item==0){
                return [[NSAttributedString alloc] 
                        initWithString:[NSString stringWithFormat:@"%d key/value pairs",[[model header] count]] 
                            attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor grayColor],NSForegroundColorAttributeName,nil]];
            }
            else {
                if([item isLeafNode]){
                    return [NSString stringWithFormat:@"%@",[item object]];
                }
                else {
                    return [[NSAttributedString alloc] 
                        initWithString:[NSString stringWithFormat:@"%d key/value pairs",[item count]] 
                            attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor grayColor],NSForegroundColorAttributeName,nil]];            
                }
            }
        }
        
        else return nil;
    }
    else return nil;
}



- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
    if([[model filesToReplay] count]){
        id obj = [[model filesToReplay]  objectAtIndex:rowIndex];
        return [obj stringByAbbreviatingWithTildeInPath];
    }
    else return nil;
}

// just returns the number of items we have.
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    
    return [[model filesToReplay] count];
}


- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex
{
    [headerView setNeedsDisplay:YES];
    return YES;
}

- (NSDragOperation) tableView:(NSTableView *) tableView validateDrop:(id <NSDraggingInfo>) info proposedRow:(int) row proposedDropOperation:(NSTableViewDropOperation) operation
{
    return NSDragOperationCopy;
}

- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op
{
    NSPasteboard* pb = [info draggingPasteboard];
    NSData* data = [pb dataForType:NSFilenamesPboardType];
    NSFileManager* fm = [NSFileManager defaultManager];
    [fm createFileAtPath:@"OrcaJunkTemp" contents:data attributes:nil];
    [self processFileList:[NSArray arrayWithContentsOfFile:@"OrcaJunkTemp"]];
    [fm removeFileAtPath:@"OrcaJunkTemp" handler:nil];
    return YES;
}


@end

@implementation ORReplayDataController (private)
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        NSString* filePath = [[sheet filenames] objectAtIndex:0];
        [model setLastFilePath:filePath];
        [self processFileList:[sheet filenames]];
    }
}

-(void) processFileList:(NSArray*)filenames
{
    NSMutableArray* theFinalList = [NSMutableArray array];
    NSFileManager* fm = [NSFileManager defaultManager];
    NSEnumerator* e = [filenames objectEnumerator];
    BOOL isDirectory;
    id fileName;
    while(fileName = [e nextObject]){
        [fm fileExistsAtPath:fileName isDirectory:&isDirectory];
        if(!isDirectory){
            //just a file
            if([fileName rangeOfString:@"Run"].location != NSNotFound){
                [theFinalList addObject:fileName];
            }
        }
        else {
            //it's a directory
            [self addDirectoryContents:fileName toArray:theFinalList];
        }
    }
	
    [model addFilesToReplay:theFinalList];
    [fileListView reloadData];
}

- (void) addDirectoryContents:(NSString*)aPath toArray:(NSMutableArray*)anArray
{
    BOOL isDirectory;
    NSFileManager* fm = [NSFileManager defaultManager];
    [fm fileExistsAtPath:aPath isDirectory:&isDirectory];
    if(isDirectory){
        NSDirectoryEnumerator* e = [fm enumeratorAtPath:aPath];
        NSString *file;
        while (file = [e nextObject]) {
            [fm fileExistsAtPath:file isDirectory:&isDirectory];
            if(!isDirectory){
                //just a file
                if([file rangeOfString:@"Run"].location != NSNotFound){
                    [anArray addObject:[NSString stringWithFormat:@"%@/%@",aPath,file]];
                }
            }
            else {
                //it's a directory
                [self addDirectoryContents:file toArray:anArray];
            }
			
        }
    }
}


- (void) saveListDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        NSString* listPath = [[sheet filenames] objectAtIndex:0];
        [model setLastListPath:listPath];
        [[model filesToReplay] writeToFile:listPath atomically:YES];
    }
}

- (void) loadListDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        NSString* listPath = [[sheet filenames] objectAtIndex:0];
        NSMutableArray* theList = [NSMutableArray arrayWithContentsOfFile:listPath];
        if(theList){
            [model removeAll];
            [model addFilesToReplay:theList];
            [fileListView reloadData];
        }
        else NSLog(@"<%@> replay list is empty\n",listPath);
    }
}

@end


