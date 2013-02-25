//
//  RogueDriver.m
//  Brogue
//
//  Created by Brian and Kevin Walker on 12/26/08.
//  Copyright 2012. All rights reserved.
//
//  This file is part of Brogue.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as
//  published by the Free Software Foundation, either version 3 of the
//  License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#include <limits.h>
#include <unistd.h>
#include "CoreFoundation/CoreFoundation.h"
#import "RogueDriver.h"
#import "ViewController.h"

#define BROGUE_VERSION	4	// A special version number that's incremented only when
// something about the OS X high scores file structure changes.

//static Viewport *theMainDisplay;
NSDate *pauseStartDate;
short mouseX, mouseY;

@implementation RogueDriver
/*
- (void)awakeFromNib
{
	extern Viewport *theMainDisplay;
	NSSize theSize;
	short versionNumber;
    
	versionNumber = [[NSUserDefaults standardUserDefaults] integerForKey:@"Brogue version"];
	if (versionNumber == 0 || versionNumber < BROGUE_VERSION) {
		// This is so we know when to purge the relevant preferences and save them anew.
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"NSWindow Frame Brogue main window"];
        
		if (versionNumber != 0) {
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Brogue version"];
		}
		[[NSUserDefaults standardUserDefaults] setInteger:BROGUE_VERSION forKey:@"Brogue version"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
    
	theMainDisplay = theDisplay;
	[theWindow setFrameAutosaveName:@"Brogue main window"];
	[theWindow useOptimizedDrawing:YES];
	[theWindow setAcceptsMouseMovedEvents:YES];
    
    // Comment out this line if you're trying to compile on a system earlier than OS X 10.7:
    [theWindow setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
    
	theSize.height = 7 * VERT_PX * kROWS / FONT_SIZE;
	theSize.width = 7 * HORIZ_PX * kCOLS / FONT_SIZE;
	[theWindow setContentMinSize:theSize];
    
	mouseX = mouseY = 0;
}

- (IBAction)playBrogue:(id)sender
{
    //UNUSED(sender);
    //	[fileMenu setAutoenablesItems:NO];
	rogueMain();
    //	[fileMenu setAutoenablesItems:YES];
	//exit(0);
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    //UNUSED(aNotification);
	[theWindow makeMainWindow];
	[theWindow makeKeyWindow];
	[self windowDidResize:nil];
	//NSLog(@"\nAspect ratio is %@", [theWindow aspectRatio]);
	[self playBrogue:nil];
	[NSApp terminate:nil];
}

- (void)windowDidResize:(NSNotification *)aNotification
{
    //UNUSED(aNotification);
    NSRect theRect;
    NSSize testSizeBox;
    NSMutableDictionary *theAttributes = [[NSMutableDictionary alloc] init];
    short theWidth, theHeight, theSize;
    
    theRect = [theWindow contentRectForFrameRect:[theWindow frame]];
    theWidth = theRect.size.width;
    theHeight = theRect.size.height;
    theSize = min(FONT_SIZE * theWidth / (HORIZ_PX * kCOLS), FONT_SIZE * theHeight / (VERT_PX * kROWS));
    //NSLog(@"Start theSize=%d (w=%d, h=%d)", theSize, theWidth, theHeight);
    do {
        [theAttributes setObject:[NSFont fontWithName:[theMainDisplay fontName] size:theSize] forKey:NSFontAttributeName];
        testSizeBox = [@"a" sizeWithAttributes:theAttributes];
        //NSLog(@"theSize=%d testSizeBox w=%f, h=%f", theSize, testSizeBox.width, testSizeBox.height);
        theSize++;
    } while (testSizeBox.width < theWidth / kCOLS && testSizeBox.height < theHeight / kROWS);
    // Now theSize is one more than what was passed in to fontWithName:size:.  Also need to subtract 1 to get to the
    // last box that fit.
    //    [theMainDisplay setHorizPixels:(theWidth / kCOLS) vertPixels:(theHeight / kROWS) fontSize:max(theSize - 2, 9)];
    [theMainDisplay setHorizWindow:theWidth vertWindow:theHeight fontSize:max(theSize - 2, 9)];
    //NSLog(@"End theSize=%d (w=%d, h=%d)  (tW/kC=%f, tH/kR=%f)", theSize, theWidth, theHeight, (theWidth / (float)kCOLS), (theHeight / (float)kROWS));
    [theAttributes release];
}*/

