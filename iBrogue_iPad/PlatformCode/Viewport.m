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
@property (nonatomic, assign) short hWindow;
@property (nonatomic, assign) short vWindow;

@end

@implementation Viewport {
@private
    CGGlyph _glyphString[1];
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
        self.hWindow = [[UIScreen mainScreen] bounds].size.height;
        self.vWindow = [[UIScreen mainScreen] bounds].size.width;
        
        // Toss the arrays onto the heap
        _charArray = (unsigned short **)malloc(kCOLS * sizeof(unsigned short *));
        _bgColorArray = (CGColorRef **)malloc(kCOLS * sizeof(CGColorRef *));
        _letterColorArray = (CGColorRef **)malloc(kCOLS * sizeof(CGColorRef *));
        
        for (NSInteger c = 0; c < kCOLS; c++) {
            _charArray[c] = (unsigned short *)malloc(kROWS * sizeof(unsigned short));
            _bgColorArray[c] = (CGColorRef *)malloc(kROWS * sizeof(CGColorRef));
            _letterColorArray[c] = (CGColorRef *)malloc(kROWS * sizeof(CGColorRef));
        }
        
        // initialize varaiables based on our window size
        [self setHorizWindow:self.hWindow vertWindow:self.vWindow];
        // black out
        [self clearColors];
        
        self.cgFont = CGFontCreateWithFontName((CFStringRef)@"Monaco");
        self.fastFontCharacterSize = [@"M" sizeWithFont:[self fastFont]];
        self.slowFontCharacterSize = [@"M" sizeWithFont:[self slowFont]];
        self.colorSpace = CGColorSpaceCreateDeviceRGB();
    });
}

- (void)setString:(NSString *)cString withBackgroundColor:(CGColorRef)bgColor letterColor:(CGColorRef)letterColor atLocation:(CGPoint)location withChar:(unsigned short)character {
    CGPoint stringOrigin = [self getStringOriginWithCharacter:character andString:cString atLocation:location];
    
    if (character == FLOOR_CHAR) {
        character = 46;
        // fudge the position with some magic numbers
        stringOrigin.y -= 4;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSInteger x = location.x;
        NSInteger y = location.y;
        
        CGColorRelease(_bgColorArray[x][y]);
        CGColorRelease(_letterColorArray[x][y]);
        
        _letterArray[x][y] = cString;
        _bgColorArray[x][y] = bgColor;
        _letterColorArray[x][y] = letterColor;
        _charArray[x][y] = character;
        _stringOriginArray[x][y] = stringOrigin;
        
        if (character == FOLIAGE_CHAR) {
            CGRect updateRect;
            updateRect.origin.y = _rectArray[x][y].origin.y;
            updateRect.size.height = _rectArray[x][y].size.height;
            updateRect.origin.x = _rectArray[x][y].origin.x + (_rectArray[x][y].size.width - _slowFontCharacterSize.width - 10)/2;
            updateRect.size.width = _slowFontCharacterSize.width + 10;
            [self setNeedsDisplayInRect:updateRect];
        }
        else {
            [self setNeedsDisplayInRect:_rectArray[x][y]];
        }
    });
}

#pragma mark - Draw Routines
- (void)drawRect:(CGRect)rect {
//        [MGBenchmark start:@"draw"];
    
    NSInteger startX = (NSInteger) (kCOLS * rect.origin.x / _hWindow);
    NSInteger endY = (NSInteger) (kCOLS * (rect.origin.y + rect.size.height + _vPixels - 1 ) / _vWindow);
    NSInteger endX = (NSInteger) (kCOLS * (rect.origin.x + rect.size.width + _hPixels - 1) / _hWindow);
    NSInteger startY = (NSInteger) (kROWS * rect.origin.y / _vWindow);
    
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
    _prevColor = nil;
    
    // draw the background rect colors.
    // In order to speed things up we do not draw black rects
    // Also we combine rects that are the same color (striping across the row) and draw that as one rect instead of individual rects
   // BOOL isColorEqual;
    CGColorRef color;
    for (NSInteger j = startY; j < endY; j++ ) {
        for (NSInteger i = startX; i < endX; i++ ) {
            color = _bgColorArray[i][j];
            
            if (_bgColorArray[i][j]) {
                if (!CGColorEqualToColor(color, _prevColor)) {
                    CGContextSetFillColorWithColor(_context, _bgColorArray[i][j]);
                }
                
                CGContextFillRect(_context, _rectArray[i][j]);
            }
            
            _prevColor = color;
        }
    }
    
    _prevColor = nil;
    
    // reset text context
    CGContextSetTextMatrix(_context, CGAffineTransformMakeScale(1.0, -1.0));
    CGContextSetFontSize(_context, FONT_SIZE);
    CGContextSetFont(_context, _cgFont);
    
    typedef void (*DrawTheStringIMP)(id object, SEL sel, NSString *string, CGRect rect, CGColorRef letterColor, unsigned short character, CGPoint origin);
    DrawTheStringIMP drawTheStringIMP = (DrawTheStringIMP)[self methodForSelector:@selector(drawTheString:centeredIn:withLetterColor:withChar:stringOrigin:)];
    
    // now draw the ascii chars
    for (NSInteger j = startY; j < endY; j++ ) {
        for (NSInteger i = startX; i < endX; i++ ) {
            // skip spaces... if there's isn't something to draw it's a space guaranteed
            if (_charArray[i][j] != 32) {
                drawTheStringIMP(self, @selector(drawTheString:centeredIn:withLetterColor:withChar:stringOrigin:), nil, _rectArray[i][j], _letterColorArray[i][j], _charArray[i][j], _stringOriginArray[i][j]);
            }
        }
    }
    
 //     [[MGBenchmark session:@"draw"] total];
//    [MGBenchmark finish:@"draw"];
}

