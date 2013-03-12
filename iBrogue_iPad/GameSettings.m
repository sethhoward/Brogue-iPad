//
//  GameSettings.m
//  iBrogue_iPad
//
//  Created by Seth Howard on 3/11/13.
//  Copyright (c) 2013 Seth howard. All rights reserved.
//

#import "GameSettings.h"

#define kHasInitializedDefaultValue @"hasInitializedDefaultValues"
#define kAllowShake @"allowShake"
#define kAllowESCGesture @"allowESCGesture"
#define kAllowMagnifier @"allMagnifier"
#define kAllowPinchToZoomDirectional @"allowPinchToZoomDirectional"

@implementation GameSettings

+ (id)sharedInstance {
    static GameSettings *instance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[GameSettings alloc] init];
    });
    
    return instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:kHasInitializedDefaultValue]) {
            [self initializeDefaultValues];
        }
        
        [self populateValues];
    }
    return self;
}

- (void)initializeDefaultValues {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kHasInitializedDefaultValue];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kAllowShake];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kAllowESCGesture];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kAllowMagnifier];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kAllowPinchToZoomDirectional];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
 //   NSLog(@"%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
}

- (void)populateValues {
  //  NSLog(@"%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
    
    self.allowShake = [[NSUserDefaults standardUserDefaults] boolForKey:kAllowShake];
    self.allowESCGesture = [[NSUserDefaults standardUserDefaults] boolForKey:kAllowESCGesture];
    self.allowMagnifier = [[NSUserDefaults standardUserDefaults] boolForKey:kAllowMagnifier];
    self.allowPinchToZoomDirectional = [[NSUserDefaults standardUserDefaults] boolForKey:kAllowPinchToZoomDirectional];
    
 //   NSLog(@"%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
}

#pragma mark - getters/setters

- (void)setAllowShake:(BOOL)allowShake {
    _allowShake = allowShake;
    [[NSUserDefaults standardUserDefaults] setBool:allowShake forKey:kAllowShake];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setAllowESCGesture:(BOOL)allowESCGesture {
    _allowESCGesture = allowESCGesture;
    [[NSUserDefaults standardUserDefaults] setBool:allowESCGesture forKey:kAllowESCGesture];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setAllowMagnifier:(BOOL)allowMagnifier {
    _allowMagnifier = allowMagnifier;
    [[NSUserDefaults standardUserDefaults] setBool:allowMagnifier forKey:kAllowMagnifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setAllowPinchToZoomDirectional:(BOOL)allowPinchToZoomDirectional {
    _allowPinchToZoomDirectional = allowPinchToZoomDirectional;
    [[NSUserDefaults standardUserDefaults] setBool:allowPinchToZoomDirectional forKey:kAllowPinchToZoomDirectional];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