//- (NSRect)windowWillUseStandardFrame:(NSWindow *)window
//					  defaultFrame:(NSRect)defaultFrame
//{
//	NSRect theRect;
//	if (defaultFrame.size.width > HORIZ_PX * kCOLS) {
//		theRect.size.width = HORIZ_PX * kCOLS;
//		theRect.size.height = VERT_PX * kROWS;
//	} else {
//		theRect.size.width = (HORIZ_PX - 1) * kCOLS;
//		theRect.size.height = (VERT_PX - 2) * kROWS;
//	}
//
//	theRect.origin = [window contentRectForFrameRect:[window frame]].origin;
//	theRect.origin.y += ([window contentRectForFrameRect:[window frame]].size.height - theRect.size.height);
//
//	if (th

@end

//  plotChar: plots inputChar at (xLoc, yLoc) with specified background and foreground colors.
//  Color components are given in ints from 0 to 100.

void plotChar(uchar inputChar,
			  short xLoc, short yLoc,
			  short foreRed, short foreGreen, short foreBlue,
			  short backRed, short backGreen, short backBlue) {
	@autoreleasepool {
        Viewport *theMainDisplay = [[ViewController sharedInstance] theDisplay];
        
        [theMainDisplay setString:[NSString stringWithCharacters:&inputChar length:1]
                   withBackground:[UIColor colorWithRed:((float)backRed/100.)
                                                        green:((float)backGreen/100.)
                                                         blue:((float)backBlue/100.)
                                                        alpha:(float)1]
                  withLetterColor:[UIColor colorWithRed:((float)foreRed/100.)
                                                        green:((float)foreGreen/100.)
                                                         blue:((float)foreBlue/100.)
                                                        alpha:(float)1]
                      atLocationX:xLoc locationY:yLoc
                    withFancyFont:(inputChar == FOLIAGE_CHAR)];
    }
}

void pausingTimerStartsNow() {
	pauseStartDate = [NSDate date];
 //   printf("\nPause timer started!");
}

// Returns true if the player interrupted the wait with a keystroke; otherwise false.
boolean pauseForMilliseconds(short milliseconds) {
	UIEvent *theEvent;
	NSDate *targetDate, *currentDate;
    //    NSComparisonResult theCompare;
    
 //   @autoreleasepool {
        currentDate = [NSDate date];
        if (pauseStartDate) {
            //            NSLog(@"\nStarting a pause: previous date was %@.", pauseStartDate);
            targetDate = [NSDate dateWithTimeInterval:((double) milliseconds) / 1000 sinceDate:pauseStartDate];
            pauseStartDate = NULL;
        } else {
            targetDate = [NSDate dateWithTimeIntervalSinceNow: ((double) milliseconds) / 1000];
        }
        //        theCompare = [targetDate compare:currentDate];
        
        //        if (theCompare != NSOrderedAscending) {
        do {
        /*    theEvent = [UIApplication nextEventMatchingMask:NSAnyEventMask untilDate:targetDate
                                             inMode:NSDefaultRunLoopMode dequeue:YES];
            if (([theEvent type] == NSKeyDown && !([theEvent modifierFlags] & NSCommandKeyMask))
                || [theEvent type] == NSLeftMouseUp
                || [theEvent type] == NSLeftMouseDown
                || [theEvent type] == NSRightMouseUp
                || [theEvent type] == NSRightMouseDown
                || [theEvent type] == NSMouseMoved
                || [theEvent type] == NSLeftMouseDragged
                || [theEvent type] == NSRightMouseDragged) {
                [UIApplication postEvent:theEvent atStart:TRUE]; // put the event back on the queue*/
                return true;
           // } else if (theEvent != nil) {
             //   [NSApp sendEvent:theEvent];
           // }
        } while (theEvent != nil);
        //        } else {
        //            [NSApp updateWindows];
        //            NSLog(@"\nSkipped a pause: target date was %@; current date was %@; comparison was %i.", targetDate, currentDate, theCompare);
        //        }
 //   }
	return false;
}

