//
//  KiipPopupNotification.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 5/8/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "KiipPopupNotification.h"

@interface KiipPopupNotification ()
    @property (nonatomic, strong) KPPoptart* poptart;
@end


@implementation KiipPopupNotification

- (void)performAction
{
    if ([GVUserDefaults standardUserDefaults].hasViewedKiip) {
        [self.poptart show];
        [self close];
    } else {
        [self close];
        [GVUserDefaults standardUserDefaults].hasViewedKiip = YES;
        KiipTourViewController* vc = [KiipTourViewController new];
        vc.poptart = self.poptart;
        [self.navController pushViewController:vc animated:YES];
    }
}

- (void)style
{
    [super style];
    UIImageView* imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"reward"]];
    
    imgView.frame = CGRectMake(self.width - imgView.width,
                               0,
                               imgView.width,
                               self.height);
    [self addSubview:imgView];
}

- (void)close
{
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.frame = CGRectOffset(self.frame, 0, -self.height);
                     } completion:^(BOOL finished) {
                         [self removeFromSuperview];
                         self.window.hidden = YES;
                     }];
}

- (void)hide
{
    
}

+(instancetype)showKiipPopUpWithPoptart:(KPPoptart *)poptart title:(NSString*)title subtitle:(NSString*)subtitle inNavigationController:(UINavigationController *)nav
{
    //Account* me = [WFCore get].accountStructure;
    
    //NSString* title = [NSString stringWithFormat:@"Look at you %@ Popular", me.isMale ? @"Mr." : @"Ms."];
    //NSString* subtitle = @"You've earned a kiip reward!";
    
    KiipPopupNotification* popup = [self showPopUpWithTitle:title
                                                  subtitle:subtitle
                                    inNavigationController:nav];
    popup.poptart = poptart;
    
    UIImage* image = [UIImage imageNamed:@"reward"];
    popup.label.width -= (image.size.width - TITLE_INDENT);
    popup.subLabel.width -= (image.size.width - TITLE_INDENT);
    
    return popup;

}

@end
