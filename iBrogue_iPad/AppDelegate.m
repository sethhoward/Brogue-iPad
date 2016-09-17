//
//  AppDelegate.m
//  iBrogue_iPad
//
//  Created by Seth Howard on 2/22/13.
//  Copyright (c) 2013 Seth howard. All rights reserved.
//

#import "AppDelegate.h"
#import "GameSettings.h"
#import "ViewController.h"
#import "iRate.h"

@implementation AppDelegate

+ (void)initialize
{
    //set the bundle ID. normally you wouldn't need to do this
    //as it is picked up automatically from your Info.plist file
    //but we want to test with an app that's actually on the store
	[iRate sharedInstance].onlyPromptIfLatestVersion = NO;
    [iRate sharedInstance].message = @"You just had a great run! Must feel good. You know what also feels good? A great rating for a free game. It feeds my ego every morning when I look at the reviews. Help out and rate now, it'll just take a minute.";
    
    //enable preview mode
    [iRate sharedInstance].previewMode = NO;
    [iRate sharedInstance].promptAgainForEachNewVersion = YES;
    [iRate sharedInstance].daysUntilPrompt = 9999;
    [iRate sharedInstance].usesUntilPrompt = 9999;
    [[iRate sharedInstance] setRemindPeriod:0.];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//    [application setStatusBarHidden:YES];
//    CGRect frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width * 2, [[UIScreen mainScreen] bounds].size.height * 2);
//    self.window = [[UIWindow alloc] initWithFrame:frame];
//    // Override point for customization after application launch.
//    self.viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
//    //self.viewController.view.frame = CGRectMake(0, 0, self.window.bounds.size.width, self.window.bounds.size.height);
//    
    if ([[GameSettings sharedInstance] allowShake]) {
        application.applicationSupportsShakeToEdit = YES;
    }
//
//    self.window.rootViewController = self.viewController;
//    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
