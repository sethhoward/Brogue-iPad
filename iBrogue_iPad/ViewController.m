//
//  ViewController.m
//  iBrogue_iPad
//
//  Created by Seth Howard on 2/22/13.
//  Copyright (c) 2013 Seth howard. All rights reserved.
//

#import "ViewController.h"
#include <limits.h>
#include <unistd.h>
#import "RogueDriver.h"
#import "Viewport.h"
#import "GameCenterManager.h"
#import "UIViewController+UIViewController_GCLeaderBoardView.h"
#import "AboutViewController.h"
#import "ZGestureRecognizer.h"
#import "GameSettings.h"

#define kStationaryTime 0.5f
#define kGamePlayHitArea CGRectMake(209., 74., 810., 650.)     // seems to be a method in the c code that does this but didn't work as expected
#define BROGUE_VERSION	4	// A special version number that's incremented only when
// something about the OS X high scores file structure changes.

Viewport *theMainDisplay;
ViewController *viewController;

typedef enum {
    KeyDownUp = 0,
    KeyDownRight,
    KeyDownDown,
    KeyDownLeft,
}KeyDown;

#define kESC_Key @"\033"

@interface ViewController () <UITextFieldDelegate, UIGestureRecognizerDelegate>
- (IBAction)escButtonPressed:(id)sender;
- (IBAction)upButtonPressed:(id)sender;
- (IBAction)downButtonPressed:(id)sender;
- (IBAction)rightButtonPressed:(id)sender;
- (IBAction)leftButtonPressed:(id)sender;
- (IBAction)upLeftButtonPressed:(id)sender;
- (IBAction)upRightButtonPressed:(id)sender;
- (IBAction)downLeftButtonPressed:(id)sender;
- (IBAction)downRightButtonPressed:(id)sender;
- (IBAction)seedKeyPressed:(id)sender;
- (IBAction)showLeaderBoardButtonPressed:(id)sender;
- (IBAction)aboutButtonPressed:(id)sender;

@property (weak, nonatomic) IBOutlet UIView *directionalButtonSubContainer;
@property (weak, nonatomic) IBOutlet UIButton *seedButton;
@property (weak, nonatomic) IBOutlet Viewport *secondaryDisplay;   // game etc
@property (nonatomic, strong) IBOutlet Viewport *titleDisplay;
@property (weak, nonatomic) IBOutlet UIView *buttonView;
@property (weak, nonatomic) IBOutlet UIButton *escButton;
@property (nonatomic, strong) NSMutableArray *cachedTouches; // collection of iBTouches
@property (weak, nonatomic) IBOutlet UIView *playerControlView;
@property (weak, nonatomic) IBOutlet UITextField *aTextField;
@property (nonatomic, strong) NSMutableArray *cachedKeyStrokes;
@end

@implementation ViewController {
    @private
    __unused NSTimer __strong *_autoSaveTimer;
    CGPoint _lastTouchLocation;
//    BOOL _blockCachingTouches;
    NSTimer __strong *_stationaryTouchTimer;
    BOOL _areDirectionalControlsHidden;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [GameCenterManager sharedInstance];
    [[GameCenterManager sharedInstance] authenticateLocalUser];
	// Do any additional setup after loading the view, typically from a nib.
    
    if (!theMainDisplay) {
        self.titleDisplay.hidden = YES;
        theMainDisplay = self.titleDisplay;
        viewController = self;
        _cachedTouches = [NSMutableArray arrayWithCapacity:1];
        _cachedKeyStrokes = [NSMutableArray arrayWithCapacity:1];
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(didShowKeyboard) name:UIKeyboardDidShowNotification object:nil];
        [center addObserver:self selector:@selector(didHideKeyboard) name:UIKeyboardWillHideNotification object:nil];
     //   [center addObserver:self selector:@selector(applicationWillResign) name:UIApplicationWillResignActiveNotification object:nil];
        [center addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        [self.buttonView setAlpha:0];
        
        double delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [UIView animateWithDuration:0.2 animations:^{
                self.buttonView.alpha = 1.;
            }];
        });
        
        [self initGestureRecognizers];
        
        //TODO: consider this... may not be the time for this yet
      //  _autoSaveTimer = [NSTimer scheduledTimerWithTimeInterval:20. target:self selector:@selector(autoSave) userInfo:nil repeats:YES];
    }
    
    [self becomeFirstResponder];
    
    
    [self playBrogue];
}

/*
- (void)applicationWillResign {
    [self.secondaryDisplay removeMagnifyingGlass];
    
    @synchronized(self){
        [self.cachedKeyStrokes removeAllObjects];
        [self.cachedTouches removeAllObjects];
    }
}*/

