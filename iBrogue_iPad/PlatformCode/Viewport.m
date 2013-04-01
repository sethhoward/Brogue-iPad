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
    UIFont *_slowFont;
    UIFont *_fastFont;
    CGContextRef _context;
    CGFontRef _cgFont;
    SHColor *_prevColor;
}

// The approximate size of one rectangle, which can be off by up to 1 pixel:
short vPixels = VERT_PX;
short hPixels = HORIZ_PX;
short theFontSize = FONT_SIZE;

// TODO:

- (UIFont *)slowFont {
	if (!_slowFont) {
        _slowFont = [UIFont fontWithName:@"ArialUnicodeMS" size:theFontSize];
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
	return _slowFont;
}

- (UIFont *)fastFont {
	if (!_fastFont) {
		_fastFont = [UIFont fontWithName:@"Monaco" size:theFontSize + 1];
    }
	return _fastFont;
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self clearColors];
    
        SHColor *color = bgColorArray[0][0];
        _prevColor = color;
        
     //   [self setNeedsDisplay];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.displayLink setPaused:YES];
        });
        
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

- (void)clearColors {
    for (int j = 0; j < kROWS; j++) {
		for (int i = 0; i < kCOLS; i++) {
			letterArray[i][j] = @"";
            charArray[i][j] = ' ';
            SHColor black;
            black.red = 0;
            black.blue = 0;
            black.green = 0;
            
            bgColorArray[i][j] = &black;
            attributes[i][j] = &black;
        }
    }
    
    SHColor *color = bgColorArray[0][0];
    _prevColor = color;
}

- (void)initializeLayoutVariables {
    self.hWindow = 1024;
    self.vWindow = 748;
    
    characterSizeDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
    
    [self clearColors];
    
	for (int j = 0; j < kROWS; j++) {
		for (int i = 0; i < kCOLS; i++) {
            CGRect rect = CGRectMake(HORIZ_PX*i, (VERT_PX*(j)), HORIZ_PX, VERT_PX);
			rectArray[i][j] = rect;
		}
	}
    
    [self setHorizWindow:self.hWindow vertWindow:self.vWindow fontSize:theFontSize];
    
    if (!_cgFont) {
        _cgFont = CGFontCreateWithFontName((CFStringRef)@"Monaco");
    }
    
    _hasInitialized = YES;
}

- (void)draw {
 //   NSLog(@"%i", test);
    [self setNeedsDisplay];
}

- (void)setString:(NSString *)c withBackgroundColor:(SHColor *)bgColor letterColor:(SHColor *)letterColor atLocationX:(short)x locationY:(short)y withChar:(unsigned short)character {
    dispatch_async(dispatch_get_main_queue(), ^{
        letterArray[x][y] = c;
        bgColorArray[x][y] = bgColor;
        attributes[x][y] = letterColor;
        charArray[x][y] = character;
    });
}

