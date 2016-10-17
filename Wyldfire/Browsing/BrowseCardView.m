//
//  BrowseCardView.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/18/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "BrowseCardView.h"

@interface BrowseCardView () <UIGestureRecognizerDelegate>
    @property (nonatomic) BOOL isInBrowseMode;
    @property (nonatomic) BOOL isInMatchMode;
    @property (nonatomic) BOOL isInTrendingMode;
    @property (nonatomic) BOOL isInProfileMode;

    @property (strong, nonatomic) UIScrollView* imageScrollView;
    @property (strong, nonatomic) NSMutableArray* imageViews;
    @property (strong, nonatomic) InfoUnderlay* underlay;
    @property (strong, nonatomic) UIImageView* hintImageView;

    @property (atomic) BOOL animating;
    @property (atomic) BOOL revealed;
    @property (nonatomic, strong) UIImageView* revealableImageView;

    //Loading
    @property (atomic) BOOL imageLoaded;
    @property (atomic, strong) UIActivityIndicatorView* activity;

    //Gesture
    @property (strong, nonatomic) UIPanGestureRecognizer* pan;
    @property (nonatomic) CGPoint originalPoint;
@end

static CGFloat statusBarHeight;

@implementation BrowseCardView

#pragma mark Init

- (id)initWithFrame:(CGRect)frame andInBrowseMode:(BOOL)isInBrowseMode andInTrendingMode:(BOOL)trending
{
    self = [super initWithFrame:frame];
    if (self) {
        _isInBrowseMode = isInBrowseMode;
        _isInTrendingMode = trending;
        _isInProfileMode = NO;
        
        [self initializeAndStyle];
        [self setupInfo];
        [self setupScrollView];
        [self setupButtons:isInBrowseMode];
        if (isInBrowseMode) {
            [self setupArrows];
        }
        [self subscribeToNotifications];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame andInBrowseMode:(BOOL)isInBrowseMode andInTrendingMode:(BOOL)trending isInProfile:(BOOL)isInProfile isInMatchMode:(BOOL)isInMatch
{
    self = [super initWithFrame:frame];
    if (self) {
        _isInBrowseMode = isInBrowseMode;
        _isInTrendingMode = trending;
        _isInProfileMode = isInProfile;
        
        [self initializeAndStyle];
        [self setupInfo];
        [self setupScrollView];
        //Added by Yurii on 06/11/14
        if (isInMatch)
            [self setupButtons:isInBrowseMode];
        if (isInBrowseMode) {
            [self setupArrows];
        }
        [self subscribeToNotifications];
    }
    return self;
}

//Setup when card appears
- (void)setupGesture
{
    UIPanGestureRecognizer* pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    pan.delegate = self;
    self.pan = pan;
    [self.imageScrollView addGestureRecognizer:pan];
    self.originalPoint = self.center;
    self.userInteractionEnabled = NO;
}

- (void)pan:(UIPanGestureRecognizer*)gestureRecognizer
{
    if (self.likeButton.enabled) {
        self.likeButton.enabled = NO;
        [self.likeButton cancelTrackingWithEvent:nil];
        [self.likeButton setHighlighted:NO];
    }
    CGFloat xDistance = [gestureRecognizer translationInView:self].x;
    CGFloat yDistance = [gestureRecognizer translationInView:self].y;
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:{
            break;
        };
        case UIGestureRecognizerStateChanged:{
            CGFloat rotationStrength = MIN(xDistance / 320, 1);
            CGFloat rotationAngel = (CGFloat) (2*M_PI * rotationStrength / 16);
            CGFloat scaleStrength = 1 - fabsf(rotationStrength) / 4;
            CGFloat scale = MAX(scaleStrength, 0.93);
            self.center = CGPointMake(self.originalPoint.x + xDistance, self.originalPoint.y + yDistance);
            CGAffineTransform transform = CGAffineTransformMakeRotation(rotationAngel);
            CGAffineTransform scaleTransform = CGAffineTransformScale(transform, scale, scale);
            self.transform = scaleTransform;
            [self updateOverlay:xDistance];
            
            break;
        };
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            if (xDistance < -100) {
                [self passGesture];
            } else if (xDistance > 100) {
                [self likeGesture];
            } else {
                [self resetViewPositionAndTransformations];
            }
            break;
        };
        case UIGestureRecognizerStatePossible:break;
        case UIGestureRecognizerStateFailed:break;
    }
}

