//
//  PhotoEditViewController.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/22/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "PhotoEditViewController.h"

@interface PhotoEditViewController ()
    @property (nonatomic, strong) WFZoomView* scrollView;
    @property (nonatomic, strong) NSArray* labels;
    @property (nonatomic, strong) NSArray* imageViews;
    @property (nonatomic, strong) UIImageView* mainPreview;
    @property (nonatomic, strong) UIScrollView *filterScrl;
    @property (nonatomic, strong) NSArray *filterAry;
    @property (nonatomic, strong) UIImageView *rightArrow;

    @property (nonatomic, strong) UIImage* image;
    @property (nonatomic, strong) UIImageView* currentSelection;

    @property (atomic) BOOL doneWithIntialEdit;
@end

@implementation PhotoEditViewController

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.filterAry = @[@"Darker", @"Lighter", @"Increase", @"Strong", @"Medium", @"Linear"];
    [self setupUI];
    [self intialEditOfPhotos];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!self.doneWithIntialEdit) [self showBlockingActivity];
}

- (void)setupUI
{
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupToolbar];
    [self setupLabelsAndPreviews];
    [self setupScrollview];
}

- (void)setupToolbar
{
    self.toolbarColor = GRAY_1;
    self.toolbarTextColor = [UIColor whiteColor];
   
    [self addToolbar:@"Edit Photo"];
}

- (void)setupLabelsAndPreviews
{
    NSMutableArray* labels = [NSMutableArray new];
    NSMutableArray* previews = [NSMutableArray new];
    
    //Labels setup
    CGFloat labelHeight = 14;
    CGFloat totalHeight = CGRectGetHeight(self.view.frame);
    CGFloat totalWidth = CGRectGetWidth(self.view.frame);
    UIFont* labelFont = [UIFont fontWithName:MAIN_FONT size:12];
    CGRect labelRect = CGRectMake(PHOTO_EDIT_HORIZONTAL_PAD,
                                  PHOTO_CELL_SIZE + PHOTO_EDIT_VERTICAL_PAD / 2,
                                  PHOTO_CELL_SIZE,
                                  labelHeight);
    
    //ImageViews setup
    CGRect imageRect = CGRectMake(PHOTO_EDIT_HORIZONTAL_PAD,
                                  0,
                                  PHOTO_CELL_SIZE,
                                  PHOTO_CELL_SIZE);
    
    // filter scroll
    self.filterScrl = [[UIScrollView alloc] initWithFrame:CGRectMake(0, totalHeight - labelHeight - PHOTO_CELL_SIZE - PHOTO_EDIT_VERTICAL_PAD, totalWidth, PHOTO_CELL_SIZE + PHOTO_EDIT_VERTICAL_PAD/2 + labelHeight)];
    self.filterScrl.contentSize = CGSizeMake(PHOTO_EDIT_HORIZONTAL_PAD + [self.filterAry count] * (PHOTO_CELL_SIZE + PHOTO_EDIT_HORIZONTAL_PAD + 1), 0);
    self.filterScrl.delegate = self;
    [self.view addSubview:self.filterScrl];
    
    for (int i = 0; i < [self.filterAry count]; i++) {
        CGRect currentLabelRect = CGRectOffset(labelRect,
                                               i * (labelRect.size.width + PHOTO_EDIT_HORIZONTAL_PAD + 1),
                                               0);
        
        UILabel* label = [self labelInRect:currentLabelRect
                                  withText:self.filterAry[i]
                                     color:GRAY_2
                                      font:labelFont];
        [labels addObject:label];
        
        CGRect currentImageViewRect = CGRectOffset(imageRect,
                                                   i * (imageRect.size.width + PHOTO_EDIT_HORIZONTAL_PAD + 1),
                                                   0);
        UIImageView* imageView = [self imageViewWithFrame:currentImageViewRect];
        [previews addObject:imageView];
    }
    
    self.labels = labels;
    self.imageViews = previews;
    
    UIImageView* imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"right_white"]];
    imgView.center = CGPointMake(self.view.width - imgView.width/2.f, self.filterScrl.y + PHOTO_CELL_SIZE/2.f);
    [self.view addSubview:imgView];
    self.rightArrow = imgView;
}

- (void)setupScrollview
{
    CGFloat toolbarEnd = CGRectGetMaxY(self.toolbar.frame);
    CGFloat totalWidth = CGRectGetWidth(self.view.frame);
    // CGFloat previewStart = CGRectGetMinY([self imageViewAtIndex:0].frame);
    CGFloat previewStart = CGRectGetMinY(self.filterScrl.frame);
    CGRect scrollViewRect = CGRectMake(0,
                                       toolbarEnd,
                                       totalWidth,
                                       previewStart - toolbarEnd - PHOTO_EDIT_VERTICAL_PAD);
    
    
    UIImage* image = [self displayImageFromParams];
    
    
    WFZoomView* scrollView = [[WFZoomView alloc] initWithImage:image andFrame:scrollViewRect];
    
    [self.view addSubview:scrollView];
    scrollView.frame = scrollViewRect;
    self.mainPreview = scrollView.imageView;
    self.scrollView = scrollView;
    
    self.image = image;
}

