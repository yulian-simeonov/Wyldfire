//
//  BrowseViewController.m
//  Wyldfire
//
//  Created by Vlad Seryakov on 9/26/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

@interface ImagePicker: NSObject <UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property (strong, nonatomic) ViewController *view;
@property (strong, nonatomic) UIImagePickerController *picker;
- (id)initWithView:(ViewController*)view;
@end;

@interface ViewController ()

@property (nonatomic) BOOL animatedMatches;
@property (nonatomic) BOOL animatedChats;
@property (nonatomic) BOOL animatedSettings;
@property (atomic) int lastLikeCount;

@end

@implementation ViewController {
    int _activityCount;
    CGPoint _center;
    NSMutableArray *_menubarActions;
    NSMutableDictionary *_menubarButtons;
    UIView *_contentView;
    CGRect _drawerFrame;
    BOOL _panStarted;
    ImagePicker *_picker;
    NSTimer *_timer;
}

- (void)configure
{
    self.modalAnimation = @"crossFade";
    if (!self.params) self.params = [@{} mutableCopy];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountUpdated:) name:@"accountUpdated" object:nil];
    
    _activityCount = 0;
    _menubarActions = [@[ @{ @"name": @"Settings", @"mode": @"drawerLeftAnchor", @"icon" : @"buttonSettings"},
                          @{ @"name": @"Match", @"mode": @"push", @"icon" : @"buttonMatches" },
                          @{ @"name": @"Browse", @"icon" : @"buttonWyldfire" },
                          @{ @"name": @"Chat", @"mode": @"push", @"icon" : @"buttonChats" },
                          @{ @"name": @"Share", @"icon" : @"buttonShare" }] mutableCopy];
    
    self.core = [WFCore get];
    self.menubarCurrentDisabled = YES;
    self.tableSections = 1;
    self.tableRows = 0;
    self.tableCell = nil;
    self.tableUnselected = NO;
    self.tableRounded = NO;
    self.tableCentered = NO;
    self.tableIndent = 9;
    self.items = [@[] mutableCopy];
    self.itemsAll = [@[] mutableCopy];
    self.panRect = CGRectZero;
    if (!self.toolbarColor) self.toolbarColor = [UIColor whiteColor];
    if (!self.toolbarTextColor) self.toolbarTextColor = [UIColor blackColor];
    self.view.backgroundColor = [UIColor colorWithRed:234/255.0 green:237/255.0 blue:241/255.0 alpha:1];
    
    self.activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activity.hidden = YES;
    self.activity.hidesWhenStopped = YES;
    self.activity.layer.backgroundColor = [[UIColor colorWithWhite:0.0f alpha:0.1f] CGColor];
    self.activity.frame = CGRectMake(0, 0, 56, 56);
    self.activity.layer.masksToBounds = YES;
    self.activity.layer.cornerRadius = 8;
    [self.view addSubview:self.activity];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationController.navigationBarHidden = YES;
    self.extendedLayoutIncludesOpaqueBars = YES;
    [self setNeedsStatusBarAppearanceUpdate];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMenubar) name:NOTIFICATION_UPDATED_STATS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMenubar) name:NOTIFICATION_NEW_CONTACT object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMenubar) name:NOTIFICATION_UPDATED_PENDING_MATCHES object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMenubar) name:NOTIFICATION_UPDATED_MESSAGES object:nil];
}
                         
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;

    // Replace button fonts manually
    for (UIButton *view in self.view.subviews) {
        if ([view isKindOfClass:[UIButton class]]) {
            view.titleLabel.font = [UIFont systemFontOfSize:view.titleLabel.font.pointSize];
        }
    }
    [self resizeTable];
    // Do not preserve selection
    if (self.table && self.tableUnselected) {
        [self onTableSelect:[self.table indexPathForSelectedRow] selected:NO];
        [self.table deselectRowAtIndexPath:[self.table indexPathForSelectedRow] animated:NO];
    }
    self.activity.center = self.view.center;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.activity.center = self.view.center;
    [self.view bringSubviewToFront:self.activity];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = YES;
    [self saveTablePosition];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
}

- (BOOL)isEmpty:(NSString*)name
{
    return [WFCore isEmpty:self.params name:name];
}

- (void)accountUpdated:(NSNotification*)notification
{
    //if (self.profileImage) self.profileImage.image = [self.core image:0];
    //if (self.profileName) self.profileName.text = [NSString stringWithFormat:@"%@, %d", self.core[@"alias"], (int)[self.core num:@"age"]];
    //NSLog(@"accountUpdated: %@: %@", self.core[@"alias"], notification);
}

