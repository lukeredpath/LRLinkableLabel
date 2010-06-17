//
//  LinkableLabelAppDelegate.h
//  LinkableLabel
//
//  Created by Luke Redpath on 17/06/2010.
//  Copyright LJR Software Limited 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LinkableLabelViewController;

@interface LinkableLabelAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    LinkableLabelViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet LinkableLabelViewController *viewController;

@end

