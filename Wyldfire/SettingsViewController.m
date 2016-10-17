//
//  Profile.m
//  Wyldfire
//
//  Created by Vlad Seryakov on 9/24/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//
#import "SideBarProfileView.h"
#import "UIView+positioning.h"

@interface SettingsViewController ()
    @property (nonatomic, strong) SideBarProfileView* profileView;
    @property (nonatomic) BOOL pushing;

@property (nonatomic, strong) UIImageView* downArrow;
@end

@implementation SettingsViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.view.multipleTouchEnabled = NO;
    [self subscribeToNotifications];

    [self loadItems];
    self.tableUnselected = YES;
    self.view.backgroundColor = GRAY_1;
  
    [self setupProfileView];
    [self setupTable];
}

- (void)loadItems
{
    self.items = [@[ @{ @"name": @"Browse",
                        @"icon": @"browse_h",
                        @"separator": @"top" },
                     @{ @"name": @"Trending",
                        @"icon": @"Trending_h",
                        @"view": @"Top10",
                        @"separator": @"top" },
                     @{ @"name": @"Profile",
                        @"icon": @"Profile_h",
                        @"view": @"Profile",
                        @"separator": @"top" },
                     @{ @"name": @"Notebook",
                        @"icon": @"notebook_h",
                        @"view": @"BlackBook",
                        @"separator": @"top",
                        @"count": [NSString stringWithFormat:@"%i", (int)[GVUserDefaults standardUserDefaults].unseenContacts.count]},
                     @{ @"name": @"Events",
                        @"icon": @"event_pink_h",
                        @"view": @"Events",
                        @"separator": @"top" },
                     @{ @"name": @"Settings",
                        @"icon": @"Settings_h",
                        @"view": @"AppSettings",
                        @"separator": @"both" }
                     ] mutableCopy];
    if ([self isFemale]) {
        [self.items insertObject:@{ @"name": @"Feathers",
                                    @"icon": @"feather_h",
                                    @"view": @"InviteFacebookFriends",
                                    @"separator": @"top"} atIndex:2];
    }
}

- (BOOL)isFemale
{
    return ![WFCore get].accountStructure.isMale;
}

- (void)setupProfileView
{
    SideBarProfileView* profileView = [[SideBarProfileView alloc] initWithFrame:CGRectMake(0, 0,
                                                                                           CGRectGetWidth(self.view.frame),
                                                                                           SIDEBAR_PROFILE_VIEW_HEIGHT)];
    
    [self.view addSubview:profileView];
    self.profileView = profileView;
    self.profileImage = profileView.profileImage;
    self.profileName = profileView.profileName;
    
    self.profileName.text = [WFCore get].accountStructure.name;
    
    [profileView.profileImage addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onProfile:)]];
    profileView.profileImage.userInteractionEnabled = YES;
}

- (void)setupTable
{
    float totalHeight = CGRectGetHeight(self.view.frame);
    float totalWidth = CGRectGetWidth(self.view.frame);
    
    self.table = [[UITableView alloc] initWithFrame:CGRectMake(0,
                                                               SIDEBAR_PROFILE_VIEW_HEIGHT,
                                                               totalWidth - DRAWER_WIDTH,
                                                               totalHeight - SIDEBAR_PROFILE_VIEW_HEIGHT)];
    self.table.backgroundColor = GRAY_1;
    self.table.separatorInset = UIEdgeInsetsZero;
    self.table.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.table.delegate = (id<UITableViewDelegate>)self;
    self.table.dataSource = (id<UITableViewDataSource>)self;
    
    [self addDownArrow];
    
    //self.table.scrollEnabled = NO;
    self.table.allowsSelection = YES;
    self.table.rowHeight = SIDEBAR_TABLE_CELL_HEIGHT;
    [self.view addSubview:self.table];
}

- (void)addDownArrow
{
    if ([WFCore get].accountStructure.isMale || (TALL_SCREEN)) return;
    
    UIImageView* imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"downArrow"]];
    imgView.center = CGPointMake((self.table.width - imgView.width) / 2 + 20, self.table.height - imgView.height / 2 + 5);
    [self.table addSubview:imgView];
    [self.table bringSubviewToFront:imgView];
    self.downArrow = imgView;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionTransitionCrossDissolve
                     animations:^{
                         self.downArrow.alpha = 0.0;
                     } completion:^(BOOL finished) {
                         //
                     }];
}