- (void)addMenubar:(NSString*)current disabled:(NSArray*)disabled
{
    _menubarButtons = [@{} mutableCopy];
    
    self.menubar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
    self.menubar.backgroundColor = [UIColor whiteColor];
    self.menubar.layer.shadowOffset = CGSizeMake(0, -1);
    self.menubar.layer.shadowOpacity = 0.3;
    self.menubar.userInteractionEnabled = YES;
    int i = 0, w = self.view.frame.size.width / _menubarActions.count;
    
    for (NSDictionary *item in _menubarActions) {
        NSString *name = item[@"name"];
        NSString *icon = item[@"icon"];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        if ([current isEqualToString:name]) {
            button.tag = 999;
            if (self.menubarCurrentDisabled) button.enabled = NO;
        } else {
            //icon = [[NSString stringWithFormat:@"%@0", name] lowercaseString];
        }
        UIImage *image = [UIImage imageNamed:icon];
        UIImage *imageActive = [UIImage imageNamed:[NSString stringWithFormat:@"%@Active", icon]];
        button.frame = CGRectMake(i*w, 20, w, 44);
        [button setImage:image forState:UIControlStateNormal];
        [button setImage:image forState:UIControlStateDisabled];
        [button setImage:imageActive forState:UIControlStateHighlighted];
        button.exclusiveTouch = YES;
        button.imageView.contentMode = UIViewContentModeCenter;
        
        //Shift the image to more evenly space them out
        float shiftLeft = 25;
        button.imageEdgeInsets = UIEdgeInsetsMake(0, -shiftLeft + i * ((shiftLeft * 2) / 5 + 2), 0, 0);
        
        [button addTarget:self action:@selector(onMenubar:) forControlEvents:UIControlEventTouchUpInside];
        [self.menubar addSubview:button];

        for (NSString *dname in disabled) {
            if ([dname isEqualToString:name]) button.enabled = NO;
        }
        if (item[@"disabled"]) button.enabled = NO;
        _menubarButtons[name] = button;
        i++;
    }
    [self.view addSubview:self.menubar];
    
    self.navigationController.navigationBarHidden = YES;
}

- (void)setMenubarParams:(NSString*)name params:(NSDictionary*)params
{
    for (int i = 0; i < _menubarActions.count; i++) {
        NSDictionary *item = _menubarActions[i];
        if ([name isEqualToString:item[@"name"]]) {
            NSMutableDictionary *menu = [item mutableCopy];
            if (params) {
                menu[@"params"] = [params copy];
            } else {
                [menu removeObjectForKey:@"params"];
            }
            [_menubarActions setObject:menu atIndexedSubscript:i];
            break;
        }
    }
}

- (void)setMenubarButton:(NSString*)name enabled:(BOOL)enabled
{
    UIButton *button = _menubarButtons[name];
    if (!button) return;
    button.enabled = enabled;
}

- (void)updateMenubar
{
    for (NSString *name in _menubarButtons) {
        UIButton *button = _menubarButtons[name];
        
        BOOL showNotification = NO;
        
        if ([name isEqualToString:@"Match"] && [DBAccount getAccountsForPendingMatches].count > 0) {
            showNotification = YES;
        } else if ([name isEqualToString:@"Chat"] && [Message hasUnreadMessages]) {
            showNotification = YES;
        } else if ([name isEqualToString:@"Settings"] && ([self hasNewLikes] || ([GVUserDefaults standardUserDefaults].unseenContacts.count > 0)))
        {
            showNotification = YES;
        }
        
        if (showNotification) {
            if ([button viewWithTag:1337]) continue;
            
            UIImageView* imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"notificationDot"]];
            imageView.tag = 1337;
            imageView.frame = CGRectMake(button.imageView.origin.x + button.imageView.size.width - imageView.size.width,
                                         button.imageView.origin.y,
                                         imageView.size.width,
                                         imageView.size.height);
            if ([name isEqualToString:@"Settings"]) {
                imageView.frame = CGRectOffset(imageView.frame, 4, -4);
            } else if ([name isEqualToString:@"Chat"]) {
                imageView.frame = CGRectOffset(imageView.frame, 4, 2);
            }
            [button addSubview:imageView];
            
            //[button setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
        } else {
            [[button viewWithTag:1337] removeFromSuperview];
        }
    }
}

