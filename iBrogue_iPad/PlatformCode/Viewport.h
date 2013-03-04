//
//  Viewport.h
//  Brogue
//
//  Created by Brian and Kevin Walker.
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

#define	VERT_PX		18
#define	HORIZ_PX	11

#define kROWS		(30+3+1)
#define kCOLS		100

// This is only used as a starting point for the calculation after the
// window resizes.
#define FONT_SIZE	10
#define FONT_NAME	@"ArialUnicodeMS"

@interface Viewport : UIView
{
	NSString __strong *letterArray[kCOLS][kROWS];
	UIColor __strong *bgColorArray[kCOLS][kROWS];
	NSMutableDictionary __strong *attributes[kCOLS][kROWS];
	NSMutableDictionary __strong *characterSizeDictionary;
	CGRect rectArray[kCOLS][kROWS];
}

- (void)setString:(NSString *)c
   withBackground:(UIColor *)bgColor
  withLetterColor:(UIColor *)letterColor
	  atLocationX:(short)x
		locationY:(short)y
    withFancyFont:(bool)fancyFont;

- (void)drawTheString:(NSString *)theString centeredIn:(CGRect)rect withAttributes:(NSMutableDictionary *)theAttributes;

- (void)setHorizWindow:(short)hPx
			vertWindow:(short)vPx
			  fontSize:(short)size;

@property (nonatomic, assign) short hWindow;
@property (nonatomic, assign) short vWindow;

@end
