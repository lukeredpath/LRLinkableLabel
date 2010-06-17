//
//  LinkableLabelViewController.h
//  LinkableLabel
//
//  Created by Luke Redpath on 17/06/2010.
//  Copyright LJR Software Limited 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LinkableLabelViewController : UITableViewController <UIActionSheetDelegate> {
  NSURL *tappedURL;
}
@property (nonatomic, retain) NSURL *tappedURL;
@end

