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

@end

@implementation Viewport {
    @private
    NSString *_letterArray[kCOLS][kROWS];
    unsigned short **_charArray;
	SHColor **_bgColorArray;
	SHColor **_attributes;
	NSMutableDictionary *_characterSizeDictionary;
	CGRect **_rectArray;
    UIFont *_slowFont;
    UIFont *_fastFont;
    CGContextRef _context;
    CGFontRef _cgFont;
    SHColor _prevColor;
    
    // The approximate size of one rectangle, which can be off by up to 1 pixel:
    short _vPixels;
    short _hPixels;
}

// TODO:
- (UIFont *)slowFont {
	if (!_slowFont) {
        _slowFont = [UIFont fontWithName:@"ArialUnicodeMS" size:FONT_SIZE];
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
		_fastFont = [UIFont fontWithName:@"Monaco" size:FONT_SIZE + 1];
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

- (id)initWithFrame:(CGRect)rect {
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
    }
    
	return self;
}

- (void)clearColors {
    for (int j = 0; j < kROWS; j++) {
		for (int i = 0; i < kCOLS; i++) {
			_letterArray[i][j] = @"";
            _charArray[i][j] = ' ';
            SHColor black;
            black.red = 0;
            black.blue = 0;
            black.green = 0;
            
            _bgColorArray[i][j] = black;
            _attributes[i][j] = black;
        }
    }
    
//    SHColor color = _bgColorArray[0][0];
//    _prevColor = color;
}

- (void)initializeLayoutVariables {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        self.hWindow = 1024;
        self.vWindow = 748;
        
        _characterSizeDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
        
        // Toss the arrays onto the heap
        _charArray = (unsigned short **)malloc(kCOLS * sizeof(unsigned short *));
        _bgColorArray = (SHColor **)malloc(kCOLS * sizeof(SHColor *));
        _attributes = (SHColor **)malloc(kCOLS * sizeof(SHColor *));
        _rectArray = (CGRect **)malloc(kCOLS * sizeof(CGRect *));
        
        for (int c = 0; c < kCOLS; c++) {
            _charArray[c] = (unsigned short *)malloc(kROWS * sizeof(unsigned short));
            _bgColorArray[c] = (SHColor *)malloc(kROWS * sizeof(SHColor));
            _attributes[c] = (SHColor *)malloc(kROWS * sizeof(SHColor));
            _rectArray[c] = (CGRect *)malloc(kROWS * sizeof(CGRect));
        }
        
        // initialize varaiables based on our window size
        [self setHorizWindow:self.hWindow vertWindow:self.vWindow fontSize:FONT_SIZE];
        // black out
        [self clearColors];
        
        _cgFont = CGFontCreateWithFontName((CFStringRef)@"Monaco");
    });
}

- (void)setString:(NSString *)c withBackgroundColor:(SHColor)bgColor letterColor:(SHColor)letterColor atLocationX:(short)x locationY:(short)y withChar:(unsigned short)character {
    dispatch_async(dispatch_get_main_queue(), ^{
        _letterArray[x][y] = c;
        _bgColorArray[x][y] = bgColor;
        _attributes[x][y] = letterColor;
        _charArray[x][y] = character;
        
        [self setNeedsDisplayInRect:_rectArray[x][y]];
    });
}

- (void)drawRect:(CGRect)rect {
   // [MGBenchmark start:@"draw"];
    int i, j, startX, startY, endX, endY;
      
    startX = (int) (kCOLS * rect.origin.x / self.hWindow);
    endY = (int) (kCOLS * (rect.origin.y + rect.size.height + _vPixels - 1 ) / self.vWindow);
    endX = (int) (kCOLS * (rect.origin.x + rect.size.width + _hPixels - 1) / self.hWindow);
    startY = (int) (kROWS * rect.origin.y / self.vWindow);
    i = startX;

    if (startX < 0) {
     startX = 0;
    }
    if (endX > kCOLS) {
     endX = kCOLS;
    }
    if (startY < 0) {
     startY = 0;
    }
    if (endY > kROWS) {
     endY = kROWS;
    }

    _context = UIGraphicsGetCurrentContext();

    CGRect startRect;// = rectArray[startX][startY];
    int width;// = 0;

    _prevColor = _bgColorArray[startX][startY];
    UIColor *aColor = [UIColor colorWithRed:_prevColor.red/100. green:_prevColor.green/100. blue:_prevColor.blue/100. alpha:1.0];
    CGContextSetFillColorWithColor(_context, [aColor CGColor]);

    // draw the background rect colors
    for ( j = startY; j < endY; j++ ) {
        width = 0;
        if (i < endX) {
            startRect = _rectArray[i][j];
        }

        for ( i = startX; i < endX; i++ ) {
            SHColor color = _bgColorArray[i][j];
            
            // if we have a mismatched color we need to draw. Otherwise we keep striping acrossed with the same color context and delay the draw
            if ((_prevColor.red != color.red || _prevColor.green != color.green || _prevColor.blue != color.blue || i == endX - 1)) {
                if (i == endX - 1) {
                    width += _rectArray[i][j].size.width;
                    // It's the last rect... and the previous rect isn't black.. draw it and then draw the last rect
                    if (_prevColor.red != 0 || _prevColor.blue != 0 || _prevColor.green != 0) {
                        CGContextFillRect(_context, CGRectMake((int)startRect.origin.x, (int)startRect.origin.y, width, (int)_rectArray[i][j].size.height));
                    }
                    
                    CGContextSetFillColorWithColor(_context, [[UIColor colorWithRed:color.red/100. green:color.green/100. blue:color.blue/100. alpha:1.0] CGColor]);
                    CGContextFillRect(_context, _rectArray[i][j]);
                }
                else {
                    // if it's not black draw it otherwise we skip drawing black rects to save time
                    if (_prevColor.red != 0 || _prevColor.blue != 0 || _prevColor.green != 0) {
                        CGContextFillRect(_context, CGRectMake((int)startRect.origin.x, (int)startRect.origin.y, width, (int)_rectArray[i][j].size.height));
                    }
                    
                    // if it's not black change the color
                    if (color.red != 0 || color.blue != 0 || color.green != 0) {
                        UIColor *aColor = [UIColor colorWithRed:color.red/100. green:color.green/100. blue:color.blue/100. alpha:1.0];
                        CGContextSetFillColorWithColor(_context, [aColor CGColor]);
                    }
                    
                    startRect = _rectArray[i][j];
                    width = _rectArray[i][j].size.width;
                }
            }
            else {
                // we're dealing with black. don't track
                if (color.red == 0 && color.blue == 0 && color.green == 0) {
                    startRect = _rectArray[i][j];
                }
                else {
                    width += _rectArray[i][j].size.width;
                }
            }
            
            _prevColor = color;
        }
    }
    
    _prevColor = _bgColorArray[0][0];
    aColor = [UIColor colorWithRed:_prevColor.red/100. green:_prevColor.green/100. blue:_prevColor.blue/100. alpha:1.0];
    CGContextSetFillColorWithColor(_context, [aColor CGColor]);
    
    // now draw the ascii chars
    for ( j = startY; j < endY; j++ ) {
        for ( i = startX; i < endX; i++ ) {
            [self drawTheString:_letterArray[i][j] centeredIn:_rectArray[i][j] withAttributes:_attributes[i][j] withChar:_charArray[i][j]];
        }
    }
    
  //  [[MGBenchmark session:@"draw"] total];
  //  [MGBenchmark finish:@"draw"];
}