- (void)applicationDidBecomeActive {
    [self.secondaryDisplay removeMagnifyingGlass];
    
    @synchronized(self){
        [self.cachedKeyStrokes removeAllObjects];
        [self.cachedTouches removeAllObjects];
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event{
    // you can do any thing at this stage what ever you want. Change the song in playlist, show photo, change photo or whatever you want to do

    if (![[GameSettings sharedInstance] allowShake]) {
        return;
    }
    
    @synchronized(self.cachedKeyStrokes) {
        [self.cachedKeyStrokes removeAllObjects];
        [self.cachedKeyStrokes addObject:kESC_Key];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)awakeFromNib
{
    //	extern Viewport *theMainDisplay;
    //	CGSize theSize;
	short versionNumber;
    
	versionNumber = [[NSUserDefaults standardUserDefaults] integerForKey:@"Brogue version"];
	if (versionNumber == 0 || versionNumber < BROGUE_VERSION) {
		// This is so we know when to purge the relevant preferences and save them anew.
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"NSWindow Frame Brogue main window"];
        
		if (versionNumber != 0) {
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Brogue version"];
		}
		[[NSUserDefaults standardUserDefaults] setInteger:BROGUE_VERSION forKey:@"Brogue version"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

- (void)playBrogue
{
    rogueMain();
}

#pragma mark - touches

- (void)initGestureRecognizers {
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    doubleTap.delegate = self;
    [self.secondaryDisplay addGestureRecognizer:doubleTap];
    
  /*  if ([[GameSettings sharedInstance] allowESCGesture]) {
        ZGestureRecognizer *zGesture = [[ZGestureRecognizer alloc] initWithTarget:self action:@selector(handleZGesture:)];
        [self.view addGestureRecognizer:zGesture];
    }*/
    
    if ([[GameSettings sharedInstance] allowPinchToZoomDirectional]) {
        UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
        [self.playerControlView addGestureRecognizer:pinch];
    }
}

- (void)handlePinch:(UIPinchGestureRecognizer *)pinch {
//    NSLog(@"%.2f %.2f", pinch.scale, pinch.velocity);
    
    if (pinch.velocity < 0 && !_areDirectionalControlsHidden) {
        self.directionalButtonSubContainer.transform = CGAffineTransformMakeScale(pinch.scale, pinch.scale);
    }
    else if(pinch.velocity > 0 && _areDirectionalControlsHidden){
        self.directionalButtonSubContainer.transform = CGAffineTransformMakeScale(1 - pinch.scale, 1 - pinch.scale);
    }
    
    if (pinch.state == UIGestureRecognizerStateEnded || pinch.state == UIGestureRecognizerStateCancelled) {
        if (pinch.scale < 0.6f) {
            [UIView animateWithDuration:0.2 animations:^{
                self.directionalButtonSubContainer.transform = CGAffineTransformMakeScale(.0000001, .0000001);
            }];
            
            _areDirectionalControlsHidden = YES;
        }
        else {
            [UIView animateWithDuration:0.2 animations:^{
                self.directionalButtonSubContainer.transform = CGAffineTransformMakeScale(1., 1.);
            }];
            
            _areDirectionalControlsHidden = NO;
        }
    }
}

/*  Not working as I had hoped plus it just feels a bit like shit
- (void)handleZGesture:(ZGestureRecognizer *)zGesture {
    [self stopStationaryTouchTimer];
    [self.secondaryDisplay removeMagnifyingGlass];
    
    @synchronized(self.cachedKeyStrokes) {
        [self.cachedKeyStrokes removeAllObjects];
        [self.cachedKeyStrokes addObject:kESC_Key];
    }
}*/

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CGPoint pointInView = [touch locationInView:gestureRecognizer.view];
    
    if ( [gestureRecognizer isMemberOfClass:[UITapGestureRecognizer class]]
        && CGRectContainsPoint(self.playerControlView.frame, pointInView)) {
        return NO;
    }
    
    return YES;
}

// TODO: touches are manually cached here instead of going through a central point
- (void)handleDoubleTap:(UITapGestureRecognizer *)tap {
    [self stopStationaryTouchTimer];
    [self.secondaryDisplay removeMagnifyingGlass];
    
    @synchronized(self.cachedTouches) {
        // we double tapped... send along another mouse down and up to the game
        iBTouch touchDown;
        touchDown.phase = UITouchPhaseStationary;
        touchDown.location = _lastTouchLocation;
        
        [self.cachedTouches addObject:[NSValue value:&touchDown withObjCType:@encode(iBTouch)]];
        
        iBTouch touchMoved;
        touchMoved.phase = UITouchPhaseMoved;
        touchMoved.location = _lastTouchLocation;
        [self.cachedTouches addObject:[NSValue value:&touchMoved withObjCType:@encode(iBTouch)]];
        
        iBTouch touchUp;
        touchUp.phase = UITouchPhaseEnded;
        touchUp.location = _lastTouchLocation;
        
        [self.cachedTouches addObject:[NSValue value:&touchUp withObjCType:@encode(iBTouch)]];
    }
}

- (void)addTouchToCache:(UITouch *)touch {
  /*  if (_blockCachingTouches) {
        return;
    }*/
    
    @synchronized(self.cachedTouches){
        iBTouch ibtouch;
        ibtouch.phase = touch.phase;
        
        // we need to make sure that a phase end touch ends in the same spot as the previous touch or a borks the char movement
        if (touch.phase == UITouchPhaseEnded) {
            ibtouch.location = _lastTouchLocation;
        }
        else {
          ibtouch.location = [touch locationInView:theMainDisplay];  
        }
        
       // NSLog(@"##### %i", touch.phase);
        
        _lastTouchLocation = ibtouch.location;
        [self.cachedTouches addObject:[NSValue value:&ibtouch withObjCType:@encode(iBTouch)]];
    }
}

- (iBTouch)getTouchAtIndex:(uint)index {
    NSValue *anObj = [self.cachedTouches objectAtIndex:index];
    iBTouch touch;
    [anObj getValue:&touch];
    
    return touch;
}

- (void)removeTouchAtIndex:(uint)index {
    @synchronized(self.cachedTouches){
        if ([self.cachedTouches count] > 0) {
            [self.cachedTouches removeObjectAtIndex:index];
        }
    }
}

- (uint)cachedTouchesCount {
    return [self.cachedTouches count];
}

- (void)handleStationary:(NSTimer *)timer {
    if (self.secondaryDisplay.hidden == NO && !self.blockMagView) {
        NSValue *v = timer.userInfo;
        CGPoint point = [v CGPointValue];
      //  [RogueDriver printRogue];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.secondaryDisplay addMagnifyingGlassAtPoint:point];
        });
    }
    
    [self stopStationaryTouchTimer];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
   // NSLog(@"%s", __PRETTY_FUNCTION__);

    [touches enumerateObjectsUsingBlock:^(UITouch *touch, BOOL *stop) {
        // Get a single touch and it's location
        [self addTouchToCache:touch];
        [self startStationaryTouchTimerWithTouch:touch andTimeout:kStationaryTime + 0.1];
    }];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
 //   NSLog(@" ##### %@", touches);
    [touches enumerateObjectsUsingBlock:^(UITouch *touch, BOOL *stop) {
        // Get a single touch and it's location
        [self addTouchToCache:touch];
        [self startStationaryTouchTimerWithTouch:touch andTimeout:kStationaryTime];
    }];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
 //   NSLog(@"%s", __PRETTY_FUNCTION__);
    [self stopStationaryTouchTimer];
    
    [touches enumerateObjectsUsingBlock:^(UITouch *touch, BOOL *stop) {
        // Get a single touch and it's location
        [self addTouchToCache:touch];
    }];
}

#pragma mark - Magnifier

- (BOOL)isMagHoldAvailableAtPoint:(CGPoint)point {
    CGRect boundaryRect = kGamePlayHitArea;
    
    if (!CGRectContainsPoint(boundaryRect, point)) {
        // NSLog(@"out of bounds");
        return NO;
    }
    
    return YES;
}

- (void)stopStationaryTouchTimer {
    [_stationaryTouchTimer invalidate];
    _stationaryTouchTimer = nil;
}

- (void)startStationaryTouchTimerWithTouch:(UITouch *)touch andTimeout:(NSTimeInterval)timeOut {
    if ([[GameSettings sharedInstance] allowMagnifier]) {
        [self stopStationaryTouchTimer];
        
        if ([self isMagHoldAvailableAtPoint:[touch locationInView:self.secondaryDisplay]]) {
            _stationaryTouchTimer = [NSTimer scheduledTimerWithTimeInterval:timeOut target:self selector:@selector(handleStationary:) userInfo:[NSValue valueWithCGPoint:[touch locationInView:self.secondaryDisplay]] repeats:NO];
        }
        else {
            // kill the mag if it's showing
            [self.secondaryDisplay removeMagnifyingGlass];
        }
    }
}

#pragma mark - views

- (void)showTitle {
    if (self.titleDisplay.hidden == YES) {
        theMainDisplay = self.titleDisplay;
        [self.titleDisplay startAnimating];
        [self.secondaryDisplay stopAnimating];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
    double delayInSeconds = 0.;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            self.titleDisplay.hidden = NO;
            self.secondaryDisplay.hidden = YES;
        });
    });
}

