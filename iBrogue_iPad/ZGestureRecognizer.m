//
//  ZGestureRecognizer.m
//  MyPetZombie
//
//  Created by Seth Howard on 4/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ZGestureRecognizer.h"

#define kMinimumLength 320
#define kMinimumAngle 35
#define kMaximumAngle 100

@implementation ZGestureRecognizer {
    @private
    NSTimeInterval _startTouchTime;
}


CGFloat distanceBetweenPoints (CGPoint first, CGPoint second) {
    CGFloat deltaX = second.x - first.x;
    CGFloat deltaY = second.y - first.y;
    return sqrt(deltaX*deltaX + deltaY*deltaY );
}

CGFloat angleBetweenLine(CGPoint line1Start, CGPoint line1End, CGPoint line2Start, CGPoint line2End) {
    
    CGFloat a = line1End.x - line1Start.x;
    CGFloat b = line1End.y - line1Start.y;
    CGFloat c = line2End.x - line2Start.x;
    CGFloat d = line2End.y - line2Start.y;
    
    CGFloat rads = acos(((a*c) + (b*d)) / ((sqrt(a*a + b*b)) * (sqrt(c*c + d*d))));
    
    double degree = 0;
    degree = rads * (57.29578); //180/3.14159265
    return degree;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    lineLengthSoFar = 0.0f;
    lastPreviousPoint = point;
    lastCurrentPoint = point;
    _startingPoint = point;
    
    waypoint1Success = NO;
    waypoint2Success = NO;
    waypoint3Success = NO;
    
    _startTouchTime = touch.timestamp;
}

- (CGFloat)validSwipSpeedWithStartPoint:(CGPoint)startPoint andCurrentPoint:(CGPoint)currentPoint andTime:(NSTimeInterval)timeStamp {
    CGFloat dy = abs(startPoint.y - currentPoint.y);
    CGFloat dx = abs(startPoint.x - currentPoint.y);
    
    CGFloat l = sqrt(dx*dx + dy*dy);
    NSTimeInterval tdiff = fabs(_startTouchTime - timeStamp);
    CGFloat speed = l/tdiff;
    
    NSLog(@"Speed %.2f Length %.2f dx %.2f dy %.2f", speed, lineLengthSoFar, dx, dy);
    
    return speed;
}

- (CGFloat) pointPairToBearingDegrees:(CGPoint)startingPoint secondPoint:(CGPoint) endingPoint
{
    CGPoint originPoint = CGPointMake(endingPoint.x - startingPoint.x, endingPoint.y - startingPoint.y); // get origin point to origin by subtracting end from start
    float bearingRadians = atan2f(originPoint.y, originPoint.x); // get bearing in radians
    float bearingDegrees = bearingRadians * (180.0 / M_PI); // convert to degrees
  //  bearingDegrees = (bearingDegrees > 0.0 ? bearingDegrees : (360.0 + bearingDegrees)); // correct discontinuity
    return fabs(bearingDegrees);
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    CGPoint previousPoint = [touch previousLocationInView:self.view];
    CGPoint currentPoint = [touch locationInView:self.view];
    
    CGFloat angle = [self pointPairToBearingDegrees:_startingPoint secondPoint:currentPoint];
        
    if (!waypoint1Success || waypoint3Success) {
    //    NSLog(@"##1:%.2f > %.2f %.2f", currentPoint.x, startingPoint.x, lineLengthSoFar);
        
        if (currentPoint.x > _startingPoint.x && lineLengthSoFar >= kMinimumLength) {
          //  if ([self validSwipSpeedWithStartPoint:startingPoint andCurrentPoint:currentPoint andTime:touch.timestamp] > 100.) {
      //     NSLog(@"1################ %.2f", angle);
            if (angle < 15.) {
                waypoint1Success = YES;
                //      NSLog(@"Gesture Success 1");
                lineLengthSoFar = 0;
                _startingPoint.x = currentPoint.x;
                _startingPoint.y = currentPoint.y;
                _startTouchTime = touch.timestamp;
                lastPreviousPoint = previousPoint;
                lastCurrentPoint =  currentPoint;
            }
            else {
                //[self setState:UIGestureRecognizerStateCancelled];
                [self reset];
            }
        }
    }
    else if(!waypoint2Success){
        
    //    NSLog(@"##2: y %.2f > %.2f %.2f x: %.2f < %2.f", currentPoint.y, startingPoint.y, lineLengthSoFar, currentPoint.x, startingPoint.x);
        
        if (/*currentPoint.y > startingPoint.y &&*/ lineLengthSoFar >= kMinimumLength && currentPoint.x < _startingPoint.x) {
         //   NSLog(@"2################ %.2f", angle);
         //   NSLog(@"Gesture Success 2");
          //  if ([self validSwipSpeedWithStartPoint:startingPoint andCurrentPoint:currentPoint andTime:touch.timestamp] > 600.) {
               // [self validSwipSpeedWithStartPoint:startingPoint andCurrentPoint:currentPoint andTime:touch.timestamp];
            if (angle < 195. && angle > 150.) {
                waypoint2Success = YES;
                lineLengthSoFar = 0;
                _startingPoint.x = currentPoint.x;
                _startingPoint.y = _startingPoint.y;
                _startTouchTime = touch.timestamp;
                lastPreviousPoint = previousPoint;
                lastCurrentPoint =  currentPoint;
            }
            else {
                //[self setState:UIGestureRecognizerStateCancelled];
                [self reset];
            }
            
        }
    }
    else if(!waypoint3Success){
      //  NSLog(@"##3: %.2f > %.2f %.2f", currentPoint.x, startingPoint.x, lineLengthSoFar);
        
        if (currentPoint.x > _startingPoint.x && lineLengthSoFar >= kMinimumLength) {
     //       NSLog(@"3################ %.2f", angle);
         //   if ([self validSwipSpeedWithStartPoint:startingPoint andCurrentPoint:currentPoint andTime:touch.timestamp] > 100.) {
             //   [self validSwipSpeedWithStartPoint:startingPoint andCurrentPoint:currentPoint andTime:touch.timestamp];
            if (angle < 40.) {
                waypoint3Success = YES;
          //      NSLog(@"Gesture Success 3");
                lineLengthSoFar = 0;
           //     NSLog(@"#######FIRE#####");
                [self setState:UIGestureRecognizerStateEnded];
              
                [self reset];
            }
            else {
                //[self setState:UIGestureRecognizerStateCancelled];
                [self reset];
            }
        }
    }
    
    lineLengthSoFar += distanceBetweenPoints(previousPoint, currentPoint);
}

- (void)reset {
    [super reset];
    waypoint1Success = NO;
    waypoint2Success = NO;
    waypoint3Success = NO;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    [self setState:UIGestureRecognizerStateCancelled];
}


@end
