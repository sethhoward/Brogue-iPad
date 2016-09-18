//
//  ViewController.m
//  iBrogue_iPad
//
//  Created by Seth Howard on 2/22/13.
//  Copyright (c) 2013 Seth howard. All rights reserved.
//

#import "ViewController.h"
#import "RogueDriver.h"
#import "Viewport.h"
#import "GameCenterManager.h"
#import "UIViewController+UIViewController_GCLeaderBoardView.h"
#import "UIViewController+UIViewController_GCAchievementView.h"
#import "AboutViewController.h"
#import "GameSettings.h"
#import "DirectionControlsViewController.h"
#import <KVOController/FBKVOController.h>
#import "IncludeGlobals.h"

static NSString *kESC_Key = @"\033";

#define kEnterKey @"\015"
#define kBackSpaceKey @"\177"

#define kStationaryTime 0.1f
//#define kGamePlayHitArea CGRectMake(209., 74., 810., 650.)     // seems to be a method in the c code that does this but didn't work as expected
//#define kGameSideBarArea CGRectMake(0., 0., 210., 768.)
#define BROGUE_VERSION	4	// A special version number that's incremented only when
// something about the OS X high scores file structure changes.

Viewport *theMainDisplay;
ViewController *viewController;

NSDictionary* keyCommands;

@interface ViewController () <UITextFieldDelegate, UIGestureRecognizerDelegate, RPPreviewViewControllerDelegate, RPScreenRecorderDelegate>
@property (weak, nonatomic) IBOutlet UIView *titleButtonView;
// @property (weak, nonatomic) IBOutlet UIView *directionalButtonSubContainer;
@property (weak, nonatomic) IBOutlet UIButton *seedButton;
@property (weak, nonatomic) IBOutlet Viewport *secondaryDisplay;   // game etc
@property (weak, nonatomic) IBOutlet UIButton *escButton;
@property (nonatomic, strong) NSMutableArray *cachedTouches; // collection of iBTouches
// @property (weak, nonatomic) IBOutlet UIView *playerControlView;
@property (weak, nonatomic) IBOutlet UITextField *aTextField;
@property (nonatomic, strong) NSMutableArray *cachedKeyStrokes;
@property (weak, nonatomic) IBOutlet UIButton *showInventoryButton;

@property (nonatomic, assign) BOOL blockMagView;    // block the magnifying glass from appearing

// gestures
// @property (nonatomic, strong) UIPinchGestureRecognizer *directionalPinch;
@property (nonatomic, assign) CGPoint lastTouchLocation;
@property (nonatomic, strong) NSTimer  *stationaryTouchTimer;

@property (nonatomic, assign, getter = isSideBarSingleTap) BOOL sideBarSingleTap;       // handles special touch cases when user touches the side bar
@property (nonatomic, assign, getter = ishandlingDoubleTap) BOOL ishandlingDoubleTap;      // handles special double tap touch case
@property (nonatomic, assign) BrogueGameEvent lastBrogueGameEvent;
@property (nonatomic, assign) BOOL ignoreSideBarInteraction; // we could check if the last event was something like BrogueGameEventOpenedInventory but too fragile

// Cache the count. The game loop nails the array count method slowing things down
@property (nonatomic, assign) NSUInteger cachedKeyCount;
@property (nonatomic, assign) NSUInteger cachedTouchCount;

// Directional Controls
@property (nonatomic, strong) DirectionControlsViewController *directionControlsViewController;
@property (nonatomic, strong) FBKVOController *kvoDirectionControlButton;



@end

@implementation ViewController {
@private
    NSMutableArray *_commands;
    NSDictionary *_keyCommandsTranslator;
}
@dynamic hasEvent;
@dynamic hasTouchEvent;
@synthesize hasKeyEvent;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [GameCenterManager sharedInstance];
    [[GameCenterManager sharedInstance] authenticateLocalUser];
    
    [self loadDirectionControlsViewController];
    [self.directionControlsViewController.view setHidden:YES];
    
    [self createDirectionControlListener];
    
    [self addNotificationObservers];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [RogueDriver sharedInstance];
        
        if (!theMainDisplay) {
            theMainDisplay = self.secondaryDisplay;
            viewController = self;
            _cachedTouches = [NSMutableArray arrayWithCapacity:1];
            _cachedKeyStrokes = [NSMutableArray arrayWithCapacity:1];
        }
        
        // bump up the default stack size for a background thread. Anything less than the magic number below
        // risks blowing up the stack. A good test is seed #15
        NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(playBrogue) object:nil];
        [thread setStackSize:350 * 8192];
        [thread start];
    });
}

