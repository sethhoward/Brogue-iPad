//
//  AppDelegate.m
//  iBrogue_iPad
//
//  Created by Seth Howard on 2/22/13.
//  Copyright (c) 2013 Seth howard. All rights reserved.
//

#import "AppDelegate.h"
#import "GameSettings.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if ([[GameSettings sharedInstance] allowShake]) {
        application.applicationSupportsShakeToEdit = YES;
    }
    return YES;
}

@end