- (void)resetViewPositionAndTransformations
{
    self.likeButton.enabled = [self hintCount] > 0;
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.transform = CGAffineTransformIdentity;
                         
                         CGRect cardFrame = CARD_FRAME;
                         if (statusBarHeight > 20) {
                             cardFrame.size.height -= 20;
                         }
                         self.frame = cardFrame;
                         
                         self.overlay.alpha = 0;
                     }];
}

- (void)initializeAndStyle
{
    self.backgroundColor = [UIColor whiteColor];
    //self.layer.borderWidth = 0.5f;
    //self.layer.borderColor = GRAY_7.CGColor;
    self.imageViews = [NSMutableArray new];
    _imageLoaded = NO;
    
    _activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    _activity.hidesWhenStopped = YES;
    _activity.hidden = YES;
    _activity.layer.backgroundColor = [[UIColor colorWithWhite:0.0f alpha:0.4f] CGColor];
    _activity.frame = CGRectMake(0, 0, 64, 64);
    _activity.layer.masksToBounds = YES;
    _activity.layer.cornerRadius = 8;
}

- (void)setupScrollView
{
    UIScrollView* scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0,
                                                                              CARD_WIDTH, PROFILE_IMAGE_HEIGHT)];
    
    scrollView.pagingEnabled = YES;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.delegate = self;
    
    scrollView.backgroundColor = GRAY_8;
    
    self.imageScrollView = scrollView;
    [self addSubview:scrollView];
    
    //Page Control
    CGRect pageControlFrame = CGRectMake(0,
                                         PROFILE_IMAGE_HEIGHT - 40,
                                         CARD_WIDTH,
                                         40);
    UIPageControl* pageControl = [[UIPageControl alloc] initWithFrame:pageControlFrame];
    pageControl.alpha = 0;
    pageControl.pageIndicatorTintColor = [UIColor darkGrayColor];
    pageControl.currentPageIndicatorTintColor = WYLD_BLUE;
    
    self.pageControl = pageControl;
    [self addSubview:pageControl];
}

- (UIImageView*)imageView
{
    UIImageView* imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CARD_WIDTH, PROFILE_IMAGE_HEIGHT)];
    imgView.contentMode = UIViewContentModeScaleAspectFill;
    imgView.clipsToBounds = YES;
    
    if (self.imageViews.count == 0) {
        UIImage* cornerImage = [UIImage imageNamed:@"topright_red_corner"];
        UIImageView *corner = [[UIImageView alloc] initWithImage:cornerImage];
        [WFCore addImageAtCorner:imgView image:corner corner:UIRectCornerTopRight];
    }
    //imgView.layer.borderColor = GRAY_7.CGColor;
    //imgView.layer.borderWidth = 0.5f;
    
    return imgView;
}

- (CGRect)infoRect
{
    if (self.isInProfileMode)
        return CGRectMake(0, (382 - (TALL_SCREEN ? 0 : 88) - (statusBarHeight > 20 ? 20 : 0)),
                          CARD_WIDTH,
                          CARD_HEIGHT - LIKE_BUTTON_HEIGHT - (382 - (TALL_SCREEN ? 0 : 88) - (statusBarHeight > 20 ? 20 : 0)) + 0.5);
    return CGRectMake(0, PROFILE_IMAGE_HEIGHT,
                      CARD_WIDTH,
                      CARD_HEIGHT - (statusBarHeight > 20 && !self.isInTrendingMode  ? 20 : 0) - LIKE_BUTTON_HEIGHT - PROFILE_IMAGE_HEIGHT + 0.5);
}

- (void)setupInfoUnderlay
{
    InfoUnderlay* underlay = [[InfoUnderlay alloc] initWithFrame:[self infoRect]];
    underlay.backgroundColor = GRAY_1;
    [self addSubview:underlay];
    
    self.underlay = underlay;
}

- (void)setupInfo
{
    [self setupInfoUnderlay];
 
    self.info = [[InfoPaneView alloc] initWithFrame:[self infoRect]];
    self.info.icon1 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"away"]];
    self.info.icon1.frame = CGRectMake(0, 0, 16, 12);
    self.info.icon2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"feathers"]];
    self.info.icon2.frame = CGRectMake(0, 0, 16, 12);
    [self.info configure];
    
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(infoTapped)];
    [self.info addGestureRecognizer:tap];
    tap.delegate = self;
    
    UISwipeGestureRecognizer* swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(infoTapped)];
    [self.info addGestureRecognizer:swipe];
    swipe.direction = UISwipeGestureRecognizerDirectionLeft | UISwipeGestureRecognizerDirectionRight;
    swipe.delegate = self;
    
    self.info.userInteractionEnabled = NO;
    [self addSubview:self.info];
    
    self.info.layer.borderColor = GRAY_7.CGColor;
    self.info.layer.borderWidth = 0.5f;
}