- (void)createDirectionControlListener {
    self.kvoDirectionControlButton = [FBKVOController controllerWithObserver:self];
    
    __weak typeof(self) weakSelf = self;
    [self.kvoDirectionControlButton observe:self.directionControlsViewController keyPath:@"directionalButton" options:NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary *change) {
        UIButton *directionalButton = change[@"new"];
        
        if ([directionalButton isEqual:[NSNull null]]) {
            return;
        }
        
        enum ControlDirection controlDirection = directionalButton.tag;
        
        switch (controlDirection) {
            case ControlDirectionUp:
                [weakSelf addKeyStroke:kUP_Key];
                break;
            case ControlDirectionRight:
                [weakSelf addKeyStroke:kRIGHT_key];
                break;
            case ControlDirectionDown:
                [weakSelf addKeyStroke:kDOWN_key];
                break;
            case ControlDirectionLeft:
                [weakSelf addKeyStroke:kLEFT_key];
                break;
            case ControlDirectionUpLeft:
                [weakSelf addKeyStroke:kUPLEFT_key];
                break;
            case ControlDirectionUpRight:
                [weakSelf addKeyStroke:kUPRight_key];
                break;
            case ControlDirectionDownRight:
                [weakSelf addKeyStroke:kDOWNRIGHT_key];
                break;
            case ControlDirectionDownLeft:
                [weakSelf addKeyStroke:kDOWNLEFT_key];
                break;
            default:
                break;
        }
    }];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)loadDirectionControlsViewController {
    self.directionControlsViewController = [[DirectionControlsViewController alloc] init];

    // temp until we rewrite with autolayout in mind
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        CGRect viewFrame = self.view.frame;
        CGRect directionalFrame = self.directionControlsViewController.view.frame;
        CGPoint point = CGPointMake(104, viewFrame.size.height - directionalFrame.size.height/2 - 10);
        self.directionControlsViewController.view.center = point;
    }
    else {
        CGRect frame = self.directionControlsViewController.view.frame;
        self.directionControlsViewController.view.frame = frame;
        self.directionControlsViewController.view.center = CGPointMake(20., 140.);
    }
    
    [self.view addSubview:self.directionControlsViewController.view];
    [self addChildViewController:self.directionControlsViewController];
}

- (void)addNotificationObservers {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didShowKeyboard) name:UIKeyboardDidShowNotification object:nil];
    [center addObserver:self selector:@selector(didHideKeyboard) name:UIKeyboardWillHideNotification object:nil];
    [center addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
     [self hideKeyboard];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5. * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!KEYBOARD_LABELS) {
            return;
        }
        
        BOOL hasShownKeyBoardWarning = [[NSUserDefaults standardUserDefaults] boolForKey:@"Has Shown Keyboard Warning"];
        
        if (!hasShownKeyBoardWarning) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Has Shown Keyboard Warning"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Keyboard Detected" message:@"There's a bluetooth keyboard detected. The in game keyboard will not be displayed. Turn off blue tooth if you do not plan on using an external keyboard." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    });
}

- (void)applicationDidBecomeActive {
    [self.secondaryDisplay removeMagnifyingGlass];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)awakeFromNib
{
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

- (void)playBrogue {
    rogueMain();
}

#pragma mark - Shake Motion

// Used for escape
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event{
    if (![[GameSettings sharedInstance] allowShake]) {
        return;
    }
    
    @synchronized(self.cachedKeyStrokes) {
        [self.cachedKeyStrokes removeAllObjects];
        [self.cachedKeyStrokes addObject:kESC_Key];
        self.cachedKeyCount = [self.cachedKeyStrokes count];
    }
}

#pragma mark - touches

// TODO: touches are manually cached here instead of going through a central point
// we save the last touch point so the second tap doesn't stray to far from the first tap. Otherwise the user's expectations of where they want to go and where they go might not match up
- (void)handleDoubleTap:(UITapGestureRecognizer *)tap {
    [self stopStationaryTouchTimer];
    [self.secondaryDisplay removeMagnifyingGlass];
    
    // I'm only going to say this once. Mess with cachedTouches or keys and you best synch them or prepare to crash when you least expect it (most likely during a touch)
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
        
        self.cachedTouchCount = [self.cachedTouches count];
    }
}

