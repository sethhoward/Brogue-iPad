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
@end

@implementation Viewport {
    @private
    UIFont __strong *theSlowFont;
    UIFont __strong *theFastFont;
    
    UIColor __strong *bgColorArrayCopy[kCOLS][kROWS];
    NSTimer __strong *timer;
    
    BOOL animationRunning;

}

CGSize characterSize;

// The approximate size of one rectangle, which can be off by up to 1 pixel:
short vPixels = VERT_PX;
short hPixels = HORIZ_PX;

// The exact size of the window:
short hWindow = 1004;
short vWindow = 786;

short theFontSize = FONT_SIZE;  // Will get written over when windowDidResize
NSString *basicFontName = FONT_NAME;


// Letting OS X handle the fallback for us produces inconsistent results
// across versions, and on OS X 10.8 falls back to Emoji Color for some items
// (e.g. foliage), which doesn't draw correctly at all. So we need to use a
// cascade list forcing it to fall back to Arial Unicode MS and Apple Symbols,
// which have the desired characters.
//
// Using a cascade list, even an empty one, makes text drawing unusably
// slower. To fix this, we store two fonts, one "fast" for ASCII characters
// which we assume Monaco will always be able to handle, and one "slow" for
// non-ASCII.
//
// Because I prefer the default glyphs for all characters except for foliage,
// the cascade list is used only for foliage characters.

- (UIFont *)slowFont {
	if (!theSlowFont) {
	//	UIFont *baseFont = [UIFont fontWithName:basicFontName size:theFontSize];
        UIFont *baseFont = [UIFont systemFontOfSize:theFontSize];
	/*	NSArray *fallbackDescriptors = [NSArray arrayWithObjects:
		                                // Arial provides reasonable versions of most characters.
		                                [NSFontDescriptor fontDescriptorWithName:@"Arial Unicode MS" size:theFontSize],
		                                // Apple Symbols provides U+26AA, for rings, which Arial does not.
		                                [NSFontDescriptor fontDescriptorWithName:@"Apple Symbols" size:theFontSize],
		                                nil];
		NSDictionary *fodDict = [NSDictionary dictionaryWithObject:fallbackDescriptors forKey:NSFontCascadeListAttribute];
		NSFontDescriptor *desc = [baseFont.fontDescriptor fontDescriptorByAddingAttributes:fodDict];*/
        
		//theSlowFont = [[UIFont fontWithDescriptor:desc size:theFontSize] retain];
        
        theSlowFont = baseFont;
	}
	return theSlowFont;
}

- (UIFont *)fastFont {
	if (!theFastFont) {
		//theFastFont = [[NSFont fontWithName:basicFontName size:theFontSize] retain];
       // theFastFont = [UIFont fontWithName:basicFontName size:theFontSize];
        theFastFont = [UIFont systemFontOfSize:theFontSize];
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
    
        if (!timer) {
            
            //timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(draw) userInfo:nil repeats:YES];
        }
        
        self.displayLink =  [CADisplayLink displayLinkWithTarget:self selector:@selector(draw)];
    }
    
	return self;
}

- (void)initializeLayoutVariables {
    int i, j;
    
	for (j = 0; j < kROWS; j++) {
		for (i = 0; i < kCOLS; i++) {
			letterArray[i][j] = @" ";
            //           [letterArray[i][j] setString:@" "];
            //			[letterArray[i][j] retain];
			//bgColorArray[i][j] = [UIColor whiteColor];

			bgColorArray[i][j] = [UIColor whiteColor];
            bgColorArrayCopy[i][j] = [UIColor blueColor];
            
			attributes[i][j] = [[NSMutableDictionary alloc] init];
			[attributes[i][j] setObject:[self fastFont] forKey:NSFontAttributeName];
			[attributes[i][j] setObject:[UIColor blackColor]
                                 forKey:NSForegroundColorAttributeName];
            
            // (18 * 33) - (18 *(j + 1))
            CGRect rect = CGRectMake(HORIZ_PX*i, (VERT_PX*(j)), HORIZ_PX, VERT_PX);
            
			rectArray[i][j] = rect; // NSStringFromCGRect(CGRectMake(HORIZ_PX*i, (VERT_PX * kROWS)-(VERT_PX*(j+1)), HORIZ_PX, VERT_PX));
		}
	}
    
	characterSizeDictionary = [NSMutableDictionary dictionaryWithCapacity:100];
    
	//characterSize = [a sizeWithAttributes:attributes[0][0]]; // no need to do this every time we draw a character
    
    characterSize = [@"a" sizeWithFont:[UIFont systemFontOfSize:theFontSize]];
}

