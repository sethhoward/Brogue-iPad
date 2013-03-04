//
//  Viewport.m
//  Brogue
//
//  Created by Brian and Kevin Walker on 11/28/08.
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

#import "Viewport.h"
#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>


@interface Viewport ()
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) UIFont *font;
@end

@implementation Viewport {
    @private
    BOOL _animationRunning;
    BOOL _hasInitialized;
}

CGSize characterSize;

// The approximate size of one rectangle, which can be off by up to 1 pixel:
short vPixels = VERT_PX;
short hPixels = HORIZ_PX;

short theFontSize = FONT_SIZE;  // Will get written over when windowDidResize

- (UIFont *)font {
	if (!_font) {
        _font = [UIFont fontWithName:FONT_NAME size:theFontSize];
    }
	return _font;
}

- (id)initWithFrame:(CGRect)rect
{
	if (![super initWithFrame:rect]) {
		return nil;
	}

	[self initializeLayoutVariables];

	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self initializeLayoutVariables];
        self.displayLink =  [CADisplayLink displayLinkWithTarget:self selector:@selector(draw)];
    }
    
	return self;
}

- (void)initializeLayoutVariables {
    int i, j;
    self.hWindow = 1024;
    self.vWindow = 748;
    
	for (j = 0; j < kROWS; j++) {        
		for (i = 0; i < kCOLS; i++) {            
			letterArray[i][j] = @" ";
			bgColorArray[i][j] = [UIColor blackColor];

			attributes[i][j] = [[NSMutableDictionary alloc] init];
			[attributes[i][j] setObject:[self font] forKey:NSFontAttributeName];
			[attributes[i][j] setObject:[UIColor blackColor]
                                 forKey:NSForegroundColorAttributeName];
            
            // (18 * 33) - (18 *(j + 1))
            CGRect rect = CGRectMake(HORIZ_PX*i, (VERT_PX*(j)), HORIZ_PX, VERT_PX);
			rectArray[i][j] = rect;
		}
	}
    
    [self setHorizWindow:self.hWindow vertWindow:self.vWindow fontSize:10];
    
    _hasInitialized = YES;
}

- (void)draw {
    [self setNeedsDisplay];
}

- (void)setString:(NSString *)c
   withBackground:(UIColor *)bgColor
  withLetterColor:(UIColor *)letterColor
	  atLocationX:(short)x
		locationY:(short)y
    withFancyFont:(bool)fancyFont
{
    dispatch_async(dispatch_get_main_queue(), ^{
        letterArray[x][y] = nil;
        bgColorArray[x][y] = nil;
        
        letterArray[x][y] = c;
        bgColorArray[x][y] = bgColor;
    
        [attributes[x][y] setObject:letterColor forKey:NSForegroundColorAttributeName];
    });
}

- (void)drawRect:(CGRect)rect
{
 //   NSLog(@"%s", __PRETTY_FUNCTION__);
    if (!_animationRunning)
    {
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        _animationRunning = YES;
        return;
    }
    
    if (!_hasInitialized) {
        NSLog(@"haven't init yet");
        return;
    }
    
    
	int i, j, startX, startY, endX, endY;

    startX = 0;
    endX = kCOLS;
    startY = 0;
    endY = kROWS;

    CGContextRef context = UIGraphicsGetCurrentContext();

    for ( j = startY; j < endY; j++ ) {
        for ( i = startX; i < endX; i++ ) {
            UIColor *color = bgColorArray[i][j];
            [color set];
            
            CGContextFillRect(context, rectArray[i][j]);
            [self drawTheString:letterArray[i][j] centeredIn:rectArray[i][j] withAttributes:attributes[i][j]];
        }
    }
}

- (void)drawTheString:(NSString *)theString centeredIn:(CGRect)rect withAttributes:(NSMutableDictionary *)theAttributes
{
   // NSLog(@"theString is '%@'", theString);

	// Assuming a space character is an empty rectangle provides a major
	// increase in redraw speed.
	if (theString.length == 0 || [theString isEqualToString:@" "]) {
		return;
	}

    CGPoint stringOrigin;
    CGSize stringSize;
    
    // Cache sizes.
    if ([characterSizeDictionary objectForKey:theString] == nil) {
        stringSize = [theString sizeWithFont:self.font];	// quite expensive
        //	NSLog(@"stringSize for '%@' has width %f and height %f", theString, stringSize.width, stringSize.height);
        [characterSizeDictionary setObject:[NSValue valueWithCGSize:stringSize] forKey:theString];
    } else {
        stringSize = [[characterSizeDictionary objectForKey:theString] CGSizeValue];
    }
    
    stringOrigin.x = rect.origin.x + (rect.size.width - stringSize.width) * 0.5;
    stringOrigin.y = rect.origin.y + (rect.size.height - stringSize.height) * 0.5;
    
    CGFloat red;
    CGFloat blue;
    CGFloat green;
    CGFloat alpha;
    
    UIColor *color = [theAttributes objectForKey:NSForegroundColorAttributeName];
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    [color set];
    
    [theString drawAtPoint:stringOrigin withFont:self.font];
}

- (void)setHorizWindow:(short)hPx
            vertWindow:(short)vPx
              fontSize:(short)size
{
    int i, j;
    hPixels = hPx / kCOLS;
    vPixels = vPx / kROWS;
    self.hWindow = hPx;
    self.vWindow = vPx;
    theFontSize = size;
    self.font = nil;
    
    for (j = 0; j < kROWS; j++) {
        for (i = 0; i < kCOLS; i++) {
            [attributes[i][j] setObject:self.font forKey:NSFontAttributeName];
            rectArray[i][j] = CGRectMake((int) (hPx * i / kCOLS),
                                         (int) ((vPx * (j) / kROWS)),
                                         ((int) (hPx * (i+1) / kCOLS)) - ((int) (hPx * (i) / kCOLS)),//hPixels + 1,
                                         ((int) (vPx * (j+1) / kROWS)) - ((int) (vPx * (j) / kROWS)));//vPixels + 1);
        }
    }

    [characterSizeDictionary removeAllObjects];
}


@end