- (BOOL)hasNewLikes
{
    BOOL ret = NO;
    int likes = (int)[WFCore get].accountStructure.stats.likesReceived;
    if (likes != self.lastLikeCount) {
        ret = YES;
    }

    return ret;
}

- (void)sawLikes
{
    int likes = (int)[WFCore get].accountStructure.stats.likesReceived;
    self.lastLikeCount = likes;
    [self updateMenubar];
}

- (IBAction)onMenubar:(id)sender
{
    for (NSString *name in _menubarButtons) {
        UIButton *button = _menubarButtons[name];
        if (sender == button) {
            if ([name isEqualToString:@"Share"]) {
                [self showShare];
            } else {
                // Find additional parameters for given action
                NSDictionary *action = @{};
                for (NSDictionary *item in _menubarActions) {
                    if ([name isEqualToString:item[@"name"]]) {
                        action = item;
                        break;
                    }
                }
                
                if ([name isEqualToString:@"Settings"]) {
                    [self sawLikes];
                }
                
                // Replace active button with normal icon to keep tool bar state for drawers
//                [button setImage:[UIImage imageNamed:[name lowercaseString]] forState:UIControlStateNormal];
                [WFCore showViewController:self name:name mode:action[@"mode"] params:action[@"params"]];
                break;
            }
        }
    }
}

- (void)showShare
{
    UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:@"Share" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Message",@"Email",nil];
    action.tag = ACTIONSHEET_SHARE;
    action.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [action showInView:self.view];
    [action styleWithTintColor:WYLD_RED];
}

- (void)addToolbar:(NSString*)title
{
    self.toolbar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, TOOLBAR_HEIGHT)];
    self.toolbar.backgroundColor = self.toolbarColor;
    self.toolbar.layer.shadowOffset = CGSizeMake(0, -1);
    self.toolbar.layer.shadowOpacity = 0.3;
    self.toolbar.userInteractionEnabled = YES;
    self.toolbar.clipsToBounds = NO;
    [self.view addSubview:self.toolbar];
    
    self.toolbarBack = [UIButton buttonWithType:UIButtonTypeCustom];
    self.toolbarBack.imageView.contentMode = UIViewContentModeCenter;
    self.toolbarBack.frame = CGRectMake(0, 20, self.toolbar.frame.size.height-20, self.toolbar.frame.size.height-20);
    [self.toolbarBack setImage:[UIImage imageNamed:self.toolbarBackIcon ? self.toolbarBackIcon : @"left_red"] forState:UIControlStateNormal];
    [self.toolbarBack addTarget:self action:@selector(onBack:) forControlEvents:UIControlEventTouchUpInside];
    [self.toolbar addSubview:self.toolbarBack];
    
    self.toolbarTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.toolbar.frame.size.width, self.toolbar.frame.size.height-20)];
    self.toolbarTitle.text = title;
    self.toolbarTitle.textColor = self.toolbarTextColor;
    self.toolbarTitle.textAlignment = NSTextAlignmentCenter;
    self.toolbarTitle.font = [UIFont fontWithName:BOLD_FONT size:17];
    [self.toolbar addSubview:self.toolbarTitle];

    self.toolbarNext = [UIButton buttonWithType:UIButtonTypeCustom];
    self.toolbarNext.imageView.contentMode = UIViewContentModeCenter;
    if (self.toolbarNextIcon) {
        UIImage* image = [UIImage imageNamed:self.toolbarNextIcon];
        [self.toolbarNext setImage:image forState:UIControlStateNormal];
    } else {
        [self.toolbarNext setTitle:@"Next" forState:UIControlStateNormal];
        [self.toolbarNext setTitleColor:WYLD_RED forState:UIControlStateNormal];
        self.toolbarNext.titleLabel.font = [UIFont fontWithName:MAIN_FONT size:17];
    }
    [self.toolbarNext sizeToFit];
    self.toolbarNext.center = CGPointMake(self.toolbar.frame.size.width-self.toolbarNext.frame.size.width/2 - 10, self.toolbar.frame.size.height/2 + 10);
    [self.toolbarNext addTarget:self action:@selector(onNext:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)addTable
{
    CGRect frame = CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64);
    self.table = [[UITableView alloc] initWithFrame:frame];
    self.table.backgroundColor = [UIColor whiteColor];
    self.table.separatorInset = UIEdgeInsetsZero;
    self.table.delegate = (id<UITableViewDelegate>)self;
    self.table.dataSource = (id<UITableViewDataSource>)self;
    self.table.tag = 9990;
    self.table.delegate = self;
    self.table.dataSource = self;
    self.table.contentInset = UIEdgeInsetsZero;
    self.table.bouncesZoom = YES;
    self.table.delaysContentTouches = YES;
    self.table.canCancelContentTouches = YES;
    self.table.showsHorizontalScrollIndicator = NO;
    self.table.showsVerticalScrollIndicator = YES;
    self.table.separatorInset = UIEdgeInsetsZero;
    self.table.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    self.table.rowHeight = 50;
    
    if (self.tableCentered) {
        self.table.frame = CGRectInset(frame, 9, 0);
        self.table.contentInset = UIEdgeInsetsMake(9, 0, 5, 0);
    }
    
    if (self.tableRounded) {
        self.table.backgroundColor = [UIColor clearColor];
    }
    [self.view addSubview:self.table];
    
    self.tableSearch = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 44)];
    self.tableSearch.backgroundColor = GRAY_8;
    
    UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, self.tableSearch.frame.size.height)];
    leftView.backgroundColor = self.tableSearch.backgroundColor;
    self.tableSearch.leftView = leftView;
    self.tableSearch.leftViewMode = UITextFieldViewModeAlways;

    UIImageView *rightView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"contact"]];
    rightView.frame = CGRectMake(self.tableSearch.bounds.size.width - 47,
                                 6,
                                 19,
                                 19);
    rightView.backgroundColor = nil;
    rightView.tag = DELETE_ON_ENTRY;
    
    [self.tableSearch addSubview:rightView];
    
    
    [WFCore setTextBorder:self.tableSearch color:GRAY_6];
    self.tableSearch.placeholder = @"Search";
    self.tableSearch.textAlignment = NSTextAlignmentCenter;
    self.tableSearch.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.tableSearch.delegate = self;
}

