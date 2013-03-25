//
//  ViewController.h
//  iBrogue_iPad
//
//  Created by Seth Howard on 2/22/13.
//  Copyright (c) 2013 Seth howard. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Rogue.h"

@class Viewport, ViewController;

extern Viewport *theMainDisplay;
extern ViewController *viewController;

@interface ViewController : UIViewController

struct iBTouch {
    UITouchPhase phase;
    CGPoint location;
};
typedef struct iBTouch iBTouch;

- (void)setBrogueGameEvent:(BrogueGameEvent)brogueGameEvent;
@property (nonatomic, readonly, getter = isSeedKeyDown) BOOL seedKeyDown;
@property (nonatomic, assign) BOOL blockMagView;    // block the magnifying glass from appearing
@property (readonly) uint cachedTouchesCount;
@property (readonly) uint cachedKeyStrokeCount;

- (iBTouch)getTouchAtIndex:(uint)index;
- (void)removeTouchAtIndex:(uint)index;
- (char)dequeKeyStroke;

- (void)showKeyboard;

// only one screen can show at a time. We use two different views for the game and title view to handle custom
// iOS buttons etc. This makes for smoother transitions and is for looks only.
- (void)showTitle;
- (void)showAuxillaryScreensWithDirectionalControls:(BOOL)controls;
- (void)showInventoryShowButton:(BOOL)show;

- (void)turnOnPinchGesture;
- (void)turnOffPinchGesture;

@end