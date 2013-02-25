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

+ (id)sharedInstance;

@property (nonatomic, strong) IBOutlet Viewport *theDisplay;
- (IBAction)fuckyoutouched:(id)sender;

@end
