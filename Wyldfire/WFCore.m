//
//  WFCore.m
//  Wyldfire
//
//  Created by Vlad Seryakov on 9/17/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

#import "WFCore.h"
#import <CommonCrypto/CommonHMAC.h>
#import <objc/runtime.h>
#import "DTAlertView.h"

@implementation WFCore {
    CLPlacemark *_place;
    CLLocationManager *_locationManager;
    CLLocation* _location;
    Kiip *_kiip;
    NSOperationQueue *_queue;
    AFHTTPClient *_client;
    NSTimer *_timer;
    UIActivityIndicatorView *_activity;
};

static WFCore *_global;

+ (Account*)account
{
    return [self get].accountStructure;
}

- (WFCore*)init
{
    self = [super init];
    self.loading = [UIImage imageNamed:@"loading.png"];
    self.images = [@{} mutableCopy];
    self.params = [@{} mutableCopy];
    self.account = [@{ @"age": @"0",
                       @"alias": @"No Name",
                       @"women0": @"1",
                       @"age0":[NSNumber numberWithInt:18],
                       @"age1":[NSNumber numberWithInt:30],
                       @"distance0": [NSNumber numberWithInt:25] } mutableCopy];
    return self;
}

- (void)configure
{
    NSMutableDictionary *defaults = [@{} mutableCopy];
    NSArray *preferences = [[NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"] stringByAppendingPathComponent:@"Root.plist"]] objectForKey:@"PreferenceSpecifiers"];
    for (NSDictionary *item in preferences) {
        NSString *key = item[@"Key"];
        NSString *val = item[@"DefaultValue"];
        if (key && val) defaults[key] = val;
    }
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    [[NSUserDefaults standardUserDefaults] synchronize];

    _timer = nil;
    _queue = [[NSOperationQueue alloc] init];
    [_queue setMaxConcurrentOperationCount:10];
    _client = [[AFHTTPClient alloc] initWithBaseURL:[[NSURL alloc] initWithString:@""]];
    _client.parameterEncoding = AFJSONParameterEncoding;
    
    _kiip = [[Kiip alloc] initWithAppKey:@"fd7e96aa8308415a4b46a105e6d3ffcf" andSecret:@"0ec750faa5fb7294e63da77981ca60d9"];
    _kiip.delegate = self;
    [Kiip setSharedInstance:_kiip];
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
   
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    [_locationManager setDesiredAccuracy:kCLLocationAccuracyKilometer];
    [_locationManager setDistanceFilter:1000];
    [_locationManager startUpdatingLocation];

    _activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    _activity.hidesWhenStopped = YES;
    _activity.hidden = YES;
    _activity.layer.backgroundColor = [[UIColor colorWithWhite:0.0f alpha:0.4f] CGColor];
    _activity.frame = CGRectMake(0, 0, 64, 64);
    _activity.layer.masksToBounds = YES;
    _activity.layer.cornerRadius = 8;
      
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor blackColor],
                                                           NSFontAttributeName: [UIFont fontWithName:BOLD_FONT size:20]}];
    
    self.instagram = [[Instagram alloc] init:@"instagram" clientId:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"InstagramAppID"] clientSecret:@"9815411fd63e46029a9768122c9d8cd2"];
    
    // Retrieve saved account info
    self.email = [[NSUserDefaults standardUserDefaults] stringForKey:@"Wyldfire:email"];
    self.secret = [SSKeychain passwordForService:self.email account:@"Wyldfire"];
}

#pragma mark - LocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    _location = [locations lastObject];
    [self putLocation:nil failure:nil];
}

- (CLLocation *)getLocation
{
    if (_location == nil) return [[CLLocation alloc] initWithLatitude:90 longitude:0]; // Use North Pole
    return _location;
}

- (void)putLocation:(GenericBlock)success failure:(GenericBlock)failure;
{
    if (_location != nil && self.accountStructure != nil) {
        [[APIClient sharedClient] putLocation:_location success:success failure:failure];
    } else {
        if (failure) failure();
    }
}