- (void)onProfile:(id)sender
{
    [WFCore showViewController:self name:@"Profile" mode:@"push" params:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self statsChanged];
    [[APIClient sharedClient] getStats:nil];
    [self loadItems];
    [self.table reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.profileView animate];
    self.pushing = NO;
}

- (void)onTableSelect:(NSIndexPath *)indexPath selected:(BOOL)selected
{
    NSLog(@"select %ld %d", (long)indexPath.row, selected);
    UITableViewCell *cell = [self.table cellForRowAtIndexPath:indexPath];
    UILabel *label = (UILabel*)[cell viewWithTag:100];
    label.textColor = selected ? WYLD_RED : [UIColor whiteColor];
    if (!selected) return;
    NSDictionary *item = [self getItem:indexPath];
    
    
    if (!self.pushing ) {
        self.pushing = YES;
        if ([item[@"name"] isEqualToString:@"Browse"]) {
            [self showPrevious];
        }
       
        if (item[@"view"]) {
            [WFCore showViewController:self name:item[@"view"] mode:@"push" params:nil];
        }
    }
}

- (void)onTableCell:(UITableViewCell*)cell indexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if (!item[@"name"]) return;
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    UIImageView *image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:item[@"icon"]]];
    image.center = CGPointMake(self.table.rowHeight/2, self.table.rowHeight/2);
    image.contentMode = UIViewContentModeCenter;
    [cell addSubview:image];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(self.table.rowHeight + self.tableIndent, 0, cell.frame.size.width - 100, cell.frame.size.height)];
    label.textColor = [UIColor whiteColor];
    label.text = item[@"name"];
    label.tag = 100;
    label.font = [UIFont fontWithName:BOLD_FONT size:SIDEBAR_PROFILE_NAME_FONTSIZE];
    [cell addSubview:label];

    if (item[@"count"] && ([item[@"count"] intValue] > 0)) {
        UIImageView *badge = [WFCore imageWithBadge:CGRectMake(0, 0, 0, 0) icon:@"red_circle" color:[UIColor blackColor] value:[item[@"count"] intValue]];
        badge.center = CGPointMake(cell.frame.size.width - 30, self.table.rowHeight/2+1);
        [cell addSubview:badge];
    }
    if ([WFCore matchString:@"top|both" string:item[@"separator"]]) {
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cell.frame.size.width, 1)];
        line.backgroundColor = SIDEBAR_SEPARATOR_COLOR;
        [cell addSubview:line];
    }
    if ([WFCore matchString:@"bottom|both" string:item[@"separator"]]) {
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, cell.frame.size.height-1, cell.frame.size.width, 1)];
        line.backgroundColor = SIDEBAR_SEPARATOR_COLOR;
        [cell addSubview:line];
    }
}

#pragma mark Notifications

- (void)subscribeToNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statsChanged) name:NOTIFICATION_UPDATED_STATS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged) name:NOTIFICATION_UPDATED_SETTINGS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged) name:NOTIFICATION_UPDATED_LOCATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resize:) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
}

- (void)resize:(NSNotification*)notification
{
    [self settingsChanged];
    //Added by Yurii on 11/06/14
    [UIView animateWithDuration:0.2 delay:0.0 options:0
                      animations:^{
                          CGRect statusBarFrame = [((NSValue*)notification.userInfo[UIApplicationStatusBarFrameUserInfoKey]) CGRectValue];
                          if (statusBarFrame.size.height > 20)
                              self.downArrow.center = CGPointMake((self.table.width - self.downArrow.width) / 2 + 20, self.table.height - self.downArrow.height / 2 + 5);
                          else
                              self.downArrow.center = CGPointMake((self.table.width - self.downArrow.width) / 2 + 20, self.table.height - self.downArrow.height / 2 - 15);
                          } completion:nil];
}

- (void)statsChanged
{
    self.profileView.profileLikes.text = [NSString stringWithFormat:@"Likes: %i", (int)[WFCore get].accountStructure.stats.likesReceived];
}

- (void)settingsChanged
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //New screen capture
        UIImage *image = [WFCore captureImage:((UIViewController*)self.navigationController.viewControllers[0]).view];
        
        self.drawerView.y = 0;
        // Sliding button with the screenshot
        [self.drawerView setImage:image forState:UIControlStateNormal];
        [self.drawerView setImage:image forState:UIControlStateHighlighted];
    });
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
