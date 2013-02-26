//
//  MainMenu.h
//  iBrogue_iPad
//
//  Created by Seth Howard on 2/25/13.
//  Copyright (c) 2013 Seth howard. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface MainMenu : NSObject
- (void)renderTitle;

@end

static MainMenu __strong *mainMenuInstance;