//
//  LinkedAccountsViewController.m
//  Wyldfire
//
//  Created by Vlad Seryakov on 11/21/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

@implementation LinkedAccountsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self addTable];
    [self addToolbar:@"Linked Accounts"];
    self.items = [@[ /*@"Facebook",*/ @"Instagram"/*, @"Twitter"*/] mutableCopy];
    self.table.scrollEnabled = NO;
    self.table.backgroundColor = GRAY_8;
    self.table.contentInset = UIEdgeInsetsMake(68 / 2, 0, 0, 0);
}

- (void)onSwitch:(id)sender
{
    UISwitch *button = sender;
    NSString *name = objc_getAssociatedObject(sender, @"name");
    NSLog(@"account: %@: %@", name, self.core.account[[NSString stringWithFormat:@"%@_id", [name lowercaseString]]]);
    
    if ([name isEqualToString:@"Instagram"]) {
        if (button.on) {
            [self.core.instagram getAccount:^(NSDictionary *result) {
                [self.core.instagram saveAccount];
                [[APIClient sharedClient] updateAccount:@{ @"instagram_id": [WFCore toString:result name:@"id"],
                                                           @"instagram_username": [WFCore toString:result name:@"username"] }
                                                 notify:NO success:nil failure:nil];
            } failure:^(NSInteger code) {
                [self.core.instagram logout];
                [self.core.instagram saveAccount];
                [button setOn:NO animated:YES];
            }];
        } else {
            [self.core.instagram logout];
            [self.core.instagram saveAccount];
            
        }
    }
    if ([name isEqualToString:@"Twitter"]) {
        if (button.on) {
            [self.core.twitter getAccount:^(NSDictionary *result) {
                [self.core.twitter saveAccount];
            } failure:^(NSInteger code) {
                [self.core.twitter logout];
                [self.core.twitter saveAccount];
            }];
        } else {
            [self.core.twitter logout];
        }
    }
}

- (void)onTableCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor whiteColor];
    
    NSString *name = [self getItem:indexPath];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, cell.frame.size.width - 100, cell.frame.size.height)];
    label.textColor = [UIColor blackColor];
    label.text = name;
    label.font = [UIFont fontWithName:MAIN_FONT size:17];
    [cell addSubview:label];
    
    UISwitch *button = [[UISwitch alloc] init];
    button.onTintColor = WYLD_RED;
    objc_setAssociatedObject(button, @"name", name, OBJC_ASSOCIATION_COPY);
    button.on = [self.core[[NSString stringWithFormat:@"%@_id", [name lowercaseString]]] isEqualToString:@""] ? NO : YES;
    [button addTarget:self action:@selector(onSwitch:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = button;
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
}

@end
