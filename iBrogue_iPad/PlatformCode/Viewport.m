//
//  Viewport.m
//  Brogue
//
//  Created by Brian and Kevin Walker on 11/28/08.
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

#import "Viewport.h"
#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "MGBenchmark.h"
#import "MGBenchmarkSession.h"

@interface Viewport ()
- (void)drawTheString:(NSString *)theString centeredIn:(CGRect)rect withLetterColor:(CGColorRef)letterColor withChar:(unsigned short)character;
- (void)setHorizWindow:(short)hPx vertWindow:(short)vPx;

@property (nonatomic, strong) UIFont *slowFont;
@property (nonatomic, strong) UIFont *fastFont;
@property (nonatomic, strong) NSMutableDictionary *characterSizeDictionary;
// The approximate size of one rectangle, which can be off by up to 1 pixel:
@property (nonatomic, assign) short vPixels;
@property (nonatomic, assign) short hPixels;
@property (nonatomic, assign) CGSize fastFontCharacterSize;
@property (nonatomic, assign) CGSize slowFontCharacterSize;
@property (nonatomic, assign) CGContextRef context;
@property (nonatomic, assign) CGFontRef cgFont;
@property (nonatomic, assign) CGColorRef prevColor;
@property (nonatomic, assign) CGColorSpaceRef colorSpace;

@end

@implementation Viewport {
    @private
    CGGlyph glyphString[1];
    NSString *_letterArray[kCOLS][kROWS];
    unsigned short **_charArray;
	CGColorRef **_bgColorArray;
	CGColorRef **_letterColorArray;
	CGRect _rectArray[kCOLS][kROWS];
    CGPoint _stringOriginArray[kCOLS][kROWS];    //we're going to do the string processing on the background thread
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
        self.characterSizeDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
        // TODO: this should just grab the screens bounds... brogue does well with just about any size
        self.hWindow = [[UIScreen mainScreen] bounds].size.height;
        self.vWindow = [[UIScreen mainScreen] bounds].size.width;
 
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

- (void)setString:(NSString *)cString withBackgroundColor:(CGColorRef)bgColor letterColor:(CGColorRef)letterColor atLocationX:(short)x locationY:(short)y withChar:(unsigned short)character {
    
    CGSize stringSize;
    
    if (character > 127 && character != FLOOR_CHAR) {
        stringSize = _slowFontCharacterSize;
        // great code to include if you can run arial unicode. sadly arial unicode crashes ios 6
        id cachedSize = [self.characterSizeDictionary objectForKey:cString];
        if (cachedSize == nil) {
            stringSize = [cString sizeWithFont:[self slowFont]];	// quite expensive
            [self.characterSizeDictionary setObject:[NSValue valueWithCGSize:stringSize] forKey:cString];
        } else {
            stringSize = [[self.characterSizeDictionary objectForKey:cString] CGSizeValue];
        }
    }
    else {
        stringSize = _fastFontCharacterSize;
    }
    
    __block CGPoint stringOrigin = [self originForCharacterSize:stringSize andRect:_rectArray[x][y]];
    
    if (character == FOLIAGE_CHAR) {
        stringOrigin.x++;
    }
    else if(character == WEAPON_CHAR) {
        stringOrigin.x += 2;
    }
    else if (character == FLOOR_CHAR) {
        character = 46;
        
        // fudge the position with some magic numbers
        stringOrigin.y -= 4;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CGColorRelease(_bgColorArray[x][y]);
        CGColorRelease(_letterColorArray[x][y]);
        
        _letterArray[x][y] = cString;
        _bgColorArray[x][y] = bgColor;
        _letterColorArray[x][y] = letterColor;
        _charArray[x][y] = character;
        _stringOriginArray[x][y] = stringOrigin;
        
        // consider keeping
        
        if (character == FOLIAGE_CHAR) {            
     //       if (stringSize.width >= _rectArray[x][y].size.width) { // custom update rectangle
                CGRect updateRect;
                updateRect.origin.y = _rectArray[x][y].origin.y;
                updateRect.size.height = _rectArray[x][y].size.height;
                updateRect.origin.x = _rectArray[x][y].origin.x + (_rectArray[x][y].size.width - _slowFontCharacterSize.width - 10)/2;
                updateRect.size.width = _slowFontCharacterSize.width + 10;
                [self setNeedsDisplayInRect:updateRect];
       //     }
        }
        else {
            [self setNeedsDisplayInRect:_rectArray[x][y]];
        }
    });
    
}

