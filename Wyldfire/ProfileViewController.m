//
//  ProfileViewController.m
//  Wyldfire
//
//  Created by Vlad Seryakov on 10/21/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

#import "LikeRatioGraph.h"
#import "ProfileViewsGraphView.h"

@interface ProfileViewController ()
@property (nonatomic, strong) BrowseCardView* card;
@property (nonatomic, strong) LikeRatioGraph* likeGraph;
@property (nonatomic, strong) ProfileViewsGraphView* viewsGraph;

@property (nonatomic, strong) IBOutlet InfoPaneView *info;
@property (nonatomic, strong) IBOutlet UIView *charts2;
@property (nonatomic, strong) IBOutlet BarChart *barChart;
@property (nonatomic, strong) IBOutlet CircleChart *circleChart;

@property (nonatomic, strong) UIImageView* downArrow;
@end

@implementation ProfileViewController {
    BOOL _editMode;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self addToolbar:@"Profile"];
    
    [self.toolbar addSubview:self.toolbarNext];
    [self.toolbarNext setTitle:@"Edit" forState:UIControlStateNormal];
    
    _editMode = NO;
    self.tableRows = 4;

    [self.table setContentInset:UIEdgeInsetsMake(8, 0, 8, 0)];
    self.table.backgroundColor = [UIColor clearColor];
    
    self.table.frame = CGRectMake(8, 64, 320 - 16, self.view.bounds.size.height - 64);
    
    CGRect frame = self.table.frame;
    
    //Card
    BrowseCardView* card = [BrowseCardView cardForAccount:[WFCore account] inBrowse:NO inTrending:NO inMatches:NO inProfile:YES];
    card.myCard = YES;
    [card cropButtons];
    
    self.card = card;
    self.info = card.info;
    
    CGRect likeRect = CGRectMake(0, 0,
                                 CARD_WIDTH,
                                 CIRCLE_GRAPH_DIAMETER + CIRCLE_GRAPH_PAD * 2);
    LikeRatioGraph* likeGraph = [[LikeRatioGraph alloc] initWithFrame:likeRect];
    
    UILabel* titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, frame.size.width, 44)];
    titleLbl.textAlignment = NSTextAlignmentCenter;
    titleLbl.text = @"Statistics";
    titleLbl.font = [UIFont fontWithName:MAIN_FONT size:14];
    titleLbl.textColor = [UIColor blackColor];
    [likeGraph addSubview:titleLbl];
    
    self.likeGraph = likeGraph;

    
    CGRect viewsRect = CGRectMake(0, 0,
                                  CARD_WIDTH,
                                  PROFILE_VIEWS_GRAPH_TOTALHEIGHT);
    ProfileViewsGraphView* viewsGraph = [[ProfileViewsGraphView alloc] initWithFrame:viewsRect];
    self.viewsGraph = viewsGraph;
    
    self.charts2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, MATCH_SECTION_HEIGHT)];
    self.charts2.backgroundColor = [UIColor whiteColor];
    self.charts2.clipsToBounds = YES;
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, frame.size.width, 44)];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"Matches by Day";
    label.font = [UIFont fontWithName:MAIN_FONT size:14];
    label.textColor = [UIColor blackColor];
    [self.charts2 addSubview:label];
    
    self.barChart = [[BarChart alloc] initWithFrame:CGRectMake(0, 80, frame.size.width, self.charts2.frame.size.height- 80 - 40)];
	self.barChart.backgroundColor = [UIColor clearColor];
    self.barChart.axisColor = [UIColor grayColor];
    self.barChart.barColor = WYLD_BLUE;
    self.barChart.clipsToBounds = NO;
	[self.charts2 addSubview:self.barChart];
    
    [self reloadTable];
    [self restoreTablePosition];
    
    self.view.backgroundColor = GRAY_8;
    
    UIImageView* imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"downArrow"]];
    imgView.center = CGPointMake(self.view.width / 2, self.view.height - imgView.height / 2);
    [self.view addSubview:imgView];
    self.downArrow = imgView;
    
    NSIndexPath* path = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.table scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self statsUpdated];
    [[APIClient sharedClient] getStats:nil];
    
    if (![GVUserDefaults standardUserDefaults].firstViewProfile) {
        [GVUserDefaults standardUserDefaults].firstViewProfile = TRUE;
        [WFCore showAlert:@"Your Profile" text:@"Edit photos, update your contact info, and view stats to see what’s working...and what isn’t." delegate:nil cancelButtonText:@"OK" otherButtonTitles:nil tag:TRENDING_ALERT];
    }
}

