//
//  Viewport.m
//  Brogue
//
//  Created by Brian and Kevin Walker on 11/28/08.
//  Updated for iOS by Seth Howard on 03/01/13
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
#import "MGBenchmark.h"
#import "MGBenchmarkSession.h"


@interface Viewport ()
@property (nonatomic, strong) CADisplayLink *displayLink;
@end

@implementation Viewport {
    @private
    BOOL _animationRunning;
    BOOL _hasInitialized;
    UIFont *theSlowFont;
    UIFont *theFastFont;
    CGContextRef context;
    CGFontRef CGFont;
}

CGSize characterSize;

// The approximate size of one rectangle, which can be off by up to 1 pixel:
short vPixels = VERT_PX;
short hPixels = HORIZ_PX;

short theFontSize = FONT_SIZE;

// TODO:

- (UIFont *)slowFont {
	if (!theSlowFont) {
        theSlowFont = [UIFont fontWithName:@"ArialUnicodeMS" size:theFontSize];
/*		NSFont *baseFont = [NSFont fontWithName:basicFontName size:theFontSize];
		NSArray *fallbackDescriptors = [NSArray arrayWithObjects:
		                                // Arial provides reasonable versions of most characters.
		                                [UIFontDescriptor fontDescriptorWithName:@"Arial Unicode MS" size:theFontSize],
		                                // Apple Symbols provides U+26AA, for rings, which Arial does not.
		                                [UIFontDescriptor fontDescriptorWithName:@"Apple Symbols" size:theFontSize],
		                                nil];
		NSDictionary *fodDict = [NSDictionary dictionaryWithObject:fallbackDescriptors forKey:NSFontCascadeListAttribute];
		NSFontDescriptor *desc = [baseFont.fontDescriptor fontDescriptorByAddingAttributes:fodDict];
		theSlowFont = [[NSFont fontWithDescriptor:desc size:theFontSize] retain];*/
	}
	return theSlowFont;
}

- (UIFont *)fastFont {
	if (!theFastFont) {
		theFastFont = [UIFont fontWithName:@"Monaco" size:theFontSize + 1];
    }
	return theFastFont;
}

- (UIFont *)fontForString:(NSString *)s {
	if (s.length == 1 && ([s characterAtIndex:0] < 128)) {
		return [self fastFont];
	} else {
		return [self slowFont];
    }
}

- (id)initWithFrame:(CGRect)rect
{
    self = [super initWithFrame:rect];
    
	if (!self) {
		return nil;
	}

	[self initializeLayoutVariables];

	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self initializeLayoutVariables];
        
       [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResign) name:UIApplicationWillResignActiveNotification object:nil];
    }
    
	return self;
}

- (void)applicationDidBecomeActive {
    if ([self.displayLink isPaused] && _animationRunning) {
        [self.displayLink setPaused:NO];
    }
}

- (void)applicationWillResign {
    if ([self.displayLink isPaused] == NO) {
        [self.displayLink setPaused:YES];
    }
}

- (void)stopAnimating {
    [self.displayLink setPaused:YES];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        for (int j = 0; j < kROWS; j++) {
            for (int i = 0; i < kCOLS; i++) {
                letterArray[i][j] = @" ";
              //  bgColorArray[i][j] = [UIColor blackColor];
                
              //  attributes[i][j] = [UIColor blackColor];
            }
        }
    
        [self setNeedsDisplay];
    });
    
    _animationRunning = NO;
}