- (void)showAuxillaryScreensWithDirectionalControls:(BOOL)controls {
    if (self.titleDisplay.hidden == NO) {
        theMainDisplay = self.secondaryDisplay;
        [self.secondaryDisplay startAnimating];
        [self.titleDisplay stopAnimating];
    }
    
    self.titleDisplay.hidden = YES;
    self.secondaryDisplay.hidden = NO;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        double delayInSeconds = 0.;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            self.titleDisplay.hidden = YES;
            self.secondaryDisplay.hidden = NO;
            
            self.playerControlView.hidden = !controls;
        });
    });
    
}

#pragma mark - keyboard stuff

- (void)showKeyboard {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.aTextField.text = @"Recording";
        [self.aTextField becomeFirstResponder];
    });
}

- (void)viewDidUnload {
    [self setPlayerControlView:nil];
    [self setATextField:nil];
    [self setEscButton:nil];
    [self setButtonView:nil];
    [super viewDidUnload];
}

- (uint)cachedKeyStrokeCount {
    return [self.cachedKeyStrokes count];
}

- (char)dequeKeyStroke {
    NSString *keyStroke = [self.cachedKeyStrokes objectAtIndex:0];
    @synchronized(self.cachedKeyStrokes){
        [self.cachedKeyStrokes removeObjectAtIndex:0];
    }
    
    return [keyStroke characterAtIndex:0];
}