- (void)reloadTable
{
    if (self.itemsAll.count) self.items = [self filterItems:self.itemsAll];
    [self.table reloadData];
    [self resizeTable];
}

- (id)getItem:(NSIndexPath*)indexPath
{
    NSInteger index = indexPath.row - self.tableRows;
    return index >=0 && index < self.items.count ? self.items[index] : nil;
}

- (void)setItem:(NSIndexPath*)indexPath data:(id)data
{
    NSInteger index = indexPath.row - self.tableRows;
    if (index >= 0 && index < self.items.count) self.items[index] = data;
}

- (void)resizeTable
{
    // Make table extend beyond the screen at the bottom if we have many rows
    if (self.table.tag == 9990 && self.table.frame.size.height == 488 && self.table.contentSize.height > self.table.frame.size.height) {
        self.table.frame = CGRectMake(self.table.frame.origin.x, self.table.frame.origin.y, self.table.frame.size.width, 508);
        self.table.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.table.frame.size.width, 20)];
        self.table.tableFooterView.backgroundColor = [UIColor whiteColor];
        [self.view viewWithTag:9991].frame = self.table.frame;
    }
}

- (void)restoreTablePosition
{
    if (!self.table) return;
    float top = [self.core.params[[NSString stringWithFormat:@"tableTop:%@",self.name]] floatValue];
    [self.table setContentOffset:CGPointMake(0, top -  self.table.contentInset.top) animated:NO];
}

- (void)saveTablePosition
{
    if (!self.table) return;
    self.core.params[[NSString stringWithFormat:@"tableTop:%@",self.name]] = @(self.table.contentOffset.y);
}

