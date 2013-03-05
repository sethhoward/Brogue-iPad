//
//  ViewController.h
//  iBrogue_iPad
//
//  Created by Seth Howard on 2/22/13.
//  Copyright (c) 2013 Seth howard. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Viewport, ViewController;

extern Viewport *theMainDisplay;
extern ViewController *viewController;

@interface ViewController : UIViewController

struct iBTouch {
    UITouchPhase phase;
    CGPoint location;
};
typedef struct iBTouch iBTouch;

@property (nonatomic, strong) IBOutlet Viewport *theDisplay;
@property (nonatomic, readonly, getter = isSeedKeyDown) BOOL seedKeyDown;

- (uint)cachedTouchesCount;
- (iBTouch)getTouchAtIndex:(uint)index;
- (void)removeTouchAtIndex:(uint)index;

- (uint)cachedKeyStrokeCount;
- (char)dequeKeyStroke;

- (void)hideControls;
- (void)showControls;
- (void)showKeyboard;
- (void)showTitlePageItems:(BOOL)show;

@end