#pragma mark - KiipDelegate

- (void)kiip:(Kiip *)kiip didReceiveContent:(NSString *)contentId quantity:(int)quantity transactionId:(NSString *)transactionId signature:(NSString *)signature {
    
}

+ (void)saveMoment:(NSString*)moment
          onlyOnce:(BOOL)onlyOnce
           topText:(NSString*)topText
        bottomText:(NSString*)bottomText
            inNavC:(UINavigationController*)nav
{
    if (onlyOnce && [[GVUserDefaults standardUserDefaults] wasKiipMomentAlreadyRewarded:moment]) return;
    
    [[Kiip sharedInstance] saveMoment:moment withCompletionHandler:^(KPPoptart *poptart, NSError *error) {
        if (error) NSLog(@"saveMoment: %@", error);
        
        if (poptart) {
            if (onlyOnce) {
                [[GVUserDefaults standardUserDefaults] addKiipMomentRewarded:moment];
            }
            [KiipPopupNotification showKiipPopUpWithPoptart:poptart title:topText subtitle:bottomText inNavigationController:nav];
        }
    }];
}


#pragma mark - WFCore

- (void)showActivity
{
    if (_activity.superview) return;
    UIViewController *root = [WFCore topMostController];
    [root.view addSubview:_activity];
    _activity.center = root.view.center;
    _activity.hidden = NO;
    [_activity startAnimating];
}

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

- (void)notify:(NSString*)reason
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"accountUpdated" object:nil userInfo:@{ @"reason": reason ? reason : @"account" }];
}

- (void)savePassword
{
    [[NSUserDefaults standardUserDefaults] setObject:self.email forKey:@"Wyldfire:email"];
    [SSKeychain setPassword:self.secret forService:self.email account:@"Wyldfire"];
}

- (CLLocationDistance)calcDistance:(NSNumber*)latitude longitude:(NSNumber*)longitude
{
    CLLocation *location = [[CLLocation alloc] initWithLatitude:[latitude doubleValue] longitude:[longitude doubleValue]];
    // In case if location manager does not work we use last account location
    CLLocation *my = _place ? _place.location : [[CLLocation alloc] initWithLatitude:[WFCore toNumber:self.account[@"latitude"]] longitude:[WFCore toNumber:self.account[@"longitude"]]];
    return [my distanceFromLocation:location];
}


#pragma mark Start of API


- (void)onBlockTimer:(NSTimer *)timer
{
    SuccessBlock block = timer.userInfo[@"block"];
    block(timer.userInfo[@"params"]);
}

- (void)queueBlock:(SuccessBlock)block params:(id)params
{
    if (!block) return;
    [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(onBlockTimer:) userInfo:@{ @"block": [block copy],  @"params": params } repeats:NO];
}

- (void)checkBlackbook:(NSDictionary*)item success:(GenericBlock)success failure:(GenericBlock)failure
{
    // Testing mode
    if ([item[@"alias"] isEqualToString:@"Yana"]) {
        if (success) success();
        return;
    }
    if (failure) failure();
}

- (void)checkLikeStatus:(NSDictionary*)item success:(GenericBlock)success failure:(GenericBlock)failure
{
    if (failure) failure();
}

- (void)checkLikedStatus:(NSDictionary*)item success:(GenericBlock)success failure:(GenericBlock)failure
{
    if (failure) failure();
}

- (void)checkBurnStatus:(NSDictionary*)item success:(GenericBlock)success failure:(GenericBlock)failure
{
    if (failure) failure();
}

- (NSArray*)list:(NSString*)name
{
    id rc = self.account[name];
    if (!rc || ![rc isKindOfClass:[NSArray class]]) return @[];
    return rc;
}

- (NSDictionary*)dict:(NSString*)name
{
    id rc = self.account[name];
    if (!rc || ![rc isKindOfClass:[NSDictionary class]]) return @{};
    return rc;
}