- (void)queueTableSearch
{
    if (_timer) [_timer invalidate];
    _timer = [NSTimer timerWithTimeInterval:0.4 target:self selector:@selector(onSearch:) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (NSMutableArray*)filterItems:(NSArray*)items
{
    if (!self.searchText.length) return [items mutableCopy];
    
    NSMutableArray *list = [@[] mutableCopy];
    for (int i = 0; i < items.count; i++) {
        NSDictionary *item = items[i];
        if (item[@"name"] && [item[@"name"] rangeOfString:self.searchText options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [list addObject:item];
        } else
        if (item[@"alias"] && [item[@"alias"] rangeOfString:self.searchText options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [list addObject:item];
        }
    }
    return list;
}

- (void)onSearch:(id)sender
{
    [self.table beginUpdates];
    NSMutableArray *paths = [@[] mutableCopy];
    for (int i = 0; i < self.items.count; i++) [paths addObject:[NSIndexPath indexPathForRow:i+self.tableRows inSection:0]];
    [self.table deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationNone];
    
    self.items = [self filterItems:self.itemsAll];
    paths = [@[] mutableCopy];
    for (int i = 0; i < self.items.count; i++) [paths addObject:[NSIndexPath indexPathForRow:i+self.tableRows inSection:0]];
    [self.table insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationFade];
    [self.table endUpdates];
    [self resizeTable];
}

- (MBProgressHUD*)showBlockingActivity
{
    return [MBProgressHUD showHUDAddedTo:self.view animated:YES];
}

- (void)hideBlockingActivity
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)showActivity
{
    self.activity.hidden = NO;
    [self.view bringSubviewToFront:self.activity];
    [self.activity startAnimating];
}

- (void)hideActivity
{
    _activityCount = 0;
    [self.activity stopAnimating];
    self.activity.hidden = YES;
}

- (void)showActivity:(BOOL)incr
{
    if (incr) _activityCount++;
    [self showActivity];
}

- (void)hideActivity:(BOOL)decr
{
    if (decr) {
        _activityCount--;
        if (_activityCount > 0) return;
    }
    [self hideActivity];
}

- (UITextView*)addEmptyViewWithText:(NSMutableAttributedString*)text
{
    CGFloat labelHeight = 80;
    
    UITextView* label = [[UITextView alloc] initWithFrame:CGRectMake(10,
                                                              10 + (self.view.height - labelHeight) / 2,
                                                              self.view.width - 20,
                                                              labelHeight)];
    [label setAttributedText:text];
    label.textAlignment = NSTextAlignmentCenter;
    [label setTextColor:[UIColor grayColor]];
    [label setBackgroundColor:[UIColor clearColor]];
    UIFont* font = [UIFont fontWithName:MAIN_FONT size:16];
    [label setFont:font];
    
    label.scrollEnabled = NO;
    label.editable = NO;
    label.textContainer.lineFragmentPadding = 0;
    label.textContainerInset = UIEdgeInsetsMake(0, 0, 0, 0);
    //label.delegate = self; Do this on the viewcontroller
    
    [self.view addSubview:label];
    
    return label;
}

- (void)onBack:(id)sender
{
    [self showPrevious];
}

- (void)onNext:(id)sender
{
}

- (ViewController*)prevController
{
    if (self.navigationController.childViewControllers.count > 1) {
        return (ViewController*)self.navigationController.childViewControllers[self.navigationController.childViewControllers.count - 2];
    }
    return nil;
}

- (void)showPrevious
{
    NSLog(@"showPrevious: %@: %@ %@", self.name, self.mode, self.caller);
    
    if ([self.drawerView isKindOfClass:[UIView class]]) {
        BounceAnimation *bounce = [[BounceAnimation alloc] initWithKeyPath:@"position.x" start:nil stop:^(id anim) {
            [self closeDrawer];
        }];
        bounce.fromValue = [NSNumber numberWithFloat:self.drawerView.center.x];
        bounce.toValue = [NSNumber numberWithFloat:self.view.center.x];
        bounce.overshoot = NO;
        [bounce configure:self.drawerView];
        return;
    }
    
    // Pop current and return to the parent controller
    if ([self.mode isEqualToString:@"push"]) {
        ViewController *prev = [self prevController];
        [self.navigationController popViewControllerAnimated:YES];
        if ([prev respondsToSelector:@selector(updateMenubar)])
            [prev updateMenubar];
        return;
    }
    
    // Replace with previous controller completely
    [WFCore showViewController:self name:self.caller mode:nil params:self.params];
}


- (void)closeDrawer
{
    [self.navigationController popViewControllerAnimated:NO];
    ViewController *prev = [self prevController];
    [prev updateMenubar];
    [self.drawerView removeFromSuperview];
    self.drawerView = nil;
}

- (void)showDrawer
{
    // Animation for the drawer
    BounceAnimation *bounce = [[BounceAnimation alloc] initWithKeyPath:@"position.x" start:nil stop:nil];
    bounce.fromValue = [NSNumber numberWithFloat:self.drawerView.center.x];
    bounce.toValue = [NSNumber numberWithFloat:_drawerFrame.origin.x + _drawerFrame.size.width/2];
    [bounce configure:self.drawerView];
}

- (void)prepareDrawerMode:(UIViewController*)owner
{
    CGRect frame = self.view.frame;
    
    // Screen capture the current content of the navigation view (alogn with the navigation bar, if any)
    UIImage *image = [WFCore captureImage:owner.view.window];
    
    // Sliding button with the screenshot
    self.drawerView = [UIButton buttonWithType:UIButtonTypeCustom];
    self.drawerView.exclusiveTouch = YES;
    if (frame.origin.y > 0) {
        frame.size.height += frame.origin.y;
        frame.origin.y *= -1;
    }
    self.drawerView.frame = frame;
    [self.drawerView setImage:image forState:UIControlStateNormal];
    [self.drawerView setImage:image forState:UIControlStateHighlighted];
    self.drawerView.layer.shadowOffset = CGSizeZero;
    self.drawerView.layer.shadowRadius = 5;
    self.drawerView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.drawerView.layer.shadowOpacity = .5;
    self.drawerView.layer.shadowPath = [UIBezierPath bezierPathWithRect:owner.view.window.layer.bounds].CGPath;
    [self.drawerView addTarget:self action:@selector(showPrevious) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.drawerView];
    
    _drawerFrame = self.view.bounds;
    if ([self.mode isEqualToString:@"drawerLeft"]) {
        _drawerFrame.origin.x = _drawerFrame.size.width + 5;
    }
    if ([self.mode isEqualToString:@"drawerLeftAnchor"]) {
        _drawerFrame.origin.x = _drawerFrame.size.width - DRAWER_WIDTH;
    }
    if ([self.mode isEqualToString:@"drawerRight"]) {
        _drawerFrame.origin.x =  5 - _drawerFrame.size.width;
    }
    if ([self.mode isEqualToString:@"drawerRightAnchor"]) {
        _drawerFrame.origin.x = DRAWER_WIDTH - _drawerFrame.size.width;
    }
    
    // Support swipe in addition to touch
//    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onDrawerPan:)];
//    self.panGesture.delegate = self;
//    [self.view addGestureRecognizer:self.panGesture];
}

- (void)preparePushMode:(UIViewController*)owner
{
    /*_contentView = self.view;
    UIImageView *bg = [[UIImageView alloc] initWithFrame:owner.view.frame];
    bg.image = [WFCore captureImage:owner.view.window];
    bg.userInteractionEnabled = YES;
    self.view = bg;
    [self.view addSubview:_contentView];
    
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPushPan:)];
    self.panGesture.delegate = self;
    [self.view addGestureRecognizer:self.panGesture];*/
}

- (void)onPan:(UIPanGestureRecognizer *)recognizer view:(UIView*)view right:(BOOL)right completion:(GenericBlock)completion
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [recognizer locationInView:self.view];
        if (CGRectEqualToRect(self.panRect, CGRectZero) || CGRectContainsPoint(self.panRect, point)) {
            _center = view.center;
            _panStarted = YES;
        }
    } else
    if (_panStarted && recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint point = [recognizer translationInView:self.view];
        if (_center.x + point.x >= self.view.frame.size.width/2) {
            view.center = CGPointMake(_center.x + point.x, _center.y);
        }
    } else
    if (_panStarted && (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled || recognizer.state == UIGestureRecognizerStateFailed)) {
        _panStarted = NO;
        CGPoint velocity = [recognizer velocityInView:self.view];
        float magnitude = sqrtf((velocity.x * velocity.x) + (velocity.y * velocity.y));
        float offset = view.frame.origin.x - self.view.frame.size.width*0.5;
        NSLog(@"onPan: %g: %g: %g: %g", view.frame.origin.x, velocity.x, magnitude, offset);
        if ((magnitude > 1500 && ((!right && velocity.x < 0) || (right && velocity.x > 0))) ||
            (!right && offset <= 0) || (right && offset >= 0)) {
            completion();
        } else {
            [UIView animateWithDuration:0.25
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{ view.center = _center; }
                             completion:nil];
        }
    }
}

- (void)onDrawerPan:(UIPanGestureRecognizer *)recognizer
{
    [self onPan:recognizer view:self.drawerView right:NO completion:^{ [self showPrevious]; }];
}

- (void)onPushPan:(UIPanGestureRecognizer *)recognizer
{
    [self onPan:recognizer view:_contentView right:YES completion:^{
            [UIView animateWithDuration:0.25
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionOverrideInheritedDuration
                             animations:^{
                                 _contentView.center = CGPointMake(self.view.frame.size.width*1.5, self.view.center.y);
                             } completion:^(BOOL stop) {
                                 [self.navigationController popViewControllerAnimated:NO];
                             }];
    }];
}

- (void)showImagePickerFromCamera:(id)sender
{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) return;
    if (!_picker) _picker = [[ImagePicker alloc] initWithView:self];
    _picker.picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:_picker.picker animated:YES completion:NULL];
}