#pragma mark - UITextFieldDelegate

- (void)didHideKeyboard {
    if ([self.cachedKeyStrokes count] == 0) {
        [self.cachedKeyStrokes addObject:kESC_Key];
    }

    self.escButton.hidden = YES;
}

- (void)didShowKeyboard {
    self.escButton.hidden = NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.cachedKeyStrokes addObject:@"\015"];
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    const char *_char = [string cStringUsingEncoding:NSUTF8StringEncoding];
    int isBackSpace = strcmp(_char, "\b");
    
    if (isBackSpace == -8) {
        // is backspace
        [self.cachedKeyStrokes addObject:@"\177"];
    }
    else if([string isEqualToString:@"\n"]) {
        [textField resignFirstResponder];
        // enter
        [self.cachedKeyStrokes addObject:@"\015"];
    }
    else {
        // misc
        [self.cachedKeyStrokes addObject:string];
    }
    
    return YES;
}

#pragma mark - Actions

- (IBAction)escButtonPressed:(id)sender {
    [self.cachedKeyStrokes addObject:@"\033"];
    [self.aTextField resignFirstResponder];
}

- (IBAction)upButtonPressed:(id)sender {
    [self.cachedKeyStrokes addObject:@"k"];
}

- (IBAction)downButtonPressed:(id)sender {
    [self.cachedKeyStrokes addObject:@"j"];
}

- (IBAction)rightButtonPressed:(id)sender {
    [self.cachedKeyStrokes addObject:@"l"];
}

- (IBAction)leftButtonPressed:(id)sender {
    [self.cachedKeyStrokes addObject:@"h"];
}

- (IBAction)upLeftButtonPressed:(id)sender {
    [self.cachedKeyStrokes addObject:@"y"];
}

- (IBAction)upRightButtonPressed:(id)sender {
    [self.cachedKeyStrokes addObject:@"u"];
}

- (IBAction)downLeftButtonPressed:(id)sender {
    [self.cachedKeyStrokes addObject:@"b"];
}

- (IBAction)downRightButtonPressed:(id)sender {
    [self.cachedKeyStrokes addObject:@"n"];
}

- (IBAction)seedKeyPressed:(id)sender {
    _seedKeyDown = !_seedKeyDown;
    
    if (_seedKeyDown) {
        [self.seedButton setImage:[UIImage imageNamed:@"brogue_sproutedseed.png"] forState:UIControlStateNormal];
    }
    else {
        [self.seedButton setImage:[UIImage imageNamed:@"brogue_seed.png"] forState:UIControlStateNormal];
    }
}

- (IBAction)showLeaderBoardButtonPressed:(id)sender {
    [self rgGCshowLeaderBoardWithCategory:kBrogueHighScoreLeaderBoard];
}

- (IBAction)aboutButtonPressed:(id)sender {
    self.modalPresentationStyle = UIModalPresentationFormSheet;
    AboutViewController *aboutVC = [[AboutViewController alloc] init];
    aboutVC.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:aboutVC animated:YES completion:nil];
}

#pragma mark - setters/getters

- (void)setBlockMagView:(BOOL)blockMagView {
    _blockMagView = blockMagView;
    
    if (blockMagView) {
        [self.secondaryDisplay removeMagnifyingGlass];
    }
}

@end
