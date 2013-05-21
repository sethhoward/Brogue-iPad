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
- (void)drawTheString:(NSString *)theString centeredIn:(CGRect)rect withLetterColor:(CGColorRef)letterColor withChar:(unsigned short)character;
- (void)setHorizWindow:(short)hPx vertWindow:(short)vPx;
@end

@implementation Viewport {
    @private
    NSString *_letterArray[kCOLS][kROWS];
    unsigned short **_charArray;
	CGColorRef **_bgColorArray;
	CGColorRef **_letterColorArray;
	CGRect _rectArray[kCOLS][kROWS];
    UIFont *_slowFont;
    UIFont *_fastFont;
    CGContextRef _context;
    CGFontRef _cgFont;
    CGColorRef _prevColor;
    
    // The approximate size of one rectangle, which can be off by up to 1 pixel:
    short _vPixels;
    short _hPixels;
    
    CGSize _fastFontCharacterSize;
    CGSize _slowFontCharacterSize;
    
    CGColorSpaceRef _colorSpace;
}

- (id)initWithFrame:(CGRect)rect {
    self = [super initWithFrame:rect];
    
	if (self) {
		[self initializeLayoutVariables];
	}

	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self initializeLayoutVariables];
    }
    
	return self;
}

- (void)initializeLayoutVariables {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        self.hWindow = 1024;
        self.vWindow = 748;
        
        // Toss the arrays onto the heap
        _charArray = (unsigned short **)malloc(kCOLS * sizeof(unsigned short *));
        _bgColorArray = (CGColorRef **)malloc(kCOLS * sizeof(CGColorRef *));
        _letterColorArray = (CGColorRef **)malloc(kCOLS * sizeof(CGColorRef *));
        
        for (int c = 0; c < kCOLS; c++) {
            _charArray[c] = (unsigned short *)malloc(kROWS * sizeof(unsigned short));
            _bgColorArray[c] = (CGColorRef *)malloc(kROWS * sizeof(CGColorRef));
            _letterColorArray[c] = (CGColorRef *)malloc(kROWS * sizeof(CGColorRef));
        }
        
        // initialize varaiables based on our window size
        [self setHorizWindow:self.hWindow vertWindow:self.vWindow];
        // black out
        [self clearColors];
        
        _cgFont = CGFontCreateWithFontName((CFStringRef)@"Monaco");
        _fastFontCharacterSize = [@"M" sizeWithFont:[self fastFont]];
        _slowFontCharacterSize = [@"M" sizeWithFont:[self slowFont]];
        _colorSpace = CGColorSpaceCreateDeviceRGB();
    });
}

- (void)setString:(NSString *)c withBackgroundColor:(CGColorRef)bgColor letterColor:(CGColorRef)letterColor atLocationX:(short)x locationY:(short)y withChar:(unsigned short)character {
    dispatch_async(dispatch_get_main_queue(), ^{
        CGColorRelease(_bgColorArray[x][y]);
        CGColorRelease(_letterColorArray[x][y]);
        
        _letterArray[x][y] = c;
        _bgColorArray[x][y] = bgColor;
        _letterColorArray[x][y] = letterColor;
        _charArray[x][y] = character;
        
        [self setNeedsDisplayInRect:_rectArray[x][y]];
    });
}

#pragma mark - Draw Routines