- (void)startAnimating {
    _animationRunning = YES;
    
    if (!self.displayLink) {
        self.displayLink =  [CADisplayLink displayLinkWithTarget:self selector:@selector(draw)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        [self.displayLink setFrameInterval:1];
    }
    else {
        [self.displayLink setPaused:NO];
    }
}

- (void)initializeLayoutVariables {
    int i, j;
    self.hWindow = 1024;
    self.vWindow = 748;
    
    characterSizeDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
    
	for (j = 0; j < kROWS; j++) {        
		for (i = 0; i < kCOLS; i++) {            
			letterArray[i][j] = @" ";
            
            SHColor black;
            black.red = 0;
            black.blue = 0;
            black.green = 0;
            
            bgColorArray[i][j] = &black;
            attributes[i][j] = &black;
            
       //     prevCharGrid[i][j] = 0;
            
		//	bgColorArray[i][j] = [UIColor blackColor];
        //    attributes[i][j] = [UIColor blackColor];
            
            // (18 * 33) - (18 *(j + 1))
            CGRect rect = CGRectMake(HORIZ_PX*i, (VERT_PX*(j)), HORIZ_PX, VERT_PX);
			rectArray[i][j] = rect;
		}
	}
    
    [self setHorizWindow:self.hWindow vertWindow:self.vWindow fontSize:theFontSize];
    
    if (!CGFont) {
        CGFont = CGFontCreateWithFontName((CFStringRef)@"Monaco");
    }
    
    _hasInitialized = YES;
}

- (void)draw {
 //   NSLog(@"%i", test);
    [self setNeedsDisplay];
}

/*- (void)setString:(NSString *)c
   withBackground:(UIColor *)bgColor
  withLetterColor:(UIColor *)letterColor
	  atLocationX:(short)x
		locationY:(short)y
{
    dispatch_async(dispatch_get_main_queue(), ^{
        letterArray[x][y] = c;
        bgColorArray[x][y] = bgColor;
        attributes[x][y] = letterColor;
    });
}*/

- (void)setString:(NSString *)c withBackgroundColor:(SHColor *)bgColor letterColor:(SHColor *)letterColor atLocationX:(short)x locationY:(short)y {
    dispatch_async(dispatch_get_main_queue(), ^{
        letterArray[x][y] = c;
        bgColorArray[x][y] = bgColor;
        attributes[x][y] = letterColor;
    });
}

SHColor *prevColor = NULL;
- (void)drawRect:(CGRect)rect
{
    [MGBenchmark start:@"draw"];

    context = UIGraphicsGetCurrentContext();
    
    CGRect startRect = CGRectNull;
    int width = 0;
   // int starti = 0;

    for (int j = 0; j < kROWS; j++ ) {
        startRect = rectArray[0][j];
        width = 0;
        //starti = 1;
        
        for (int i = 0; i < kCOLS; i++ ) {
            SHColor *color = bgColorArray[i][j];

            if (!prevColor) {
                startRect = CGRectNull;
                CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:color->red/100. green:color->green/100. blue:color->blue/100. alpha:1.0] CGColor]);
            }
            else {
                if (prevColor->red != color->red || prevColor->green != color->green || prevColor->blue != color->blue || i == kCOLS - 1) {
                  //  if (!CGRectIsNull(startRect)) {
                //        NSLog(@"%@", NSStringFromCGRect(startRect));
                //        NSLog(@"%@", NSStringFromCGRect(rectArray[i][j]));
                 //       NSLog(@"%i", width);
                    if (i == kCOLS - 1) {
                        width += rectArray[i][j].size.width;
                    }
                        
                        CGContextFillRect(context, CGRectMake((int)startRect.origin.x, (int)startRect.origin.y, width, (int)rectArray[i][j].size.height));
                        
                        startRect = rectArray[i][j];
                      //  starti = 1;
                        width = rectArray[i][j].size.width;
                        
                        CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:color->red/100. green:color->green/100. blue:color->blue/100. alpha:1.0] CGColor]);
                   // }
                   // else {
                     //   CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:color->red/100. green:color->green/100. blue:color->blue/100. alpha:1.0] CGColor]);
                        //CGContextFillRect(context, rectArray[i][j]);
                   // }
                    
                    

                   // NSLog(@"DUPE COLOR");
                  //  CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:color->red green:color->green blue:color->blue alpha:1.0] CGColor]);
                }
                else {
                /*    if (CGRectIsNull(startRect)) {
                        CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:color->red/100. green:color->green/100. blue:color->blue/100. alpha:1.0] CGColor]);
                        startRect = rectArray[i][j];
                        //starti = 1;
                    }*/
                    
                  //  starti++;
                    width += rectArray[i][j].size.width;
                }
            }
            
            prevColor = color;
 
        }
    }
    
    for (int j = 0; j < kROWS; j++ ) {
        for (int i = 0; i < kCOLS; i++ ) {
            [self drawTheString:letterArray[i][j] centeredIn:rectArray[i][j] withAttributes:attributes[i][j]];
        }
    }
    
    [[MGBenchmark session:@"draw"] total];
    [MGBenchmark finish:@"draw"];
}