- (NSString*)str:(NSString*)name
{
    return [WFCore toString:self.account[name]];
}

- (double)num:(NSString*)name
{
    return [WFCore toNumber:self.account[name]];
}

- (id)objectForKey:(id)key
{
    return [self str:key];
}

- (id)objectForKeyedSubscript:(id)key
{
    return [self str:key];
}

- (void)setObject:(id)obj forKey:(id < NSCopying >)key
{
    self.account[key] = obj == nil ? @"" : obj;
}

- (void)setObject:(id)obj forKeyedSubscript:(id < NSCopying >)key
{
    self.account[key] = obj == nil ? @"" : obj;
}

- (BOOL)isEmpty:(NSString*)name
{
    return [WFCore isEmpty:self.account name:name];
}

#pragma mark - WFCore class methods

+ (WFCore*)get
{
    if (_global == nil) {
        _global = [[super alloc] init];
    }
    return _global;
}

+ (BOOL)isEmpty:(id)val
{
    return [WFCore toString:val].length == 0;
}

+ (BOOL)isEmpty:(id)obj name:(NSString*)name
{
    if (!obj || ![obj isKindOfClass:[NSDictionary class]]) return YES;
    id val = obj[name];
    return val == nil || [WFCore toString:val].length == 0;
}

+ (NSString*)toString:(id)obj
{
    return [NSString stringWithFormat:@"%@", obj == nil ? @"" : obj];
}