static iBTouch _lastTouch;

- (void)addUITouchToCache:(UITouch *)touch {
    @synchronized(self.cachedTouches){
       // if(_lastTouch) {
            if(_lastTouch.phase == touch.phase && CGPointEqualToPoint(_lastTouch.location, [touch locationInView:theMainDisplay])) {
                return;
            }
      //  }
        
        iBTouch ibtouch;
        ibtouch.phase = touch.phase;
        
        // we need to make sure that a phase end touch ends in the same spot as the previous touch or a borks the char movement
        if (touch.phase == UITouchPhaseEnded) {
            ibtouch.location = _lastTouchLocation;
        }
        else {
          ibtouch.location = [touch locationInView:theMainDisplay];  
        }
        
        _lastTouchLocation = ibtouch.location;
        [self.cachedTouches addObject:[NSValue value:&ibtouch withObjCType:@encode(iBTouch)]];
        self.cachedTouchCount = [self.cachedTouches count];
        _lastTouch = ibtouch;
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
            self.cachedTouchCount = [self.cachedTouches count];
        }
    }
}

- (NSUInteger)cachedTouchesCount {
    return _cachedTouchCount;
}

- (void)handleStationary:(NSTimer *)timer {
    if (self.secondaryDisplay.hidden == NO && !self.blockMagView) {
        NSValue *v = timer.userInfo;
        CGPoint point = [v CGPointValue];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.secondaryDisplay addMagnifyingGlassAtPoint:point];
        });
    }
    
    [self stopStationaryTouchTimer];
}

- (void)escapeTouchKeyEvent {
    @synchronized(self.cachedKeyStrokes){
        [self.cachedKeyStrokes removeAllObjects];
        [self.cachedKeyStrokes addObject:kESC_Key];
        self.cachedKeyCount = [self.cachedKeyStrokes count];
    }
    
    @synchronized(self.cachedTouches) {
        [self.cachedTouches removeAllObjects];
        self.cachedTouchCount = [self.cachedTouches count];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
     self.sideBarSingleTap = NO;

    [touches enumerateObjectsUsingBlock:^(UITouch *touch, BOOL *stop) {
        CGPoint touchPoint = [touch locationInView:theMainDisplay];
        
        if (touch.tapCount == 2) {
            // if we're in the game we just want to send our custom double tap and return
            if ([self isPointInGamePlayArea:touchPoint]) {
                //This will cancel the singleTap action
                [self handleDoubleTap:nil];
                return ;
            }
            else {
                // we're outside the play area. (most likely the side bar). This handles that side bar case where do don't actually send a touch up until the user has double tapped
                @synchronized(self.cachedTouches) {
                    iBTouch touchUp;
                    touchUp.phase = UITouchPhaseEnded;
#warning _lastTouchLocation is set in [self addTouchToCach:]. Not what I'd call intuitive and potentially deal breaking if changes were made
                    touchUp.location = _lastTouchLocation;
                    
                    [self.cachedTouches addObject:[NSValue value:&touchUp withObjCType:@encode(iBTouch)]];
                    
                    // setting flag to handle some special logic on touchesEnded
                    _ishandlingDoubleTap = YES;
                    self.cachedTouchCount = [self.cachedTouches count];
                }
            }
        }
        // no tap just a touch
        else {
            // if we touch in the side bar we want to block the touches up and so we set a bool here to do just that. This forces the user to double tap anything in the side bar that they actually want to run to and allows a single tap to bring up the selection information.
            // when a user touches the screen we need to 'nudge' the movement so brogue event handles can update (highlight, show popup, etc) where we touched
            if (CGRectContainsPoint(self.secondaryDisplay.sideBarArea, touchPoint) && _lastBrogueGameEvent != BrogueGameEventShowHighScores && !_ignoreSideBarInteraction) {

                @synchronized(self.cachedTouches) {
                    iBTouch touchMoved;
                    touchMoved.phase = UITouchPhaseMoved;
                    touchMoved.location = touchPoint;
                    [self.cachedTouches addObject:[NSValue value:&touchMoved withObjCType:@encode(iBTouch)]];
                    self.cachedTouchCount = [self.cachedTouches count];
                }
                
                self.sideBarSingleTap = YES;
            }
            
            // Get a single touch and it's location
            [self addUITouchToCache:touch];
            [self startStationaryTouchTimerWithTouch:touch andTimeout:kStationaryTime];
        }
    }];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [touches enumerateObjectsUsingBlock:^(UITouch *touch, BOOL *stop) {
        // Get a single touch and it's location
        [self addUITouchToCache:touch];
        [self startStationaryTouchTimerWithTouch:touch andTimeout:kStationaryTime];
    }];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self stopStationaryTouchTimer];
    
    // under certain conditions we don't actually want to pass through a 'mouse up'
    if ((!self.ishandlingDoubleTap && !self.isSideBarSingleTap) || self.lastBrogueGameEvent == BrogueGameEventOpenedInventory) {
        [touches enumerateObjectsUsingBlock:^(UITouch *touch, BOOL *stop) {
            // Get a single touch and it's location
            [self addUITouchToCache:touch];
        }];
    }

    _ishandlingDoubleTap = NO;
}

