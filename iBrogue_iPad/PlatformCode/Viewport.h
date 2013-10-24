//
//  Viewport.h
//  Brogue
//
//  Created by Brian and Kevin Walker.
//  Updated for iOS by Seth Howard on 03/01/13.
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

#import <UIKit/UIKit.h>
#import "ACMagnifyingView.h"

#define kROWS		(30+3+1)
#define kCOLS		100
#define FONT_SIZE	16

@interface Viewport : ACMagnifyingView

/**
 Adds a character to the screen at a particular location.
 
 @param cString The character's NSString representation. The caller will pass nil unless the character is unicode.
 @param bgColor The backing pixel/rectangle color at the position of this character.
 @param letterColor The color of the letter.
 @param location The rectangle as represented by it's x and y coords in a 2D array.
 @param character Passed along for preferred ASCII drawing as well as short comparisons.
 */
- (void)setString:(NSString *)cString withBackgroundColor:(CGColorRef)bgColor letterColor:(CGColorRef)letterColor atLocation:(CGPoint)location withChar:(unsigned short)character;

/// The game's horizontal window size.
@property (nonatomic, readonly) short hWindow;
/// The game's vertical window size.
@property (nonatomic, readonly) short vWindow;

@end
