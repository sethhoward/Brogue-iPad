//
//  GameSettings.h
//  iBrogue_iPad
//
//  Created by Seth Howard on 3/11/13.
//  Copyright (c) 2013 Seth howard. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GameSettings : NSObject

+ (id)sharedInstance;

@property (nonatomic, assign) BOOL allowShake;
@property (nonatomic, assign) BOOL allowESCGesture;
@property (nonatomic, assign) BOOL allowMagnifier;
@property (nonatomic, assign) BOOL allowPinchToZoomDirectional;

@end