+ (float)randomNumber:(float)from to:(float)to
{
    return (((float)(arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * (to - from)) + from;
}

+ (double)toNumber:(id)obj
{
    if (obj) return [obj doubleValue];
    return 0;
}

+ (long long)now
{
    return [[NSDate date] timeIntervalSince1970];
}

+ (NSDictionary*)toDictionary:(id)obj name:(NSString*)name
{
    if (![obj isKindOfClass:[NSDictionary class]]) return @{};
    id rc = obj[name];
    if (![rc isKindOfClass:[NSDictionary class]]) return @{};
    return rc;
}

+ (NSArray*)toArray:(id)obj name:(NSString*)name
{
    if (![obj isKindOfClass:[NSDictionary class]]) return @[];
    id rc = obj[name];
    if (![rc isKindOfClass:[NSArray class]]) return @[];
    return rc;
}

+ (NSString*)toString:(id)obj name:(NSString*)name
{
    if (![obj isKindOfClass:[NSDictionary class]]) return @"";
    return [WFCore toString:obj[name]];
}

+ (double)toNumber:(id)obj name:(NSString*)name
{
    if (![obj isKindOfClass:[NSDictionary class]]) return 0;
    return [WFCore toNumber:obj[name]];
}

+ (NSArray*)toDictionaryArray:(id)obj name:(NSString*)name field:(NSString*)field
{
    return [WFCore toArray:[WFCore toDictionary:obj name:name] name:field];
}

+ (NSString*)toDictionaryString:(id)obj name:(NSString*)name field:(NSString*)field
{
    return [WFCore toString:[WFCore toDictionary:obj name:name] name:field];
}

+ (NSArray*)pastDates:(int)days format:(NSString*)format
{
    NSMutableArray *rc = [@[] mutableCopy];
    NSDate *now = [NSDate date];
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = format;
    
    for (int i = 0; i < days; i++) {
        now = [now dateByAddingTimeInterval:-86400 * i];
        [rc addObject:[[fmt stringFromDate:now] lowercaseString]];
    }
    return rc;
}

+ (NSMutableDictionary *)parseQueryString:(NSString *)query
{
    NSMutableDictionary *dict = [@{} mutableCopy];
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    for (NSString *pair in pairs) {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
        NSString *key = [[elements objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *val = [[elements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [dict setObject:val forKey:key];
    }
    return dict;
}

+ (NSString *)escape:(NSString  *)string
{
	return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, (__bridge CFStringRef)@"[].", (__bridge CFStringRef)@":/?&=;+!@#$()',*", kCFStringEncodingUTF8);
}

+ (BOOL)matchString:(NSString *)pattern string:(NSString*)string
{
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    if (regex == nil) {
        NSLog(@"matchString: %@: %@", pattern, error);
        return NO;
    }
    NSUInteger n = [regex numberOfMatchesInString:string options:0 range:NSMakeRange(0, string.length)];
    return n == 1;
}

+ (NSString *)captureString:(NSString *)pattern string:(NSString*)string
{
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    if(regex == nil) {
        NSLog(@"captureString: %@: %@", pattern, error);
        return nil;
    }
    NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:string options:0 range:NSMakeRange(0, string.length)];
    if(rangeOfFirstMatch.location == NSNotFound) return nil;
    
    return [string substringWithRange:rangeOfFirstMatch];
}

+ (NSMutableDictionary*)createParams:(NSDictionary*)item params:(NSDictionary*)params
{
    NSMutableDictionary *rc = [(item ? item : @{}) mutableCopy];
    for (id key in params) rc[key] = params[key];
    return rc;
}

+ (NSString*)createUUID
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    return (NSString *)CFBridgingRelease(string);
}

+ (NSString*)hmacSHA1:(NSData*)data secret:(NSString*)secret
{
    unsigned char hmac[20];
    NSData *secretData = [secret dataUsingEncoding:NSUTF8StringEncoding];
    CCHmac(kCCHmacAlgSHA1, [secretData bytes], [secretData length], [data bytes], [data length], hmac);
    return [WFCore base64Encode:[NSData dataWithBytes:hmac length:sizeof(hmac)]];
}

+ (NSString*)base64Encode:(NSData*)data
{
    return [data base64EncodedStringWithOptions:0];
}

+ (NSData*)base64Decode:(NSString*) string
{
    return [[NSData alloc] initWithBase64EncodedString:string options:0];
}

+ (UIViewController*)topMostController:(UIViewController*)controller
{
    UIViewController *topController = controller;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    if ([topController isKindOfClass:[UINavigationController class]]) {
        UIViewController *visible = ((UINavigationController *)topController).visibleViewController;
        if (visible) topController = visible;
    }
    return (topController != controller ? topController : nil);
}

+ (UIViewController*)topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIViewController *next = nil;
    
    while ((next = [WFCore topMostController:topController]) != nil) {
        topController = next;
    }
    
    return topController;
}

+ (void)showViewController:(UIViewController*)owner name:(NSString*)name mode:(NSString*)mode params:(NSDictionary*)params
{
    NSLog(@"showViewController: %@ %@", mode ? mode : @"", name);
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
    UIViewController *controller = nil;
    if ([name isEqualToString:@"BlackBook"]) controller = [[BlackBookViewController alloc] init];
    if ([name isEqualToString:@"LinkedAccounts"]) controller = [[LinkedAccountsViewController alloc] init];
    if ([name isEqualToString:@"InviteFriends"]) controller = [[InviteFriendsViewController alloc] init];
    if ([name isEqualToString:@"InviteContactFriends"]) controller = [[InviteContactFriendsViewController alloc] init];
    if ([name isEqualToString:@"InviteFacebookFriends"]) controller = [[InviteFacebookFriendsViewController alloc] init];
    if ([name isEqualToString:@"MutualFriends"]) controller = [[MutualFriendsViewController alloc] init];
    if ([name isEqualToString:@"Chat"]) controller = [[ChatViewController alloc] init];
    if ([name isEqualToString:@"Settings"]) controller = [[SettingsViewController alloc] init];
    if ([name isEqualToString:@"AppSettings"]) controller = [[AppSettingsViewController alloc] init];
    if ([name isEqualToString:@"Top10"]) controller = [[TrendingViewController alloc] init];
    if ([name isEqualToString:@"Album"]) controller = [[AlbumViewController alloc] init];
    if ([name isEqualToString:@"Match"]) controller = [[MatchesViewController alloc] init];
    if ([name isEqualToString:@"Photos"]) controller = [[PhotosViewController alloc] init];
    if ([name isEqualToString:@"Waiting"]) controller = [[WaitingRoomViewController alloc] init];
    if ([name isEqualToString:@"PhotoEdit"]) controller = [[PhotoEditViewController alloc] init];
    if ([name isEqualToString:@"AgeRange"]) controller = [[AgeRangeSettingsViewController alloc] init];
    if ([name isEqualToString:@"TrendingRadius"]) controller = [[TrendingRadiusSettingsViewController alloc] init];
    if ([name isEqualToString:@"SearchRadius"]) controller = [[SearchRangeViewController alloc] init];
    if ([name isEqualToString:@"PrivacyPolicy"]) controller = [[PrivacyPolicyViewController alloc] init];
    if ([name isEqualToString:@"WaitingRoomFriends"]) controller = [[WaitingRoomFriendsViewController alloc] init];
    if ([name isEqualToString:@"EditProfile"]) controller = [[EditProfileViewController alloc] init];
    if ([name isEqualToString:@"AvatarEdit"]) controller = [[AvatarEditViewController alloc] init];
    if ([name isEqualToString:@"Events"]) controller = [[EventsViewController alloc] init];
    
    if (!controller && [name length] > 0) controller = [storyboard instantiateViewControllerWithIdentifier:name];
    ViewController *view = (ViewController*)controller;
    
    // Pass parameters to the new controller, save caller and controller name for reference
    if ([controller isKindOfClass:[ViewController class]]) {
        view.name = name;
        view.mode = mode ? mode : @"";
        view.caller = [owner isKindOfClass:[ViewController class]] ? [(ViewController*)owner name] : @"Browse";
        view.params = [params mutableCopy];
        [view configure];
    }
    
    if (mode == nil) {
        owner.navigationController.delegate = (id<UINavigationControllerDelegate>)view;
        [owner.navigationController setViewControllers:@[controller] animated:YES];
    } else
        if ([mode hasPrefix:@"push"]) {
            if ([controller isKindOfClass:[ViewController class]]) {
                [view preparePushMode:owner];
            }
            owner.navigationController.delegate = (id<UINavigationControllerDelegate>)view;
            [owner.navigationController pushViewController:controller animated:YES];
        } else
            if ([mode hasPrefix:@"drawer"]) {
                if ([controller isKindOfClass:[ViewController class]]) {
                    if (view.drawerView != nil) return;
                    
                    [view prepareDrawerMode:owner];
                    [owner.navigationController pushViewController:controller animated:NO];
                    [view showDrawer];
                }
            }
}

+ (void)showAlert:(NSString *)title text:(NSString *)text delegate:(id)delegate cancelButtonText:(NSString*)cancel otherButtonTitles:(NSArray*)otherButtonTitles tag:(int)tag
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title message:text delegate:delegate cancelButtonTitle:cancel otherButtonTitles:nil];
    for(NSString *buttonTitle in otherButtonTitles) {
        [alert addButtonWithTitle:buttonTitle];
    }
    alert.tag = tag;
    [alert show];
}

