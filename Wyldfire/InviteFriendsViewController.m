//
//  InviteFriendsViewController.m
//  Wyldfire
//
//  Created by Vlad Seryakov on 11/21/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

@implementation InviteFriendsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableCentered = NO;
    
    [self addTable];
    [self addToolbar:@"Invite Friends"];
    self.items = [@[ @{ @"name": @"Facebook",
                        @"icon": @"facebook",
                        @"view": @"InviteFacebookFriends" },
                     @{ @"name": @"Email contacts",
                        @"icon": @"phone",
                        @"view": @"InviteContactFriends" }] mutableCopy];
    self.table.scrollEnabled = NO;
    self.tableUnselected = YES;
    
}

- (void)onTableSelect:(NSIndexPath *)indexPath selected:(BOOL)selected
{
    if (!selected) return;
    NSDictionary *item = [self getItem:indexPath];
    if (item[@"view"]) [WFCore showViewController:self name:item[@"view"] mode:@"push" params:nil];
}

- (void)onTableCell:(UITableViewCell*)cell indexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    
    UIImageView *image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:item[@"icon"]]];
    image.center = CGPointMake(self.table.rowHeight/2, self.table.rowHeight/2);
    image.contentMode = UIViewContentModeCenter;
    [cell addSubview:image];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(self.table.rowHeight + self.tableIndent, 0, cell.frame.size.width - 100, cell.frame.size.height)];
    label.textColor = [UIColor grayColor];
    label.text = item[@"name"];
    [cell addSubview:label];
}

@end
