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

struct iBTouch {
    UITouchPhase phase;
    CGPoint location;
};
typedef struct iBTouch iBTouch;

@property (nonatomic, strong) IBOutlet Viewport *theDisplay;
@property (weak, nonatomic) IBOutlet UIView *playerControlView;

- (IBAction)fuckyoutouched:(id)sender;
- (uint)cachedTouchesCount;
- (iBTouch)getTouchAtIndex:(uint)index;
- (void)removeTouchAtIndex:(uint)index;

- (void)hideControls;
- (void)showControls;

@end

extern Viewport *theMainDisplay;
extern ViewController *viewController;