//
//  Account.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 3/14/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <KiipSDK/KiipSDK.h>

#import "WFCore.h"
#import "Stats.h"

@interface Account : NSObject

@property (nonatomic) BOOL isOk;
@property (nonatomic, strong) NSString* accountID;
@property (nonatomic) long long facebookID;

@property (nonatomic, strong) NSString* email;
@property (nonatomic, strong) NSString* facebookEmail;
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* alias;
@property (nonatomic, strong) NSString* instagramID;
@property (nonatomic, strong) NSString* instagramUsername;
@property (nonatomic, strong) NSString* birthday;
@property (nonatomic, strong) NSDate* birthDate;
@property (nonatomic, strong) NSString* gender;
@property (nonatomic, strong) NSString* deviceID;
@property (nonatomic, strong) NSString* facebookIcon; //Not in DB
@property (nonatomic) BOOL isMale;
@property (nonatomic) int age;

@property (nonatomic) BOOL hasFeather;  //Not in DB
//For other people's accounts:
@property (nonatomic) BOOL isTrending;  //Not in DB
@property (nonatomic) int distance;  //Not in DB
@property (nonatomic, strong) NSString* phone;

//Images
@property (nonatomic, strong) UIImage* avatarPhoto;
@property (nonatomic, strong) UIImage* showcasePhoto;
@property (nonatomic, strong) NSMutableDictionary* profilePhotos;
@property (nonatomic, strong) NSArray* icons;

//setImage does not call the API, just changes locally
- (void)setImage:(UIImage*)image forType:(NSInteger)type;
- (UIImage*)profileImageForType:(NSInteger)type;
- (NSArray*)allProfileImages;

//References to other items
@property (nonatomic, strong) Stats* stats;

//Factory Methods
+ (instancetype)accountFromAPICall:(id)user;
+ (instancetype)accountFromAPICall:(id)user usingObject:(Account*)account;
+ (instancetype)accountFromFBUser:(id)user;

//JSON Support
- (NSDictionary*)dictionaryRepresentation;

//For ChatViewController
@property (nonatomic) int messageCount;

@end
