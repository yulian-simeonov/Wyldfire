//
//  PhotosViewController.m
//  Wyldfire
//
//  Created by Vlad Seryakov on 11/2/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

#import "MBProgressHUD.h"

@interface PhotosViewController () <UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) IBOutlet UICollectionView *photos;
@property (nonatomic) BOOL reachedEndOfPhotos;
@property (nonatomic) int page;
@end

@implementation PhotosViewController

// It is required that the "photos:" property to be an array of objects with at
// least one property: "icon", or "image" or "photo"
- (void)viewDidLoad
{
    self.barStyle = UIStatusBarStyleLightContent;
    [super viewDidLoad];
    


    self.view.backgroundColor = [UIColor whiteColor];
    self.toolbarColor = GRAY_1;
    self.toolbarTextColor = [UIColor whiteColor];
    //self.toolbarBackIcon = @"left_white";
    [self addToolbar:@"Choose Picture"];
    
    NSMutableDictionary *images = self.params[@"_images"];
    
    if (images.count >= 1 && !self.toolbarNext.superview) {
        [self.toolbar addSubview:self.toolbarNext];
    }
    

    CGRect frame = CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64);
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.minimumInteritemSpacing = 8.f;
    layout.minimumLineSpacing = 8.f;
    layout.sectionInset = UIEdgeInsetsZero;
    layout.itemSize = CGSizeMake(PHOTO_CELL_SIZE, PHOTO_CELL_SIZE);
    layout.sectionInset = UIEdgeInsetsMake(8, 8, 8, 8);
    
    self.photos = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:layout];
    self.photos.backgroundColor = [UIColor clearColor];
    [self.photos registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    [self.photos setDataSource:self];
    [self.photos setDelegate:self];
    [self.view addSubview:self.photos];
    
    self.photos.allowsSelection = YES;
    if (self.params[@"_multiple"]) {
        self.photos.allowsMultipleSelection = YES;;
    }
    
    // Passed photos in the album object
    for (NSDictionary *photo in self.params[@"photos"]) {
        [self.items addObject:photo];
    }
    
    if (self.items.count) return;
    
    // Photos to be retrieved from the remote accounts
    if ([self.params[@"type"] isEqualToString:@"facebook"]) {
        [self loadMorePhotos];
    } else if ([self.params[@"type"] isEqualToString:@"instagram"]) {
        [self.core.instagram getPhotos:self.params[@"id"] success:^(id photos) {
            for (NSDictionary *photo in photos) {
                [self.items addObject:photo];
            }
            [self reloadData];
            [self hideActivity];
        } failure:^(NSInteger code) {
            [self hideActivity];
        }];
    }
    
    self.view.multipleTouchEnabled = NO;
}

- (void)loadMorePhotos
{
    if (self.reachedEndOfPhotos) return;
    
    if ([self.params[@"type"] isEqualToString:@"facebook"]) {
        [FacebookUtility getPhotos:self.params[@"id"]
                              page:self.page++
                           success:^(NSString *next, NSArray *list) {
                               if (!next) {
                                   self.reachedEndOfPhotos = YES;
                               }
                               
                               if (list.count > 0) {
                                   for (NSDictionary *photo in list) {
                                       [self.items addObject:photo];
                                   }
                                   [self reloadData];
                               }
                               [self hideActivity];
                           } failure:^(NSInteger code) {
                               [self hideActivity];
                           }];
    }
}