- (void)drawRect:(CGRect)rect {
  //  [MGBenchmark start:@"draw"];
    int i, j, startX, startY, endX, endY, width;
      
    startX = (int) (kCOLS * rect.origin.x / self.hWindow);
    endY = (int) (kCOLS * (rect.origin.y + rect.size.height + _vPixels - 1 ) / self.vWindow);
    endX = (int) (kCOLS * (rect.origin.x + rect.size.width + _hPixels - 1) / self.hWindow);
    startY = (int) (kROWS * rect.origin.y / self.vWindow);

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
    CGRect startRect = _rectArray[startX][startY];

    _prevColor = _bgColorArray[startX][startY];
    CGContextSetFillColorWithColor(_context, _prevColor);

    // draw the background rect colors.
    // In order to speed things up we do not draw black rects
    // Also we combine rects that are the same color (striping across the row) and draw that as one rect instead of individual rects
    for ( j = startY; j < endY; j++ ) {
        for ( i = startX; i < endX; i++ ) {
            CGColorRef color = _bgColorArray[i][j];
            
            // if we have a mismatched color we need to draw. Otherwise we keep striping acrossed with the same color context and delay the draw
            if (!CGColorEqualToColor(color, _prevColor) || i == endX - 1) {
                if (i == endX - 1) {
                    width += _rectArray[i][j].size.width;
                    // It's the last rect... and the previous rect isn't black.. draw it and then draw the last rect
                    if (![self isSHColorBlack:_prevColor]) {
                        CGContextFillRect(_context, CGRectMake((int)startRect.origin.x, (int)startRect.origin.y, width, (int)_rectArray[i][j].size.height));
                    }
                    
                    CGContextSetFillColorWithColor(_context, color);
                    CGContextFillRect(_context, _rectArray[i][j]);
                }
                else {
                    // if it's not black draw it otherwise we skip drawing black rects to save time
                    if (![self isSHColorBlack:_prevColor]) {
                        CGContextFillRect(_context, CGRectMake((int)startRect.origin.x, (int)startRect.origin.y, width, (int)_rectArray[i][j].size.height));
                    }
                    
                    // if it's not black change the color
                    if (![self isSHColorBlack:color]) {
                        CGContextSetFillColorWithColor(_context, color);
                    }
                    
                    startRect = _rectArray[i][j];
                    width = _rectArray[i][j].size.width;
                }
            }
            else {
                // we're dealing with black. don't track
                if ([self isSHColorBlack:color]) {
                    startRect = _rectArray[i][j];
                }
                else {
                    width += _rectArray[i][j].size.width;
                }
            }
            
            _prevColor = color;
        }
 
        // end of the row, reset values
        width = 0;
        startRect = _rectArray[i][j];
    }
    
    _prevColor = _bgColorArray[startX][startY];
    CGContextSetFillColorWithColor(_context, _prevColor);
    CGContextSetTextMatrix(_context, CGAffineTransformMakeScale(1.0, -1.0));
    CGContextSetFontSize(_context, FONT_SIZE);
    CGContextSetFont(_context, _cgFont);
    
    // now draw the ascii chars
    for ( j = startY; j < endY; j++ ) {
        for ( i = startX; i < endX; i++ ) {
            [self drawTheString:_letterArray[i][j] centeredIn:_rectArray[i][j] withLetterColor:_letterColorArray[i][j] withChar:_charArray[i][j]];
        }
    }
    
  // [[MGBenchmark session:@"draw"] total];
  // [MGBenchmark finish:@"draw"];
}

// drawTheString vars declared outside the method. Seem to speed things up just a hair
CGGlyph glyphString[1];
- (void)drawTheString:(NSString *)theString centeredIn:(CGRect)rect withLetterColor:(CGColorRef)letterColor withChar:(unsigned short)character {
    // before the letter array is set we ensure that anything that isn't supposed to show a character is set to size 0
	if (character == 32) {
		return;
	}
    
    // only switch color context when needed. This call is expensive
    if (!CGColorEqualToColor(letterColor, _prevColor)) {
        CGContextSetFillColorWithColor(_context, letterColor);
        _prevColor = letterColor;
    }
    
    CGSize stringSize = _fastFontCharacterSize;
    
    if (character > 127 && character != 183) {
        stringSize = _slowFontCharacterSize;
    }
    
    // center the characters
    CGPoint stringOrigin;
    stringOrigin.x = rect.origin.x + (rect.size.width - stringSize.width) * 0.5;
    stringOrigin.y = rect.origin.y + (rect.size.height - stringSize.height) * 0.5;
    
    // we have a unicode character. Draw it with drawAtPoint
    // if it's one of those fancy centered dots (183) toss it for a period. It's used a lot and slows things down
    if (character == 183) {
        character = 46;
        
        // fudge the position with some magic numbers
        stringOrigin.y -= 4;
    }
    
    // we're not in ascii country... draw the unicode char the only way we know how
    if (character > 127) {
        // super slow call.. only used occassionally though
        [theString drawAtPoint:stringOrigin withFont:[self slowFont]];
        
        // seems like we need to change the context back or we render incorrect glyps. We do it here assuming we call this less than the show glyphs below
        CGContextSetFont(_context, _cgFont);
    }
    // plain jane characters. Draw them nice and fast.
    else {
        glyphString[0] = character-29;
        CGContextShowGlyphsAtPoint(_context, stringOrigin.x, stringOrigin.y + FONT_SIZE, glyphString, 1);
    }
}

#pragma mark - Private Helpers

- (void)setHorizWindow:(short)hPx vertWindow:(short)vPx {
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
}

- (BOOL)isSHColorBlack:(CGColorRef)color {
    if (!color) {
        return YES;
    }
    
    return NO;
}

- (void)clearColors {
    for (int j = 0; j < kROWS; j++) {
		for (int i = 0; i < kCOLS; i++) {
			_letterArray[i][j] = @"";
            _charArray[i][j] = ' ';            
            _bgColorArray[i][j] = nil;
            _letterColorArray[i][j] = nil;
        }
    }
}

#pragma mark - Font

// TODO:
- (UIFont *)slowFont {
	if (!_slowFont) {
        _slowFont = [UIFont fontWithName:@"ArialUnicodeMS" size:FONT_SIZE - 1];
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
		_fastFont = [UIFont fontWithName:@"Monaco" size:FONT_SIZE];
    }
	return _fastFont;
}

/*
- (UIFont *)fontForString:(NSString *)s {
	if (s.length == 1 && ([s characterAtIndex:0] < 128)) {
		return [self fastFont];
	} else {
		return [self slowFont];
    }
}*/


@end