- (BOOL)hasEvent {
    return [self cachedKeyStrokeCount] + [self cachedTouchesCount];
}

- (BOOL)hasKeyEvent {
    return [self cachedKeyStrokeCount];
}

- (BOOL)hasTouchEvent {
    return [self cachedTouchesCount];
}

#pragma mark - Magnifier

- (void)stopStationaryTouchTimer {
    [_stationaryTouchTimer invalidate];
    _stationaryTouchTimer = nil;
}

- (void)startStationaryTouchTimerWithTouch:(UITouch *)touch andTimeout:(NSTimeInterval)timeOut {
    if ([[GameSettings sharedInstance] allowMagnifier] && touch.type != UITouchTypeStylus) {
        [self stopStationaryTouchTimer];
        
        if ([self isPointInGamePlayArea:[touch locationInView:self.secondaryDisplay]]) {
            _stationaryTouchTimer = [NSTimer scheduledTimerWithTimeInterval:timeOut target:self selector:@selector(handleStationary:) userInfo:[NSValue valueWithCGPoint:[touch locationInView:self.secondaryDisplay]] repeats:NO];
        }
        else {
            // kill the mag if it's showing
            [self.secondaryDisplay removeMagnifyingGlass];
        }
    }
}

#pragma mark - views

- (BOOL)isPointInGamePlayArea:(CGPoint)point {
    //CGRect boundaryRect = kGamePlayHitArea;
    CGRect boundaryRect = self.secondaryDisplay.gameArea;
    //#define kGamePlayHitArea CGRectMake(209., 74., 810., 650.) 
    
    if (!CGRectContainsPoint(boundaryRect, point)) {
        // NSLog(@"out of bounds");
        return NO;
    }
    
    return YES;
}

- (void)showTitle {
    dispatch_async(dispatch_get_main_queue(), ^{
        double delayInSeconds = 0.5;
        [self.directionControlsViewController.view setHidden:YES];
     
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                if (_lastBrogueGameEvent == BrogueGameEventShowTitle || _lastBrogueGameEvent == BrogueGameEventOpenGameFinished) {
                    [self.titleButtonView setHidden:NO];
                }
            });
    });
}

- (void)hideTitleButtons {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.titleButtonView setHidden:YES];
    });
}

- (void)showAuxillaryScreensWithDirectionalControls:(BOOL)controls {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.titleButtonView setHidden:YES];
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self.directionControlsViewController.view setHidden:!controls];
        });
    });
}

#pragma mark - keyboard stuff

// when showing the keyboard we need to set the field to 'recording' so we can catch backspace events (soley for saving a replay or game)
- (void)showKeyboard {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.aTextField.text = @"Recording";
        [self.aTextField becomeFirstResponder];
    });
}

