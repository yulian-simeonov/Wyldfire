//
//  Message.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 4/9/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Message : NSManagedObject

@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSData * image;
@property (nonatomic, retain) NSNumber * mtime;
@property (nonatomic, retain) NSString * senderAccountID;
@property (nonatomic, retain) NSNumber * sent;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSDate * updated;
@property (nonatomic, retain) NSNumber * unread;

@end
