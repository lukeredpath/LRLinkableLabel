//
//  LRLinkableLabel.m
//  LinkableLabel
//
//  Created by Luke Redpath on 17/06/2010.
//  Copyright 2010 LJR Software Limited. All rights reserved.
//

#import "LRLinkableLabel.h"

@interface LRURLString : NSObject
{
  NSString *string;
}
@property (nonatomic, readonly) NSURL *URL;
@property (nonatomic, readonly) NSString *string;

- (id)initWithString:(NSString *)aString;
+ (id)URLStringWithString:(NSString *)aString;
@end

@implementation LRURLString

@synthesize string;

- (id)initWithString:(NSString *)aString;
{
  if (self = [super init]) {
    string = [aString copy];
  }
  return self;
}

+ (id)URLStringWithString:(NSString *)aString;
{
  return [[[self alloc] initWithString:aString] autorelease];
}

- (NSURL *)URL;
{
  return [NSURL URLWithString:string];
}

@end

@interface LRLinkableLabelComponentScanner : NSObject
{
  NSString *stringToScan;
}
- (id)initWithString:(NSString *)string;
- (NSArray *)components;
@end

@implementation LRLinkableLabelComponentScanner

- (id)initWithString:(NSString *)string;
{
  if (self = [super init]) {
    stringToScan = [string copy];
  }
  return self;
}

- (void)dealloc;
{
  [stringToScan release];
  [super dealloc];
}

- (NSArray *)components;
{
  NSScanner *scanner = [NSScanner scannerWithString:stringToScan];
  [scanner setCharactersToBeSkipped:nil]; // don't skip whitespace
  
  NSMutableArray *components = [NSMutableArray array];
  
  while (![scanner isAtEnd]) {
    NSString *currentComponent;
    BOOL foundComponent = [scanner scanUpToString:@"http" intoString:&currentComponent];
    if (foundComponent) {
      [components addObject:currentComponent];
      
      NSString *string;
      BOOL foundURLComponent = [scanner scanUpToString:@" " intoString:&string];
      if (foundURLComponent) {
        // if last character of URL is punctuation, its probably not part of the URL
        NSCharacterSet *punctuationSet = [NSCharacterSet punctuationCharacterSet];
        NSInteger lastCharacterIndex = string.length - 1;
        if ([punctuationSet characterIsMember:[string characterAtIndex:lastCharacterIndex]]) {
          // remove the punctuation from the URL string and move the scanner back
          string = [string substringToIndex:lastCharacterIndex];
          [scanner setScanLocation:scanner.scanLocation - 1];
        }        
        LRURLString *URLString = [LRURLString URLStringWithString:string];
        [components addObject:URLString];
      }
    } else { // first string is a link
      NSString *string;
      BOOL foundURLComponent = [scanner scanUpToString:@" " intoString:&string];
      if (foundURLComponent) {
        LRURLString *URLString = [LRURLString URLStringWithString:string];
        [components addObject:URLString];
      }
    }
  }
  return [[components copy] autorelease];
}

@end

@interface LRLinkableLabel ()
- (void)drawComponent:(NSString *)stringComponent currentPoint:(CGPoint *)currentPoint availableWidth:(CGFloat *)availableWidth constraint:(CGSize)constraint separatorWidth:(CGFloat)separatorWidth;

- (void)addButtonForLinkComponent:(LRURLString *)URLStringComponent currentPoint:(CGPoint *)currentPoint availableWidth:(CGFloat *)width constraint:(CGSize)constraint separatorWidth:(CGFloat)separatorWidth;
@end

@implementation LRLinkableLabel

@synthesize text;
@synthesize font;
@synthesize comparison;
@synthesize linkColor;
@synthesize textColor;
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame 
{
  if ((self = [super initWithFrame:frame])) {
    font = [[UIFont systemFontOfSize:22] retain];
    links = [[NSMutableArray alloc] init];
    linkColor = [[UIColor redColor] retain];
    textColor = [[UIColor blackColor] retain];
    linkButtons = [[NSMutableArray alloc] init];
    self.backgroundColor = [UIColor whiteColor];
    self.comparison = NO;
  }
  return self;
}

- (void)dealloc;
{
  [linkColor release];
  [font release];
  [links release];
  [super dealloc];
}