- (NSUInteger)cachedKeyStrokeCount {
    return _cachedKeyCount;
}

- (char)dequeKeyStroke {
    NSString *keyStroke = [self.cachedKeyStrokes objectAtIndex:0];
    @synchronized(self.cachedKeyStrokes){
        [self.cachedKeyStrokes removeObjectAtIndex:0];
        _cachedKeyCount = [self.cachedKeyStrokes count];
    }
    
    return [keyStroke characterAtIndex:0];
}

#pragma mark - UITextFieldDelegate

// when using the hide keyboard button on the UIKit keyboard we treat it like an escape
- (void)didHideKeyboard {
    if ([self.cachedKeyStrokes count] == 0) {
        [self.cachedKeyStrokes addObject:kESC_Key];
        self.cachedKeyCount = [self.cachedKeyStrokes count];
    }

    self.escButton.hidden = YES;
}

- (void)didShowKeyboard {
    self.escButton.hidden = NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.cachedKeyStrokes addObject:kEnterKey];
    self.cachedKeyCount = [self.cachedKeyStrokes count];
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    const char *_char = [string cStringUsingEncoding:NSUTF8StringEncoding];
    NSInteger isBackSpace = strcmp(_char, "\b");
    
    if (isBackSpace == -8) {
        // is backspace
        [self.cachedKeyStrokes addObject:kBackSpaceKey];
        self.cachedKeyCount = [self.cachedKeyStrokes count];
    }
    else if([string isEqualToString:@"\n"]) {
        [textField resignFirstResponder];
        // enter
        [self.cachedKeyStrokes addObject:kEnterKey];
        self.cachedKeyCount = [self.cachedKeyStrokes count];
    }
    else {
        // misc
        [self.cachedKeyStrokes addObject:string];
        self.cachedKeyCount = [self.cachedKeyStrokes count];
    }
    
    return YES;
}
- (void)addKeyStroke:(NSString *)key {
    [self.cachedKeyStrokes addObject:key];
    self.cachedKeyCount = [self.cachedKeyStrokes count];
}

- (IBAction)escButtonPressed:(id)sender {
    [self addKeyStroke:kESC_Key];
    [self.aTextField resignFirstResponder];
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

- (IBAction)showInventoryButtonPressed:(id)sender {
    @synchronized(self.cachedKeyStrokes){
        [self.cachedKeyStrokes removeAllObjects];
        [self.cachedKeyStrokes addObject:@"i"];
        self.cachedKeyCount = [self.cachedKeyStrokes count];
    }
}

#pragma mark - setters/getters

- (void)setBlockMagView:(BOOL)blockMagView {
    _blockMagView = blockMagView;
    
    if (blockMagView) {
        [self.secondaryDisplay removeMagnifyingGlass];
    }
}

- (void)showInventoryOnDeathButton:(BOOL)show {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.showInventoryButton.hidden = !show;
    });
}

// it's possible to lose focus of the hidden text field. This ensures we dismiss the keyboard
- (void)hideKeyboard {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.aTextField becomeFirstResponder];
        [self.aTextField resignFirstResponder];
    });
}

