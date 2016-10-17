//
//  AlbumController.m
//  Wyldfire
//
//  Created by Vlad Seryakov on 9/17/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

// Popup alert
@interface PopupView: UIImageView
@property (strong, nonatomic) UIView *view;
@property (strong, nonatomic) UILabel *title;
@property (strong, nonatomic) UILabel *descr;

- (PopupView *)initWithTitle:(NSString*)title;
@end

@implementation AlbumViewController {
    BOOL _alerted;
    NSMutableDictionary *_images;
}

- (void)viewDidLoad
{
    self.barStyle = UIStatusBarStyleLightContent;
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.toolbarColor = GRAY_1;
    self.toolbarTextColor = [UIColor whiteColor];//[UIColor colorWithRed:245/255.0 green:98/255.0 blue:98/255.0 alpha:1];
    self.toolbarBackIcon = @"left_red";
    [self addTable];
    [self addToolbar:@"Choose Album"];
    if (!self.params[@"_edit"]) {
        self.toolbarBack.alpha = 0;
    }
    
    _images = [@{} mutableCopy];
    self.params[@"_images"] = _images;
    
    self.view.multipleTouchEnabled = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.items.count == 0) {
        [self refreshItems];
        [self showActivity];
    }
    // Choosing a profile photo mode
    if (self.params[@"_main"]) {
        if (!_alerted) {
            [self showPopup:@"Choose Profile Picture"
                       descr:@"Make sure to choose a photo\nof just you facing the camera."
                      icons:@[ @"popup_pic1", @"popup_pic2", @"popup_pic3" ]
                     checks:@[ @"cancel", @"cancel", @"green_check" ]];
            _alerted = YES;
        }
    }
    
    // Multiple profile photos
    if (self.params[@"_multiple"]) {
        if (!_alerted) {
            [self showPopup:@"Choose Additional Photos"
                       descr:[NSString stringWithFormat:@"Choose up to %i additional profile\npictures of whatever you like.", ADDITIONAL_PROFILE_PHOTO_COUNT]
                      icons:@[ @"popup_pic4", @"popup_pic5", @"popup_pic6" ]
                     checks:nil];
            _alerted = YES;
        }
    }
}

- (void)refreshItems
{
    
    //[self showActivity];
    [self loadAlbum:nil success:^{
        //[self loadAlbum:self.core.instagram success:^() {
            [self reloadTable];
            [self hideActivity];
        //}];
    }];
}

- (void)reloadTable
{
    if (self.itemsAll.count) self.items = [self filterItems:self.itemsAll];
    [self.table reloadData];
    [self.table reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationLeft];
    //[self resizeTable];
}

- (void)loadAlbum:(id)account success:(GenericBlock)success
{
    if ([[account name] isEqualToString:@"instagram"])
    {
        if (![account isOpen]) {
            success();
            return;
        }
        
        [account getAlbums:^(id alist) {
            for (id item in alist) [self.items addObject:item];
            success();
            [self hideActivity];
        } failure:^(NSInteger code) {
            success();
            [self hideActivity];
        }];

    } else {
        [FacebookUtility getAlbums:^(id alist) {
            for (id item in alist) [self.items addObject:item];
            success();
            [self hideActivity];
        } failure:^(NSInteger code) {
            success();
            [self hideActivity];
        }];
    }
}

- (void)onBack:(id)sender
{
    if ([self.mode isEqualToString:@"push"]) {
        [self showPrevious];
    } else {
        [WFCore showViewController:self name:@"Profile" mode:nil params:nil];
    }
}

- (void)onTableSelect:(NSIndexPath *)indexPath selected:(BOOL)selected
{
    if (!selected) return;
    NSDictionary *item = [self getItem:indexPath];
    [WFCore showViewController:self name:@"Photos" mode:@"push" params:[WFCore createParams:item params:self.params]];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}

