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

@interface ViewController () <UITextFieldDelegate>
- (IBAction)escButtonPressed:(id)sender;
- (IBAction)upButtonPressed:(id)sender;
- (IBAction)downButtonPressed:(id)sender;
- (IBAction)rightButtonPressed:(id)sender;
- (IBAction)leftButtonPressed:(id)sender;
- (IBAction)upLeftButtonPressed:(id)sender;
- (IBAction)upRightButtonPressed:(id)sender;
- (IBAction)downLeftButtonPressed:(id)sender;
- (IBAction)downRightButtonPressed:(id)sender;


@property (weak, nonatomic) IBOutlet UIButton *escButton;
@property (nonatomic, strong) NSMutableArray *cachedTouches; // collection of iBTouches
@property (weak, nonatomic) IBOutlet UIView *playerControlView;
@property (weak, nonatomic) IBOutlet UITextField *aTextField;
@property (nonatomic, strong) NSMutableArray *cachedKeyStrokes;
@end

@implementation ViewController {
    @private
    NSTimer __strong *_autoSaveTimer;
}

- (void)autoSave {
    [RogueDriver autoSave];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    if (!theMainDisplay) {
        theMainDisplay = self.theDisplay;
        viewController = self;
        _cachedTouches = [NSMutableArray arrayWithCapacity:1];
        _cachedKeyStrokes = [NSMutableArray arrayWithCapacity:1];
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(didShowKeyboard) name:UIKeyboardDidShowNotification object:nil];
        [center addObserver:self selector:@selector(didHideKeyboard) name:UIKeyboardWillHideNotification object:nil];
        
        //TODO: consider this... may not be the time for this yet
      //  _autoSaveTimer = [NSTimer scheduledTimerWithTimeInterval:20. target:self selector:@selector(autoSave) userInfo:nil repeats:YES];
    }
    
    [self playBrogue];
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

- (void)addTouchToCache:(UITouch *)touch {
    iBTouch ibtouch;
    ibtouch.location = [touch locationInView:theMainDisplay];
    ibtouch.phase = touch.phase;
    [self.cachedTouches addObject:[NSValue value:&ibtouch withObjCType:@encode(iBTouch)]];
}

- (iBTouch)getTouchAtIndex:(uint)index {
    NSValue *anObj = [self.cachedTouches objectAtIndex:index];
    iBTouch touch;
    [anObj getValue:&touch];
    
    return touch;
}

- (void)removeTouchAtIndex:(uint)index {
    [self.cachedTouches removeObjectAtIndex:index];
}

- (uint)cachedTouchesCount {
    return [self.cachedTouches count];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  //  NSLog(@"%s", __PRETTY_FUNCTION__);
    [touches enumerateObjectsUsingBlock:^(UITouch *touch, BOOL *stop) {
        // Get a single touch and it's location
        [self addTouchToCache:touch];
    }];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
   // NSLog(@"%s", __PRETTY_FUNCTION__);
    [touches enumerateObjectsUsingBlock:^(UITouch *touch, BOOL *stop) {
        // Get a single touch and it's location
        [self addTouchToCache:touch];
    }];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  //  NSLog(@"%s", __PRETTY_FUNCTION__);
    [touches enumerateObjectsUsingBlock:^(UITouch *touch, BOOL *stop) {
        // Get a single touch and it's location
        [self addTouchToCache:touch];
    }];
}

#pragma mark - views

- (void)hideControls {
    if (self.playerControlView.hidden == NO) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.playerControlView.hidden = YES;
        });
    }
}

- (void)showControls {
    if (self.playerControlView.hidden == YES) {
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            self.playerControlView.hidden = NO;
        });
    }
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
    [super viewDidUnload];
}

- (uint)cachedKeyStrokeCount {
    return [self.cachedKeyStrokes count];
}

- (char)dequeKeyStroke {
    NSString *keyStroke = [self.cachedKeyStrokes objectAtIndex:0];
    [self.cachedKeyStrokes removeObjectAtIndex:0];
    
    return [keyStroke characterAtIndex:0];
}

#pragma mark - UITextFieldDelegate

- (void)didHideKeyboard {
    [self.cachedKeyStrokes addObject:@"\015"];
    self.escButton.hidden = YES;
}

- (void)didShowKeyboard {
    self.escButton.hidden = NO;
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
        [self.cachedKeyStrokes addObject:string];
    }
    else {
        // misc
        [self.cachedKeyStrokes addObject:string];
    }
    
    return YES;
}

- (IBAction)buttonTouchDown:(id)sender {
    // store which button it is... certain combinations will allow for diag movement
}

- (IBAction)escButtonPressed:(id)sender {
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

@end