+ (void)showAlert:(NSString*)title msg:(NSString*)msg delegate:(id)delegate confirmHandler:(AlertBlock)confirmHandler
{
    if (delegate == nil) delegate = [self get];

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:msg delegate:delegate cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    if (confirmHandler) objc_setAssociatedObject(alertView, @"alertBlock", confirmHandler, OBJC_ASSOCIATION_RETAIN);
    [alertView show];
}

+ (void)showConfirm:(NSString*)title msg:(NSString*)msg ok:(NSString*)ok delegate:(id)delegate confirmHandler:(AlertBlock)confirmHandler
{
    if (delegate == nil) delegate = [self get];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:msg delegate:delegate cancelButtonTitle:@"Cancel" otherButtonTitles:ok,nil];
    if (confirmHandler) objc_setAssociatedObject(alertView, @"alertBlock", confirmHandler, OBJC_ASSOCIATION_RETAIN);
    [alertView show];
}

+ (void)setTextBorder:(UITextField*)view color:(UIColor*)color
{
    view.layer.masksToBounds = YES;
    view.layer.cornerRadius = 8.0f;
    view.layer.borderColor = color ? color.CGColor : [UIColor whiteColor].CGColor;
    view.layer.borderWidth = 1;
    [view setValue:[UIColor whiteColor] forKeyPath:@"_placeholderLabel.textColor"];
}