- (void)showImagePickerFromLibrary:(id)sender
{
    if (!_picker) _picker = [[ImagePicker alloc] initWithView:self];
    _picker.picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:_picker.picker animated:YES completion:NULL];
}

- (void)showImagePickerFromAlbums:(id)sender
{
    [WFCore showViewController:self name:@"Album" mode:@"push" params:@{ @"_fullsize" : @(YES), @"_block": ^(NSDictionary *photo) {
        // Keep reference when calling a callback so the image will not be freed
        UIImage *img = photo[@"_image"];
        [self onImagePicker:img];
    } }];
}

- (void)onImagePicker:(UIImage*)image
{
}

- (void)onPopup:(UIPanGestureRecognizer *)recognizer
{
    UIView *view = recognizer.view;;
    [UIView transitionWithView:self.view
                      duration:0.5
                       options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionTransitionCrossDissolve
                    animations:^ { [view removeFromSuperview]; }
                    completion:^(BOOL finished) {
                        if ( [self respondsToSelector:@selector(onPopupClosed:)]) [self performSelector:@selector(onPopupClosed:) withObject:view];
                    }];
}

# pragma mark - UIViewDelegate methods

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.barStyle ? self.barStyle : UIStatusBarStyleDefault;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (![self isKindOfClass:[MessagesViewController class]]) {
        [self.view endEditing:YES];
    }
    [super touchesBegan:touches withEvent:event];
}