- (void)setupArrows
{
    UIImage* leftImg = [UIImage imageNamed:@"pass"];
    UIImage* rightImg = [UIImage imageNamed:@"likedCard"];
    
    CGPoint leftOrigin = CGPointMake(5, self.imageScrollView.centerY - leftImg.size.height / 2);
    CGPoint rightOrigin = CGPointMake(self.right - rightImg.size.width - 13, self.imageScrollView.centerY - rightImg.size.height / 2);
    
    CGRect leftRect = { leftOrigin, leftImg.size };
    CGRect rightRect = { rightOrigin, rightImg.size };
    
    UIButton* leftButton = [[UIButton alloc] initWithFrame:leftRect];
    UIButton* rightButton = [[UIButton alloc] initWithFrame:rightRect];
    
    [leftButton setImage:leftImg forState:UIControlStateNormal];
    [rightButton setImage:rightImg forState:UIControlStateNormal];
    
    [self addSubview:leftButton];
    [self addSubview:rightButton];
    
    [leftButton addTarget:self action:@selector(passPressed) forControlEvents:UIControlEventTouchUpInside];
    [rightButton addTarget:self action:@selector(likePressed) forControlEvents:UIControlEventTouchUpInside];
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)setupButtons:(BOOL)isInBrowseMode
{
    float buttonHeight = LIKE_BUTTON_HEIGHT;
    float parentHeight = CARD_HEIGHT - (statusBarHeight > 20 && !self.isInTrendingMode  ? 20 : 0);
    float parentWidth = CARD_WIDTH;
    
    if (isInBrowseMode) {
        UIImageView* hintImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hint"]];
        CGRect hintImageFrame = CGRectMake(92, (parentHeight - buttonHeight) + (buttonHeight - 18) / 2, 18, 18);
        hintImageView.frame = hintImageFrame;
        self.hintImageView = hintImageView;
        
        CGRect buttonFrame = CGRectMake(0,
                                        parentHeight - buttonHeight,
                                        parentWidth,
                                        buttonHeight);
        
        self.likeButton = [self buttonWithTitle:@""
                                          frame:buttonFrame
                                          color:WYLD_BLUE
                                      andTarget:@"hintPressed"];
        [self.likeButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 30.0f, 0.0f, 0.0f)];
        ((WFButton*)self.likeButton).hintImageView = hintImageView;
        [self updateHintCount];
        self.likeButton.backgroundColor = nil;
        
        
        CGRect rewindRect = CGRectMake(0, parentHeight - buttonHeight, 50, LIKE_BUTTON_HEIGHT);
        UIButton* rewindButton = [[UIButton alloc] initWithFrame:rewindRect];
        [rewindButton setImage:[UIImage imageNamed:@"rewind"] forState:UIControlStateNormal];
        [rewindButton addTarget:self action:@selector(rewindPressed) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:rewindButton];
        
        [self addSubview:hintImageView];
        self.rewindButton = rewindButton;
    } else {
        CGRect buttonFrame = CGRectMake(0,
                                        parentHeight - buttonHeight,
                                        parentWidth / 2,
                                        buttonHeight);
        self.passButton = [self buttonWithTitle:@"Burn"
                                          frame:buttonFrame
                                          color:WYLD_RED
                                      andTarget:@"passPressed"];
        CGRect likeFrame = CGRectOffset(buttonFrame, parentWidth / 2 - 0.5, 0);
        likeFrame = CGRectMake(likeFrame.origin.x, likeFrame.origin.y, likeFrame.size.width + 0.5, likeFrame.size.height);
        self.likeButton = [self buttonWithTitle:@"Chat"
                                          frame:likeFrame
                                          color:WYLD_BLUE
                                      andTarget:@"likePressed"];
    }
}