+ (void)setLabelAttributes:(UILabel*)label color:(UIColor*)color font:(UIFont*)font range:(NSRange)range
{
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:label.text];
    if (color) [attr addAttributes:@{NSForegroundColorAttributeName: color} range:range];
    if (font) [attr addAttributes:@{NSFontAttributeName: font} range:range];
    label.attributedText = attr;
}

+ (void)setImageBorder:(UIView*)view color:(UIColor*)color radius:(float)radius
{
    view.layer.cornerRadius = radius ? radius : view.frame.size.width/2;
    view.layer.masksToBounds = YES;
    view.layer.borderColor = color ? color.CGColor : [UIColor lightGrayColor].CGColor;
    view.layer.borderWidth = 2;
}

+ (void)addImageWithBorderAndShadow:(UIView*)view image:(UIImageView*)image color:(UIColor*)color radius:(float)radius
{
    UIView *shadowView = [[UIView alloc] initWithFrame:view.bounds];
    shadowView.center = CGPointMake(view.frame.size.width / 2, view.frame.size.height / 2);
    shadowView.backgroundColor = [UIColor clearColor];
    shadowView.layer.shadowColor = [[UIColor blackColor] CGColor];
    shadowView.layer.shadowOpacity = 0.9;
    shadowView.layer.shadowRadius = 2;
    shadowView.layer.shadowOffset = CGSizeMake(0, 0);
    
    image.frame = view.bounds;
    image.center = shadowView.center;
    image.layer.cornerRadius = radius ? radius : image.frame.size.width/2;
    image.layer.masksToBounds = YES;
    image.layer.borderColor = color ? color.CGColor : [UIColor whiteColor].CGColor;
    image.layer.borderWidth = 3;
    image.contentMode = UIViewContentModeScaleAspectFill;
    [shadowView addSubview:image];
    
    [view addSubview:shadowView];
}

+ (void)setRoundCorner:(UIView*)view corner:(UIRectCorner)corner radius:(float)radius
{
    if (!corner) corner = UIRectCornerTopLeft|UIRectCornerTopRight;
    if (!radius) radius = 8;
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:view.bounds byRoundingCorners:corner cornerRadii:CGSizeMake(radius, radius)];
    CAShapeLayer *mask = [CAShapeLayer layer];
    mask.frame = view.bounds;
    mask.path = path.CGPath;
    view.layer.mask = mask;
    view.layer.masksToBounds = YES;
}

+ (void)addImageAtCorner:(UIView*)view image:(UIImageView*)image corner:(UIRectCorner)corner
{
    [view addSubview:image];
    if (corner == UIRectCornerTopRight) {
        image.layer.anchorPoint = CGPointMake(0, 1);
        image.frame = CGRectMake(view.frame.size.width - image.frame.size.width, 0.0, image.frame.size.width, image.frame.size.height);
    } else
    if (corner == UIRectCornerTopLeft) {
        image.layer.anchorPoint = CGPointMake(0, 0);
        image.frame = CGRectMake(0, 0, image.frame.size.width, image.frame.size.height);
    } else
    if (corner == UIRectCornerBottomLeft) {
        image.layer.anchorPoint = CGPointMake(1, 0);
        image.frame = CGRectMake(0, view.frame.size.height - image.frame.size.height, image.frame.size.width, image.frame.size.height);
    } else
    if (corner == UIRectCornerBottomRight) {
        image.layer.anchorPoint = CGPointMake(1, 1);
        image.frame = CGRectMake(view.frame.size.width - image.frame.size.width, view.frame.size.height - image.frame.size.height, image.frame.size.width, image.frame.size.height);
    }
}