- (void)reloadData
{
    [self.photos performBatchUpdates:^{
        [self.photos reloadSections:[NSIndexSet indexSetWithIndex:0]];
    } completion:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Multiple mode means we are choosing 4 additional profile icons, no processing, just additional icons
    if (self.params[@"_multiple"]) {
        self.toolbarTitle.text = @"Choose Photos";
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    if (self.items.count == 0) {
        [self showActivity];
        self.activity.center = self.view.center;
        [self reloadData];
    }
}

- (void)onNext:(id)sender
{
    if (self.params[@"_multiple"]) {
        NSMutableDictionary *images = self.params[@"_images"];
        int i = 2;
        for (NSString *url in images) {
            [[APIClient sharedClient] setImageFromURL:url type:i++ success:nil failure:nil];
        }
        
        [GVUserDefaults standardUserDefaults].hasFinishedSetup = YES;
        [[APIClient sharedClient] nextActionAfterLogin:self];
    }
    
}

- (void)doBlock:(NSDictionary*)item block:(SuccessBlock)block
{
    // Return largest image not the thumbnail
    if (self.params[@"_fullsize"]) {
        [self showActivity];
        [[APIClient sharedClient] downloadImage:item[@"_url"]
            success:^(UIImage *image, NSString *url) {
                [self hideActivity];
                [self doClose];
                block(@{ @"_image": image, @"_url": item[@"_url"] });
            } failure:^(NSInteger code) {
                [self hideActivity];
                [self doClose];
                block(item);
            }];
    } else {
        block(item);
        [self doClose];
    }
}
- (void)doClose
{
    // We have to remove Albums controller in order to return to the actual caller
    ViewController *albums = [self prevController];
    [self.navigationController popToViewController:albums animated:NO];
    [albums showPrevious];
}

// Return largest image url
- (NSString*)getURL:(NSDictionary*)item
{
    return item[@"photo"] ? item[@"photo"] : item[@"image"] ? item[@"image"] : item[@"icon"];
}

- (void)additionalPhotoSelected:(UIImage*)image urlString:(NSString*)url
{
    int type = [self.params[@"_type"] intValue];
    [[WFCore get].accountStructure setImage:image forType:type];
    [[APIClient sharedClient] setImageFromURL:url type:type success:nil failure:nil];

    [self performSelector:@selector(popToEditProfile) withObject:nil afterDelay:0.8];
    
}

- (void)popToEditProfile
{
    [self.navigationController popToViewController:self.params[@"_edit"] animated:YES];
}

- (void)showcasePhotoChosen:(UIImageView*)imageView urlString:(NSString*)url
{
    NSMutableDictionary *params = [self.params mutableCopy];
    params[@"fullImage"] = imageView.image;
    params[@"_url"] = url;
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [[APIClient sharedClient] downloadImage:url success:^(UIImage *image, NSString *url) {
        params[@"fullImage"] = image;
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [WFCore showViewController:self name:@"PhotoEdit" mode:@"push" params:params];
        [self removeCheckSubview:imageView];
    } failure:^(NSInteger code) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [WFCore showViewController:self name:@"PhotoEdit" mode:@"push" params:params];
        [self removeCheckSubview:imageView];
    }];
}

- (void)avatarPhotoChosen:(UIImageView*)imageView urlString:(NSString*)url
{
    NSMutableDictionary *params = [self.params mutableCopy];
    params[@"fullImage"] = imageView.image;
    params[@"_url"] = url;
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [[APIClient sharedClient] downloadImage:url success:^(UIImage *image, NSString *url) {
        params[@"fullImage"] = image;
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [WFCore showViewController:self name:@"AvatarEdit" mode:@"push" params:params];
        [self removeCheckSubview:imageView];
    } failure:^(NSInteger code) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [WFCore showViewController:self name:@"AvatarEdit" mode:@"push" params:params];
        [self removeCheckSubview:imageView];
    }];
}

- (void)selectPhoto:(UIImageView*)view index:(NSInteger)index selected:(BOOL)selected
{
    NSDictionary *item = self.items[index];
    NSString* url = item[@"photo"];
    
    // Place check mark on top of the image
    if (selected) {
        if (self.params[@"_block"]) {
            NSDictionary *item = @{ @"_image": view.image, @"_url": url };
            [self doBlock:item block:self.params[@"_block"]];
        } else if (self.params[@"_multiple"]) {                            //Initial setup, choosing multiple photos
            NSMutableDictionary *images = self.params[@"_images"];
            
            if (images.count < ADDITIONAL_PROFILE_PHOTO_COUNT) {
                [self addCheckSubview:view];
                if (view.image) images[url] = view.image;
            }
                
            if (images.count >= 1 && !self.toolbarNext.superview) {
                [self.toolbar addSubview:self.toolbarNext];
            }
            
        } else if (self.params[@"_main"]) {                         //Showcase Photo
            [self addCheckSubview:view];
            [self showcasePhotoChosen:view urlString:url];
        } else if (self.params[@"_type"]) {                          //Choosing single profile photo
            [self addCheckSubview:view];
            [self additionalPhotoSelected:view.image urlString:url];
        } else if (self.params[@"_avatar"]) {                          //Choosing single profile photo
            [self addCheckSubview:view];
            [self avatarPhotoChosen:view urlString:url];
        }
    } else {
        [self removeCheckSubview:view];
        
        // Multiple mode: disable next button until we have 1 photo
        if (self.params[@"_multiple"]) {
            NSMutableDictionary *images = self.params[@"_images"];
            [images removeObjectForKey:url];
            if (images.count < 1) {
                [self.toolbarNext removeFromSuperview];
            }
        }
    }
}

