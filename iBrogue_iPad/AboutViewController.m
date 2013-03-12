//
//  AboutViewController.m
//  iBrogue_iPad
//
//  Created by Seth Howard on 3/5/13.
//  Copyright (c) 2013 Seth howard. All rights reserved.
//

#import "AboutViewController.h"
#import "GameSettings.h"

@interface AboutViewController ()
- (IBAction)dismissButtonPressed:(id)sender;
- (IBAction)shakeSwitch:(id)sender;
- (IBAction)escGesture:(id)sender;
- (IBAction)pinchSwitch:(id)sender;
- (IBAction)magnifierSwitch:(id)sender;

@property (weak, nonatomic) IBOutlet UISwitch *shakeSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *escGestureSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *pinchDirectionalSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *magnifierSwitch;

@end

@implementation AboutViewController

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
    
    self.shakeSwitch.on = [[GameSettings sharedInstance] allowShake];
    self.escGestureSwitch.on = [[GameSettings sharedInstance] allowESCGesture];
    self.pinchDirectionalSwitch.on = [[GameSettings sharedInstance] allowPinchToZoomDirectional];
    self.magnifierSwitch.on = [[GameSettings sharedInstance] allowMagnifier];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)dismissButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)shakeSwitch:(id)sender {
    UISwitch *aSwitch = (UISwitch *)sender;
    [[GameSettings sharedInstance] setAllowShake:aSwitch.on];
}

- (IBAction)escGesture:(id)sender {
    UISwitch *aSwitch = (UISwitch *)sender;
    [[GameSettings sharedInstance] setAllowESCGesture:aSwitch.on];
}

- (IBAction)pinchSwitch:(id)sender {
    UISwitch *aSwitch = (UISwitch *)sender;
    [[GameSettings sharedInstance] setAllowPinchToZoomDirectional:aSwitch.on];
}

- (IBAction)magnifierSwitch:(id)sender {
    UISwitch *aSwitch = (UISwitch *)sender;
    [[GameSettings sharedInstance] setAllowMagnifier:aSwitch.on];
}

@end
