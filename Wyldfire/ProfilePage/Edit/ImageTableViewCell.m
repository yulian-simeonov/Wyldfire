//
//  ImageTableViewCell.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 3/22/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "ImageTableViewCell.h"

@interface ImageTableViewCell ()
@property (nonatomic, strong) UIImageView* accountImageView;
@end

@implementation ImageTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self addImageView];
        [self addTitleLabel];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    //[super setSelected:selected animated:animated];
}

- (CGFloat)itemHeight
{
    return EDIT_PROFILE_IMAGECELL_HEIGHT;
}

- (CGFloat)pad
{
    return 9.0f;
}

- (void)addImageView
{
    CGFloat pad = [self pad];
    CGFloat sideLength = self.itemHeight - pad * 2;
    
    CGRect rect = CGRectMake(20, pad, sideLength, sideLength);
    
    UIImageView* imgView = [[UIImageView alloc] initWithFrame:rect];
    imgView.contentMode = UIViewContentModeScaleAspectFill;
    imgView.clipsToBounds = YES;
    [self addSubview:imgView];
    self.accountImageView = imgView;
}

- (void)addTitleLabel
{
    CGFloat pad = [self pad];
    CGRect rect = CGRectMake(EDIT_PROFILE_TEXT_INSET,
                             pad,
                             self.width - self.accountImageView.right - pad * 2,
                             self.itemHeight - pad * 2);
    
    UILabel* label = [UILabel labelInRect:rect
                                 withText:@""
                                    color:[UIColor blackColor]
                                 fontSize:21];
    label.font = FONT_BOLD(15);
    label.textAlignment = NSTextAlignmentLeft;
    [self addSubview:label];
    self.titleLabel = label;
}

- (void)setImage:(UIImage*)image{
    _image = image;
    if (image == nil) {
        self.titleLabel.text = @"Add Profile Picture";
    }
    
    self.accountImageView.image = image;
}

- (void)setIsAvatar:(BOOL)isAvatar
{
    _isAvatar = isAvatar;
    
    if (isAvatar) {
        self.accountImageView.layer.cornerRadius = self.accountImageView.size.width / 2;
    }
}

@end