- (void)onTableCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    CGFloat height = [self tableView:self.table heightForRowAtIndexPath:indexPath];
    CGFloat pad = 8;
    
    cell.backgroundColor = [UIColor whiteColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSMutableDictionary *item = [[self getItem:indexPath] mutableCopy];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(ALBUM_PREVIEW_SIZE + pad * 2,
                                                               22,
                                                               cell.frame.size.width - 96,
                                                               18)];
    label.text = item[@"name"];
    label.font = [UIFont fontWithName:BOLD_FONT size:34 / 2];
    label.textColor = [UIColor blackColor];
    [cell addSubview:label];
    
    UILabel *sublabel = [[UILabel alloc] initWithFrame:CGRectMake(ALBUM_PREVIEW_SIZE + pad * 2,
                                                                  CGRectGetMaxY(label.frame),
                                                                  cell.frame.size.width - 96,
                                                                  14)];
    sublabel.text = [NSString stringWithFormat:@"%@ Photos", item[@"count"]];
    if ([ALBUM_ID_PHOTOS_OF_YOU isEqualToString:item[@"id"]]) sublabel.text = @"";
    sublabel.font = [UIFont fontWithName:MAIN_FONT size:24 / 2];
    sublabel.textColor = GRAY_2;
    [cell addSubview:sublabel];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(8,
                                                                           (height - ALBUM_PREVIEW_SIZE) / 2
                                                                           , ALBUM_PREVIEW_SIZE,
                                                                           ALBUM_PREVIEW_SIZE)];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    
    [cell addSubview:imageView];
    
    // Already cached photo
    if (item[@"image"]) {
        imageView.image = item[@"image"];
        return;
    }
    
    // Retrieve album picture by URL.
    [[APIClient sharedClient] downloadImage:item[@"icon"]
        success:^(UIImage *image, NSString *url) {
            item[@"image"] = image;
            imageView.image = image;
            [self setItem:indexPath data:item];
        } failure:nil];
}

#pragma mark - Popups

- (void)showPopup:(NSString*)title descr:(NSString*)descr icons:(NSArray*)icons checks:(NSArray*)checks
{
    PopupView *popup = [[PopupView alloc] initWithTitle:title];
    popup.descr.text = descr;
    
    for (int i = 0; i < 3; i++) {
        UIImage *pic = [icons[i] isKindOfClass:[UIImage class]] ? icons[i] : [UIImage imageNamed:icons[i]];
        
        UIImageView *img = [[UIImageView alloc] initWithImage:pic];
        int w = img.frame.size.width/2 + (popup.view.frame.size.width/3 - img.frame.size.width)/2;
        img.center = CGPointMake(w + i*w*2, 120 + CGRectGetHeight(img.frame) / 2);
        [popup.view addSubview:img];
        
        if (!checks) continue;
        UIImageView *check = [[UIImageView alloc] initWithImage:[UIImage imageNamed:checks[i]]];
        check.center = CGPointMake(w + i*w*2, img.center.y + check.frame.size.height/2 + img.frame.size.height/2 + 10);
        [popup.view addSubview:check];
    }
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onPopup:)];
    [popup addGestureRecognizer:tap];
    
    CGRect properRect = popup.view.frame;
    popup.view.frame = CGRectOffset(properRect, -320, 0);
    
    [UIView transitionWithView:self.view
                      duration:0.2
                       options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionTransitionCrossDissolve
                    animations:^ { [self.view addSubview:popup]; }
                    completion:^(BOOL finished) {
                        if (finished) {
                            
                            [UIView animateWithDuration:0.5 animations:^{
                                popup.view.frame = properRect;
                            }];
                        }
                    }];
}

@end

@implementation PopupView

- (PopupView*)initWithTitle:(NSString*)title
{
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    //self.backgroundColor = [UIColor whiteColor];
    self.image = [UIImage imageNamed:@"popup_bg"];
    self.opaque = NO;
    self.userInteractionEnabled = YES;
    
    self.view = [[UIView alloc] initWithFrame:CGRectMake(49 / 2.,
                                                         236 / 2,
                                                         541 / 2.,
                                                         476 / 2)];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.layer.masksToBounds = YES;
    self.view.opaque = YES;
    [self addSubview:self.view];
    
    self.title = [[UILabel alloc] initWithFrame:CGRectMake(0, 65 / 2, self.view.frame.size.width, 20)];
    self.title.textAlignment = NSTextAlignmentCenter;
    self.title.font = [UIFont fontWithName:MAIN_FONT size:35 / 2];
    self.title.adjustsFontSizeToFitWidth = YES;
    self.title.text = title;
    self.title.textColor = [UIColor blackColor];
    [self.view addSubview:self.title];
    
    self.descr = [[UILabel alloc] initWithFrame:CGRectMake(0, 115 / 2, self.view.frame.size.width, 40)];
    self.descr.textAlignment = NSTextAlignmentCenter;
    self.descr.font = [UIFont fontWithName:MAIN_FONT size:24 / 2];
    
    self.descr.numberOfLines = 0;
    self.descr.adjustsFontSizeToFitWidth = YES;
    self.descr.textColor = GRAY_2;
    [self.view addSubview:self.descr];
    
    return self;
}

@end