- (void)drawRect:(CGRect)rect
{
   // [MGBenchmark start:@"draw"];

    _context = UIGraphicsGetCurrentContext();
    
    CGRect startRect = rectArray[0][0];
    int width = rectArray[0][0].size.width;
    
    _prevColor = bgColorArray[0][0];

    // draw the background rect colors
    for (int j = 0; j < kROWS; j++ ) {
        width = 0;
        startRect = rectArray[0][j];
        
        for (int i = 0; i < kCOLS; i++ ) {
            SHColor *color = bgColorArray[i][j];
            
            // if we have a mismatched color we need to draw. Otherwise we keep striping acrossed with the same color context and delay the draw
            if ((_prevColor->red != color->red || _prevColor->green != color->green || _prevColor->blue != color->blue || i == kCOLS - 1)) {
                if (i == kCOLS - 1) {
                    width += rectArray[i][j].size.width;
                    if (_prevColor->red != 0 || _prevColor->blue != 0 || _prevColor->green != 0) {
                        CGContextFillRect(_context, CGRectMake((int)startRect.origin.x, (int)startRect.origin.y, width, (int)rectArray[i][j].size.height));
                        if (color->red != 0 || color->blue != 0 || color->green != 0) {
                            CGContextSetFillColorWithColor(_context, [[UIColor colorWithRed:color->red/100. green:color->green/100. blue:color->blue/100. alpha:1.0] CGColor]);
                            CGContextFillRect(_context, rectArray[i][j]);
                        }
                    }
                }
                else {
                    // if it's not black draw it otherwise we skip drawing black rects to save time
                    if (_prevColor->red != 0 || _prevColor->blue != 0 || _prevColor->green != 0) {
                        CGContextFillRect(_context, CGRectMake((int)startRect.origin.x, (int)startRect.origin.y, width, (int)rectArray[i][j].size.height));
                    }
                    
                    // if it's not black change the color
                    if (color->red != 0 || color->blue != 0 || color->green != 0) {
                        CGContextSetFillColorWithColor(_context, [[UIColor colorWithRed:color->red/100. green:color->green/100. blue:color->blue/100. alpha:1.0] CGColor]);
                    }
                    
                    startRect = rectArray[i][j];
                    width = rectArray[i][j].size.width;
                }
            }
            else {
                // we're dealing with black. don't track
                if (color->red == 0 && color->blue == 0 && color->green == 0) {
                    startRect = rectArray[i][j];
                    width = rectArray[i][j].size.width;
                }
                else 
                    width += rectArray[i][j].size.width;
            }
            
            _prevColor = color;
        }
    }

    _prevColor = bgColorArray[0][0];
    CGContextSetFillColorWithColor(_context, [[UIColor colorWithRed:_prevColor->red/100. green:_prevColor->green/100. blue:_prevColor->blue/100. alpha:1.0] CGColor]);
    
    // now draw the ascii chars
    for (int j = 0; j < kROWS; j++ ) {
        for (int i = 0; i < kCOLS; i++ ) {
            [self drawTheString:letterArray[i][j] centeredIn:rectArray[i][j] withAttributes:attributes[i][j] withChar:charArray[i][j]];
        }
    }
    
   // [[MGBenchmark session:@"draw"] total];
   // [MGBenchmark finish:@"draw"];
}

// drawTheString vars declared outside the method. Seem to speed things up just a hair
size_t stringLength;
CGGlyph glyphString[1];
CGPoint stringOrigin;
CGSize stringSize;
unsigned short string;
//char *prevCharGrid[kCOLS][kROWS];
- (void)drawTheString:(NSString *)theString centeredIn:(CGRect)rect withAttributes:(SHColor *)letterColor withChar:(unsigned short)character
{
    // before the letter array is set we ensure that anything that isn't supposed to show a character is set to size 0
	if (theString.length == 0) {
		return;
	}

    // Cache sizes.
    NSValue *size = [characterSizeDictionary objectForKey:theString];
    
    if (size) {
        stringSize = [size CGSizeValue];
    } else {
        stringSize = [theString sizeWithFont:[self fontForString:theString]];	// quite expensive
        //	NSLog(@"stringSize for '%@' has width %f and height %f", theString, stringSize.width, stringSize.height);
        [characterSizeDictionary setObject:[NSValue valueWithCGSize:stringSize] forKey:theString];
    }
    
    stringOrigin.x = rect.origin.x + (rect.size.width - stringSize.width) * 0.5;
    stringOrigin.y = rect.origin.y + (rect.size.height - stringSize.height) * 0.5;
    
    string = character;//[theString cStringUsingEncoding:NSASCIIStringEncoding];
    
    // only switch color context when needed. This call is expensive
    if (_prevColor->red != letterColor->red || _prevColor->green != letterColor->green || _prevColor->blue != letterColor->blue) {
        UIColor *color = [UIColor colorWithRed:letterColor->red/100. green:letterColor->green/100. blue:letterColor->blue/100. alpha:1.0];
        CGContextSetFillColorWithColor(_context, [color CGColor]);
    }
    
    _prevColor = letterColor;
    
    // we have a unicode character. Draw it with drawAtPoint
    if (character >= 128)
    {
        [theString drawAtPoint:stringOrigin withFont:[self slowFont]];
    }
    else {
        // This seems like overkill but supposedly it's faster than drawAtPoint
       // stringLength = strlen(string);
        glyphString[0] = string-29;//string[0]-29;
        
        CGContextSetTextMatrix(_context, CGAffineTransformMakeScale(1.0, -1.0));
        CGContextSetFont(_context, _cgFont);
        CGContextSetFontSize(_context, theFontSize);
        //   CGContextSetFillColorWithColor(context, [color CGColor]);
        
        CGContextShowGlyphsAtPoint(_context, stringOrigin.x, stringOrigin.y + theFontSize, glyphString, 1);
    }
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