- (void)onNext:(id)sender
{
    [WFCore showViewController:self name:@"EditProfile" mode:@"push" params:nil];
    if (![GVUserDefaults standardUserDefaults].firstEditProfile) {
        [GVUserDefaults standardUserDefaults].firstEditProfile = TRUE;
        [WFCore showAlert:@"User Information" text:@"Users can share info with each other in chat. Set your phone number and email in your profile." delegate:nil cancelButtonText:@"OK" otherButtonTitles:nil tag:EDIT_PROFILE_ALERT];
    }
}

#pragma mark - TableView

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionTransitionCrossDissolve
                     animations:^{
                         self.downArrow.alpha = 0.0;
                     } completion:^(BOOL finished) {
                         //
                     }];
}

- (void)onTableCell:(UITableViewCell*)cell indexPath:(NSIndexPath*)indexPath
{
    cell.backgroundColor = [UIColor clearColor];
    cell.clipsToBounds = YES;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    switch (indexPath.row) {
        case 0:
            [cell addSubview:self.card];
            break;
        case 1:
            [cell addSubview:self.likeGraph];
            [self.likeGraph animate];
            break;
        case 2:
            [cell addSubview:self.viewsGraph];
            [self.viewsGraph animate];
            break;
        case 3:
            [cell addSubview:self.charts2];
            [self.barChart drawChart];
            
            UIButton* button = [[UIButton alloc] initWithFrame:self.barChart.bounds];
            [button addTarget:self action:@selector(clickedMatches) forControlEvents:UIControlEventTouchUpInside];
            [self.barChart addSubview:button];
            
            break;
    }
}

- (void)clickedMatches
{
    if (![GVUserDefaults standardUserDefaults].firstProfileMatchesByDay) {
        [GVUserDefaults standardUserDefaults].firstProfileMatchesByDay = TRUE;
        [WFCore showAlert:@"Matches by Day" text:@"We track your daily matches. The red bar indicates your last profile edit." delegate:nil cancelButtonText:@"OK" otherButtonTitles:nil tag:CLICKED_MATCHES_PROFILE_ALERT];
    }
}

#pragma mark - TableView

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
            return self.card.frame.size.height;
        case 1:
            return self.likeGraph.frame.size.height;
        case 2:
            return self.viewsGraph.frame.size.height;
        default:
            return self.charts2.frame.size.height;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
    
    [self onTableCell:cell indexPath:indexPath];
    
    return cell;
}

#pragma mark Reload Data

- (void)subscribeToNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(statsUpdated) name:NOTIFICATION_UPDATED_STATS object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)statsUpdated
{
    Account* account = [WFCore get].accountStructure;
    
    int likesPerformed = (int)account.stats.likesPerformed;
    int likesReceived = (int)account.stats.likesReceived;
    
	[self.barChart setXLabels:account.stats.daysMatched];
    [self.barChart setYValues:account.stats.matches];
    
    //Change color for days with an image change
    for (int i = 0; i < account.stats.daysChangedImage.count; i++) {
        if ([account.stats.daysChangedImage[i] boolValue]) {
            self.barChart.colors = @{ [NSNumber numberWithInt:i]: WYLD_RED };
        }
    }
    
    [self.viewsGraph setViewCounts:account.stats.viewCounts withDayTitles:account.stats.daysViewed];
    
    [self.likeGraph setNumLikes:likesPerformed andTimesBeenLiked:likesReceived];
    
//    self.circleChart.current = nliked ? MIN(100, nlikes/nliked*100) : 0;
//    self.circleChart.completionHandler = ^(UIView *view) {
//        GlowAnimation *glow = [[GlowAnimation alloc] init:nil stop:nil];
//        [glow configure:view];
//    };
//    
    self.info.name.text = [NSString stringWithFormat:@"%@, %d", account.name, account.age];
    self.info.info1.text = [NSString stringWithFormat:@"Radius: %i Mi", [GVUserDefaults standardUserDefaults].settingSearchRadius];
    self.info.info2.text = [NSString stringWithFormat:@"Likes: %i", likesReceived];
}

@end
