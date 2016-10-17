//
//  BrowseCardView.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/18/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIView+util.h"
#import "InfoUnderlay.h"
#import "Account.h"
#import "WFButton.h"

@class BrowseCardView;

@protocol CardDelegateProtocol <NSObject>
@optional
    - (void)cardRequestedPrevious;
    - (void)cardWasHinted:(BrowseCardView*)card;
    - (void)cardWasLiked:(BrowseCardView*)card;
    - (void)cardWasPassed:(BrowseCardView*)card;
    - (void)cardLikeTapped:(BrowseCardView*)card;
    - (void)cardPassTapped:(BrowseCardView*)card;
    - (void)trendingCardTapped:(BrowseCardView*)card;
@end

@interface BrowseCardView : UIView <UIScrollViewDelegate>

    @property (strong, nonatomic) NSDictionary* item;
    @property (strong, nonatomic) Account* account;

    @property (strong, nonatomic) UIImageView *image;

    @property (strong, nonatomic) InfoPaneView *info;
    @property (nonatomic, strong) UIButton* likeButton;
    @property (nonatomic, strong) UIButton* passButton;
    @property (nonatomic, strong) UIButton* rewindButton;
    @property (nonatomic, strong) UIView* overlay;
    @property (strong, nonatomic) UIPageControl* pageControl;
    @property (nonatomic) BOOL revealableInfo;
    @property (weak, nonatomic) id<CardDelegateProtocol> delegate;
    @property (nonatomic) BOOL myCard;
    @property (nonatomic) BOOL hinted;
    //Added by Yurii on 06/16/14
    @property (nonatomic) BOOL isFromNotebook;
    @property (nonatomic) BOOL isFromChat;

// User by Browse / Matches
- (void)addImageFromURLString:(NSString*)urlString;
- (void)loadOtherImages:(int)maxCount;
- (void)cardDidAppear;
- (void)updateHintCount;
- (void)resetViewPositionAndTransformations;

// Used by Profile
- (void)addImages:(NSArray*)images;
- (void)cropButtons;

//Overlays
- (void)addOverlayWithText:(NSString*)text color:(UIColor*)color;

+ (BrowseCardView *)cardForAccount:(Account*)account inBrowse:(BOOL)browse inTrending:(BOOL)trending inMatches:(BOOL)match;
+ (BrowseCardView *)cardForAccount:(Account*)account inBrowse:(BOOL)browse inTrending:(BOOL)trending inMatches:(BOOL)match inProfile:(BOOL)profile;

@end