void nextKeyOrMouseEvent(rogueEvent *returnEvent, boolean textInput, boolean colorsDance) {
    return;
    
	//UNUSED(textInput);
    UIEvent *theEvent;
	UIEventType theEventType;
	CGPoint event_location;
	CGPoint local_point;
	short x, y;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        for(;;) {
            if (colorsDance) {
                shuffleTerrainColors(3, true);
                commitDraws();
            }
            
            /*         theEvent = [NSApp nextEventMatchingMask:NSAnyEventMask
             untilDate:[NSDate dateWithTimeIntervalSinceNow: ((NSTimeInterval) ((double) 50) / ((double) 1000))]
             inMode:NSDefaultRunLoopMode
             dequeue:YES];
             theEventType = [theEvent type];
             if (theEventType == NSKeyDown && !([theEvent modifierFlags] & NSCommandKeyMask)) {
             returnEvent->eventType = KEYSTROKE;
             returnEvent->param1 = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
             //printf("\nKey pressed: %i", returnEvent->param1);
             returnEvent->param2 = 0;
             returnEvent->controlKey = ([theEvent modifierFlags] & NSControlKeyMask ? 1 : 0);
             returnEvent->shiftKey = ([theEvent modifierFlags] & NSShiftKeyMask ? 1 : 0);
             break;
             } else if (theEventType == NSLeftMouseDown
             || theEventType == NSLeftMouseUp
             || theEventType == NSRightMouseDown
             || theEventType == NSRightMouseUp
             || theEventType == NSMouseMoved
             || theEventType == NSLeftMouseDragged
             || theEventType == NSRightMouseDragged) {
             [NSApp sendEvent:theEvent];
             switch (theEventType) {
             case NSLeftMouseDown:
             returnEvent->eventType = MOUSE_DOWN;
             break;
             case NSLeftMouseUp:
             returnEvent->eventType = MOUSE_UP;
             break;
             case NSRightMouseDown:
             returnEvent->eventType = RIGHT_MOUSE_DOWN;
             break;
             case NSRightMouseUp:
             returnEvent->eventType = RIGHT_MOUSE_UP;
             break;
             case NSMouseMoved:
             case NSLeftMouseDragged:
             case NSRightMouseDragged:
             returnEvent->eventType = MOUSE_ENTERED_CELL;
             break;
             default:
             break;
             }
             event_location = [theEvent locationInWindow];
             local_point = [theMainDisplay convertPoint:event_location fromView:nil];
             x = COLS * local_point.x / [theMainDisplay horizWindow];
             y = ROWS - (ROWS * local_point.y / [theMainDisplay vertWindow]);
             // Correct for the fact that truncation occurs in a positive direction when we're below zero:
             if (local_point.x < 0) {
             x--;
             }
             if ([theMainDisplay vertWindow] < local_point.y) {
             y--;
             }
             returnEvent->param1 = x;
             returnEvent->param2 = y;
             returnEvent->controlKey = ([theEvent modifierFlags] & NSControlKeyMask ? 1 : 0);
             returnEvent->shiftKey = ([theEvent modifierFlags] & NSShiftKeyMask ? 1 : 0);
             //			if (theEventType != NSMouseMoved || x != mouseX || y != mouseY) { // Don't send mouse_entered_cell events if the cell hasn't changed
             mouseX = x;
             mouseY = y;
             break;
             //			}
             }
             if (theEvent != nil) {
             [NSApp sendEvent:theEvent]; // pass along any other events so, e.g., the menus work
             }*/
            
            //[[UIApplication sharedApplication] sendEvent:theEvent];
        }
        // printf("\nRogueEvent: eventType: %i, param1: %i, param2: %i, controlKey: %s, shiftKey: %s", returnEvent->eventType, returnEvent->param1,
        //			 returnEvent->param2, returnEvent->controlKey ? "true" : "false", returnEvent->shiftKey ? "true" : "false");
        

    });
}

