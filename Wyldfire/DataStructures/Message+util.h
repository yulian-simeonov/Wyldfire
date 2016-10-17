//
//  Message+util.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 4/2/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "Message.h"
#import "CoreData.h"
#import "DBAccount+util.h"
#import "Account.h"
#import "Constants.h"

@interface Message (util)

//Can pass nil for account to just create in DB with accountID
+ (Message*) createMessageWithSenderAccountID:(NSString*)accountID
                                        mtime:(long long)mtime
                                         text:(NSString*)text
                                        image:(UIImage*)image
                                         sent:(BOOL)sent
                                        notify:(BOOL)notify;

+ (NSArray*) retrieveAccountsInMessages;
+ (NSArray*) messagesForAccountID:(NSString*)accountID;
+ (Message*) lastMessageForAccountID:(NSString*)accountID;

- (UIImage*) uiImage;
- (void)save;

+ (BOOL)hasUnreadMessages;

@end