- (void)repositionElements
{
    //Added by Yurii on 06/16/14
    if (!self.isInBrowseMode && self.isInProfileMode)
        return;
    CGRect cardFrame = CARD_FRAME;
    if (statusBarHeight > 20) {
        cardFrame.size.height -= 20;
    }
    self.frame = cardFrame;
    self.info.frame = [self infoRect];
    
    float buttonHeight = LIKE_BUTTON_HEIGHT;
    float parentHeight = CARD_HEIGHT - (statusBarHeight > 20 ? 20 : 0);
    float parentWidth = CARD_WIDTH;
    
    if (self.isInBrowseMode) {
        CGRect hintImageFrame = CGRectMake(92, (parentHeight - buttonHeight) + (buttonHeight - 18) / 2, 18, 18);
        self.hintImageView.frame = hintImageFrame;
        
        CGRect buttonFrame = CGRectMake(0,
                                        parentHeight - buttonHeight,
                                        parentWidth,
                                        buttonHeight);
        self.likeButton.frame = buttonFrame;
        
        CGRect rewindRect = CGRectMake(0, parentHeight - buttonHeight, 50, LIKE_BUTTON_HEIGHT);
        self.rewindButton.frame = rewindRect;
    } else if (!self.isInProfileMode) { //This is not Profile View in Chat ViewController Replaced by Yurii
        CGRect buttonFrame = CGRectMake(0,
                                        parentHeight - buttonHeight,
                                        parentWidth / 2,
                                        buttonHeight);
        self.passButton.frame = buttonFrame;
        CGRect likeFrame = CGRectOffset(buttonFrame, parentWidth / 2 - 0.5, 0);
        self.likeButton.frame = likeFrame;
    }
    
    self.underlay.frame = [self infoRect];
    self.revealed = NO;
    self.animating = NO;
    
    self.imageScrollView.frame = CGRectMake(0, 0,
                                            CARD_WIDTH, PROFILE_IMAGE_HEIGHT);
    self.pageControl.frame =  CGRectMake(0,
                                         PROFILE_IMAGE_HEIGHT - 40,
                                         CARD_WIDTH,
                                         40);
    [self reloadAllImages];
}

- (UIButton*)buttonWithTitle:(NSString*)title frame:(CGRect)frame color:(UIColor*)color andTarget:(NSString*)selectorString
{
    WFButton* button = [WFButton buttonWithType:UIButtonTypeCustom];
    
    button.frame = frame;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:color forState:UIControlStateNormal];
    button.layer.borderColor = GRAY_7.CGColor;
    button.layer.borderWidth = 0.5f;
    
    [button.titleLabel setFont:[UIFont fontWithName:MAIN_FONT size:17]];
    [button addTarget:self
               action:NSSelectorFromString(selectorString)
     forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:button];
    return button;
}

- (void)addOverlayWithText:(NSString*)text color:(UIColor*)color
{
    [self.overlay removeFromSuperview];
    self.overlay = nil;
    
    UIView* overlay = [[UIView alloc] initWithFrame:self.imageScrollView.bounds];
    overlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
    
    
    CGFloat labelHeight = CARD_OVERLAY_FONTSIZE + 5;
    CGRect labelRect = CGRectMake(0,
                                  (self.imageScrollView.height - labelHeight) / 2,
                                  self.width,
                                  labelHeight);
    UILabel* label = [[UILabel alloc] initWithFrame:labelRect];
    label.tag = 123;
    [label setFont:CARD_OVERLAY_FONT];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setText:text];
    [label setTextColor:color];
    
    //overlay.layer.zPosition = 100;
    [overlay addSubview:label];
    [self.imageScrollView addSubview:overlay];
    self.overlay = overlay;
    
    if ([[text lowercaseString] isEqualToString:@"hint!"]) {
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeOverlay)];
        [overlay addGestureRecognizer:tap];
    }
}

- (void)removeOverlay
{
    [self.overlay removeFromSuperview];
    self.overlay = nil;
}

- (void)updateOverlay:(CGFloat)distance
{
    BOOL leftward = distance < 0;
    NSString* text = leftward ? @"PASS" : @"LIKE";
    UIColor* color = leftward ? [UIColor whiteColor] : WYLD_RED;
    
    if (!self.overlay) {
        [self addOverlayWithText:text color:color];
    } else {
        UILabel* label = (UILabel*)[self.overlay viewWithTag:123];
        [label setFont:CARD_OVERLAY_FONT];
        [label setTextColor:color];
        [label setText:text];
    }
    
    CGFloat overlayStrength = MIN(fabsf(distance) / 50., 1.0);
    self.overlay.alpha = overlayStrength;
}


#pragma mark Notifications

- (void)subscribeToNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadImages:)
                                                 name:NOTIFICATION_UPDATED_ACCOUNT_PHOTOS
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resize:) name:UIApplicationWillChangeStatusBarFrameNotification object:nil];
}

- (void)resize:(NSNotification*)notification
{
    CGRect statusBarFrame = [((NSValue*)notification.userInfo[UIApplicationStatusBarFrameUserInfoKey]) CGRectValue];
    
    statusBarHeight = statusBarFrame.size.height;
    self.clipsToBounds = YES;
    
    if (self.isInMatchMode || self.isInBrowseMode) {
        [UIView animateWithDuration:0.2 delay:0.0 options:0
                         animations:^{
                             [self repositionElements];
                         } completion:nil];
    }
}

