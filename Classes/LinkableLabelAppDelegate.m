//
//  LinkableLabelAppDelegate.m
//  LinkableLabel
//
//  Created by Luke Redpath on 17/06/2010.
//  Copyright LJR Software Limited 2010. All rights reserved.
//

#import "LinkableLabelAppDelegate.h"
#import "LinkableLabelViewController.h"

@implementation LinkableLabelAppDelegate

@synthesize window;
@synthesize viewController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // Override point for customization after app launch    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];

	return YES;
}


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
