//
//  DBAccount.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 5/10/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface DBAccount : NSManagedObject

@property (nonatomic, retain) NSString * accountID;
@property (nonatomic, retain) NSNumber * age;
@property (nonatomic, retain) NSString * alias;
@property (nonatomic, retain) NSData * avatarPhoto;
@property (nonatomic, retain) NSString * birthday;
@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * facebookEmail;
@property (nonatomic, retain) NSNumber * facebookID;
@property (nonatomic, retain) NSNumber * inBlackbook;
@property (nonatomic, retain) NSNumber * inChat;
@property (nonatomic, retain) NSNumber * isMale;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSData * profilePhoto1;
@property (nonatomic, retain) NSData * profilePhoto2;
@property (nonatomic, retain) NSData * profilePhoto3;
@property (nonatomic, retain) NSData * profilePhoto4;
@property (nonatomic, retain) NSData * showcasePhoto;
@property (nonatomic, retain) NSNumber * showInMatches;
@property (nonatomic, retain) NSDate * updated;
@property (nonatomic, retain) NSNumber * burned;
@property (nonatomic, retain) NSNumber * sentShareTo;

@end
