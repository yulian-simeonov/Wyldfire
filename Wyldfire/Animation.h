//
//  Animation.h
//  Wyldfire
//
//  Created by Yulian Simeonov and Vlad Seryakov on 12/16/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//
//  Bounce animation is based on https://github.com/khanlou/SKBounceAnimation
//

@interface Animation: NSObject<UIViewControllerAnimatedTransitioning>
@property (nonatomic, strong) NSString *type;
@property (nonatomic, assign) float duration;

- (id)initWithType:(NSString*)type duration:(float)duration;
@end

@interface BounceAnimation: CAKeyframeAnimation
@property (nonatomic, strong) id fromValue;
@property (nonatomic, strong) id toValue;
@property (nonatomic, assign) BOOL shaking;
@property (nonatomic, assign) BOOL overshoot;
@property (nonatomic, assign) NSUInteger bounces;
@property (nonatomic, assign) NSString *stiffness;

- (BounceAnimation*) initWithKeyPath:(NSString*)keyPath start:(SuccessBlock)start stop:(SuccessBlock)stop;
- (void) configure:(UIView*)view;
@end

@interface GlowAnimation: CABasicAnimation
@property (nonatomic, strong) UIColor *color;

- (GlowAnimation*) init:(SuccessBlock)start stop:(SuccessBlock)stop;
- (void) configure:(UIView*)view;
@end