# pragma mark - UINavigationControllerDelegate methods

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC
{
    ViewController *view = (ViewController*)toVC;
    if ([view.mode isEqualToString:@"push"]) {
        if (view.pushAnimation) return [[Animation alloc] initWithType:view.pushAnimation duration:view.pushDuration];
    } else {
        if (view.modalAnimation) return [[Animation alloc] initWithType:view.modalAnimation duration:view.modalDuration];
    }
    return nil;
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    navigationController.delegate = nil;
}

# pragma mark - UIViewControllerTansitioningDelegate methods

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    ViewController *view = (ViewController*)presented;
    if (view.modalAnimation) return [[Animation alloc] initWithType:view.modalAnimation duration:view.modalDuration];
    return nil;
}

# pragma mark - UIpopupDelegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)index
{
    NSString *title = [alertView buttonTitleAtIndex:index];
    AlertBlock block = objc_getAssociatedObject(alertView, @"alertBlock");
    if (block) block(alertView, title);
}

# pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)recognizer shouldReceiveTouch:(UITouch *)touch
{
    if (recognizer == self.panGesture) {
        if ([touch.view isKindOfClass:[RangeSlider class]] || [touch.view isKindOfClass:[UISlider class]]) return NO;
    }
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)recognizer
{
    if (recognizer == self.panGesture) {
        CGPoint point = [recognizer locationInView:self.view];
        if (!CGRectEqualToRect(self.panRect, CGRectZero) && !CGRectContainsPoint(self.panRect, point)) return NO;
    }
    return YES;
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == ACTIONSHEET_SHARE) {
        UIGraphicsBeginImageContextWithOptions(self.view.size, YES, [UIScreen mainScreen].scale);
        [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:NO];
        UIImage* shareImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        NSData* data = nil;
        @try {
            data = UIImageJPEGRepresentation(shareImage, 1.0);
        }
        @catch (NSException *exception) {
            data = nil;
        }
        @finally {
            
        }
        NSData* imageData = data;
        
        NSString *action = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([action isEqualToString:@"Message"]) {
            [self sendMessage:imageData];
        } else if ([action isEqualToString:@"Email"]){
            [self sendEmail:imageData];
        }
    } else {
        NSLog(@"Code up the other actions");
    }
}