- (void)addCheckSubview:(UIView*)view
{
    UIImageView *check = (UIImageView*)[view viewWithTag:1239];
    if (!check) {
        check = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"green_check"]];
        check.tag = 1239;
        [view addSubview:check];
        check.layer.anchorPoint = CGPointMake(0, 1);
        check.frame = CGRectMake(view.frame.size.width - check.frame.size.width - 3, 2, check.frame.size.width, check.frame.size.height);
    }
    
    CABasicAnimation* scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    [scale setFromValue:@(1)];
    [scale setToValue:@(1.2)];
    [scale setAutoreverses:YES];
    [scale setDuration:1.0 / 4];
    [scale setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    [check.layer addAnimation:scale forKey:@"scaled"];
    
    CABasicAnimation* position = [CABasicAnimation animationWithKeyPath:@"position"];
    [position setFromValue:[NSValue valueWithCGPoint:check.layer.position]];
    [position setToValue:[NSValue valueWithCGPoint:CGPointMake(check.layer.position.x - 2, check.layer.position.y + 2)]];
    [position setAutoreverses:YES];
    [position setDuration:1.0 / 4];
    [position setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    [check.layer addAnimation:position forKey:@"position"];
}

- (void)removeCheckSubview:(UIView*)view
{
    UIView *check = [view viewWithTag:1239];
    [check removeFromSuperview];
}

# pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    return self.items.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == self.items.count - 1) {
        [self loadMorePhotos];
    }
    
    NSDictionary *item = self.items[indexPath.row];
    NSString* url = [self getURL:item];
    
    UICollectionViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.clipsToBounds = YES;
    
    UIImageView *imageView = (UIImageView*)[cell viewWithTag:1000];
    if (!imageView) {
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.width)];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.tag = 1000;
        [cell addSubview:imageView];
    } else {
        imageView.image = nil;
    }
    
    BOOL selected = NO;
    // In multiple mode we should show already selected photos
    if (self.params[@"_multiple"] && self.params[@"_images"][url] != nil) {
        selected = YES;
    }
    
    if (selected) {
        [cv selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        [cell setSelected:YES];
        [self addCheckSubview:imageView];
    }
    
    [self selectPhoto:imageView index:indexPath.row selected:selected];
    
    // Show small icon to make it fast and not consume bandwidth but use large photo url for selection
    [[APIClient sharedClient] downloadImage:item[@"icon"] success:^(UIImage *image, NSString *url) {
        [UIView transitionWithView:imageView
                          duration:0.25
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            imageView.image = image;
                        } completion:^(BOOL finished) {
                            //
                        }];
    } failure:^(NSInteger code) {
        //
    }];
    
    return cell;
}

# pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [self.photos cellForItemAtIndexPath:indexPath];
    __weak UIImageView *imageView = (UIImageView*)[cell viewWithTag:1000];
    [self selectPhoto:imageView index:indexPath.row selected:1];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [self.photos cellForItemAtIndexPath:indexPath];
    __weak UIImageView *imageView = (UIImageView*)[cell viewWithTag:1000];
    [self selectPhoto:imageView index:indexPath.row selected:0];
    
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionOverrideInheritedDuration|UIViewAnimationOptionOverrideInheritedCurve
            animations:^{
                imageView.alpha = 1.0;
            }
            completion:nil];
}

@end
