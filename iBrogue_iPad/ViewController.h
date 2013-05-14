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

// Lazy accessors. Used in the C bridge.
extern Viewport *theMainDisplay;
extern ViewController *viewController;

@interface ViewController : UIViewController

struct iBTouch {
    UITouchPhase phase;
    CGPoint location;
};
typedef struct iBTouch iBTouch;

// Used to trigger seed
@property (nonatomic, readonly, getter = isSeedKeyDown) BOOL seedKeyDown;

- (void)setBrogueGameEvent:(BrogueGameEvent)brogueGameEvent;

// Touches
- (iBTouch)getTouchAtIndex:(uint)index;
- (void)removeTouchAtIndex:(uint)index;
- (char)dequeKeyStroke;

@property (readonly) uint cachedTouchesCount;
@property (readonly) uint cachedKeyStrokeCount;

// Settings
- (void)turnOnPinchGesture;
- (void)turnOffPinchGesture;

@end