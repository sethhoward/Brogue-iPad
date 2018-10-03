//
//  DirectionControlsViewController.m
//  iBrogue_iPad
//
//  Created by Seth Howard on 7/12/14.
//  Copyright (c) 2014 Seth howard. All rights reserved.
//

#import "DirectionControlsViewController.h"

NSString *kUP_Key = @"k";
NSString *kRIGHT_key = @"l";
NSString *kDOWN_key = @"j";
NSString *kLEFT_key = @"h";
NSString *kUPLEFT_key = @"y";
NSString *kUPRight_key = @"u";
NSString *kDOWNLEFT_key = @"b";
NSString *kDOWNRIGHT_key = @"n";

@interface DirectionControlsViewController ()
// we use the container to animate hide and show while keeping the parent view on the parent layer
@property (weak, nonatomic) IBOutlet UIView *controlsContainer;
@property (nonatomic, assign, getter = isButtonDown) BOOL buttonDown;
@property (nonatomic, strong) NSTimer *repeatTimer;
@end

@implementation DirectionControlsViewController

#pragma mark -

- (void)handleRepeatKeyPress {
    // trigger the KVO
    self.directionalButton = self.directionalButton;
}

- (void)cancel {
    [self buttonUp:self];
}

- (IBAction)buttonDown:(id)sender {
    self.directionalButton = (UIButton *)sender;
    self.buttonDown = YES;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.buttonDown) {
            [self.repeatTimer invalidate];
            self.repeatTimer = nil;
            self.repeatTimer = [NSTimer scheduledTimerWithTimeInterval:0.08 target:self selector:@selector(handleRepeatKeyPress) userInfo:nil repeats:YES];
        }
    });
}

- (IBAction)buttonUp:(id)sender {
    self.buttonDown = NO;
    [self.repeatTimer invalidate];
    self.repeatTimer = nil;
    self.directionalButton = nil;
}

@end
