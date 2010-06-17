//
//  LRLinkableLabel.h
//  LinkableLabel
//
//  Created by Luke Redpath on 17/06/2010.
//  Copyright 2010 LJR Software Limited. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LRLinkableLabel : UIView {
  NSString *text;
  UIFont *font;
  UIColor *linkColor;
  UIColor *textColor;
  NSMutableArray *links;
  NSMutableArray *linkButtons;
  BOOL comparison;
  id delegate;
}
@property (nonatomic, copy) NSString *text;
@property (nonatomic, retain) UIFont *font;
@property (nonatomic, retain) UIColor *linkColor;
@property (nonatomic, retain) UIColor *textColor;
@property (nonatomic, assign) BOOL comparison;
@property (nonatomic, assign) id delegate;
@end

@interface NSObject (LRLinkableLabelDelegate)
- (void)linkableLabel:(LRLinkableLabel *)label clickedButton:(UIButton *)button forURL:(NSURL *)url;
@end
