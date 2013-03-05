//
//  AboutViewController.m
//  iBrogue_iPad
//
//  Created by Seth Howard on 3/5/13.
//  Copyright (c) 2013 Seth howard. All rights reserved.
//

#import "AboutViewController.h"

@interface AboutViewController ()
- (IBAction)dismissButtonPressed:(id)sender;
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)dismissButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
