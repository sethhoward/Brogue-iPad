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

@property (nonatomic, readonly, getter = isSeedKeyDown) BOOL seedKeyDown;

- (uint)cachedTouchesCount;
- (iBTouch)getTouchAtIndex:(uint)index;
- (void)removeTouchAtIndex:(uint)index;

- (uint)cachedKeyStrokeCount;
- (char)dequeKeyStroke;

- (void)showKeyboard;

// only one screen can show at a time. We use two different views for the game and title view to handle custom
// iOS buttons etc. This makes for smoother transitions and is for looks only.
- (void)showTitle;
- (void)showAuxillaryScreensWithDirectionalControls:(BOOL)controls;

@end