- (BOOL)isOpaque
{
	return YES;
}

- (void)draw {
 //   NSLog(@"test");
 //   dispatch_async(dispatch_get_main_queue(), ^{
        [self setNeedsDisplay];
  //  });
}

- (void)setString:(NSString *)c
   withBackground:(UIColor *)bgColor
  withLetterColor:(UIColor *)letterColor
	  atLocationX:(short)x
		locationY:(short)y
    withFancyFont:(bool)fancyFont
{
   // dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
  //       NSString *character =  c;
   //      UIColor *backColor = bgColor;
   //      UIColor *letColor = letterColor;
    return;
        CGRect updateRect;
        CGSize stringSize;
        
        letterArray[x][y] = nil;
        bgColorArray[x][y] = nil;
        attributes[x][y] = nil;
        
        letterArray[x][y] = c;
        bgColorArray[x][y] = bgColor;
   //     [attributes[x][y] setObject:letterColor forKey:NSForegroundColorAttributeName];
        //[attributes[x][y] setObject:[self fontForString:c] forKey:NSFontAttributeName];
   //     [attributes[x][y] setObject:(fancyFont ? [self slowFont] : [self fastFont]) forKey:NSFontAttributeName];
        
        stringSize = [[characterSizeDictionary objectForKey:c] CGSizeValue];
        stringSize.width += 1;
        
        if (stringSize.width >= rectArray[x][y].size.width) { // custom update rectangle
            updateRect.origin.y = rectArray[x][y].origin.y;
            updateRect.size.height = rectArray[x][y].size.height;
            updateRect.origin.x = rectArray[x][y].origin.x + (rectArray[x][y].size.width - stringSize.width - 10)/2;
            updateRect.size.width = stringSize.width + 10;
            //[self setNeedsDisplayInRect:updateRect];
            dispatch_async(dispatch_get_main_queue(), ^{
                //[self setNeedsDisplay];
                [self setNeedsDisplayInRect:updateRect];
            });
            
        } else { // fits within the cell rectangle; no need for a custom update rectangle
            //[self setNeedsDisplayInRect:rectArray[x][y]];
            //       dispatch_async(dispatch_get_main_queue(), ^{
       //     [self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:YES];
        }
  //  });
}

- (void)drawRect:(CGRect)rect
{
 //   NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if (!animationRunning)
    {
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        animationRunning = YES;
        return;
    }

    
	int i, j, startX, startY, endX, endY;

    
        startX = (int) (kCOLS * rect.origin.x / hWindow);
        startY = kROWS - (int) (kCOLS * (rect.origin.y + rect.size.height + vPixels - 1 ) / vWindow);
        endX = (int) (kCOLS * (rect.origin.x + rect.size.width + hPixels - 1) / hWindow);
        endY = kROWS - (int) (kROWS * rect.origin.y / vWindow);
        
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

        for ( j = startY; j < endY; j++ ) {
            for ( i = startX; i < endX; i++ ) {
             @autoreleasepool {
                //
                UIColor *color = bgColorArrayCopy[i][j];
                
               // if ([color respondsToSelector:@selector(set)]) {
                    [color set];
                    UIBezierPath *path = [UIBezierPath bezierPathWithRect:rectArray[i][j]];
                    [path fill];
                
                    path = nil;
                    //color = nil;
             }
                //}
                
                    
               // }
                
      //          NSLog(@"bgColorArray[%i][%i] is %@; letter is %@, letter color is %@", i, j, bgColorArray[i][j], letterArray[i][j], [attributes[i][j] objectForKey:NSForegroundColorAttributeName]);
              //  [self drawTheString:letterArray[i][j] centeredIn:rectArray[i][j] withAttributes:attributes[i][j]];
                   //[self drawTheString:@"A" centeredIn:CGRectMake(10, 10, 10, 10) withAttributes:attributes[i][j]];
            }
        }
   // }
}