size_t stringLength;
CGGlyph glyphString[1];
CGPoint stringOrigin;
CGSize stringSize;
//char *prevCharGrid[kCOLS][kROWS];
- (void)drawTheString:(NSString *)theString centeredIn:(CGRect)rect withAttributes:(SHColor *)letterColor
{
	if ([theString isEqualToString:@" "]) {
		return;
	}

    // Cache sizes.
    if ([characterSizeDictionary objectForKey:theString] == nil) {
        stringSize = [theString sizeWithFont:[self fontForString:theString]];	// quite expensive
        //	NSLog(@"stringSize for '%@' has width %f and height %f", theString, stringSize.width, stringSize.height);
        [characterSizeDictionary setObject:[NSValue valueWithCGSize:stringSize] forKey:theString];
    } else {
        stringSize = [[characterSizeDictionary objectForKey:theString] CGSizeValue];
    }
    
    stringOrigin.x = rect.origin.x + (rect.size.width - stringSize.width) * 0.5;
    stringOrigin.y = rect.origin.y + (rect.size.height - stringSize.height) * 0.5;
    
    const char* string = [theString cStringUsingEncoding:NSASCIIStringEncoding];
    
    UIColor *color = [UIColor colorWithRed:letterColor->red/100. green:letterColor->green/100. blue:letterColor->blue/100. alpha:1.0];
    
    if (prevColor->blue != letterColor->blue || prevColor->green != letterColor->green || prevColor->blue != letterColor->blue) {
        CGContextSetFillColorWithColor(context, [color CGColor]);
    }
    
    prevColor = letterColor;
    
    // we have a unicode character. Draw it with drawAtPoint
    if (!string)
    {
        [theString drawAtPoint:stringOrigin withFont:[self fontForString:theString]];
    }
    else {
        // This seems like overkill but supposedly it's faster than drawAtPoint
        stringLength = strlen(string);
        glyphString[0] = string[0]-29;
        
        CGContextSetTextMatrix(context, CGAffineTransformMakeScale(1.0, -1.0));
        CGContextSetFont(context, CGFont);
        CGContextSetFontSize(context, theFontSize);
        //   CGContextSetFillColorWithColor(context, [color CGColor]);
        
        CGContextShowGlyphsAtPoint(context, stringOrigin.x, stringOrigin.y + theFontSize, glyphString, stringLength);
    }
    
    
    
  //  [[MGBenchmark session:@"draw"] step:@"text glyph stop"];
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

    for (j = 0; j < kROWS; j++) {
        for (i = 0; i < kCOLS; i++) {
            rectArray[i][j] = CGRectMake((int) (hPx * i / kCOLS),
                                         (int) ((vPx * (j) / kROWS)),
                                         ((int) (hPx * (i+1) / kCOLS)) - ((int) (hPx * (i) / kCOLS)),//hPixels + 1,
                                         ((int) (vPx * (j+1) / kROWS)) - ((int) (vPx * (j) / kROWS)));//vPixels + 1);
        }
    }

    [characterSizeDictionary removeAllObjects];
}


@end