#pragma mark - Draw Routines
- (void)drawRect:(CGRect)rect {
//    [MGBenchmark start:@"draw"];

    int width = 0;
    int startX = (int) (kCOLS * rect.origin.x / self.hWindow);
    int endY = (int) (kCOLS * (rect.origin.y + rect.size.height + _vPixels - 1 ) / self.vWindow);
    int endX = (int) (kCOLS * (rect.origin.x + rect.size.width + _hPixels - 1) / self.hWindow);
    int startY = (int) (kROWS * rect.origin.y / self.vWindow);

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
    BOOL isColorEqual;
    CGColorRef color;
    for (int j = startY; j < endY; j++ ) {
        for (int i = startX; i < endX; i++ ) {
            color = _bgColorArray[i][j];
            isColorEqual = CGColorEqualToColor(color, _prevColor);
            
            // if we have a mismatched color we need to draw. Otherwise we keep striping acrossed with the same color context and delay the draw
            if (!isColorEqual || i == endX - 1) {
                // if it's not black draw it otherwise we skip drawing black rects to save time
                if (_prevColor) {
                    CGContextFillRect(_context, CGRectMake((int)startRect.origin.x, (int)startRect.origin.y, width, (int)_rectArray[i][j].size.height));
                }
                
                if (i == endX - 1) {
                    if (color) {
                        CGContextSetFillColorWithColor(_context, color);
                        CGContextFillRect(_context, _rectArray[i][j]);
                    }
                }
                else {
                    // if it's not black change the color
                    if (color) {
                        CGContextSetFillColorWithColor(_context, color);
                    }
                    
                    startRect = _rectArray[i][j];
                    width = _rectArray[i][j].size.width;
                }
                
                _prevColor = color;
            }
            else {
                // we're dealing with black. don't track
                if (color == nil) {
                    startRect = _rectArray[i][j];
                }
                else {
                    width += _rectArray[i][j].size.width;
                }
            }
        }
        
        // end of the row, reset values
        width = 0;
        startRect = _rectArray[startX][j];
    }
    
    _prevColor = nil;
    
    CGContextSetTextMatrix(_context, CGAffineTransformMakeScale(1.0, -1.0));
    CGContextSetFontSize(_context, FONT_SIZE);
    CGContextSetFont(_context, _cgFont);
    
    // now draw the ascii chars
    for (int j = startY; j < endY; j++ ) {
        for (int i = startX; i < endX; i++ ) {
            // skip spaces... if there's isn't something to draw it's a space guaranteed
            if (_charArray[i][j] != 32) {
                [self drawTheString:_letterArray[i][j] centeredIn:_rectArray[i][j] withLetterColor:_letterColorArray[i][j] withChar:_charArray[i][j] stringOrigin:_stringOriginArray[i][j]];
            }
        }
    }
    
//   [[MGBenchmark session:@"draw"] total];
//   [MGBenchmark finish:@"draw"];
}

// drawTheString vars declared outside the method. Seem to speed things up just a hair
- (void)drawTheString:(NSString *)theString centeredIn:(CGRect)rect withLetterColor:(CGColorRef)letterColor withChar:(unsigned short)character stringOrigin:(CGPoint)stringOrigin{
    // only switch color context when needed. This call is expensive
    if (!CGColorEqualToColor(letterColor, _prevColor)) {
        CGContextSetFillColorWithColor(_context, letterColor);
        _prevColor = letterColor;
    }
    
    // we're not in ascii country... draw the unicode char the only way we know how
    if (character > 127) {
              
     //   CGPoint stringOrigin = _stringOriginArray//[self originForCharacterSize:stringSize andRect:rect];
        
        [theString drawAtPoint:stringOrigin withFont:[self slowFont]];
        
        // seems like we need to change the context back or we render incorrect glyps. We do it here assuming we call this less than the show glyphs below
        CGContextSetTextMatrix(_context, CGAffineTransformMakeScale(1.0, -1.0));
        CGContextSetFontSize(_context, FONT_SIZE);
        CGContextSetFont(_context, _cgFont);
    }
    // plain jane characters. Draw them nice and fast.
    else {
        //CGPoint stringOrigin = [self originForCharacterSize:_fastFontCharacterSize andRect:rect];
        // we have a unicode character. Draw it with drawAtPoint
        // if it's one of those fancy centered dots (183) toss it for a period. It's used a lot and slows things down
        
        
        glyphString[0] = character-29;
        CGContextShowGlyphsAtPoint(_context, stringOrigin.x, stringOrigin.y + FONT_SIZE, glyphString, 1);
    }
}

#pragma mark - Private Helpers

- (CGPoint)originForCharacterSize:(CGSize)fontSize andRect:(CGRect)rect {
    // center the characters
    CGPoint stringOrigin;
    stringOrigin.x = rect.origin.x + (rect.size.width - fontSize.width) / 2;
    stringOrigin.y = rect.origin.y + (rect.size.height - fontSize.height) / 2;
    
    return stringOrigin;
}

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

- (void)clearColors {
    for (int j = 0; j < kROWS; j++) {
		for (int i = 0; i < kCOLS; i++) {
			_letterArray[i][j] = @"";
            _charArray[i][j] = ' ';            
            _bgColorArray[i][j] = nil;
            _letterColorArray[i][j] = nil;
            _stringOriginArray[i][j] = CGPointZero;
        }
    }
}

#pragma mark - Font

- (UIFont *)slowFont {
	if (!_slowFont) {
        _slowFont = [UIFont fontWithName:@"ArialUnicodeMS" size:FONT_SIZE];
	}
	return _slowFont;
}

- (UIFont *)fastFont {
	if (!_fastFont) {
		_fastFont = [UIFont fontWithName:@"Monaco" size:FONT_SIZE];
    }
	return _fastFont;
}

@end