- (void)drawTheString:(NSString *)theString centeredIn:(CGRect)rect withLetterColor:(CGColorRef)letterColor withChar:(unsigned short)character stringOrigin:(CGPoint)stringOrigin {
    // only switch color context when needed. This call is expensive
    if (!CGColorEqualToColor(letterColor, _prevColor)) {
        CGContextSetFillColorWithColor(_context, letterColor);
        _prevColor = letterColor;
    }
    
    // we're not in ascii country... draw the unicode char the only way we know how
    if (character > 127) {
        [theString drawAtPoint:stringOrigin withFont:[self slowFont]];
        
        // seems like we need to change the context back or we render incorrect glyps. We do it here assuming we call this less than the show glyphs below
        CGContextSetTextMatrix(_context, CGAffineTransformMakeScale(1.0, -1.0));
        CGContextSetFontSize(_context, FONT_SIZE);
        CGContextSetFont(_context, _cgFont);
    }
    // plain jane characters. Draw them nice and fast.
    else {
        _glyphString[0] = character-29;
        CGContextShowGlyphsAtPoint(_context, stringOrigin.x, stringOrigin.y + FONT_SIZE, _glyphString, 1);
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

- (CGPoint)getStringOriginWithCharacter:(short)character andString:(NSString *)aString atLocation:(CGPoint)location {
    CGSize stringSize;
    
    if (character > 127 && character != FLOOR_CHAR) {
        stringSize = _slowFontCharacterSize;
        // great code to include if you can run arial unicode. sadly arial unicode crashes ios 6
        id cachedSize = [self.characterSizeDictionary objectForKey:aString];
        if (cachedSize == nil) {
            stringSize = [aString sizeWithFont:[self slowFont]];	// quite expensive
            [self.characterSizeDictionary setObject:[NSValue valueWithCGSize:stringSize] forKey:aString];
        } else {
            stringSize = [[self.characterSizeDictionary objectForKey:aString] CGSizeValue];
        }
    }
    else {
        stringSize = _fastFontCharacterSize;
    }
    
    NSInteger x = location.x;
    NSInteger y = location.y;
    CGPoint stringOrigin = [self originForCharacterSize:stringSize andRect:_rectArray[x][y]];
    
    if (character == FOLIAGE_CHAR) {
        stringOrigin.x++;
    }
    else if(character == WEAPON_CHAR) {
        stringOrigin.x += 2;
    }
    
    return stringOrigin;
}

- (void)setHorizWindow:(short)hPx vertWindow:(short)vPx {
    self.hPixels = hPx / kCOLS;
    self.vPixels = vPx / kROWS;
    self.hWindow = hPx;
    self.vWindow = vPx;
    
    for (NSInteger j = 0; j < kROWS; j++) {
        for (NSInteger i = 0; i < kCOLS; i++) {
            _rectArray[i][j] = CGRectMake((NSInteger) (hPx * i / kCOLS),
                                          (NSInteger) ((vPx * (j) / kROWS)),
                                          ((NSInteger) (hPx * (i+1) / kCOLS)) - ((NSInteger) (hPx * (i) / kCOLS)),//hPixels + 1,
                                          ((NSInteger) (vPx * (j+1) / kROWS)) - ((NSInteger) (vPx * (j) / kROWS)));//vPixels + 1);
        }
    }
}

- (void)clearColors {
    for (NSInteger j = 0; j < kROWS; j++) {
		for (NSInteger i = 0; i < kCOLS; i++) {
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
