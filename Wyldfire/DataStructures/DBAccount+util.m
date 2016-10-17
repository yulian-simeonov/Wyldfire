//
//  DBAccount+util.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 4/2/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "DBAccount+util.h"

@implementation DBAccount (util)

- (void) updateUserWithAccount:(Account*)account
{
    if (account) {
        if(account.name)        self.name = account.name;
        if(account.age > 0)     self.age = @(account.age);
        if(account.alias)       self.alias = account.alias;
        if(account.accountID)   self.accountID = account.accountID;
        
        self.isMale = [NSNumber numberWithBool:account.isMale];
        
        if (account.avatarPhoto) {
            self.avatarPhoto = [self dataFromImage:account.avatarPhoto];
        }
        if (account.showcasePhoto) {
            self.showcasePhoto = [self dataFromImage:account.showcasePhoto];
        }
        
        NSMutableArray* imageDatas = [NSMutableArray new];
        for (UIImage* image in account.profilePhotos.allValues)
        {
            if ([image isKindOfClass:[UIImage class]])
                [imageDatas addObject:[self dataFromImage:image]];
        }
        
        if (imageDatas.count > 0) self.profilePhoto1 = imageDatas[0];
        if (imageDatas.count > 1) self.profilePhoto1 = imageDatas[1];
        if (imageDatas.count > 2) self.profilePhoto1 = imageDatas[2];
        if (imageDatas.count > 3) self.profilePhoto1 = imageDatas[3];
    }
    
    [self save];
}

- (void)save
{
    self.updated = [NSDate date];
    [CoreData save];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_UPDATED_PENDING_MATCHES object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_UPDATED_MESSAGES object:self];
}

- (UIImage*)imageFromData:(NSData*)data
{
    if (!data) return nil;
    
    return [UIImage imageWithData:data];
}

- (NSData*)dataFromImage:(UIImage*)image
{
    if (!image) return nil;
    
    NSData* data = nil;
    @try {
        data = UIImageJPEGRepresentation(image, 1.0);
    }
    @catch (NSException *exception) {
        data = nil;
    }
    @finally {
        return data;
    }
    
}

+ (DBAccount*) createOrUpdateDBAccountWithAccountID:(NSString*)accountID
                                            account:(Account*)account
{
    NSManagedObjectContext* context = [CoreData context];
    DBAccount* user = nil;
    
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"DBAccount"];
    request.predicate = [NSPredicate predicateWithFormat:@"accountID == %@", accountID];
    
    NSError *error = nil;
    NSArray* matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || ([matches count] > 1)) {
        NSLog(@"User lookup error, found multiple");
    } else
    if ([matches count] == 0) {
        user = (DBAccount*)[CoreData create:@"DBAccount"];
        user.created = [NSDate date];
        user.updated = [NSDate date];
        user.accountID = accountID;
        [user updateUserWithAccount:account];
        NSLog(@"User created");
    } else {
        user = [matches lastObject];
        user.updated = [NSDate date];
        [user updateUserWithAccount:account];
        NSLog(@"User update");
    }
    
    return user;
}

+ (DBAccount*) retrieveDBAccountForAccountID:(NSString*)accountID
{
    NSManagedObjectContext* context = [CoreData context];
    DBAccount* user = nil;
    
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"DBAccount"];
    request.predicate = [NSPredicate predicateWithFormat:@"accountID=%@",accountID];
    
    NSError* error = nil;
    NSArray* matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || ([matches count] > 1)) {
        NSLog(@"User lookup error, found multiple or error");
    } else if ([matches count] == 0) {
        NSLog(@"No users set");
    } else {
        user = [matches lastObject];
        NSLog(@"User found");
    }
    return user;
}

+ (Account*)accountFromDBAccount:(DBAccount*)dbAccount
{
    Account* account = [Account new];
    
    account.name = dbAccount.name;
    account.alias = dbAccount.alias;
    account.age = [dbAccount.age intValue];
    account.accountID = dbAccount.accountID;
    account.email = dbAccount.email;
    account.phone = dbAccount.phone;
    
    //Images
    account.avatarPhoto = [dbAccount imageFromData:dbAccount.avatarPhoto];
    account.showcasePhoto = [dbAccount imageFromData:dbAccount.showcasePhoto];
    for (int i = 1; i <= 4; i++) {
        NSString* propertyStr = [NSString stringWithFormat:@"profilePhoto%i", i];
        NSData* data = [dbAccount valueForKey:propertyStr];
        UIImage* image = [dbAccount imageFromData:data];
        [account setImage:image forType:i + 1];
    }
    
    return account;
}

+ (NSArray*) getAccountsForPendingMatches
{
    NSManagedObjectContext* context = [CoreData context];
    
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"DBAccount"];
    request.predicate = [NSPredicate predicateWithFormat:@"showInMatches=%@ AND burned=%@",[NSNumber numberWithBool:YES], [NSNumber numberWithBool:NO]];
    
    NSError* error = nil;
    NSArray* matches = [context executeFetchRequest:request error:&error];
    
    NSMutableArray* accounts = [NSMutableArray new];
    
    for (DBAccount* dbAccount in matches) {
        Account* account = [self accountFromDBAccount:dbAccount];
        
        [accounts addObject:account];
    }
    
    return accounts;
}


+ (NSArray*) retrieveAccountsInMessages
{
    NSManagedObjectContext* context = [CoreData context];
    
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"DBAccount"];
    request.predicate = [NSPredicate predicateWithFormat:@"inChat=%@ AND burned=%@",[NSNumber numberWithBool:YES], [NSNumber numberWithBool:NO]];
    
    NSError* error = nil;
    NSArray* matches = [context executeFetchRequest:request error:&error];
    
    NSMutableArray* accounts = [NSMutableArray new];
    
    for (DBAccount* dbAccount in matches) {
        Account* account = [self accountFromDBAccount:dbAccount];
        
        [accounts addObject:account];
    }
    
    return accounts;
}

+ (NSArray*)retrieveAccountsInBlackbook
{
    NSManagedObjectContext* context = [CoreData context];
    
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"DBAccount"];
    request.predicate = [NSPredicate predicateWithFormat:@"inBlackbook=%@ AND burned=%@",[NSNumber numberWithBool:YES], [NSNumber numberWithBool:NO]];
    
    NSError* error = nil;
    NSArray* matches = [context executeFetchRequest:request error:&error];
    
    NSMutableArray* accounts = [NSMutableArray new];
    
    for (DBAccount* dbAccount in matches) {
        Account* account = [self accountFromDBAccount:dbAccount];
        
        [accounts addObject:account];
    }
    
    return accounts;
}

+ (NSArray*)retrieveAccountIDsNotBurned
{
    NSManagedObjectContext* context = [CoreData context];
    
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"DBAccount"];
    request.predicate = [NSPredicate predicateWithFormat:@"burned=%@",[NSNumber numberWithBool:NO]];
    
    NSError* error = nil;
    NSArray* matches = [context executeFetchRequest:request error:&error];
    
    NSMutableArray* accounts = [NSMutableArray new];
    
    for (DBAccount* dbAccount in matches) {
        [accounts addObject:dbAccount.accountID];
    }
    
    return accounts;
}


@end
