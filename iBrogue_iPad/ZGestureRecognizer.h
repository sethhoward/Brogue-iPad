//
//  ZGestureRecognizer.h
//  
//  Z - swipe gesture
//
//  Created by Seth Howard on 4/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIGestureRecognizerSubclass.h>

@interface ZGestureRecognizer : UIGestureRecognizer {
    CGPoint lastPreviousPoint;
    CGPoint lastCurrentPoint;
    CGFloat lineLengthSoFar;
    CGPoint _startingPoint;
    
 //   int swipeDirection; //1 for a up/right -1 for left down
    
    BOOL waypoint1Success;
    BOOL waypoint2Success;
    BOOL waypoint3Success;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;

@end