- (UIImageView*)imageViewWithFrame:(CGRect)frame
{
    UIImageView* imgView = [[UIImageView alloc] initWithFrame:frame];
    imgView.contentMode = UIViewContentModeScaleAspectFill;
    imgView.clipsToBounds = YES;
    imgView.layer.borderColor = WYLD_RED.CGColor;
    imgView.layer.borderWidth = 0.0f;
    imgView.userInteractionEnabled = YES;
    
    UIButton* clearOverlay = [[UIButton alloc] initWithFrame:imgView.bounds];
    [clearOverlay addTarget:self action:@selector(selectedImageView:) forControlEvents:UIControlEventTouchUpInside];
    [imgView addSubview:clearOverlay];
    
    [self.filterScrl addSubview:imgView];
    return imgView;
}

- (UILabel*)labelInRect:(CGRect)frame withText:(NSString*)text color:(UIColor*)color font:(UIFont*)font
{
    UILabel* label = [[UILabel alloc] initWithFrame:frame];
    
    label.text = text;
    label.textColor = color;
    label.font = font;
    label.textAlignment = NSTextAlignmentCenter;
    label.alpha = 1.0;
    
    [self.filterScrl addSubview:label];
    return label;
}

#pragma mark - UIScrollView delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([scrollView isEqual:self.filterScrl]) {
        [UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationOptionTransitionCrossDissolve
                         animations:^{
                             self.rightArrow.alpha = 0.0;
                         } completion:^(BOOL finished) {
                             //
                         }];
    }
}

#pragma mark Accessing Properties

- (UIImageView*)imageViewAtIndex:(int)index
{
    return [self itemInArray:self.imageViews AtIndex:index];
}

- (UILabel*)labelAtIndex:(int)index
{
    return [self itemInArray:self.labels AtIndex:index];
}

- (id)itemInArray:(NSArray*)array AtIndex:(int)index
{
    if (array.count > index) {
        return array[index];
    } else {
        return nil;
    }
}

#pragma mark Displaying Images

- (UIImage*)displayImageFromParams
{
    UIImage* image = self.params[@"fullImage"];
    
    for (int i = 0; i < [self.filterAry count]; i++) {
        UIImageView* imageView = [self imageViewAtIndex:i];
        imageView.image = image;
    }
    return image;
}

- (void)displayImages:(NSArray*)images
{
    if (images.count < [self.filterAry count]) return;
    
    for (int i = 0; i < [self.filterAry count]; i++) {
        UIImageView* imageView = [self imageViewAtIndex:i];
        imageView.image = images[i];
    }
    
    self.currentSelection = [self imageViewAtIndex:0];
}

- (void)setCurrentSelection:(UIImageView*)currentSelection
{
    UIImageView* lastSelection = self.currentSelection;
    lastSelection.layer.borderWidth = 0;
    
    _currentSelection = currentSelection;
    currentSelection.layer.borderWidth = 2.0f;
    self.mainPreview.image = currentSelection.image;
}

#pragma mark Edit Photos

- (GPUImageToneCurveFilter*)filterWithName:(NSString*)name
{
    return [[GPUImageToneCurveFilter alloc] initWithACV:name];
}

- (NSArray*)filters
{
    NSMutableArray *result = [NSMutableArray array];
    for (NSString *filterName in self.filterAry) {
        [result addObject:[self filterWithName:filterName]];
    }
    
    return result;
}

- (void)intialEditOfPhotos
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage* imageToFilter = [[[GPUImageGrayscaleFilter alloc] init] imageByFilteringImage:self.image];
        
        NSArray* filters = [self filters];
        
        NSMutableArray *images = [NSMutableArray array];
        for (GPUImageFilter *filterItem in filters) {
            [images addObject:[filterItem imageByFilteringImage:imageToFilter]];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self displayImages:images];
            self.doneWithIntialEdit = YES;
            [self hideBlockingActivity];
        });
    });
}

#pragma mark Actions

- (void)onNext:(id)sender
{
    // Crop scaled version with crop rectangle
    WFZoomView *contentScrollView = self.scrollView;
    
    UIGraphicsBeginImageContextWithOptions(contentScrollView.bounds.size,
                                           YES,
                                           [UIScreen mainScreen].scale);
//    CGPoint offset=contentScrollView.contentOffset;
//    CGContextTranslateCTM(UIGraphicsGetCurrentContext(), -offset.x, -offset.y);
//    
    [self.scrollView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *visibleScrollViewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    MBProgressHUD* hud = [self showBlockingActivity];
    hud.labelText = @"Uploading...";
    [[APIClient sharedClient] uploadImage:visibleScrollViewImage
        type:0 success:^{
            [self hideBlockingActivity];
            // In new account registering mode we ask for the additional photos
            if (self.params[@"_edit"]) {
                [self.navigationController popToViewController:self.params[@"_edit"] animated:YES];
            } else if (self.params[@"_main"]) {
                [WFCore showViewController:self name:@"Album" mode:nil params:@{ @"_multiple": @1 }];
            } else {
                // Return to the personal profile screen
                [WFCore showViewController:self name:@"Profile" mode:nil params:nil];
            }
        } failure:^{
            [self hideBlockingActivity];
            [WFCore showAlert:@"Your image upload failed" msg:@"Please check your Internet connection or try again later." delegate:nil confirmHandler:nil];
        }];
}

- (void)selectedImageView:(UIButton *)buttonOverlay
{
    self.currentSelection = (UIImageView*)buttonOverlay.superview;

    [self.toolbar addSubview:self.toolbarNext];
}

@end
