//
//  Animation.h
//  Wyldfire
//
//  Created by Yulian Simeonov and Vlad Seryakov on 12/16/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

@implementation Animation

- (id)initWithType:(NSString*)type duration:(float)duration
{
    self = [super init];
    self.type = type;
    self.duration = duration ? duration : 0.5;
    return self;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return self.duration;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    if ([self.type isEqualToString:@"crossFade"]) {
        [self crossFade:transitionContext];
    }
    if ([self.type isEqualToString:@"explode"]) {
        [self explode:transitionContext];
    }
}

- (void)crossFade:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *toView = toVC.view;
    UIView *fromView = fromVC.view;
    
    UIView* containerView = [transitionContext containerView];
    [containerView addSubview:toView];
    [containerView sendSubviewToBack:toView];

    NSTimeInterval duration = [self transitionDuration:transitionContext];
    [UIView animateWithDuration:duration animations:^{
        fromView.alpha = 0.0;
    } completion:^(BOOL finished) {
        if ([transitionContext transitionWasCancelled]) {
            fromView.alpha = 1.0;
        } else {
            // reset from- view to its original state
            [fromView removeFromSuperview];
            fromView.alpha = 1.0;
        }
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

- (void)explode:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView* containerView = [transitionContext containerView];
    [containerView addSubview:toVC.view];
    [containerView sendSubviewToBack:toVC.view];
    
    CGSize size = toVC.view.frame.size;
    NSMutableArray *snapshots = [NSMutableArray new];
    CGFloat xFactor = 25.0f, yFactor = xFactor * size.height / size.width;
    UIView *fromViewSnapshot = [fromVC.view snapshotViewAfterScreenUpdates:NO];
    
    // create a snapshot for each of the exploding pieces
    for (CGFloat x=0; x < size.width; x+= size.width / xFactor) {
        for (CGFloat y=0; y < size.height; y+= size.height / yFactor) {
            CGRect snapshotRegion = CGRectMake(x, y, size.width / xFactor, size.height / yFactor);
            UIView *snapshot = [fromViewSnapshot resizableSnapshotViewFromRect:snapshotRegion  afterScreenUpdates:NO withCapInsets:UIEdgeInsetsZero];
            snapshot.frame = snapshotRegion;
            [containerView addSubview:snapshot];
            [snapshots addObject:snapshot];
        }
    }
    [containerView sendSubviewToBack:fromVC.view];
    
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    [UIView animateWithDuration:duration animations:^{
        for (UIView *view in snapshots) {
            CGFloat xOffset = [WFCore randomNumber:-100.0 to:100.0];
            CGFloat yOffset = [WFCore randomNumber:-100.0 to:100.0];
            view.frame = CGRectOffset(view.frame, xOffset, yOffset);
            view.alpha = 0.0;
            view.transform = CGAffineTransformScale(CGAffineTransformMakeRotation([WFCore randomNumber:-10.0 to:10.0]), 0.0, 0.0);
        }
    } completion:^(BOOL finished) {
        for (UIView *view in snapshots) {
            [view removeFromSuperview];
        }
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}
@end

@implementation BounceAnimation

- (id) initWithKeyPath:(NSString*)keyPath start:(SuccessBlock)start stop:(SuccessBlock)stop
{
	self = [super init];
    super.keyPath = keyPath;
    self.duration = 1.0;
    self.bounces = 2;
    self.overshoot = YES;
    self.stiffness = @"Medium";
    self.delegate = [WFCore get];
    [self setValue:start forKey:@"startBlock"];
    [self setValue:stop forKey:@"stopBlock"];
	return self;
}

- (void) configure:(UIView*)view
{
	if (!self.fromValue || !self.toValue || !self.duration) return;
    
    if ([self.fromValue isKindOfClass:[NSNumber class]] && [self.toValue isKindOfClass:[NSNumber class]]) {
        self.values = [self valueArrayForStartValue:[self.fromValue floatValue] endValue:[self.toValue floatValue]];
    } else
    if ([self.fromValue isKindOfClass:[NSValue class]] && [self.toValue isKindOfClass:[NSValue class]]) {
        NSString *valueType = [NSString stringWithCString:[self.fromValue objCType] encoding:NSStringEncodingConversionAllowLossy];
        if ([valueType rangeOfString:@"CGRect"].location == 1) {
            CGRect fromRect = [self.fromValue CGRectValue];
            CGRect toRect = [self.toValue CGRectValue];
            self.values = [self createRectArrayFromXValues:[self valueArrayForStartValue:fromRect.origin.x endValue:toRect.origin.x]
                                                   yValues:[self valueArrayForStartValue:fromRect.origin.y endValue:toRect.origin.y]
                                                    widths:[self valueArrayForStartValue:fromRect.size.width endValue:toRect.size.width]
                                                   heights:[self valueArrayForStartValue:fromRect.size.height endValue:toRect.size.height]];
        } else
        if ([valueType rangeOfString:@"CGPoint"].location == 1) {
            CGPoint fromPoint = [self.fromValue CGPointValue];
            CGPoint toPoint = [self.toValue CGPointValue];
            CGPathRef path = createPathFromXYValues([self valueArrayForStartValue:fromPoint.x endValue:toPoint.x],
                                                    [self valueArrayForStartValue:fromPoint.y endValue:toPoint.y]);
            self.path = path;
            CGPathRelease(path);
        } else
        if ([valueType rangeOfString:@"CATransform3D"].location == 1) {
            CATransform3D fromTransform = [self.fromValue CATransform3DValue];
            CATransform3D toTransform = [self.toValue CATransform3DValue];
            self.values = [self createTransformArrayFromM11:[self valueArrayForStartValue:fromTransform.m11 endValue:toTransform.m11]
                                                        M12:[self valueArrayForStartValue:fromTransform.m12 endValue:toTransform.m12]
                                                        M13:[self valueArrayForStartValue:fromTransform.m13 endValue:toTransform.m13]
                                                        M14:[self valueArrayForStartValue:fromTransform.m14 endValue:toTransform.m14]
                                                        M21:[self valueArrayForStartValue:fromTransform.m21 endValue:toTransform.m21]
                                                        M22:[self valueArrayForStartValue:fromTransform.m22 endValue:toTransform.m22]
                                                        M23:[self valueArrayForStartValue:fromTransform.m23 endValue:toTransform.m23]
                                                        M24:[self valueArrayForStartValue:fromTransform.m24 endValue:toTransform.m24]
                                                        M31:[self valueArrayForStartValue:fromTransform.m31 endValue:toTransform.m31]
                                                        M32:[self valueArrayForStartValue:fromTransform.m32 endValue:toTransform.m32]
                                                        M33:[self valueArrayForStartValue:fromTransform.m33 endValue:toTransform.m33]
                                                        M34:[self valueArrayForStartValue:fromTransform.m34 endValue:toTransform.m34]
                                                        M41:[self valueArrayForStartValue:fromTransform.m41 endValue:toTransform.m41]
                                                        M42:[self valueArrayForStartValue:fromTransform.m42 endValue:toTransform.m42]
                                                        M43:[self valueArrayForStartValue:fromTransform.m43 endValue:toTransform.m43]
                                                        M44:[self valueArrayForStartValue:fromTransform.m44 endValue:toTransform.m44]
                           ];
        } else
        if ([valueType rangeOfString:@"CGSize"].location == 1) {
            CGSize fromSize = [self.fromValue CGSizeValue];
            CGSize toSize = [self.toValue CGSizeValue];
            CGPathRef path = createPathFromXYValues([self valueArrayForStartValue:fromSize.width endValue:toSize.width],
                                                    [self valueArrayForStartValue:fromSize.height endValue:toSize.height]);
            self.path = path;
            CGPathRelease(path);
        }
    }
    self.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [view.layer addAnimation:self forKey:@"bounce"];
    [view.layer setValue:self.toValue forKeyPath:self.keyPath];
}

- (NSArray*) createRectArrayFromXValues:(NSArray*)xValues yValues:(NSArray*)yValues widths:(NSArray*)widths heights:(NSArray*)heights
{
	NSUInteger numberOfRects = xValues.count;
	NSMutableArray *values = [NSMutableArray arrayWithCapacity:numberOfRects];
	
	for (NSInteger i = 1; i < numberOfRects; i++) {
		CGRect value = CGRectMake([[xValues objectAtIndex:i] floatValue],[[yValues objectAtIndex:i] floatValue],[[widths objectAtIndex:i] floatValue],[[heights objectAtIndex:i] floatValue]);
		[values addObject:[NSValue valueWithCGRect:value]];
	}
	return values;
}

static CGPathRef createPathFromXYValues(NSArray *xValues, NSArray *yValues)
{
	NSUInteger numberOfPoints = xValues.count;
	CGMutablePathRef path = CGPathCreateMutable();
	CGPoint value = CGPointMake([[xValues objectAtIndex:0] floatValue], [[yValues objectAtIndex:0] floatValue]);
	CGPathMoveToPoint(path, NULL, value.x, value.y);
	
	for (NSInteger i = 1; i < numberOfPoints; i++) {
		value = CGPointMake([[xValues objectAtIndex:i] floatValue], [[yValues objectAtIndex:i] floatValue]);
		CGPathAddLineToPoint(path, NULL, value.x, value.y);
	}
	return path;
}

- (NSArray*) createTransformArrayFromM11:(NSArray*)m11 M12:(NSArray*)m12 M13:(NSArray*)m13 M14:(NSArray*)m14 M21:(NSArray*)m21 M22:(NSArray*)m22 M23:(NSArray*)m23 M24:(NSArray*)m24 M31:(NSArray*)m31 M32:(NSArray*)m32 M33:(NSArray*)m33 M34:(NSArray*)m34 M41:(NSArray*)m41 M42:(NSArray*)m42 M43:(NSArray*)m43 M44:(NSArray*)m44
{
	NSUInteger numberOfTransforms = m11.count;
	NSMutableArray *values = [NSMutableArray arrayWithCapacity:numberOfTransforms];
	
	for (NSInteger i = 1; i < numberOfTransforms; i++) {
		CATransform3D value = CATransform3DIdentity;
		value.m11 = [[m11 objectAtIndex:i] floatValue];
		value.m12 = [[m12 objectAtIndex:i] floatValue];
		value.m13 = [[m13 objectAtIndex:i] floatValue];
		value.m14 = [[m14 objectAtIndex:i] floatValue];
		
		value.m21 = [[m21 objectAtIndex:i] floatValue];
		value.m22 = [[m22 objectAtIndex:i] floatValue];
		value.m23 = [[m23 objectAtIndex:i] floatValue];
		value.m24 = [[m24 objectAtIndex:i] floatValue];
		
		value.m31 = [[m31 objectAtIndex:i] floatValue];
		value.m32 = [[m32 objectAtIndex:i] floatValue];
		value.m33 = [[m33 objectAtIndex:i] floatValue];
		value.m44 = [[m34 objectAtIndex:i] floatValue];
		
		value.m41 = [[m41 objectAtIndex:i] floatValue];
		value.m42 = [[m42 objectAtIndex:i] floatValue];
		value.m43 = [[m43 objectAtIndex:i] floatValue];
		value.m44 = [[m44 objectAtIndex:i] floatValue];
		[values addObject:[NSValue valueWithCATransform3D:value]];
	}
	return values;
}

- (NSArray*) valueArrayForStartValue:(CGFloat)startValue endValue:(CGFloat)endValue
{
	NSInteger steps = 60 * self.duration; //60 fps desired
	
	CGFloat stiffnessCoefficient = 0.1f;
	if ([self.stiffness isEqualToString:@"Heavy"]) {
		stiffnessCoefficient = 0.001f;
	} else
    if ([self.stiffness isEqualToString:@"Light"]) {
        stiffnessCoefficient = 5.0f;
    }
	
	CGFloat alpha = 0;
	if (startValue == endValue) {
		alpha = log2f(stiffnessCoefficient)/steps;
	} else {
		alpha = log2f(stiffnessCoefficient/fabsf(endValue - startValue))/steps;
	}
	if (alpha > 0) {
		alpha = -1.0f*alpha;
	}
	CGFloat numberOfPeriods = self.bounces/2 + 0.5;
	CGFloat omega = numberOfPeriods * 2 * M_PI/steps;
	NSMutableArray *values = [NSMutableArray arrayWithCapacity:steps];
	CGFloat value = 0, oscillationComponent, coefficient;
	
	// conforms to y = A * e^(-alpha*t)*cos(omega*t)
	for (NSInteger t = 0; t < steps; t++) {
		if (self.shaking) {
			oscillationComponent = sin(omega*t);
		} else {
			oscillationComponent = cos(omega*t);
		}
		coefficient =  (startValue - endValue);
		if (!self.overshoot) {
			oscillationComponent = fabsf(oscillationComponent);
		}
		value = coefficient * pow(2.71, alpha*t) * oscillationComponent + endValue;
		[values addObject:[NSNumber numberWithFloat:value]];
	}
	return values;
}
@end

@implementation GlowAnimation

- (GlowAnimation*) init:(SuccessBlock)start stop:(SuccessBlock)stop
{
    self = [super init];
    self.keyPath = @"opacity";
    self.fromValue = @(0.1);
    self.toValue = @(0.9);
    self.duration = 0.4;
    self.repeatCount = 0;
    self.autoreverses = YES;
    self.color = [UIColor whiteColor];
    self.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    self.delegate = [WFCore get];
    [self setValue:start forKey:@"startBlock"];
    // We have to remove glow view after the animation
    [self setValue:^(id anim) {
        UIView *glowView = [anim valueForKey:@"glowView"];
        if (glowView) [glowView removeFromSuperview];
        [anim setValue:nil forKey:@"glowView"];
        if (stop) stop(anim);
    } forKey:@"stopBlock"];
    return self;
}

- (void)configure:(UIView*)view
{
    UIImageView* glow = [[UIImageView alloc] initWithFrame:view.frame];
    glow.alpha = 0;
    glow.layer.shadowColor = self.color.CGColor;
    glow.layer.shadowOffset = CGSizeZero;
    glow.layer.shadowRadius = 10;
    glow.layer.shadowOpacity = 1.0;
    
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, [UIScreen mainScreen].scale); {
        [view.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIBezierPath* path = [UIBezierPath bezierPathWithRect:view.bounds];
        [self.color setFill];
        [path fillWithBlendMode:kCGBlendModeSourceAtop alpha:1.0];
        glow.image = UIGraphicsGetImageFromCurrentImageContext();
    } UIGraphicsEndImageContext();
    
    [self setValue:glow forKey:@"glowView"];
    [glow.layer addAnimation:self forKey:@"glow"];
    [view.superview insertSubview:glow aboveSubview:view];
}

@end
