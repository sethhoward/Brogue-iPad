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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self initGestureRecognizers];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -

- (void)hideWithAnimation:(BOOL)animation {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.2 animations:^{
            self.controlsContainer.transform = CGAffineTransformMakeScale(.0000001, .0000001);
            [self buttonUp:nil];
        }];
    });
}

- (void)showWithAnimation:(BOOL)animation {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.2 animations:^{
            self.controlsContainer.transform = CGAffineTransformMakeScale(1., 1.);
            [self buttonUp:nil];
        }];
    });
}

- (void)initGestureRecognizers {
    UIPinchGestureRecognizer *directionalPinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [self.view addGestureRecognizer:directionalPinch];
}

- (void)handlePinch:(UIPinchGestureRecognizer *)pinch {
    if (pinch.velocity < 0 && !_areDirectionalControlsHidden) {
        self.controlsContainer.transform = CGAffineTransformMakeScale(pinch.scale, pinch.scale);
    }
    else if(pinch.velocity > 0 && _areDirectionalControlsHidden){
        self.controlsContainer.transform = CGAffineTransformMakeScale(1 - pinch.scale, 1 - pinch.scale);
    }
    
    if (pinch.state == UIGestureRecognizerStateEnded || pinch.state == UIGestureRecognizerStateCancelled) {
        if (pinch.scale < 0.6f) {
            [self hideWithAnimation:YES];
            
            _areDirectionalControlsHidden = YES;
        }
        else {
            [self showWithAnimation:YES];
            
            _areDirectionalControlsHidden = NO;
        }
    }
}


#pragma mark -

- (void)handleRepeatKeyPress {
    // trigger the KVO
    self.directionalButton = self.directionalButton;
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