boolean controlKeyIsDown() {
	//return (([[UIap currentEvent] modifierFlags] & NSControlKeyMask) ? true : false);
    return NO;
}

boolean shiftKeyIsDown() {
	//return (([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask) ? true : false);
    return NO;
}

void initHighScores() {
	NSMutableArray *scoresArray, *textArray, *datesArray;
	short j, theCount;
    
	if ([[NSUserDefaults standardUserDefaults] arrayForKey:@"high scores scores"] == nil
		|| [[NSUserDefaults standardUserDefaults] arrayForKey:@"high scores text"] == nil
		|| [[NSUserDefaults standardUserDefaults] arrayForKey:@"high scores dates"] == nil) {
        
		scoresArray = [NSMutableArray arrayWithCapacity:HIGH_SCORES_COUNT];
		textArray = [NSMutableArray arrayWithCapacity:HIGH_SCORES_COUNT];
		datesArray = [NSMutableArray arrayWithCapacity:HIGH_SCORES_COUNT];
        
		for (j=0; j<HIGH_SCORES_COUNT; j++) {
			[scoresArray addObject:[NSNumber numberWithLong:0]];
			[textArray addObject:[NSString string]];
			[datesArray addObject:[NSDate date]];
		}
        
		[[NSUserDefaults standardUserDefaults] setObject:scoresArray forKey:@"high scores scores"];
		[[NSUserDefaults standardUserDefaults] setObject:textArray forKey:@"high scores text"];
		[[NSUserDefaults standardUserDefaults] setObject:datesArray forKey:@"high scores dates"];
	}
    
	theCount = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"high scores scores"] count];
    
	if (theCount < HIGH_SCORES_COUNT) { // backwards compatibility
		scoresArray = [NSMutableArray arrayWithCapacity:HIGH_SCORES_COUNT];
		textArray = [NSMutableArray arrayWithCapacity:HIGH_SCORES_COUNT];
		datesArray = [NSMutableArray arrayWithCapacity:HIGH_SCORES_COUNT];
        
		[scoresArray setArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"high scores scores"]];
		[textArray setArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"high scores text"]];
		[datesArray setArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"high scores dates"]];
        
		for (j=theCount; j<HIGH_SCORES_COUNT; j++) {
			[scoresArray addObject:[NSNumber numberWithLong:0]];
			[textArray addObject:[NSString string]];
			[datesArray addObject:[NSDate date]];
		}
        
		[[NSUserDefaults standardUserDefaults] setObject:scoresArray forKey:@"high scores scores"];
		[[NSUserDefaults standardUserDefaults] setObject:textArray forKey:@"high scores text"];
		[[NSUserDefaults standardUserDefaults] setObject:datesArray forKey:@"high scores dates"];
	}
}