- (void)sendMessage:(NSData*)image
{
    MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
    if([MFMessageComposeViewController canSendText])
    {
        [controller addAttachmentData:image typeIdentifier:@"image/jpg" filename:@"Wyldfire.jpg"];
        controller.navigationBar.tintColor = [UIColor blackColor];
        controller.navigationBar.barTintColor = [UIColor blackColor];
        controller.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor blackColor]};
        controller.body = @"Check out this person I found on Wyldfire. Download the app here: AppStore.com/Wyldfire or watch the commercial at youtu.be/BagXyAops9E";
        controller.messageComposeDelegate = self;
        [self presentViewController:controller animated:YES completion:nil];
    } else {
        [WFCore showAlert:@"Messaging is disabled" msg:@"Please check your device settings to allow access." delegate:nil confirmHandler:nil];
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [controller dismissViewControllerAnimated:YES completion:nil];
    
    if (result == MessageComposeResultCancelled)
        NSLog(@"Message cancelled");
    else if (result == MessageComposeResultSent)
        NSLog(@"Message sent");
    else
        NSLog(@"Message failed");
}

- (void)sendEmail:(NSData*)image
{
    WFMailComposeViewController *mailViewController = [[WFMailComposeViewController alloc] init];
    mailViewController.navigationBar.tintColor = [UIColor blackColor];
    mailViewController.navigationBar.barTintColor = [UIColor blackColor];//WYLD_RED;
    //mailViewController.navigationBar.translucent = NO;
    mailViewController.mailComposeDelegate = self;
    mailViewController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor blackColor]};
    [mailViewController setSubject:@"Wyldfire"];
    [mailViewController setMessageBody:@"Check out this person I found on Wyldfire. Download the app here: AppStore.com/Wyldfire or watch the commercial at youtu.be/BagXyAops9E" isHTML:NO];
    [mailViewController addAttachmentData:image mimeType:@"image/jpg" fileName:@"Wydlfire.jpg"];
    [[mailViewController navigationBar] setTintColor:[UIColor blackColor]];
    [self.navigationController presentViewController:mailViewController animated:YES completion:^{
        
    }];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
		  didFinishWithResult:(MFMailComposeResult)result
						error:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:nil];
}


# pragma mark - UITextFieldDelegate methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    [[textField viewWithTag:DELETE_ON_ENTRY] removeFromSuperview];
    
    if ([textField isEqual:self.tableSearch]) {
        self.searchText = [textField.text stringByReplacingCharactersInRange:range withString:string];
        [self queueTableSearch];
    }
    
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    if (textField == self.tableSearch) {
        self.searchText = @"";
        [self queueTableSearch];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.tableSearch) {
        [textField resignFirstResponder];
    }
    return YES;
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.tableSearch resignFirstResponder];
}

#pragma mark - Table view data source

- (void)selectTableRow:(int)index animated:(BOOL)animated
{
    NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
    [self.table selectRowAtIndexPath:path animated:animated scrollPosition:UITableViewScrollPositionNone];
    [self onTableSelect:path selected:YES];
}

- (void)onTableSelect:(NSIndexPath *)indexPath selected:(BOOL)selected
{
}

- (void)onTableCell:(UITableViewCell*)cell indexPath:(NSIndexPath*)indexPath
{
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self onTableSelect:indexPath selected:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self onTableSelect:indexPath selected:NO];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tableSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableRows + self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = self.tableCell ? [tableView dequeueReusableCellWithIdentifier:self.tableCell] : nil;
    if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:self.tableCell];
    
    // This could be a small performance hit but it is good to know the cell width/height beforehand
    cell.frame = CGRectMake(0, 0, MIN(tableView.frame.size.width, cell.frame.size.width), [self tableView:tableView heightForRowAtIndexPath:indexPath]);
    cell.backgroundColor = [UIColor clearColor];
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    // Rounded table, round corners on the first and last cells
    if (self.tableRounded) {
        cell.backgroundColor = [UIColor whiteColor];
        if (indexPath.row == 0) {
            [WFCore setRoundCorner:cell corner:UIRectCornerTopLeft|UIRectCornerTopRight radius:0];
        }
        if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1) {
            [WFCore setRoundCorner:cell corner:UIRectCornerBottomLeft|UIRectCornerBottomRight radius:0];
        }
    }
    [self onTableCell:cell indexPath:indexPath];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return tableView.rowHeight;
}

@end

#import "NoStatusBarImagePickerController.h"

@implementation ImagePicker

- (id)initWithView:(ViewController*)view
{
    self = [super init];
    self.picker = [[NoStatusBarImagePickerController alloc] init];
    self.picker.delegate = self;
    self.view = view;
    return self;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:NO completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self.view onImagePicker:info[UIImagePickerControllerOriginalImage]];
    [picker dismissViewControllerAnimated:NO completion:NULL];
}

@end