+ (UIImageView*)imageWithBadge:(CGRect)frame icon:(NSString*)icon color:(UIColor*)color value:(int)value
{
    UIImageView *image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:icon]];
    if (frame.size.width && frame.size.height) {
        image.contentMode = UIViewContentModeScaleAspectFit;
        image.frame = frame;
    } else {
        image.frame = CGRectMake(frame.origin.x, frame.origin.y, image.frame.size.width, image.frame.size.height);
    }
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(3, 3, image.frame.size.width-6, image.frame.size.height-6)];
    label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    label.textAlignment = NSTextAlignmentCenter;
    label.adjustsFontSizeToFitWidth = YES;
    label.textColor = color ? color : [UIColor darkGrayColor];
    label.text = [NSString stringWithFormat:@"%d", value];
    [image addSubview:label];
    return image;
}

+ (void)shakeView:(UIView*)view
{
    CAKeyframeAnimation * anim = [ CAKeyframeAnimation animationWithKeyPath:@"transform" ] ;
    anim.values = @[ [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(-5.0f, 0.0f, 0.0f) ],
                     [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(5.0f, 0.0f, 0.0f) ] ] ;
    anim.autoreverses = YES ;
    anim.repeatCount = 2.0f ;
    anim.duration = 0.07f ;
    [view.layer addAnimation:anim forKey:nil];
}

+ (void)jiggleView:(UIView*)view
{
    float angle = 1.0 * (1.0f + ((rand() / (float)RAND_MAX) - 0.5f) * 0.1f);
    float rotate = angle / 180. * M_PI;
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    animation.duration = 0.1;
    animation.additive = YES;
    animation.autoreverses = YES;
    animation.repeatCount = FLT_MAX;
    animation.fromValue = @(-rotate);
    animation.toValue = @(rotate);
    animation.timeOffset = (rand() / (float)RAND_MAX) * 0.1;
    [view.layer addAnimation:animation forKey:@"jiggle"];
}

+ (UIImage*)scaleToFill:(UIImage*)image size:(CGSize)size
{
    size_t width = (size_t)(size.width * image.scale);
    size_t height = (size_t)(size.height * image.scale);
    if (image.imageOrientation == UIImageOrientationLeft || image.imageOrientation == UIImageOrientationLeftMirrored || image.imageOrientation == UIImageOrientationRight || image.imageOrientation == UIImageOrientationRightMirrored) {
        size_t temp = width;
        width = height;
        height = temp;
    }
    static CGColorSpaceRef _colorSpace = NULL;
    if (!_colorSpace) _colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageAlphaInfo alpha = CGImageGetAlphaInfo(image.CGImage);
    BOOL hasAlpha = (alpha == kCGImageAlphaFirst || alpha == kCGImageAlphaLast || alpha == kCGImageAlphaPremultipliedFirst || alpha == kCGImageAlphaPremultipliedLast);
    CGImageAlphaInfo alphaInfo = (hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst);
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, width * 4, _colorSpace, kCGBitmapByteOrderDefault | alphaInfo);
    
    CGContextSetShouldAntialias(context, true);
    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    
    UIGraphicsPushContext(context);
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), image.CGImage);
    UIGraphicsPopContext();
    
    CGImageRef scaledRef = CGBitmapContextCreateImage(context);
    UIImage* scaled = [UIImage imageWithCGImage:scaledRef scale:image.scale orientation:image.imageOrientation];
    
    CGImageRelease(scaledRef);
    CGContextRelease(context);
    
    return scaled;
}