// returns the index number of the most recent score
short getHighScoresList(rogueHighScoresEntry returnList[HIGH_SCORES_COUNT]) {
	NSArray *scoresArray, *textArray, *datesArray;
	NSDateFormatter *dateFormatter;
	NSDate *mostRecentDate;
	short i, j, maxIndex, mostRecentIndex;
	long maxScore;
	boolean scoreTaken[HIGH_SCORES_COUNT];
    
	// no scores have been taken
	for (i=0; i<HIGH_SCORES_COUNT; i++) {
		scoreTaken[i] = false;
	}
    
	initHighScores();
    
	scoresArray = [[NSUserDefaults standardUserDefaults] arrayForKey:@"high scores scores"];
	textArray = [[NSUserDefaults standardUserDefaults] arrayForKey:@"high scores text"];
	datesArray = [[NSUserDefaults standardUserDefaults] arrayForKey:@"high scores dates"];
    
	mostRecentDate = [NSDate distantPast];
	//dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%1m/%1d/%y"];
    
	// store each value in order into returnList
	for (i=0; i<HIGH_SCORES_COUNT; i++) {
		// find the highest value that hasn't already been taken
		maxScore = 0; // excludes scores of zero
		for (j=0; j<HIGH_SCORES_COUNT; j++) {
			if (scoreTaken[j] == false && [[scoresArray objectAtIndex:j] longValue] >= maxScore) {
				maxScore = [[scoresArray objectAtIndex:j] longValue];
				maxIndex = j;
			}
		}
		// maxIndex identifies the highest non-taken score
		scoreTaken[maxIndex] = true;
		returnList[i].score = [[scoresArray objectAtIndex:maxIndex] longValue];
		strcpy(returnList[i].description, [[textArray objectAtIndex:maxIndex] cStringUsingEncoding:NSASCIIStringEncoding]);
		strcpy(returnList[i].date, [[dateFormatter stringFromDate:[datesArray objectAtIndex:maxIndex]] cStringUsingEncoding:NSASCIIStringEncoding]);
        
		// if this is the most recent score we've seen so far
		if ([mostRecentDate compare:[datesArray objectAtIndex:maxIndex]] == NSOrderedAscending) {
			mostRecentDate = [datesArray objectAtIndex:maxIndex];
			mostRecentIndex = i;
		}
	}
	return mostRecentIndex;
}

// saves the high scores entry over the lowest-score entry if it qualifies.
// returns whether the score qualified for the list.
// This function ignores the date passed to it in theEntry and substitutes the current
// date instead.
boolean saveHighScore(rogueHighScoresEntry theEntry) {
	NSMutableArray *scoresArray, *textArray, *datesArray;
	NSNumber *newScore;
	NSString *newText;
    
	short j, minIndex = -1;
	long minScore = theEntry.score;
    
	// generate high scores if prefs don't exist or contain no high scores data
	initHighScores();
    
	scoresArray = [NSMutableArray arrayWithCapacity:HIGH_SCORES_COUNT];
	textArray = [NSMutableArray arrayWithCapacity:HIGH_SCORES_COUNT];
	datesArray = [NSMutableArray arrayWithCapacity:HIGH_SCORES_COUNT];
    
	[scoresArray setArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"high scores scores"]];
	[textArray setArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"high scores text"]];
	[datesArray setArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"high scores dates"]];
    
	// find the lowest value
	for (j=0; j<HIGH_SCORES_COUNT; j++) {
		if ([[scoresArray objectAtIndex:j] longValue] < minScore) {
			minScore = [[scoresArray objectAtIndex:j] longValue];
			minIndex = j;
		}
	}
    
	if (minIndex == -1) { // didn't qualify
		return false;
	}
    
	// minIndex identifies the score entry to be replaced
	newScore = [NSNumber numberWithLong:theEntry.score];
	newText = [NSString stringWithCString:theEntry.description encoding:NSASCIIStringEncoding];
	[scoresArray replaceObjectAtIndex:minIndex withObject:newScore];
	[textArray replaceObjectAtIndex:minIndex withObject:newText];
	[datesArray replaceObjectAtIndex:minIndex withObject:[NSDate date]];
    
	[[NSUserDefaults standardUserDefaults] setObject:scoresArray forKey:@"high scores scores"];
	[[NSUserDefaults standardUserDefaults] setObject:textArray forKey:@"high scores text"];
	[[NSUserDefaults standardUserDefaults] setObject:datesArray forKey:@"high scores dates"];
	[[NSUserDefaults standardUserDefaults] synchronize];
    
	return true;
}

