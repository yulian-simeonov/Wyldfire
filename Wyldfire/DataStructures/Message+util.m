//
//  Message+util.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 4/2/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "Message+util.h"

@implementation Message (util)

+ (Message*) createMessageWithSenderAccountID:(NSString*)accountID
                                        mtime:(long long)mtime
                                         text:(NSString*)text
                                        image:(UIImage*)image
                                         sent:(BOOL)sent
                                       notify:(BOOL)notify
{
    NSManagedObjectContext* context = [CoreData context];
    Message* message = nil;
    
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
    request.predicate = [NSPredicate predicateWithFormat:@"(senderAccountID == %@) AND (mtime = %@)", accountID, @(mtime)];
    
    NSError *error = nil;
    NSArray* matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || ([matches count] > 1)) {
        NSLog(@"Message lookup error, found multiple");
    } else
    if ([matches count] == 0) {
        message = (Message*)[CoreData create:@"Message"];
        message.created = [NSDate date];
        message.updated = [NSDate date];
        message.senderAccountID = accountID;
        message.text = [WFCore toString:text];
        message.image = [message dataFromImage:image];
        message.mtime = @(mtime);
        message.sent = [NSNumber numberWithBool:sent];
        message.unread = [NSNumber numberWithBool:YES];
        [message save];
        
        if (notify) {
            if (!sent) [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NEW_MESSAGES object:self userInfo:@{@"senderID" : message.senderAccountID}];
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_UPDATED_MESSAGES object:self];
        }
    } else {
        message = [matches lastObject];
        if (![message.text isEqualToString:text]) {
            NSLog(@"Error, existing message is different");
        }
    }
    
    return message;
}

+ (NSArray*) messagesForAccountID:(NSString*)accountID
{
    NSManagedObjectContext* context = [CoreData context];
    
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
    request.predicate = [NSPredicate predicateWithFormat:@"senderAccountID=%@",accountID];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"mtime" ascending:YES]];
    
    NSError* error = nil;
    NSArray* messages = [context executeFetchRequest:request error:&error];
    
    return messages;
}

+ (NSArray*) allMessages
{
    NSManagedObjectContext* context = [CoreData context];
    
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
    
    NSError* error = nil;
    NSArray* messages = [context executeFetchRequest:request error:&error];
    
    return messages;
}

+ (NSArray*) allUnreadMessages
{
    NSManagedObjectContext* context = [CoreData context];
    
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
    request.predicate = [NSPredicate predicateWithFormat:@"unread == %@ && senderAccountID != %@", @(YES), [WFCore get].accountStructure.accountID];
    
    NSError* error = nil;
    NSArray* messages = [context executeFetchRequest:request error:&error];
    
    //Cross reference with Accounts in Chat
    NSArray* accounts = [DBAccount retrieveAccountsInMessages];

    NSArray* accountIDs = [accounts valueForKeyPath:@"@unionOfObjects.accountID"];
    
    NSMutableArray* ret = [@[] mutableCopy];
    for (Message* message in messages) {
        if ([accountIDs containsObject:message.senderAccountID]) {
            [ret addObject:message];
        }
    }
    
    return ret;
}

+ (NSArray*) retrieveAccountsInMessages
{
    NSArray* messages = [self allMessages];
    
    NSMutableSet* senderAccountIDs = [NSMutableSet new];
    for (Message* message in messages)
    {
        [senderAccountIDs addObject:message.senderAccountID];
    }
    
    for (Account* account in [DBAccount retrieveAccountsInMessages])
    {
        [senderAccountIDs addObject:account.accountID];
    }
    
    [senderAccountIDs removeObject:[WFCore get].accountStructure.accountID];
    
    //Can use this line to debug
    //long long threeDaysAgo = ([[NSDate date] timeIntervalSince1970] - 0)  * 1000;
    long long threeDaysAgo = ([[NSDate date] timeIntervalSince1970] - 60 * 60 * 24 * 3)  * 1000;
    
    NSMutableArray* accounts = [NSMutableArray new];
    for (NSString* senderAccountID in senderAccountIDs)
    {
        DBAccount* dbAccount = [DBAccount retrieveDBAccountForAccountID:senderAccountID];
        
        if ([dbAccount.burned boolValue] || (!([dbAccount.inChat boolValue]))) continue;
        
        Account* account = [DBAccount accountFromDBAccount:dbAccount];
        NSArray* accountMessages = [self messagesForAccountID:senderAccountID];
        account.messageCount = (int)accountMessages.count;
        
        if (account.accountID != nil) {
            //Check if last message is over 72 hours ago
            BOOL staleChat = NO;
            
            Message* lastMessage;
            if (accountMessages.count > 0) {
                lastMessage = [accountMessages lastObject];
                if ([lastMessage.mtime longLongValue] < threeDaysAgo) {
                    staleChat = YES;
                    
                    for (Message* message in accountMessages) {
                        message.unread = [NSNumber numberWithBool:NO];
                    }
                    dbAccount.inChat = [NSNumber numberWithBool:NO];
                    [dbAccount save];
                }
            }
            
            if (!staleChat) {
                [accounts addObject:@{@"account" : account,
                                      @"mtime"   : lastMessage.mtime ?: [NSNumber numberWithInteger:0]}];
            }
            
        } else {
            for (Message* message in accountMessages) {
                if ([message.senderAccountID isEqualToString:senderAccountID] && [message.unread boolValue] ) {
                    message.unread = [NSNumber numberWithBool:NO];
                    [message save];
                }
            }
        }
    }
    
    NSSortDescriptor* sorter = [NSSortDescriptor sortDescriptorWithKey:@"mtime" ascending:NO];
    [accounts sortUsingDescriptors:@[sorter]];
    
    NSMutableArray* onlyAccounts = [NSMutableArray new];
    for (NSDictionary* dic in accounts) {
        [onlyAccounts addObject:dic[@"account"]];
    }
    
    return onlyAccounts;
}

+ (Message*) lastMessageForAccountID:(NSString*)accountID
{
    NSManagedObjectContext* context = [CoreData context];
    
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
    request.predicate = [NSPredicate predicateWithFormat:@"senderAccountID == %@",accountID];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"mtime" ascending:YES]];
    
    NSError* error = nil;
    NSArray* messages = [context executeFetchRequest:request error:&error];
    
    if (messages.count == 0) return nil;
    
    return [messages lastObject];
}

- (void)save
{
    self.updated = [NSDate date];
    [CoreData save];
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

- (UIImage*)uiImage
{
    return [self imageFromData:self.image];
}

+ (BOOL)hasUnreadMessages
{
    return [self allUnreadMessages].count > 0;
}

@end
