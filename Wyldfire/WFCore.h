//
//  WFCore.h
//  Wyldfire
//
//  Created by Vlad Seryakov on 9/17/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

#include <math.h>
#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CommonCrypto/CommonHMAC.h>
#import <KiipSDK/KiipSDK.h>
#import <Social/Social.h>
#import <Accounts/Accounts.h>
#import <CoreImage/CIDetector.h>
#import <CoreImage/CoreImage.h>
#import <CoreData/CoreData.h>
#import <ImageIO/CGImageProperties.h>
#import <QuartzCore/QuartzCore.h>
#import <GPUImage/GPUImage.h>
#import "UIImageView+AFNetworking.h"
#import "AFHTTPClient.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "AFJSONRequestOperation.h"
#import "AFImageRequestOperation.h"
#import "SSKeychain.h"
#import "CoreData.h"
#import "ViewController.h"
#import "WebViewController.h"
#import "SocialAccount.h"
#import "Instagram.h"
#import "Twitter.h"
#import "Charts.h"
#import "RangeSlider.h"
#import "Animation.h"
#import "Constants.h"
#import "MatchesViewController.h"
#import "WaitingRoomViewController.h"
#import "PhotoEditViewController.h"
#import "AgeRangeSettingsViewController.h"
#import "SearchRangeViewController.h"
#import "TrendingRadiusSettingsViewController.h"
#import "PrivacyPolicyViewController.h"
#import "Account.h"
#import "UIView+Positioning.h"
#import "WaitingRoomFriendsViewController.h"
#import "EditProfileViewController.h"
#import "AvatarEditViewController.h"
#import "KiipPopupNotification.h"

#define DEBUG 1
#define DEGREES_TO_RADIANS(degrees) ((M_PI * degrees)/180.0)

@interface WFCore: NSObject <CLLocationManagerDelegate,KiipDelegate,UIAlertViewDelegate>
@property (strong, nonatomic) UIImage *loading;
@property (strong, nonatomic) Instagram *instagram;
@property (strong, nonatomic) Twitter *twitter;

// Account properties
@property (nonatomic, strong) Account* accountStructure;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *secret;
@property (strong, nonatomic) NSString *deviceToken;
@property (strong, nonatomic) NSMutableDictionary *images;
@property (strong, nonatomic) NSMutableDictionary *account;

//Location
- (CLLocation *)getLocation;
- (void)putLocation:(GenericBlock)success failure:(GenericBlock)failure;

// Storage for application wide key-value pairs
@property (strong, nonatomic) NSMutableDictionary *params;

+ (WFCore*)get;
+ (NSData*)base64Decode:(NSString*)string;
+ (NSString*)base64Encode:(NSData*)rawBytes;
+ (NSString*)hmacSHA1:(NSData*)data secret:(NSString*)secret;
+ (NSString*)createUUID;
+ (long long)now;
+ (NSArray*)pastDates:(int)days format:(NSString*)format;
+ (double)toNumber:(id)obj;
+ (double)toNumber:(id)obj name:(NSString*)name;
+ (float)randomNumber:(float)from to:(float)to;
+ (NSString*)toString:(id)obj;
+ (NSString*)escape:(NSString *)string;
+ (BOOL)matchString:(NSString *)pattern string:(NSString*)string;
+ (NSString *)captureString:(NSString *)pattern string:(NSString*)string;
+ (void)showFonts;
+ (NSUInteger)IOSVersion;
+ (NSMutableDictionary *)parseQueryString:(NSString *)query;
+ (UIViewController*)topMostController;
+ (UIViewController*)topMostController:(UIViewController*)controller;
+ (void)saveMoment:(NSString*)moment onlyOnce:(BOOL)onlyOnce topText:(NSString*)topText bottomText:(NSString*)bottomText inNavC:(UINavigationController*)nav;
+ (NSMutableDictionary*)createParams:(NSDictionary*)dict params:(NSDictionary*)params;
+ (NSDictionary*)toDictionary:(id)obj name:(NSString*)name;
+ (NSArray*)toArray:(id)obj name:(NSString*)name;
+ (NSString*)toString:(id)obj name:(NSString*)name;
+ (NSArray*)toDictionaryArray:(id)obj name:(NSString*)name field:(NSString*)field;
+ (NSString*)toDictionaryString:(id)obj name:(NSString*)name field:(NSString*)field;
+ (NSArray*)listNumbered:(NSDictionary*)item name:(NSString*)name;
+ (BOOL)isEmpty:(id)obj name:(NSString*)name;
+ (BOOL)isEmpty:(id)val;
+ (NSString*)documentsDirectory;
+ (Account*)account;