- (void)reloadImages:(NSNotification*)notification
{
    if (self.myCard) {
        [self reloadAllImages];
    }
}

- (void)reloadAllImages
{
    if (self.imageLoaded) {
        CGPoint offset = self.imageScrollView.contentOffset;
        
        NSMutableArray* images = [NSMutableArray new];

        //Matches images order is different
        if (self.isInMatchMode) {
            [images addObjectsFromArray:self.account.allProfileImages];
            
            if (self.account.showcasePhoto != nil) {
                [images addObject:self.account.showcasePhoto];
            }
        } else {
            if (self.account.showcasePhoto != nil) {
                [images addObject:self.account.showcasePhoto];
            }
            
            if (!self.isInBrowseMode)
                [images addObjectsFromArray:self.account.allProfileImages];
        }
    
        [self updateCardWithBlock:^{
            [self clearImages];
            [self addImages:images];
            self.imageScrollView.contentOffset = offset;
            [self scrollViewDidEndDecelerating:self.imageScrollView];
            
            if (self.account.avatarPhoto != nil) {
                self.info.icon.image = self.account.avatarPhoto;
            }
            [self.imageScrollView bringSubviewToFront:self.overlay];
        } shouldAnimate:NO];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Loading Images

- (void)showActivityInView:(UIView*)view
{
    if (_activity.superview) return;
    [view addSubview:_activity];
    _activity.center = view.center;
    _activity.hidden = NO;
    [_activity startAnimating];
}

- (void)hideActivity
{
    [_activity stopAnimating];
    [_activity removeFromSuperview];
}

- (void)cardDidAppear
{
    self.userInteractionEnabled = YES;
    if (!self.imageLoaded) {
        [self showActivityInView:self.imageScrollView];
    }
}

- (int)hintCount
{
    return 3 - [GVUserDefaults standardUserDefaults].hintsToday;
}

- (void)updateHintCount
{
    int hintCount = [self hintCount];
    if (hintCount < 0) hintCount = 0;
    NSString* buttonTitle = [NSString stringWithFormat:@"Send Hint (%i)", hintCount];
    [self.likeButton setTitle:buttonTitle forState:UIControlStateNormal];
    
    if (hintCount < 1) {
        [self.likeButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        self.likeButton.enabled = NO;
        self.hintImageView.image = [UIImage imageNamed:@"hintDisabled"];
    }
}

- (void)addImageFromURLString:(NSString*)urlString
{
    [self addImageFromURLString:urlString updateScrollView:YES];
}

- (void)addImageFromURLString:(NSString*)urlString updateScrollView:(BOOL)update
{
    UIImageView* imgView = [self imageView];
    
    [self.imageViews addObject:imgView];
    
    [[APIClient sharedClient] downloadImage:urlString success:^(UIImage *image, NSString *url) {
        self.imageLoaded = YES;
        [self hideActivity];
        imgView.image = image;
        imgView.alpha = 0.0;
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionTransitionCrossDissolve
                         animations:^{
                             imgView.alpha = 1.0;
                         } completion:nil];
    } failure:^(NSInteger code) {
        self.imageLoaded = YES;
        [self hideActivity];
    }];
    
    if (update) [self updateScrollview];
}

- (void)clearImages
{
    [self.imageViews removeAllObjects];
    [self updateScrollview];
}

- (void)addImages:(NSArray*)images
{
    for (UIImage* image in images) {
        UIImageView* imgView = [self imageView];
        
        [self.imageViews addObject:imgView];
        imgView.image = image;
    }
    
    [self updateScrollview];
}

- (void)updateScrollview
{
    NSInteger numberOfImages = self.imageViews.count;
    
    [self.imageScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.imageScrollView setContentSize:CGSizeMake(CARD_WIDTH * numberOfImages, PROFILE_IMAGE_HEIGHT)];
    
    for (int i = 0; i < numberOfImages; i++) {
        UIImageView* imgView = self.imageViews[i];
        
        CGRect frame = CGRectMake(i * CARD_WIDTH,
                                  0,
                                  CARD_WIDTH,
                                  PROFILE_IMAGE_HEIGHT);
        imgView.frame = frame;
        [self.imageScrollView addSubview:imgView];
        if (i==0) [imgView maskTopRightTriangle:32.5];
    }
    
    self.pageControl.numberOfPages = numberOfImages;
    self.pageControl.currentPage = 0;
    self.pageControl.alpha = (numberOfImages > 1 ? 1.0f : 0.0f);
    
    [self.imageScrollView bringSubviewToFront:self.overlay];
}

- (void)loadOtherImages:(int)maxCount
{
    NSArray *iconURLs = [WFCore listNumbered:self.item name:@"icon"];
    
    for (int count = 1; count <= maxCount && count < iconURLs.count; count++) {
        NSString* iconURL = iconURLs[count];
        [self addImageFromURLString:iconURL updateScrollView:NO];
    }
    
    //Only do this once after loading all imageViews
    [self updateScrollview];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    int page = scrollView.contentOffset.x / CARD_WIDTH;
    self.pageControl.currentPage = page;
}

#pragma mark Actions

- (void)cropButtons
{
    self.bounds = self.frame = CGRectMake(0, 0, CARD_WIDTH, CARD_HEIGHT - (statusBarHeight && !self.isInTrendingMode > 20 ? 20 : 0) - LIKE_BUTTON_HEIGHT);
}

- (void)passPressed
{
    [self.delegate cardPassTapped:self];
}

- (void)likePressed
{
    [self.delegate cardLikeTapped:self];
}

- (void)passGesture
{
    [self.delegate cardWasPassed:self];
}

- (void)likeGesture
{
    [self.delegate cardWasLiked:self];
}

- (void)hintPressed
{
    int hintCount = [self hintCount];
    if (hintCount > 0) {
        [self.delegate cardWasHinted:self];
    } else {
        //No hints left
    }
}

- (void)rewindPressed
{
    [self.delegate cardRequestedPrevious];
}

- (void)trending
{
    [self.delegate trendingCardTapped:self];
}

- (void)setRevealableInfo:(BOOL)revealableInfo
{
    _revealableInfo = revealableInfo;
    
    //return;
    self.info.userInteractionEnabled = revealableInfo;
    
    if (revealableInfo) {
        UIImageView* revealableImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrowDrawer"]];
        CGRect nameRect = self.info.name.frame;
        revealableImageView.frame = CGRectMake(CARD_WIDTH - 20, nameRect.origin.y + 5,
                                               8, 13);
        [self.info addSubview:revealableImageView];
        self.revealableImageView = revealableImageView;
    } else {
        [self.revealableImageView removeFromSuperview];
    }
}

- (void)infoTapped
{
    //Added by Yurii on 11/06/14
    if (!self.isFromNotebook)
        return;
    if (self.revealableInfo)
        [self revealInfo: ! self.revealed];
}

- (void)revealInfo:(BOOL)reveal
{
    if (!self.animating) {
        self.animating = YES;
        CGFloat revealAmount = 240;
        
        [UIView animateWithDuration:0.5 delay:0.0
             usingSpringWithDamping:0.5 initialSpringVelocity:1 options:0
                         animations:^{
                             self.info.frame = CGRectOffset(self.info.frame,
                                                            (reveal ?  revealAmount
                                                                    : -revealAmount),
                                                            0);
                         } completion:^(BOOL finished) {
                             if (finished) {
                                 self.animating = NO;
                                 self.revealed = reveal;
                             }
                         }];
    }
}

#pragma mark Class Methods

- (void)updateCardWithBlock:(GenericBlock)block shouldAnimate:(BOOL)shouldAnimate
{
    //Update card on main queue, ensure the card is onscreen
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        //if (self.window != nil) {
            
            if (shouldAnimate) {
                [UIView transitionWithView:self duration:0.25 options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{
                                    block();
                                    
                                } completion:^(BOOL finished) {
                                    [self.imageScrollView bringSubviewToFront:self.overlay];
                                    [self bringSubviewToFront:self.overlay];
                                }];
            } else {
                block();
                [self.imageScrollView bringSubviewToFront:self.overlay];
                [self bringSubviewToFront:self.overlay];
            }
        //}
    });
}

