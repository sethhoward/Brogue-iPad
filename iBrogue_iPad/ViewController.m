//
//  ViewController.m
//  iBrogue_iPad
//
//  Created by Seth Howard on 2/22/13.
//  Copyright (c) 2013 Seth howard. All rights reserved.
//

#import "ViewController.h"
#include <limits.h>
#include <unistd.h>
#import "RogueDriver.h"
#import "Viewport.h"

#define BROGUE_VERSION	4	// A special version number that's incremented only when
// something about the OS X high scores file structure changes.

@interface ViewController ()

@end

@implementation ViewController

{
@private
    // temp
    
    short mouseX, mouseY;
    NSDate *pauseStartDate;
}
static ViewController *instance;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    instance = self;
    
    
    [self playBrogue:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)awakeFromNib
{
    //	extern Viewport *theMainDisplay;
    //	CGSize theSize;
	short versionNumber;
    
	versionNumber = [[NSUserDefaults standardUserDefaults] integerForKey:@"Brogue version"];
	if (versionNumber == 0 || versionNumber < BROGUE_VERSION) {
		// This is so we know when to purge the relevant preferences and save them anew.
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"NSWindow Frame Brogue main window"];
        
		if (versionNumber != 0) {
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Brogue version"];
		}
		[[NSUserDefaults standardUserDefaults] setInteger:BROGUE_VERSION forKey:@"Brogue version"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
    
    //	theMainDisplay = theDisplay;
    /*	[theWindow setFrameAutosaveName:@"Brogue main window"];
     [theWindow useOptimizedDrawing:YES];
     [theWindow setAcceptsMouseMovedEvents:YES];
     
     // Comment out this line if you're trying to compile on a system earlier than OS X 10.7:
     [theWindow setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];*/
    
    //	theSize.height = 7 * VERT_PX * kROWS / FONT_SIZE;
    //	theSize.width = 7 * HORIZ_PX * kCOLS / FONT_SIZE;
    //	[theWindow setContentMinSize:theSize];
    
	mouseX = mouseY = 0;
}

- (IBAction)playBrogue:(id)sender
{
    //UNUSED(sender);
    //	[fileMenu setAutoenablesItems:NO];
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void){
        rogueMain();
    });
    

    //	[fileMenu setAutoenablesItems:YES];
	//exit(0);
}

- (IBAction)fuckyoutouched:(id)sender {
    [self.theDisplay setNeedsDisplay];
}

/*
- (void) plotChar:(char)inputChar xLoc:(short)xLoc yLoc:(short)yLoc forered:(short)foreRed foregreen:(short)foreGreen foreBlue:(short)foreBlue backRed:(short)backRed backGreen:(short)backGreen backBlue:(short)backBlue {

   // @autoreleasepool {
        
    
        [self.theDisplay setString:nil
                   withBackground:backgroundColor
                  withLetterColor:foreGroundColor
                       atLocationX:xLoc locationY:yLoc
                    withFancyFont:(inputChar == FOLIAGE_CHAR)];
    
        backgroundColor = nil;
        foreGroundColor = nil;
   // }
}*/

@end
