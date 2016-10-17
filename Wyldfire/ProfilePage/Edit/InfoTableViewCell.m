//
//  InfoTableViewCell.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 3/22/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "InfoTableViewCell.h"

@interface InfoTableViewCell () <UITextFieldDelegate>

@end

@implementation InfoTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self addImageView];
        [self addTextField];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    //[super setSelected:selected animated:animated];
}

- (CGFloat)itemHeight
{
    return EDIT_PROFILE_INFOCELL_HEIGHT;
}

- (CGFloat)pad
{
    return 6.0f;
}

- (void)addImageView
{
    CGFloat pad = [self pad];
    CGFloat sideLength = self.itemHeight - pad * 2;
    
    CGRect rect = CGRectMake(0, pad, sideLength, sideLength);
    
    UIImageView* imgView = [[UIImageView alloc] initWithFrame:rect];
    imgView.center = CGPointMake(EDIT_PROFILE_TEXT_INSET / 2, imgView.centerY);
    imgView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:imgView];
    self.infoImageView = imgView;
}

- (void)addTextField
{
    CGFloat pad = [self pad];
    CGRect rect = CGRectMake(EDIT_PROFILE_TEXT_INSET, 0, self.width - self.infoImageView.right - pad * 2, self.itemHeight);
    
    UITextField* textField = [[UITextField alloc] initWithFrame:rect];
    textField.delegate = self;
    textField.textAlignment = NSTextAlignmentLeft;
    textField.font = FONT_BOLD(15);
    textField.returnKeyType = UIReturnKeyDone;
    
    [self addSubview:textField];
    self.textField = textField;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if ([self.defaultsKey isEqualToString:@"phoneNumber"]) {
        NSString* totalString = [NSString stringWithFormat:@"%@%@",textField.text,string];
        if (range.length == 1) {
            // Delete button was hit.. so tell the method to delete the last char.
            textField.text = [textField.text formatPhoneNumber:totalString deleteLastChar:YES];
        } else {
            textField.text = [textField.text formatPhoneNumber:totalString deleteLastChar:NO ];
        }
        return NO;
    }
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    NSString* key = self.defaultsKey;
    NSString* value = textField.text;
    
    if ([self.defaultsKey isEqualToString:@"phoneNumber"]) {
        value = [value filteredDigitsOfPhoneNumber];
        ECPhoneNumberFormatter *formatter = [[ECPhoneNumberFormatter alloc] init];
        value = [formatter stringForObjectValue:value];
        textField.text = value;
        key = @"phone";
    }
    
    [[GVUserDefaults standardUserDefaults] setValue:value forKey:self.defaultsKey];
    [[APIClient sharedClient] updateAccountField:key value:value notify:NO success:nil failure:nil];
}

@end
