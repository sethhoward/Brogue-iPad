//
//  DirectionControlsViewController.h
//  iBrogue_iPad
//
//  Created by Seth Howard on 7/12/14.
//  Copyright (c) 2014 Seth howard. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ControlDirection) {
    ControlDirectionUp = 1,
    ControlDirectionRight,
    ControlDirectionDown,
    ControlDirectionLeft,
    ControlDirectionUpLeft,
    ControlDirectionUpRight,
    ControlDirectionDownRight,
    ControlDirectionDownLeft,
};

extern NSString *kUP_Key;
extern NSString *kRIGHT_key;
extern NSString *kDOWN_key;
extern NSString *kLEFT_key;
extern NSString *kUPLEFT_key;
extern NSString *kUPRight_key;
extern NSString *kDOWNLEFT_key;
extern NSString *kDOWNRIGHT_key;

@interface DirectionControlsViewController : UIViewController

- (void)hideWithAnimation:(BOOL)animation;
- (void)showWithAnimation:(BOOL)animation;

@property (nonatomic, strong) UIButton *directionalButton;
@property (nonatomic, readonly) BOOL areDirectionalControlsHidden;

@end
