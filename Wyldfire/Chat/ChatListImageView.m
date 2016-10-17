//
//  ChatListImageView.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/20/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//


#import "ChatListImageView.h"

@interface ChatListImageView ()
    @property (nonatomic, strong) UIImageView* imageView;
@end

@implementation ChatListImageView

#pragma mark Init

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupImageView];
        [self setupLabel];
        [self style];
    }
    return self;
}

- (void)style
{
    self.layer.borderWidth = 1.0f;
    self.backgroundColor = [UIColor blackColor];

    [self setColorsForCurrentNumber];
}

- (void)setColorsForCurrentNumber
{
    UIColor* color = (self.number > 9 ? WYLD_BLUE : WYLD_RED);
    
    self.layer.borderColor = color.CGColor;
    [self.numberLabel setTextColor:color];
}

- (void)setupLabel
{
    CGRect rect = CGRectInset(self.bounds, 0, CHAT_LIST_IMAGE_TEXT_INSET);
    
    self.numberLabel = [self labelInRect:rect withText:@"" color:WYLD_BLUE fontSize:CHAT_LIST_IMAGE_FONTSIZE];
}

- (UILabel*)labelInRect:(CGRect)frame withText:(NSString*)text color:(UIColor*)color fontSize:(float)fontSize
{
    UILabel* label = [[UILabel alloc] initWithFrame:frame];
    
    label.text = text;
    label.textColor = color;
    label.font = [UIFont fontWithName:LIGHT_FONT size:fontSize];
    label.textAlignment = NSTextAlignmentCenter;
    label.alpha = 1.0;
    [self addSubview:label];
    
    return label;
}

- (void)setupImageView
{
    self.imageView = [self imageView];
}

- (UIImageView*)imageView
{
    CGRect rect = CGRectInset(self.bounds, 1, 1);
    
    UIImageView* imgView = [[UIImageView alloc] initWithFrame:rect];
    imgView.contentMode = UIViewContentModeScaleAspectFill;
    imgView.clipsToBounds = YES;
    imgView.alpha = 0.46;
    [self addSubview:imgView];
    
    return imgView;
}

#pragma mark Data Input

- (void)setNumber:(int)number
{
    _number = number;
    
    [self.numberLabel setText:[NSString stringWithFormat:@"%i", number]];
    [self setColorsForCurrentNumber];
}

- (void)setImage:(UIImage *)image
{
    _image = image;

    self.imageView.image = image;
}

#pragma mark Class Methods

+ (id)imageViewWithFrame:(CGRect)rect number:(int)number image:(UIImage*)image
{
    ChatListImageView* chatImageView = [[ChatListImageView alloc] initWithFrame:rect];
    
    chatImageView.number = number;
    chatImageView.image = image;
    
    return chatImageView;
}

@end
