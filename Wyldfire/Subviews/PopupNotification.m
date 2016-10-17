//
//  PopupNotification.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 5/7/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "PopupNotification.h"

@interface PopupNotification () <UIGestureRecognizerDelegate>
    // Gestures
    @property (nonatomic, strong) UISwipeGestureRecognizer* gesture;
    @property (nonatomic, strong) UITapGestureRecognizer* tap;

    // UI Control
    @property (nonatomic, weak) UINavigationController* navController;
    @property (nonatomic, strong) UIWindow* window;

    // Actions
    @property (nonatomic, strong) NSString* action;
@end

static int popupsOnscreen = 0;

@implementation PopupNotification

- (instancetype)initWithFrame:(CGRect)frame title:(NSString*)title subtitle:(NSString*)subtitle
{
    self = [super initWithFrame:frame];
    if (self) {
        [self style];
        [self addTitle:title];
        [self addSubtitle:subtitle];
        [self setupGesture];
    }
    return self;
}

- (void)style
{
    self.backgroundColor = WYLD_RED;
}

- (void)addTitle:(NSString*)title
{
    CGRect rect = CGRectMake(TITLE_INDENT, 13, self.width - TITLE_INDENT * 2, TITLE_FONTSIZE + 4);
    self.label = [self addLabelInRect:rect withText:title andFontSize:TITLE_FONTSIZE];
}

- (void)addSubtitle:(NSString*)subtitle
{
    CGRect rect = CGRectMake(TITLE_INDENT, 37, self.width - TITLE_INDENT * 2, SUBTITLE_FONTSIZE + 2);
    self.subLabel = [self addLabelInRect:rect withText:subtitle andFontSize:SUBTITLE_FONTSIZE];
}

- (UILabel*)addLabelInRect:(CGRect)rect withText:(NSString*)text andFontSize:(CGFloat)fontsize
{
    UILabel* label = [UILabel labelInRect:rect withText:text color:[UIColor whiteColor] fontSize:fontsize];
    label.textAlignment = NSTextAlignmentLeft;
    label.adjustsFontSizeToFitWidth = YES;
    
    [self addSubview:label];
    return label;
}

- (void)setupGesture
{
    UISwipeGestureRecognizer* swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    swipe.direction = UISwipeGestureRecognizerDirectionUp;
    swipe.delegate = self;
    
    [self addGestureRecognizer:swipe];
    self.gesture = swipe;
    
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tap.delegate = self;
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    [tap requireGestureRecognizerToFail:swipe];
    
    [self addGestureRecognizer:tap];
    self.tap = tap;
}

- (void)handleSwipe:(UISwipeGestureRecognizer*)recognizer
{
    [self hide];
}

- (void)handleTap:(UITapGestureRecognizer*)tap
{
    [self performAction];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)performAction
{
    [self hide];
}

- (void)hide
{
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.frame = CGRectOffset(self.frame, 0, -self.height);
                     } completion:^(BOOL finished) {
                         [self removeFromSuperview];
                         self.window.hidden = YES;
                     }];
}

- (void)removeFromSuperview
{
    self.window = nil;
    self.gesture.delegate = nil;
    self.tap.delegate = nil;
    [self removeGestureRecognizer:self.gesture];
    [self removeGestureRecognizer:self.tap];
    self.gesture = nil;
    self.tap = nil;
    popupsOnscreen--;
    [super removeFromSuperview];
}

+ (instancetype)showPopUpWithTitle:(NSString*)title
                  subtitle:(NSString*)subtitle
    inNavigationController:(UINavigationController*)nav
{
    CGRect rect = CGRectMake(0, 0, nav.view.width, 64);
 
    UIWindow* window = [[UIWindow alloc] initWithFrame:rect];
    window.windowLevel = UIWindowLevelStatusBar + 1;
    window.hidden = NO;
    
    
    PopupNotification* popup = [[self alloc] initWithFrame:rect title:title subtitle:subtitle];
    popup.navController = nav;
    popup.window = window;
    
    popup.frame = CGRectOffset(rect, 0, -popup.height);
    
    [window addSubview:popup];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(popupsOnscreen * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        popupsOnscreen++;
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:0
                         animations:^{
                             popup.frame = rect;
                         } completion:^(BOOL finished) {
                             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                 [popup hide];
                             });
                         }];
    });
    
    return popup;
}

@end