+ (BrowseCardView *)cardForAccount:(Account*)account inBrowse:(BOOL)browse inTrending:(BOOL)trending inMatches:(BOOL)match
{
    if (statusBarHeight == 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillChangeStatusBarFrameNotification
                                                            object:nil
                                                          userInfo:@{UIApplicationStatusBarFrameUserInfoKey : [NSValue valueWithCGRect:[[UIApplication sharedApplication] statusBarFrame]]}];
    }
    
    CGRect cardFrame = CARD_FRAME;
    if (statusBarHeight > 20 && !trending) {
        cardFrame.size.height -= 20;
    }
    BrowseCardView* card = [[BrowseCardView alloc] initWithFrame:cardFrame andInBrowseMode:browse andInTrendingMode:trending];
    card.isInMatchMode = match;
    card.account = account;
    card.hinted = NO;
    
    //Card's Main Photos--------------------------------------------------------------------
    
    //-- Main Photo
    if (browse || trending || match) {
        int mainImage = (match ? 2 : 0);
        [[APIClient sharedClient] getAccountImageOfType:mainImage
                                         account:account.accountID
                                                success:^(UIImage *image, NSString *url) {
                                                    [account setImage:image forType:mainImage];
                                                    card.imageLoaded = YES;
                                                    
                                                    [card reloadAllImages];
                                                    [card hideActivity];
                                                    if (card.hinted) {
                                                        [card addOverlayWithText:@"HINT!" color:WYLD_BLUE];
                                                        [card bringSubviewToFront:card.overlay];
                                                        //[card.imageScrollView bringSubviewToFront:card.overlay];
                                                    }
                                                } failure:nil];
    } else {
        card.imageLoaded = YES;
        [card reloadAllImages];
    }
    
    //-- Additional Photos
    if (trending || match) {
        for (int i = 0; i < 4; i++) {
            int type = i + 2;
            
            if (match && i == 0) type = 0;
            
            [[APIClient sharedClient] getAccountImageOfType:type
                                             account:account.accountID
                                                    success:^(UIImage *image, NSString *url) {
                                                        [account setImage:image forType:type];
                                                        [card reloadAllImages];
                                                    } failure:nil];
        }
    }
    
    //Card's Info Panel--------------------------------------------------------------------
    
    //-- Name
    NSString* nameText = [NSString stringWithFormat:@"%@, %i", account.alias, account.age];
    card.info.name.text = nameText;
    
    //-- Hide until data loaded
    card.info.icon1.alpha = 0.0;
    card.info.icon2.alpha = 0.0;
    
    //Distance
    if (browse || match || trending) {
        [[APIClient sharedClient] getUserAccount:account.accountID obj:account
                                         success:^(Account *account, NSDictionary *json) {
                                             card.underlay.account = account;
                                             [card updateCardWithBlock:^{
                                                 NSString* distanceString = [NSString stringWithFormat:@"%imi away", account.distance];
                                                 
                                                 card.info.info1.text = distanceString;
                                                 card.info.icon1.alpha = 1.0;
                                             } shouldAnimate:YES];
                                             
                                             //Mutual Friends
                                             [FacebookUtility getMutualFriends:account.facebookID
                                                                       success:^(NSArray* list) {
                                                                           [card updateCardWithBlock:^{
                                                                               NSString* connectionsString = [NSString stringWithFormat:@"%i Mutual Friend%@", (int)list.count, ((int)list.count == 1 ? @"" : @"s")];
                                                                               card.info.info2.text = connectionsString;
                                                                               
                                                                               card.info.icon2.alpha = 1.0;
                                                                           } shouldAnimate:YES];
                                                                       } failure:^(NSInteger code) {
                                                                           //
                                                                       }];
                                         } failure:nil];
    }
    
    //Avatar Photo
    if (account.avatarPhoto != nil) {
        card.info.icon.image = account.avatarPhoto;
    } else {
        [[APIClient sharedClient] getAccountImageOfType:1
             account:account.accountID
                    success:^(UIImage *image, NSString *url) {
                        [card updateCardWithBlock:^{
                            card.info.icon.image = image;
                            [account setImage:image forType:1];
                        } shouldAnimate:YES];
                    }
                    failure:nil];
    }
    
    //Check if Hinted
    if (browse) {
        [card setupGesture];
        
        [[APIClient sharedClient] checkIfHintedbyUser:account
                                              success:^(BOOL connectionExists) {
                                                  if (connectionExists) {
                                                      card.hinted = YES;
                                                      [card updateCardWithBlock:^{
                                                          if (card.overlay == nil)
                                                              [card addOverlayWithText:@"HINT!" color:WYLD_BLUE];
                                                      } shouldAnimate:YES];
                                                  }
                                              } failure:nil];
    }
    
    if (trending) {
        [card cropButtons];
    }
    
    return card;
}

