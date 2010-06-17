//
//  LinkableLabelViewController.m
//  LinkableLabel
//
//  Created by Luke Redpath on 17/06/2010.
//  Copyright LJR Software Limited 2010. All rights reserved.
//

#import "LinkableLabelViewController.h"
#import "LRLinkableLabel.h"

@implementation LinkableLabelViewController

@synthesize tappedURL;

- (void)viewDidLoad;
{
  self.tableView.rowHeight = 180;
}

- (void)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  return YES;
}

#pragma mark -
#pragma mark UITableView methods

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
  return 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewStylePlain reuseIdentifier:CellIdentifier] autorelease];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    CGFloat labelPadding = 15.0;
    LRLinkableLabel *label = [[LRLinkableLabel alloc] initWithFrame:CGRectInset(cell.contentView.bounds, labelPadding, labelPadding)];
    label.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
    label.tag = 1;
    label.delegate = self;
    
    [cell.contentView addSubview:label];
    [label release];
  }
  LRLinkableLabel *label = (LRLinkableLabel *)[cell.contentView viewWithTag:1];
  label.text = @"This is a test string with a link http://www.example.com and lots of other text that isn't a link and its qiute long too. How about some lipsum? Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam facilisis, neque eu dapibus pharetra, http://google.com, a pharetra lacus lacus in sapien. Morbi auctor venenatis sapien non pharetra. Cras id nisi ipsum.";
  
  label.comparison = (indexPath.row == 0);
  
  return cell;
}

- (void)linkableLabel:(LRLinkableLabel *)label clickedButton:(UIButton *)button forURL:(NSURL *)url
{
  self.tappedURL = url;
  
  UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Open link", @"Open link in Safari", nil];
  [actionSheet showFromRect:button.bounds inView:button animated:YES];
  [actionSheet release];
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet
{
  self.tappedURL = nil;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
  switch (buttonIndex) {
    case 1:
      [[UIApplication sharedApplication] openURL:self.tappedURL];
      break;
    default:
      break;
  }
  self.tappedURL = nil;
}

@end
