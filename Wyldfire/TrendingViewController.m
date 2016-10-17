//
//  TrendingViewController.m
//  Wyldfire
//
//  Created by Vlad Seryakov on 11/16/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

#import "UIActionSheet+util.h"
#import "BrowseCardView.h"

@interface TrendingViewController ()
@property (nonatomic) BOOL searchMales;
@property (nonatomic, strong) NSMutableDictionary* cards;
@end

@implementation TrendingViewController {
    UIImage *_bottom;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableCentered = YES;
    [self addTable];
    self.table.contentInset = UIEdgeInsetsMake(8, 0, 8, 0);
    self.table.backgroundColor = [UIColor clearColor];
    self.table.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.toolbarNextIcon = @"trendingDots";
    [self addToolbar:@"Trending"];
    [self.toolbar addSubview:self.toolbarNext];
    
    _searchMales = [GVUserDefaults standardUserDefaults].settingInterestedInMen;
    _cards = [NSMutableDictionary new];
    [self subscribeToNotifications];
    
    self.view.backgroundColor = GRAY_8;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    

    NSString* genderString = [WFCore get].accountStructure.isMale ? @"f" : @"m";
    
    [self reloadData:genderString];
    
    if (![GVUserDefaults standardUserDefaults].firstViewTrending) {
        [GVUserDefaults standardUserDefaults].firstViewTrending = TRUE;
        [WFCore showAlert:@"Trending" text:@"Trending features popular users in your area. Set your Trending radius in Settings." delegate:nil cancelButtonText:@"OK" otherButtonTitles:nil tag:TRENDING_ALERT];
    }
}

- (void)reloadData:(NSString*)genderString
{
    [self.cards removeAllObjects];
    
    [[APIClient sharedClient] getTrendingForGenderString:genderString success:^(NSArray *accounts) {
            self.itemsAll = self.items = [accounts mutableCopy];
            [self hideActivity:YES];
            [self reloadTable];
            if (accounts.count == 0) {
                [WFCore showAlert:@"No profiles found in your area.  Please check your Settings to make sure you aren’t being too picky!" msg:nil delegate:nil confirmHandler:nil];
            }
        } failure:^{
            [WFCore showAlert:@"No profiles found in your area.  Please check your Settings to make sure you aren’t being too picky!" msg:nil delegate:nil confirmHandler:nil];
            [self hideActivity:YES];
        }];
}

#pragma mark - Pressed Options

- (void)onNext:(id)sender
{
    UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"View Women", @"View Men", @"View Men and Women", nil];
    action.tag = ACTIONSHEET_DECISIONS;
    action.tintColor = WYLD_RED;
    action.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [action showInView:self.view];
    [action styleWithTintColor:WYLD_RED];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == ACTIONSHEET_DECISIONS) {
        NSString* genderString = nil;
        if (buttonIndex == 0) {
            genderString = @"f";
        } else if (buttonIndex == 1) {
            genderString = @"m";
        } else if (buttonIndex == 2) {
            genderString = @"m,f";
        }
        
        if (genderString) {
            [self reloadData:genderString];
        }
    }
}

- (void)onTableCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    int tag = (int)indexPath.row + 1;
    
    if (![cell viewWithTag:tag]) {
        NSString* key = [@(indexPath.row) stringValue];
        
        BrowseCardView* card = self.cards[key];
        if (!card)
        {
            Account* account = [self getItem:indexPath];
            card = [BrowseCardView cardForAccount:account inBrowse:NO inTrending:YES inMatches:NO];
            card.tag = tag;
            self.cards[key] = card;
        }
        
        card.clipsToBounds = YES;
        [cell addSubview:card];
    }
}

- (void)getInfo:(NSDictionary*)item label:(UILabel*)label
{
    NSArray *friends = [WFCore toArray:item name:@"mutual_friends"];
    NSString *name = [NSString stringWithFormat:@"%@, %d", item[@"alias"], (int)[WFCore toNumber:item[@"age"]]];
    label.text = [NSString stringWithFormat:@"%@\nmutual friends: %lu", name, (unsigned long)friends.count];
    [WFCore setLabelAttributes:label color:[UIColor darkGrayColor] font:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]] range:[label.text rangeOfString:name]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CARD_HEIGHT - LIKE_BUTTON_HEIGHT + TRENDING_CELL_PADDING;
}

#pragma mark Notifications

- (void)subscribeToNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resize:) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
}

- (void)resize:(NSNotification*)notification
{
    CGRect frame = CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64);
    self.table.contentInset = UIEdgeInsetsMake(8, 0, 8, 0);
    self.table.frame = frame;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