// my original intention was to not touch any game code. In the end this was not possible in order to give the best user experience. I funnel all modification and events in the core code through here.
- (void)setBrogueGameEvent:(BrogueGameEvent)brogueGameEvent {
    _lastBrogueGameEvent = brogueGameEvent;
    
    switch (brogueGameEvent) {
        case BrogueGameEventWaitingForConfirmation:
        case BrogueGameEventActionMenuOpen:
        case BrogueGameEventOpenedInventory:
            _ignoreSideBarInteraction = YES;
            self.blockMagView = YES;
            
            if (!self.directionControlsViewController.areDirectionalControlsHidden) {
                [self.directionControlsViewController hideWithAnimation:YES];
            }
            break;
        // pretty much every inventory option
        case BrogueGameEventInventoryItemAction:
        case BrogueGameEventConfirmationComplete:
        case BrogueGameEventActionMenuClose:
        case BrogueGameEventClosedInventory:
            _ignoreSideBarInteraction = NO;
            self.blockMagView = NO;
            if (!self.directionControlsViewController.areDirectionalControlsHidden) {
                [self.directionControlsViewController showWithAnimation:YES];
            }
            break;
        case BrogueGameEventKeyBoardInputRequired:
            [self showKeyboard];
            break;
        case BrogueGameEventShowTitle:
        case BrogueGameEventOpenGameFinished:
            [self showInventoryOnDeathButton:NO];
            [self showTitle];
            [self hideKeyboard];
            [self.directionControlsViewController hideWithAnimation:YES];
            self.blockMagView = YES;
            break;
        case BrogueGameEventStartNewGame:
        case BrogueGameEventOpenGame:
            [self.directionControlsViewController showWithAnimation:YES];
            [self showAuxillaryScreensWithDirectionalControls:YES];
            @synchronized(self.cachedTouches) {
                [self.cachedTouches removeAllObjects];
                self.cachedTouchCount = [self.cachedTouches count];
            }
            self.blockMagView = NO;
            break;
        case BrogueGameEventBeginOpenGame:
            [self hideTitleButtons];
            break;
        case BrogueGameEventPlayRecording:
        case BrogueGameEventShowHighScores:
        case BrogueGameEventPlayBackPanic:
            [self showAuxillaryScreensWithDirectionalControls:NO];
            self.blockMagView = YES;
            [self.directionControlsViewController hideWithAnimation:YES];
            break;
        case BrogueGameEventMessagePlayerHasDied:
            [self showInventoryOnDeathButton:YES];
            break;
        case BrogueGameEventPlayerHasDiedMessageAcknowledged:
            [self showInventoryOnDeathButton:NO];
            break;
        default:
            break;
    }
}

- (void)viewDidUnload {
    [self setATextField:nil];
    [self setEscButton:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight;
}

#pragma mark - Keyboard

- (NSArray *)keyCommands {
    if(!_commands) {
        _keyCommandsTranslator = @{UIKeyInputUpArrow: kUP_Key,
                                   UIKeyInputDownArrow: kDOWN_key,
                                   UIKeyInputLeftArrow: kLEFT_key,
                                   UIKeyInputRightArrow: kRIGHT_key,
                                   UIKeyInputEscape: @"\033"};
        
        NSArray *keys = [[NSArray alloc] initWithObjects:
                         @">", @"<", @" ", @"\\",
                         @"]", @"?", @"~",  @"&",
                         @"\r", @"\t", @".",
                         nil];
        
        _commands = [[NSMutableArray alloc] init];
        
        for(char i = 'a'; i <= 'z'; i++) {
            NSString *key = [NSString stringWithFormat:@"%c", i];
            [_commands addObject:[UIKeyCommand keyCommandWithInput:key modifierFlags:0 action:@selector(executeKeyCommand:)]];
            [_commands addObject:[UIKeyCommand keyCommandWithInput:key modifierFlags:UIKeyModifierShift action:@selector(executeKeyCommand:)]];
        }
        
        for(id key in keys) {
            [_commands addObject:[UIKeyCommand keyCommandWithInput:key modifierFlags:0 action:@selector(executeKeyCommand:)]];
        }
        
        for(NSString *key in _keyCommandsTranslator) {
            [_commands addObject:[UIKeyCommand keyCommandWithInput:key modifierFlags:0 action:@selector(executeKeyCommand:)]];
        }
    }
    return _commands;
}

- (void)executeKeyCommand:(UIKeyCommand *)keyCommand {
    NSString *key;
    if(keyCommand.modifierFlags == UIKeyModifierShift) {
        if([keyCommand.input length] == 1
           && [keyCommand.input characterAtIndex:0] >= 'a'
           && [keyCommand.input characterAtIndex:0] <= 'z') {
            key = [keyCommand.input uppercaseString];
        }
    } else {
        key = [_keyCommandsTranslator objectForKey:keyCommand.input];
        if(key == nil) {
            key = keyCommand.input;
        }
    }
    
    if(key) {
        [self addKeyStroke:key];
    }
}

// UIKeyboardWillShowNotification
- (void)keyboardWillShow:(NSNotification *)notification {
    KEYBOARD_LABELS = 0;
}

@end
