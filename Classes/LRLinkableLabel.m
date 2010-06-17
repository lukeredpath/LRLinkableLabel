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

- (void)createButtonForLinkComponent:(LRURLString *)URLStringComponent currentPoint:(CGPoint)currentPoint availableWidth:(CGFloat)width constraint:(CGSize)constraint;
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
    font = [[UIFont systemFontOfSize:[UIFont labelFontSize]] retain];
    links = [[NSMutableArray alloc] init];
    linkColor = [[UIColor redColor] retain];
    textColor = [[UIColor blackColor] retain];
    linkButtons = [[NSMutableArray alloc] init];
    self.backgroundColor = [UIColor whiteColor];
    self.comparison = NO;
    self.contentMode = UIViewContentModeRedraw;
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
        
        [self createButtonForLinkComponent:(LRURLString *)component
               currentPoint:currentPoint 
             availableWidth:availableLineWidth 
                 constraint:constraint];
        
        [self.linkColor set];
        [self drawComponent:[(LRURLString *)component string] 
               currentPoint:&currentPoint 
             availableWidth:&availableLineWidth 
                 constraint:constraint 
             separatorWidth:0];
                
      } else {
        // remove the last space of the component as it will be added artificially
        NSString *componentWithoutLastSpace = [component substringToIndex:component.length-1];
        
        [self.textColor set];
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
    
    for (UIButton *button in linkButtons) {
      [self addSubview:button];
    }
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

- (void)createButtonForLinkComponent:(LRURLString *)URLStringComponent currentPoint:(CGPoint)currentPoint availableWidth:(CGFloat)availableWidth constraint:(CGSize)constraint
{
  CGSize componentSize = [URLStringComponent.string sizeWithFont:self.font forWidth:constraint.width lineBreakMode:UILineBreakModeClip];
  
  if (componentSize.width > availableWidth) { // move to next line
    currentPoint = CGPointMake(0, currentPoint.y + componentSize.height);
    availableWidth = constraint.width;
  }
  
  CGRect buttonRect = CGRectZero;
  buttonRect.origin = currentPoint;
  buttonRect.size = componentSize;
  
  UIButton *stringButton = [UIButton buttonWithType:UIButtonTypeCustom];
  stringButton.frame = buttonRect;
  stringButton.tag = [links indexOfObject:URLStringComponent];
  stringButton.backgroundColor = [UIColor clearColor];
  stringButton.opaque = NO;
  
  [stringButton addTarget:self action:@selector(handleLinkButtonTap:) forControlEvents:UIControlEventTouchUpInside];
  [linkButtons addObject:stringButton];
  
  CGFloat totalComponentWidth = componentSize.width;
  currentPoint = CGPointMake(currentPoint.x + totalComponentWidth, currentPoint.y);
  availableWidth -= totalComponentWidth;   
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
