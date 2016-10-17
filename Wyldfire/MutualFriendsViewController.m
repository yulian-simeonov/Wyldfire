//
//  MutualFriendsViewController.m
//  Wyldfire
//
//  Created by Vlad Seryakov on 12/8/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

@implementation MutualFriendsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self addTable];
    [self addToolbar:@"Mutual Friends"];
    self.items = self.params[@"mutual_friends"];
    self.tableRows = 3;
}

- (void) onInvite:(id)sender
{
    NSLog(@"%@", [self.table indexPathsForSelectedRows]);
}

- (void) onCheckAll:(id)sender
{
    NSArray *selected = [self.table indexPathsForSelectedRows];
    for (int i = 0; i < self.items.count; i++) {
        const NSUInteger idx[2] = { 0, i + 3 };
        NSIndexPath *path = [NSIndexPath indexPathWithIndexes:idx length:2];
        [self onTableSelect:path selected:selected.count ? NO : YES];
        if (selected.count == 0) {
            [self.table selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionNone];
        } else {
            [self.table deselectRowAtIndexPath:path animated:NO];
        }
    }
}

- (void)onTableSelect:(NSIndexPath *)indexPath selected:(BOOL)selected
{
    [self.view endEditing:YES];
    if (indexPath.row < 3) return;
    UITableViewCell *cell = [self.table cellForRowAtIndexPath:indexPath];
    [(UIImageView*)cell.accessoryView setImage:[UIImage imageNamed:selected ? @"black_check" : @"gray_circle"]];
}

- (void)onTableCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    switch (indexPath.row) {
        case 0: {
            UITextField *search = [[UITextField alloc] initWithFrame:CGRectInset(cell.frame, 5, 5)];
            [WFCore setTextBorder:search color:[UIColor lightGrayColor]];
            search.placeholder = @"Search contacts w/ email";
            search.textAlignment = NSTextAlignmentCenter;
            [cell addSubview:search];
            break;
        }
        case 1: {
            UILabel *label = [[UILabel alloc] initWithFrame:cell.frame];
            label.textAlignment = NSTextAlignmentCenter;
            label.textColor = [UIColor grayColor];
            label.text = [NSString stringWithFormat:@"%lu Mutual Friends", (unsigned long)self.items.count];
            [cell addSubview:label];
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            [button setTitle:@"invite" forState:UIControlStateNormal];
            [button sizeToFit];
            [button addTarget:self action:@selector(onInvite:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = button;
            break;
        }
        case 2: {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            [button setTitle:@"check all" forState:UIControlStateNormal];
            [button sizeToFit];
            [button addTarget:self action:@selector(onCheckAll:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = button;
            break;
        }
        default: {
            NSDictionary *item = [self getItem:indexPath];
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gray_circle"]];
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(50, 0, cell.frame.size.width - 100, cell.frame.size.height)];
            label.textColor = [UIColor grayColor];
            label.text = item[@"alias"];
            [cell addSubview:label];
            
            UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(6, 4, 36, 36)];
            imgView.contentMode = UIViewContentModeScaleAspectFill;
            imgView.layer.cornerRadius = 18;
            imgView.layer.masksToBounds = YES;
            [cell addSubview:imgView];
            
            [[APIClient sharedClient] downloadImage:item[@"icon0"]
                success:^(UIImage *image, NSString *url) {
                    imgView.image = image;
                } failure:^(NSInteger code) {
                    
                }];
        }
    }
}

@end