+ (void)showAlert:(NSString *)title text:(NSString *)text delegate:(id)delegate cancelButtonText:(NSString*)cancel otherButtonTitles:(NSArray*)otherButtonTitles tag:(int)tag;
+ (void)showConfirm:(NSString*)title msg:(NSString*)msg ok:(NSString*)ok delegate:(id)delegate confirmHandler:(AlertBlock)confirmHandler;
+ (void)showAlert:(NSString*)title msg:(NSString*)msg delegate:(id)delegate confirmHandler:(AlertBlock)confirmHandler;
+ (void)showViewController:(UIViewController*)owner name:(NSString*)name mode:(NSString*)mode params:(NSDictionary*)params;

+ (void)setLabelAttributes:(UILabel*)label color:(UIColor*)color font:(UIFont*)font range:(NSRange)range;

+ (void)setTextBorder:(UITextField*)view color:(UIColor*)color;
+ (void)setImageBorder:(UIView*)view color:(UIColor*)color radius:(float)radius;
+ (void)addImageWithBorderAndShadow:(UIView*)view image:(UIImageView*)image color:(UIColor*)color radius:(float)radius;
+ (void)setRoundCorner:(UIView*)view corner:(UIRectCorner)corner radius:(float)radius;
+ (void)addImageAtCorner:(UIView*)view image:(UIImageView*)image corner:(UIRectCorner)corner;
+ (UIImageView*)imageWithBadge:(CGRect)frame icon:(NSString*)icon color:(UIColor*)color value:(int)value;

+ (void)shakeView:(UIView*)view;
+ (void)jiggleView:(UIView*)view;

+ (UIImage*)scaleToSize:(UIImage*)image size:(CGSize)size;
+ (UIImage*)scaleToFit:(UIImage*)image size:(CGSize)size;
+ (UIImage*)scaleToFill:(UIImage*)image size:(CGSize)size;
+ (UIImage *)cropImage:(UIImage*)image frame:(CGRect)frame;
+ (UIImage *)orientImage:(UIImage*)image;
+ (UIImage *)captureImage:(UIView *)view;

- (WFCore*)init;
- (void)configure;
- (void)notify:(NSString*)reason;
- (void)showActivity;
- (void)showActivityInView:(UIView*)view;
- (void)hideActivity;

// Internal account functions
- (void)checkBlackbook:(NSDictionary*)item success:(GenericBlock)success failure:(GenericBlock)failure;
- (void)checkLikeStatus:(NSDictionary*)item success:(GenericBlock)success failure:(GenericBlock)failure;
- (void)checkLikedStatus:(NSDictionary*)item success:(GenericBlock)success failure:(GenericBlock)failure;
- (void)checkBurnStatus:(NSDictionary*)item success:(GenericBlock)success failure:(GenericBlock)failure;

// Utility functions
- (BOOL)isEmpty:(NSString*)name;
- (NSDictionary*)dict:(NSString*)name;
- (NSArray*)list:(NSString*)name;
- (NSString*)str:(NSString*)name;
- (double)num:(NSString*)name;
- (id)objectForKey:(id)key;
- (id)objectForKeyedSubscript:(id)key;
- (void)setObject:(id)obj forKey:(id < NSCopying >)key;
- (void)setObject:(id)obj forKeyedSubscript:(id < NSCopying >)key;
- (CLLocationDistance)calcDistance:(NSNumber*)latitude longitude:(NSNumber*)longitude;
- (void)queueBlock:(SuccessBlock)block params:(id)params;



@end
