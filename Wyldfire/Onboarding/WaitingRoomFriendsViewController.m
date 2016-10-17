//
//  WaitingRoomFriendsViewController.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 3/17/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "WaitingRoomFriendsViewController.h"

@implementation WaitingRoomFriendsViewController

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BOOL)isMale
{
    return [WFCore get].accountStructure.isMale;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.table.backgroundColor = GRAY_1;
    self.toolbarTitle.text = [self isMale] ? @"Request Feather" : @"Send Feather";
    self.toolbar.backgroundColor = GRAY_1;
    self.tableSearch.backgroundColor = GRAY_1;
    self.tableSearch.leftView.backgroundColor = GRAY_1;
    
    self.toolbarTitle.textColor = WYLD_RED;
    self.tableSearch.textColor = [UIColor whiteColor];
    
    UIColor *color = [UIColor whiteColor];
    self.tableSearch.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Search name or enter number" attributes:@{NSForegroundColorAttributeName: color}];
    self.tableSearch.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.tableSearch.autocorrectionType = UITextAutocorrectionTypeNo;
    
    // self.table.sectionIndexBackgroundColor = [UIColor clearColor];
    // self.table.sectionIndexColor = [UIColor lightGrayColor];
}

- (void)updateToolbarTitle
{
    //Noop
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        UIView* hideLine = [[UIView alloc] initWithFrame:cell.bounds];
        hideLine.backgroundColor = GRAY_1;
        [cell addSubview:hideLine];
        
        NSString* text = [self isMale] ? @"Women screen which men can join Wyldfire.\nAsk one of your female friends for a feather!" :
                        @"Women screen which men can join Wyldfire.\nPlease invite at least one quality guy to the network.";
        
        UILabel* label = [UILabel labelInRect:CGRectInset(cell.bounds,8,0)
                                     withText:text
                                        color:[UIColor whiteColor] fontSize:15];
        label.backgroundColor = GRAY_1;
        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentLeft;
        [cell addSubview:label];
    } else if (indexPath.row == 1) {
        cell.backgroundColor = nil;
    } else if (indexPath.row > 1) {
        [(UIImageView*)cell.accessoryView setImage:(cell.selected ? [UIImage imageNamed:@"red_check"] : nil)];
        UILabel *label = (UILabel*)[cell viewWithTag:900];
        label.textColor = [UIColor whiteColor];
    }
}

@end
