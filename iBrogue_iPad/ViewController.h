//
//  ViewController.h
//  iBrogue_iPad
//
//  Created by Seth Howard on 2/22/13.
//  Copyright (c) 2013 Seth howard. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Viewport;
@interface ViewController : UIViewController

// - (void) plotChar:(char)inputChar xLoc:(short)xLoc yLoc:(short)yLoc forered:(short)foreRed foregreen:(short)foreGreen foreBlue:(short)foreBlue backRed:(short)backRed backGreen:(short)backGreen backBlue:(short)backBlue;

@property (nonatomic, strong) IBOutlet Viewport *theDisplay;
- (IBAction)fuckyoutouched:(id)sender;

@end