- (void)drawTheString:(NSString *)theString centeredIn:(CGRect)rect withAttributes:(NSMutableDictionary *)theAttributes
{
   // NSLog(@"theString is '%@'", theString);

	// Assuming a space character is an empty rectangle provides a major
	// increase in redraw speed.
	if (theString.length == 0 || [theString isEqualToString:@" "]) {
		return;
	}

    @autoreleasepool {
        //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        CGPoint stringOrigin;
        CGSize stringSize;
        
        // Cache glyph sizes.
        if ([characterSizeDictionary objectForKey:theString] == nil) {
            stringSize = [theString sizeWithFont:[theAttributes valueForKey:NSFontAttributeName]];	// quite expensive
            //	NSLog(@"stringSize for '%@' has width %f and height %f", theString, stringSize.width, stringSize.height);
            [characterSizeDictionary setObject:[NSValue valueWithCGSize:stringSize] forKey:theString];
        } else {
            stringSize = [[characterSizeDictionary objectForKey:theString] CGSizeValue];
        }
        
        stringOrigin.x = rect.origin.x + (rect.size.width - stringSize.width) * 0.5;
        stringOrigin.y = rect.origin.y + (rect.size.height - stringSize.height) * 0.5;
        
        //	[theString drawAtPoint:stringOrigin withAttributes:theAttributes];
        [theString drawAtPoint:stringOrigin withFont:[UIFont systemFontOfSize:18]];
    }
	
    
	//[pool drain];
}

- (short)horizPixels {
	return hPixels;
}

- (short)vertPixels {
	return vPixels;
}

- (short)horizWindow {
	return hWindow;
}

- (short)vertWindow {
	return vWindow;
}

- (short)fontSize {
	return theFontSize;
}

- (NSString *)fontName {
    return basicFontName;
}

- (void)setHorizWindow:(short)hPx
            vertWindow:(short)vPx
              fontSize:(short)size
{
	@autoreleasepool {
        int i, j;
        hPixels = hPx / kCOLS;
        vPixels = vPx / kROWS;
        hWindow = hPx;
        vWindow = vPx;
        theFontSize = size;
        theSlowFont = nil;
        theFastFont = nil;
        
        for (j = 0; j < kROWS; j++) {
            for (i = 0; i < kCOLS; i++) {
                [attributes[i][j] setObject:[self fontForString:letterArray[i][j]] forKey:NSFontAttributeName];
                rectArray[i][j] = CGRectMake((int) (hPx * i / kCOLS),
                                             (int) (vPx - (vPx * (j+1) / kROWS)),
                                             ((int) (hPx * (i+1) / kCOLS)) - ((int) (hPx * (i) / kCOLS)),//hPixels + 1,
                                             ((int) (vPx * (j+1) / kROWS)) - ((int) (vPx * (j) / kROWS)));//vPixels + 1);
            }
        }
      //  characterSize = [@"a" sizeWithAttributes:attributes[0][0]];
        characterSize = [@"a" sizeWithFont:[UIFont systemFontOfSize:theFontSize]];
        [characterSizeDictionary removeAllObjects];
    }
}


@end