+ (UIImage*)scaleToFit:(UIImage*)image size:(CGSize)size
{
    size_t width, height;
    if (image.size.width > image.size.height) {
        width = (size_t)size.width;
        height = (size_t)(image.size.height * size.width / image.size.width);
    } else {
        height = (size_t)size.height;
        width = (size_t)(image.size.width * size.height / image.size.height);
    }
    if (width > size.width) {
        width = (size_t)size.width;
        height = (size_t)(image.size.height * size.width / image.size.width);
    }
    if (height > size.height) {
        height = (size_t)size.height;
        width = (size_t)(image.size.width * size.height / image.size.height);
    }
    return [WFCore scaleToFill:image size:CGSizeMake(width, height)];
}

+ (UIImage*)scaleToSize:(UIImage*)image size:(CGSize)size
{
    size_t width, height;
    CGFloat widthRatio = size.width / image.size.width;
    CGFloat heightRatio = size.height / image.size.height;
    if (heightRatio > widthRatio) {
        height = (size_t)size.height;
        width = (size_t)(image.size.width * size.height / image.size.height);
    } else {
        width = (size_t)size.width;
        height = (size_t)(image.size.height * size.width / image.size.width);
    }
    return [WFCore scaleToFill:image size:CGSizeMake(width, height)];
}

+ (UIImage *)cropImage:(UIImage*)image frame:(CGRect)frame
{
    frame = CGRectMake(frame.origin.x * image.scale, frame.origin.y * image.scale, frame.size.width * image.scale, frame.size.height * image.scale);
    CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, frame);
    UIImage *newImage = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(imageRef);
    return newImage;
}

+ (UIImage *)orientImage:(UIImage *)image
{
    if (image.imageOrientation == UIImageOrientationUp) return image;
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawInRect:(CGRect){0, 0, image.size}];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (UIImage *)captureImage:(UIView *)view
{
    CGSize size = [UIScreen mainScreen].bounds.size;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(ctx, GRAY_8.CGColor);
    CGContextFillRect(ctx, (CGRect){CGPointZero, size});
    
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

+ (void)showFonts
{
    for (NSString *familyName in [UIFont familyNames]) {
        for (NSString *fontName in [UIFont fontNamesForFamilyName:familyName]) {
            NSLog(@"font: %@", fontName);
        }
    }
}

+ (NSUInteger)IOSVersion
{
    static NSUInteger _ver = -1;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ _ver = [[[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."] objectAtIndex:0] intValue]; });
    return _ver;
}

// Return all available icons urls from the account record
+ (NSArray*)listNumbered:(NSDictionary*)item name:(NSString*)name
{
    NSMutableArray *icons = [@[] mutableCopy];
    for (int i = 0; i < 5; i++) {
        NSString *icon = [NSString stringWithFormat:@"%@%d", name, i];
        if (item[icon]) [icons addObject:item[icon]];
    }
    return icons;
}

+ (id)invocationWithClass:(Class)targetClass name:(NSString*)name
{
    SEL selector = NSSelectorFromString(name);
    Method method = class_getInstanceMethod(targetClass, selector);
    struct objc_method_description* desc = method_getDescription(method);
    if (desc == NULL || desc->name == NULL) return nil;
    
    NSMethodSignature* sig = [NSMethodSignature signatureWithObjCTypes:desc->types];
    NSInvocation* inv = [NSInvocation invocationWithMethodSignature:sig];
    [inv setSelector:selector];
    return inv;
}

+ (NSString *)documentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths firstObject];
}

# pragma mark - CAAnimation methods

- (void)animationDidStart:(CAAnimation *)animation
{
    SuccessBlock block = [animation valueForKey:@"startBlock"];
    if (block) block(animation);
}

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)flag
{
    SuccessBlock block = [animation valueForKey:@"stopBlock"];
    if (block) block(animation);
}

# pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)index
{
    //if ([alertView.title hasPrefix:@"Error"]) exit(1);
    
    NSString *title = [alertView buttonTitleAtIndex:index];
    AlertBlock block = objc_getAssociatedObject(alertView, @"alertBlock");
    if (block) block(alertView, title);
}

@end