// drawTheString vars declared outside the method. Seem to speed things up just a hair
CGGlyph glyphString[1];
CGPoint stringOrigin;
CGSize stringSize;
- (void)drawTheString:(NSString *)theString centeredIn:(CGRect)rect withAttributes:(SHColor)letterColor withChar:(unsigned short)character {
    // before the letter array is set we ensure that anything that isn't supposed to show a character is set to size 0
	if (theString.length == 0) {
		return;
	}

    // Cache sizes.
    NSValue *size = [_characterSizeDictionary objectForKey:theString];
    
    if (size) {
        stringSize = [size CGSizeValue];
    } else {
        stringSize = [theString sizeWithFont:[self fontForString:theString]];	// quite expensive
        //	NSLog(@"stringSize for '%@' has width %f and height %f", theString, stringSize.width, stringSize.height);
        [_characterSizeDictionary setObject:[NSValue valueWithCGSize:stringSize] forKey:theString];
    }
    
    // center the characters
    stringOrigin.x = rect.origin.x + (rect.size.width - stringSize.width) * 0.5;
    stringOrigin.y = rect.origin.y + (rect.size.height - stringSize.height) * 0.5;
    
    // only switch color context when needed. This call is expensive
    if (_prevColor.red != letterColor.red || _prevColor.green != letterColor.green || _prevColor.blue != letterColor.blue) {
        UIColor *color = [UIColor colorWithRed:letterColor.red/100. green:letterColor.green/100. blue:letterColor.blue/100. alpha:1.0];
        CGContextSetFillColorWithColor(_context, [color CGColor]);
    }
    
    _prevColor = letterColor;
    
    // we have a unicode character. Draw it with drawAtPoint
    // if it's one of those fancy centered dots (183) toss it for a period. It's used a lot and slows things down
    if (character == 183) {
        character = 46;
        
        // fudge the position with some magic numbers
        stringOrigin.x -= 2;
        stringOrigin.y -= 3;
    }
    
    // we're not in ascii country... draw the unicode char the only way we know how
    if (character >= 128) {
        // super slow call.. only used occassionally though
        [theString drawAtPoint:stringOrigin withFont:[self slowFont]];
    }
    // plain jane characters. Draw them nice and fast.
    else {
        glyphString[0] = character-29;
        
        CGContextSetTextMatrix(_context, CGAffineTransformMakeScale(1.0, -1.0));
        CGContextSetFont(_context, _cgFont);
        CGContextSetFontSize(_context, FONT_SIZE);
        CGContextShowGlyphsAtPoint(_context, stringOrigin.x, stringOrigin.y + FONT_SIZE, glyphString, 1);
    }
}

- (void)setHorizWindow:(short)hPx vertWindow:(short)vPx fontSize:(short)size {
    _hPixels = hPx / kCOLS;
    _vPixels = vPx / kROWS;
    self.hWindow = hPx;
    self.vWindow = vPx;

    for (int j = 0; j < kROWS; j++) {
        for (int i = 0; i < kCOLS; i++) {
            _rectArray[i][j] = CGRectMake((int) (hPx * i / kCOLS),
                                         (int) ((vPx * (j) / kROWS)),
                                         ((int) (hPx * (i+1) / kCOLS)) - ((int) (hPx * (i) / kCOLS)),//hPixels + 1,
                                         ((int) (vPx * (j+1) / kROWS)) - ((int) (vPx * (j) / kROWS)));//vPixels + 1);
        }
    }

    [_characterSizeDictionary removeAllObjects];
}


@end
