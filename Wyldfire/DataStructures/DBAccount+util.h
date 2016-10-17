//
//  DBAccount+util.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 4/2/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "CoreData.h"
#import "DBAccount.h"
#import "Account.h"

@interface DBAccount (util)

//Can pass nil for account to just create in DB with accountID
+ (DBAccount*) createOrUpdateDBAccountWithAccountID:(NSString*)accountID
                                            account:(Account*)account;

+ (DBAccount*) retrieveDBAccountForAccountID:(NSString*)accountID;

+ (NSArray*) getAccountsForPendingMatches;
+ (NSArray*) retrieveAccountsInMessages;
+ (NSArray*) retrieveAccountsInBlackbook;
+ (NSArray*)retrieveAccountIDsNotBurned;

+ (Account*)accountFromDBAccount:(DBAccount*)dbAccount;

- (void)save;

@end