- (void)drawRect:(CGRect)rect 
{
  UILineBreakMode lineBreakMode = UILineBreakModeWordWrap;
  UITextAlignment textAlignment = UITextAlignmentLeft;
  
  [self.textColor set];

  if (self.comparison) {
    [self.text drawInRect:rect withFont:self.font lineBreakMode:lineBreakMode alignment:textAlignment];
    
  } else {
    CGSize constraint = CGSizeMake(rect.size.width, CGFLOAT_MAX);
    NSString *wordSeparator = @" ";
    CGFloat wordSeparatorWidth = [wordSeparator sizeWithFont:self.font].width;

    CGPoint currentPoint = CGPointZero;
    CGFloat availableLineWidth = constraint.width;
    
    LRLinkableLabelComponentScanner *scanner = [[LRLinkableLabelComponentScanner alloc] initWithString:self.text];
    
    for (NSString *component in [scanner components]) {
      if ([component isKindOfClass:[LRURLString class]]) {
        [links addObject:component];
        
        [self addButtonForLinkComponent:(LRURLString *)component 
                 currentPoint:&currentPoint 
               availableWidth:&availableLineWidth 
                   constraint:constraint 
               separatorWidth:0];
                
      } else {
        // remove the last space of the component as it will be added artificially
        NSString *componentWithoutLastSpace = [component substringToIndex:component.length-1];
        for (NSString *word in [componentWithoutLastSpace componentsSeparatedByString:wordSeparator]) {
          [self drawComponent:word 
                 currentPoint:&currentPoint 
               availableWidth:&availableLineWidth 
                   constraint:constraint 
               separatorWidth:wordSeparatorWidth];
        }
      }
    }    
    [scanner release];
    
    // for some reason, if the buttons are added during this runloop, they aren't drawn
    // properly, so add them in the next runloop instead, bit of a hack but it works
    [self performSelector:@selector(insertLinkButtons) withObject:nil afterDelay:0.0];
  }
}

- (void)insertLinkButtons;
{
  for (UIButton *button in linkButtons) {
    [self addSubview:button];
  }
}

#pragma mark -
#pragma mark Drawing methods

- (void)drawComponent:(NSString *)stringComponent currentPoint:(CGPoint *)currentPoint availableWidth:(CGFloat *)availableWidth constraint:(CGSize)constraint separatorWidth:(CGFloat)separatorWidth;
{    
  CGSize componentSize = [stringComponent sizeWithFont:self.font forWidth:constraint.width lineBreakMode:UILineBreakModeClip];
  
  if (componentSize.width > *availableWidth) { // move to next line
    *currentPoint = CGPointMake(0, currentPoint->y + componentSize.height);
    *availableWidth = constraint.width;
  }

  [stringComponent drawAtPoint:*currentPoint withFont:self.font];
  
  CGFloat totalComponentWidth = componentSize.width + separatorWidth;

  *currentPoint = CGPointMake(currentPoint->x + totalComponentWidth, currentPoint->y);
  *availableWidth -= totalComponentWidth;  
}

- (void)addButtonForLinkComponent:(LRURLString *)URLStringComponent currentPoint:(CGPoint *)currentPoint availableWidth:(CGFloat *)availableWidth constraint:(CGSize)constraint separatorWidth:(CGFloat)separatorWidth;
{
  CGSize componentSize = [URLStringComponent.string sizeWithFont:self.font forWidth:constraint.width lineBreakMode:UILineBreakModeClip];
  
  if (componentSize.width > *availableWidth) { // move to next line
    *currentPoint = CGPointMake(0, currentPoint->y + componentSize.height);
    *availableWidth = constraint.width;
  }
  
  CGRect buttonRect = CGRectZero;
  buttonRect.origin = *currentPoint;
  buttonRect.size = componentSize;
  
  UIButton *stringButton = [UIButton buttonWithType:UIButtonTypeCustom];
  stringButton.frame = buttonRect;
  stringButton.titleLabel.font = self.font;
  stringButton.tag = [links indexOfObject:URLStringComponent];
  stringButton.backgroundColor = self.backgroundColor;
  stringButton.opaque = YES;
  
  [stringButton setTitle:URLStringComponent.string forState:UIControlStateNormal];        
  [stringButton setTitleColor:self.linkColor forState:UIControlStateNormal];
  [stringButton addTarget:self action:@selector(handleLinkButtonTap:) forControlEvents:UIControlEventTouchUpInside];
  
  [linkButtons addObject:stringButton];
  
  CGFloat totalComponentWidth = (componentSize.width + separatorWidth);
  *currentPoint = CGPointMake(currentPoint->x + totalComponentWidth, currentPoint->y);
  *availableWidth -= totalComponentWidth;   
}

#pragma mark -

- (void)setText:(NSString *)aString;
{
  [text release];
  text = [aString copy];
  [self setNeedsDisplay];
}

- (void)handleLinkButtonTap:(UIButton *)sender;
{
  LRURLString *tappedLink = [links objectAtIndex:sender.tag];
  [self.delegate linkableLabel:self clickedButton:sender forURL:tappedLink.URL];
}

@end
