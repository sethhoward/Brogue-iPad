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
#import "AppDelegate.h"
#include "IncludeGlobals.h"
#include "Rogue.h"

void autoSave();

#define BROGUE_VERSION	4	// A special version number that's incremented only when
// something about the OS X high scores file structure changes.

short mouseX, mouseY;

@implementation RogueDriver

+ (void)autoSave {
 //   autoSave();
}

// this was all garbage in my book... trashed it

@end

//  plotChar: plots inputChar at (xLoc, yLoc) with specified background and foreground colors.
//  Color components are given in ints from 0 to 100.
void plotChar(uchar inputChar,
			  short xLoc, short yLoc,
			  short foreRed, short foreGreen, short foreBlue,
			  short backRed, short backGreen, short backBlue) {
    @autoreleasepool {
        [theMainDisplay setString:[NSString stringWithCharacters:&inputChar length:1]
                   withBackground:[UIColor colorWithRed:((float)backRed/100)
                                                  green:((float)backGreen/100)
                                                   blue:((float)backBlue/100)
                                                  alpha:(float)1]
                  withLetterColor:[UIColor colorWithRed:((float)foreRed/100)
                                                  green:((float)foreGreen/100)
                                                   blue:((float)foreBlue/100)
                                                  alpha:(float)1]
                      atLocationX:xLoc locationY:yLoc
                    withFancyFont:(inputChar == FOLIAGE_CHAR)];
    }
}

void pausingTimerStartsNow() {

}

// Returns true if the player interrupted the wait with a keystroke; otherwise false.
boolean pauseForMilliseconds(short milliseconds) {
    BOOL hasEvent = NO;
    
    [NSThread sleepForTimeInterval:milliseconds/1000.0f];
        
    if ([viewController cachedTouchesCount] > 0) {
        hasEvent = YES;
    }

	return hasEvent;
}

/*
 UITouchPhaseBegan,
 UITouchPhaseMoved,
 UITouchPhaseStationary,
 UITouchPhaseEnded,
 UITouchPhaseCancelled,
 */

void showDirectionControls(boolean show) {
    if (show) {
        [viewController showControls];
    }
    else {
        [viewController hideControls];
    }
}

void nextKeyOrMouseEvent(rogueEvent *returnEvent, __unused boolean textInput, boolean colorsDance) {
	CGPoint event_location;
	short x, y;
    
    @autoreleasepool {
        for(;;) {
            [NSThread sleepForTimeInterval:0.05];
            
            //  NSLog(@"%i", rogue.nextGame);
            if (colorsDance) {
                shuffleTerrainColors(3, true);
                commitDraws();
            }
            
            if ([viewController cachedKeyStrokeCount] > 0) {
                returnEvent->eventType = KEYSTROKE;
                returnEvent->param1 = [viewController dequeKeyStroke];
                //printf("\nKey pressed: %i", returnEvent->param1);
                returnEvent->param2 = 0;
                returnEvent->controlKey = 0;//([theEvent modifierFlags] & NSControlKeyMask ? 1 : 0);
                returnEvent->shiftKey = 0;//([theEvent modifierFlags] & NSShiftKeyMask ? 1 : 0);
                break;
            }
            if ([viewController cachedTouchesCount] > 0) {
                iBTouch touch = [viewController getTouchAtIndex:0];
                UITouchPhase phase = touch.phase;
                
                if (phase != UITouchPhaseCancelled) {
                    switch (phase) {
                        case UITouchPhaseBegan:
                        case UITouchPhaseStationary:
                            returnEvent->eventType = MOUSE_DOWN;
                            break;
                        case UITouchPhaseEnded:
                            returnEvent->eventType = MOUSE_UP;
                            break;
                        case UITouchPhaseMoved:
                            returnEvent->eventType = MOUSE_ENTERED_CELL;
                            break;
                        default:
                            break;
                    }
                    
                    //    NSLog(@"Event %i w/Touch: %@", returnEvent->eventType, touch);
                    
                    event_location = touch.location;
                    x = COLS * event_location.x / [theMainDisplay hWindow];
                    y = (ROWS * event_location.y / [theMainDisplay vWindow]);
                    // Correct for the fact that truncation occurs in a positive direction when we're below zero:
                    if (event_location.x < 0) {
                        x--;
                    }
                    if ([theMainDisplay vWindow] < event_location.y) {
                        y--;
                    }
                    returnEvent->param1 = x;
                    returnEvent->param2 = y;
                    returnEvent->controlKey = 0;
                    returnEvent->shiftKey = 0;
                    
                    [viewController removeTouchAtIndex:0];
                    break;
                }
            }
        }
    }
}

boolean controlKeyIsDown() {
    return NO;
}

boolean shiftKeyIsDown() {
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
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// returns the index number of the most recent score
short getHighScoresList(rogueHighScoresEntry returnList[HIGH_SCORES_COUNT]) {
	NSArray *scoresArray, *textArray, *datesArray;
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"mm/dd/yy"];
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

// TODO: going to assume every save highscore qualifies as an end game screen.

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
    
	dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"mm/dd/yy"];//                initWithDateFormat:@"%1m/%1d/%y" allowNaturalLanguage:YES];
    
	array = [manager contentsOfDirectoryAtPath:[manager currentDirectoryPath] error:&err];
	count = [array count];
    
	fileList = (fileEntry *)malloc((count + ADD_FAKE_PADDING_FILES) * sizeof(fileEntry));
	offsets = (unsigned long*)malloc((count + ADD_FAKE_PADDING_FILES) * sizeof(unsigned long));
    
	for (i=0; i < count + ADD_FAKE_PADDING_FILES; i++) {
		if (i < count) {
			thisFileName = [[array objectAtIndex:i] cStringUsingEncoding:NSASCIIStringEncoding];
			fileAttributes = [manager attributesOfItemAtPath:[array objectAtIndex:i] error:nil];
            
            const char *date = [[dateFormatter stringFromDate:[fileAttributes fileModificationDate]] cStringUsingEncoding:NSASCIIStringEncoding];
            
			strcpy(fileList[i].date,
				   date);
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

void setWaitingForInput(boolean waiting) {
    [viewController showKeyboard];
}

//warning essentially lifted from the save code in Recordings.c
//warning redefines what Last Game is used for

// we're on a mobile device so we'll want to do this every now and then or really piss off some users
/*
void autoSave() {
    short i;
	FILE *recordFile;
    lengthOfPlaybackFile += locationInRecordingBuffer;
    
    if (lengthOfPlaybackFile != 0) {
		writeHeaderInfo(currentFilePath);
        
		recordFile = fopen(currentFilePath, "ab");
		
		for (i=0; i<locationInRecordingBuffer; i++) {
			putc(inputRecordBuffer[i], recordFile);
		}
		
		if (recordFile) {
			fclose(recordFile);
		}
		
		locationInRecordingBuffer = 0;
	}
}
*/