void initializeLaunchArguments(enum NGCommands *command, char *path, unsigned long *seed) {
	//*command = NG_SCUM;
    *command = NG_NOTHING;
	path[0] = '\0';
	*seed = 0;
}

void initializeBrogueSaveLocation() {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *err;
    
    // Look up the full path to the user's Application Support folder (usually ~/Library/Application Support/).
    NSString *basePath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
    
    // Use a folder under Application Support named after the application.
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"];
    NSString *supportPath = [basePath stringByAppendingPathComponent: appName];
    
    // Create our folder the first time it is needed.
    if (![manager fileExistsAtPath: supportPath]) {
        [manager createDirectoryAtPath:supportPath withIntermediateDirectories:YES attributes:nil error:&err];
    }
    
    // Set the working directory to this path, so that savegames and recordings will be stored here.
    [manager changeCurrentDirectoryPath: supportPath];
}

#define ADD_FAKE_PADDING_FILES 0

// Returns a malloc'ed fileEntry array, and puts the file count into *fileCount.
// Also returns a pointer to the memory that holds the file names, so that it can also
// be freed afterward.
fileEntry *listFiles(short *fileCount, char **dynamicMemoryBuffer) {
	short i, count, thisFileNameLength;
	unsigned long bufferPosition, bufferSize;
	unsigned long *offsets;
	fileEntry *fileList;
	NSArray *array;
	NSFileManager *manager = [NSFileManager defaultManager];
    NSError *err;
	NSDictionary *fileAttributes;
	NSDateFormatter *dateFormatter;
	const char *thisFileName;
    
	char tempString[500];
    
	bufferPosition = bufferSize = 0;
	*dynamicMemoryBuffer = NULL;
    
	//dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%1m/%1d/%y" allowNaturalLanguage:YES];
    
	array = [manager contentsOfDirectoryAtPath:[manager currentDirectoryPath] error:&err];
	count = [array count];
    
	fileList = malloc((count + ADD_FAKE_PADDING_FILES) * sizeof(fileEntry));
	offsets = malloc((count + ADD_FAKE_PADDING_FILES) * sizeof(unsigned long));
    
	for (i=0; i < count + ADD_FAKE_PADDING_FILES; i++) {
		if (i < count) {
			thisFileName = [[array objectAtIndex:i] cStringUsingEncoding:NSASCIIStringEncoding];
			fileAttributes = [manager attributesOfItemAtPath:[array objectAtIndex:i] error:nil];
			strcpy(fileList[i].date,
				   [[dateFormatter stringFromDate:[fileAttributes fileModificationDate]] cStringUsingEncoding:NSASCIIStringEncoding]);
		} else {
			// Debug feature.
			sprintf(tempString, "Fake padding file %i.broguerec", i - count + 1);
			thisFileName = &(tempString[0]);
			strcpy(fileList[i].date, "12/12/12");
		}
        
		thisFileNameLength = strlen(thisFileName);
        
		if (thisFileNameLength + bufferPosition > bufferSize) {
			bufferSize += sizeof(char) * 1024;
			*dynamicMemoryBuffer = (char *) realloc(*dynamicMemoryBuffer, bufferSize);
		}
        
		offsets[i] = bufferPosition; // Have to store these as offsets instead of pointers, as realloc could invalidate pointers.
        
		strcpy(&((*dynamicMemoryBuffer)[bufferPosition]), thisFileName);
		bufferPosition += thisFileNameLength + 1;
	}
    
	// Convert the offsets to pointers.
	for (i = 0; i < count + ADD_FAKE_PADDING_FILES; i++) {
		fileList[i].path = &((*dynamicMemoryBuffer)[offsets[i]]);
	}
    
	free(offsets);
    
	*fileCount = count + ADD_FAKE_PADDING_FILES;
	return fileList;
}