+ (BrowseCardView *)cardForAccount:(Account*)account inBrowse:(BOOL)browse inTrending:(BOOL)trending inMatches:(BOOL)match inProfile:(BOOL)profile
{
    if (statusBarHeight == 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillChangeStatusBarFrameNotification
                                                            object:nil
                                                          userInfo:@{UIApplicationStatusBarFrameUserInfoKey : [NSValue valueWithCGRect:[[UIApplication sharedApplication] statusBarFrame]]}];
    }
    
    CGRect cardFrame = CARD_FRAME;
    
    BrowseCardView* card = [[BrowseCardView alloc] initWithFrame:cardFrame andInBrowseMode:browse andInTrendingMode:trending isInProfile:profile isInMatchMode:match]; //Replaced by Yurii (Parameters are chagned)
    card.isInMatchMode = match;
    card.account = account;
    card.hinted = NO;
    
    //Card's Main Photos--------------------------------------------------------------------
    
    //-- Main Photo
    if (browse || trending || match) {
        int mainImage = (match ? 2 : 0);
        [[APIClient sharedClient] getAccountImageOfType:mainImage
                                         account:account.accountID
                                                success:^(UIImage *image, NSString *url) {
                                                    [account setImage:image forType:mainImage];
                                                    card.imageLoaded = YES;
                                                    
                                                    [card reloadAllImages];
                                                    [card hideActivity];
                                                    if (card.hinted) {
                                                        [card addOverlayWithText:@"HINT!" color:WYLD_BLUE];
                                                        [card bringSubviewToFront:card.overlay];
                                                        //[card.imageScrollView bringSubviewToFront:card.overlay];
                                                    }
                                                } failure:nil];
    } else {
        card.imageLoaded = YES;
        [card reloadAllImages];
    }
    
    //-- Additional Photos
    if (trending || match) {
        for (int i = 0; i < 4; i++) {
            int type = i + 2;
            
            if (match && i == 0) type = 0;
            
            [[APIClient sharedClient] getAccountImageOfType:type
                                             account:account.accountID
                                                    success:^(UIImage *image, NSString *url) {
                                                        [account setImage:image forType:type];
                                                        [card reloadAllImages];
                                                    } failure:nil];
        }
    }
    
    //Card's Info Panel--------------------------------------------------------------------
    
    //-- Name
    NSString* nameText = [NSString stringWithFormat:@"%@, %i", account.alias, account.age];
    card.info.name.text = nameText;
    
    //-- Hide until data loaded
    card.info.icon1.alpha = 0.0;
    card.info.icon2.alpha = 0.0;
    
    //Distance
    if (browse || match || trending) {
        [[APIClient sharedClient] getUserAccount:account.accountID obj:account
                                         success:^(Account *account, NSDictionary *json) {
                                             card.underlay.account = account;
                                             [card updateCardWithBlock:^{
                                                 NSString* distanceString = [NSString stringWithFormat:@"%imi away", account.distance];
                                                 
                                                 card.info.info1.text = distanceString;
                                                 card.info.icon1.alpha = 1.0;
                                             } shouldAnimate:YES];
                                             
                                             //Mutual Friends
                                             [FacebookUtility getMutualFriends:account.facebookID
                                                                       success:^(NSArray* list) {
                                                                           [card updateCardWithBlock:^{
                                                                               NSString* connectionsString = [NSString stringWithFormat:@"%i Mutual Friend%@", (int)list.count, ((int)list.count == 1 ? @"" : @"s")];
                                                                               card.info.info2.text = connectionsString;
                                                                               
                                                                               card.info.icon2.alpha = 1.0;
                                                                           } shouldAnimate:YES];
                                                                       } failure:^(NSInteger code) {
                                                                           //
                                                                       }];
                                         } failure:nil];
    }
    
    //Avatar Photo
    if (account.avatarPhoto != nil) {
        card.info.icon.image = account.avatarPhoto;
    } else {
        [[APIClient sharedClient] getAccountImageOfType:1
                                         account:account.accountID
                                                success:^(UIImage *image, NSString *url) {
                                                    [card updateCardWithBlock:^{
                                                        card.info.icon.image = image;
                                                        [account setImage:image forType:1];
                                                    } shouldAnimate:YES];
                                                }
                                                failure:nil];
    }
    
    //Check if Hinted
    if (browse) {
        [card setupGesture];
        
        [[APIClient sharedClient] checkIfHintedbyUser:account
                                              success:^(BOOL connectionExists) {
                                                  if (connectionExists) {
                                                      card.hinted = YES;
                                                      [card updateCardWithBlock:^{
                                                          if (card.overlay == nil)
                                                              [card addOverlayWithText:@"HINT!" color:WYLD_BLUE];
                                                      } shouldAnimate:YES];
                                                  }
                                              } failure:nil];
    }
    
    if (trending) {
        [card cropButtons];
    }
    
    return card;
}

@end
