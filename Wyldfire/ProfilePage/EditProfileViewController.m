//
//  EditProfileViewController.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 3/22/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "EditProfileViewController.h"
#import "NSString+util.h"

@interface EditProfileViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic) NSArray* initialImages;
@property (nonatomic) BOOL beenRewarded;
@end

@implementation EditProfileViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self addToolbar:@"Edit Profile"];
    self.toolbar.backgroundColor = GRAY_8;
    [self addTableview];
    
    Account* account = [WFCore get].accountStructure;
    self.initialImages = account.allProfileImages;
}

- (int)changedImageCount
{
    int counter = 0;
    Account* account = [WFCore get].accountStructure;
    for (UIImage* image in account.allProfileImages) {
        if (![self.initialImages containsObject:image]) {
            counter++;
        }
    }
    return counter;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    
    if ([self changedImageCount] > 1 && !self.beenRewarded) {
        self.beenRewarded = YES;
        [WFCore saveMoment:KIIP_REWARD_MOMENT_UPDATED_2_PHOTOS
                  onlyOnce:NO
                   topText:@"Makeover"
                bottomText:@"You just switched up your profile pictures!"
                    inNavC:self.navigationController];
    }
}

#pragma mark - Tableview

- (void)addTableview
{
    CGRect tableRect = CGRectMake(0,
                                  self.toolbar.bottom,
                                  self.view.width,
                                  self.view.height - self.toolbar.bottom);
    UITableView* tableView = [[UITableView alloc] initWithFrame:tableRect];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.separatorInset = UIEdgeInsetsMake(0, EDIT_PROFILE_TEXT_INSET, 0, 0);
    
    [tableView registerClass:[InfoTableViewCell class] forCellReuseIdentifier:@"infoCell"];
    [tableView registerClass:[ImageTableViewCell class] forCellReuseIdentifier:@"imageCell"];
    
    [self.view addSubview:tableView];
    self.tableView = tableView;
    [self hideEmptySeparators];
}

- (void)hideEmptySeparators
{
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.backgroundColor = [UIColor clearColor];
    [self.tableView setTableFooterView:v];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5 + ADDITIONAL_PROFILE_PHOTO_COUNT;
}

- (void)instagramSignin:(UIButton*)button
{
    if (((NSString*)self.core[@"instagram_username"]).length > 0) {
        [self logoutInstagram];
    } else {
        [self.core.instagram getAccount:^(NSDictionary *result) {
            [self.core.instagram saveAccount];
            
            [[APIClient sharedClient] updateAccount:@{ @"instagram_id": [WFCore toString:result name:@"id"],
                                                       @"instagram_username": [WFCore toString:result name:@"username"] }
                                             notify:NO success:nil failure:nil];
            [self.tableView reloadData];
        } failure:^(NSInteger code) {
            [self logoutInstagram];
        }];
    }
}

- (void)logoutInstagram
{
    [self.core.instagram logout];
    [self.core.instagram saveAccount];
    [self.tableView reloadData];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell;
    
    if (indexPath.row == EditProfileOrderEmail || indexPath.row == EditProfileOrderPhone) {
        InfoTableViewCell* infoCell = [tableView dequeueReusableCellWithIdentifier:@"infoCell" forIndexPath:indexPath];
        
        BOOL isEmail = indexPath.row == EditProfileOrderEmail;
        
        infoCell.defaultsKey = (isEmail ? @"email" : @"phoneNumber");
        infoCell.infoImageView.image = [UIImage imageNamed:(isEmail ? @"mail" : @"phone")];
        GVUserDefaults* defaults = [GVUserDefaults standardUserDefaults];
        infoCell.textField.text = [defaults valueForKey:infoCell.defaultsKey];
        
        if (!isEmail) {
            infoCell.textField.keyboardType = UIKeyboardTypePhonePad;
            [infoCell.textField addDoneAccessory];
            infoCell.textField.placeholder = @"(555) 555-5555";
        }
        
        cell = infoCell;
    } else
    if (indexPath.row == EditProfileOrderInstagram) {
        InfoTableViewCell* infoCell = [tableView dequeueReusableCellWithIdentifier:@"infoCell" forIndexPath:indexPath];
        
        infoCell.infoImageView.image = [UIImage imageNamed:@"instagram"];
        infoCell.textField.userInteractionEnabled = NO;
        infoCell.textField.text = self.core[@"instagram_username"];
        UIButton* button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.width, EDIT_PROFILE_INFOCELL_HEIGHT)];
        [infoCell addSubview:button];
        //[button addTarget:self action:@selector(instagramSignin:) forControlEvents:UIControlEventTouchUpInside];
        infoCell.textField.text = @"Instagram support coming soon...";
        infoCell.textField.font = FONT_MAIN(10);
        infoCell.textField.textColor = GRAY_2;
        cell = infoCell;
    } else {
        ImageTableViewCell* imageCell = [tableView dequeueReusableCellWithIdentifier:@"imageCell" forIndexPath:indexPath];
        Account* account = [WFCore get].accountStructure;
        
        UIImage* image;
        NSString* text;
        if (indexPath.row == EditProfileOrderAvatar) {
            image = [account avatarPhoto];
            imageCell.isAvatar = YES;
            text = @"Avatar Photo";
        } else if (indexPath.row == EditProfileOrderShowcase) {
            image = [account showcasePhoto];
            text = @"Showcase Photo";
        } else {
            int imageType = (int)indexPath.row - EditProfileOrderProfile + 2;
            image = [account profileImageForType:imageType];
            text = [NSString stringWithFormat:@"Profile Picture %i", (int)(indexPath.row - EditProfileOrderProfile + 1)];
        }
        
        imageCell.titleLabel.text = text;
        imageCell.image = image;
        
        cell = imageCell;
    }
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == EditProfileOrderEmail || indexPath.row == EditProfileOrderPhone || indexPath.row == EditProfileOrderInstagram) {
        return EDIT_PROFILE_INFOCELL_HEIGHT;
    } else {
        return EDIT_PROFILE_IMAGECELL_HEIGHT;
    }
}

#pragma mark - Delete

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    ImageTableViewCell* cell = (ImageTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    
    return indexPath.row >= EditProfileOrderProfile &&
    cell.image != nil;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self deleteItemAtIndexPath:indexPath];
        self.tableView.editing = NO;
    }
}

- (void)deleteItemAtIndexPath:(NSIndexPath*)indexPath
{
    ImageTableViewCell* cell = (ImageTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    cell.image = nil;
    
    int imageType = (int)indexPath.row - EditProfileOrderProfile + 2;
    [[[WFCore get] accountStructure] setImage:nil forType:imageType];
    [[APIClient sharedClient] uploadImage:nil type:imageType success:nil failure:nil];
}

#pragma mark - Selection

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == EditProfileOrderAvatar) {
        //Avatar Photo
        
        id params = @{ @"_avatar": @1 ,
                       @"_edit": self };
        [WFCore showViewController:self name:@"Album" mode:@"push" params:params];
    } else if (indexPath.row == EditProfileOrderShowcase) {
        //Showcase Photo
        
        id params = @{ @"_main": @1 ,
                       @"_edit": self };
        [WFCore showViewController:self name:@"Album" mode:@"push" params:params];
    } else if (indexPath.row >= EditProfileOrderProfile) {
        //Additional Profile Photos
        
        int imageType = (int)indexPath.row - EditProfileOrderProfile + 2;
        
        id params = @{ @"_edit": self , @"_type" : @(imageType)};
        [WFCore showViewController:self name:@"Album" mode:@"push" params:params];
    }
}


@end
