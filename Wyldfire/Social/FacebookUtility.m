//
//  FacebookUtility.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 3/19/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "FacebookUtility.h"

@implementation FacebookUtility

+ (void)handleAuthError:(NSError *)error
{
    NSString *alertText;
    NSString *alertTitle;
    
    if ([FBErrorUtility shouldNotifyUserForError:error] == YES){
        // Error requires people using you app to make an action outside your app to recover
        alertTitle = @"Something went wrong";
        alertText = [FBErrorUtility userMessageForError:error];
        [self showMessage:alertText withTitle:alertTitle];
        
    } else {
        // You need to find more information to handle the error within your app
        if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
            //The user refused to log in into your app, either ignore or...
            alertTitle = @"Login cancelled";
            alertText = @"You need to login to access this part of the app";
            [self showMessage:alertText withTitle:alertTitle];
            
        } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession){
            // We need to handle session closures that happen outside of the app
            alertTitle = @"Session Error";
            alertText = @"Your current session is no longer valid. Please log in again.";
            [self showMessage:alertText withTitle:alertTitle];
            
        } else {
            // All other errors that can happen need retries
            // Show the user a generic error message
            alertTitle = @"Something went wrong";
            alertText = @"Please try again.";
            [self showMessage:alertText withTitle:alertTitle];
        }
    }
}

+ (void)showMessage:(NSString *)text withTitle:(NSString *)title
{
    [[[UIAlertView alloc] initWithTitle:title
                                message:text
                               delegate:self
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

+ (void)getFriendsOfGender:(BOOL)searchMale success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSString* genderString = (searchMale ? @"male" : @"female");
    
    [FBRequestConnection startWithGraphPath:@"/me/friends?fields=id,name,gender,email"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                              if (!error) {
                                  //NSLog(@"user events: %@", result);
                                  NSMutableArray *list = [@[] mutableCopy];
                                  for (NSDictionary *item in result[@"data"]) {
                                      if ([item[@"gender"] isEqualToString:genderString]) {
                                          NSMutableDictionary *rec = [item mutableCopy];
                                          rec[@"account"] = @"facebook";
                                          rec[@"icon"] = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=small", rec[@"id"]];
                                          [list addObject:rec];
                                      }
                                  }
                                  //NSLog(@"getFacebookFriends: %d", (int)list.count);
                                  if (success) success(list);
                              } else {
                                  if (failure) failure(error.code);
                              }
                          }];
}

+ (void)getFriends:(SuccessBlock)success failure:(FailureBlock)failure
{
    [FBRequestConnection startWithGraphPath:@"/me/friends"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                              if (!error) {
                                  NSMutableArray *list = [@[] mutableCopy];
                                  for (NSDictionary *item in result[@"data"]) {
                                      NSMutableDictionary *rec = [item mutableCopy];
                                      rec[@"account"] = @"facebook";
                                      rec[@"icon"] = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=small", rec[@"id"]];
                                      [list addObject:rec];
                                  }
                                  NSLog(@"getFacebookFriends: %d", (int)list.count);
                                  if (success) success(list);
                              } else {
                                  if (failure) failure(error.code);
                              }
                          }];
}

+ (void)getAlbums:(SuccessBlock)success failure:(FailureBlock)failure
{
    //me/photos
    [FBRequestConnection startWithGraphPath:@"/me?fields=albums.fields(name,photos.limit(1).fields(picture),count)"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                              if (!error) {
                                  NSMutableArray *list = [@[] mutableCopy];
                                  for (NSDictionary *album in [WFCore toArray:result[@"albums"] name:@"data"]) {
                                      for (NSDictionary *icon in [WFCore toArray:album[@"photos"] name:@"data"]) {
                                          [list addObject:@{ @"type": @"facebook",
                                                             @"id": [WFCore toString:album name:@"id"],
                                                             @"name": [WFCore toString:album name:@"name"],
                                                             @"icon": [WFCore toString:icon name:@"picture"],
                                                             @"count": [WFCore toString:album name:@"count"] }];
                                      }
                                  }
                                  
                                  [FBRequestConnection startWithGraphPath:@"/me/photos?fields=picture"
                                                        completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                                            if (!error) {
                                                                
                                                                NSArray* photos = result[@"data"];
                                                                if (photos.count > 0) {
                                                                    NSDictionary* firstPhoto = photos[0];
                                                                    
                                                                    NSDictionary* rep = @{ @"type": @"facebook",
                                                                                       @"id": ALBUM_ID_PHOTOS_OF_YOU,
                                                                                       @"name": @"Photos of You",
                                                                                       @"icon": firstPhoto[@"picture"],
                                                                                       @"count":[@(photos.count) stringValue]};
                                                                    [list insertObject:rep atIndex:0];
                                                                }
                                                                //NSLog(@"getFacebookAlbums: %d", (int)list.count);
                                                                if (success) success(list);
                                                            } else {
                                                                if (failure) failure(error.code);
                                                            }
                                                        }];
                                  
                                  //NSLog(@"getFacebookAlbums: %d", (int)list.count);
                                  //if (success) success(list);
                              } else {
                                  if (failure) failure(error.code);
                              }
                          }];
}

+ (void)getAccount:(SuccessBlock)success failure:(FailureBlock)failure
{
    [FBRequestConnection startWithGraphPath:@"/me"
                 parameters:@{ @"fields": @"picture.type(large),id,email,name,username,birthday,gender" }
                 HTTPMethod:@"GET"
          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
              if (!error) {
                  if (success) success(result);
              } else {
                  if (failure) failure(error.code);
              }
          }];
}

+ (void)getPhotos:(NSString*)album page:(int)page success:(void (^)(NSString* next, NSArray* list))success failure:(FailureBlock)failure
{
    int limit = 50;
    int offset = limit * page;
    
    NSString* query = [NSString stringWithFormat:@"limit=%i&offset=%i", limit, offset];
    
    NSString* endpoint = [album isEqualToString:ALBUM_ID_PHOTOS_OF_YOU]
                    ? [NSString stringWithFormat:@"/me/photos?%@", query]
                    : [NSString stringWithFormat:@"/%@/photos?%@", album, query];
    
    [FBRequestConnection startWithGraphPath:endpoint
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                              if (!error) {
                                  NSMutableArray *list = [@[] mutableCopy];
                                  for (NSDictionary *item in result[@"data"]) {
                                      [list addObject:@{ @"type": @"facebook", @"icon": [WFCore toString:item name:@"picture"], @"image": [WFCore toString:item name:@"source"], @"photo": [WFCore toString:item name:@"source"] }];
                                  }
                                  if (success) success(result[@"paging"][@"next"], list);
                              } else {
                                  if (failure) failure(error.code);
                              }
                          }];
}



+ (void)getMutualFriends:(long long)facebookID success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSLog(@"FB: get mutual friends: %lld", facebookID);
    if (facebookID > 0) {
        [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/me/mutualfriends/%lli?fields=name,picture",facebookID,nil]
                              completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                  if (!error) {
                                      NSMutableArray *list = [@[] mutableCopy];
                                      for (NSMutableDictionary *item in result[@"data"]) {
                                          item[@"account"] = @"facebook";
                                          item[@"icon"] = [WFCore toDictionaryString:[WFCore toDictionary:item name:@"picture"] name:@"data" field:@"url"];
                                          [list addObject:item];
                                      }
                                      //NSLog(@"getFacebookMutualFriends: %d", (int)list.count);
                                      if (success) success(list);
                                  } else {
                                      if (failure) failure(error.code);
                                  }
                              }];
    } else {
        if (success) success(@[]);
    }
}

/*
 
 What i got with John:
 birthday = "01/01/1986";
 "first_name" = John;
 gender = male;
 id = 100004965990710;
 "last_name" = Smith;
 link = "https://www.facebook.com/profile.php?id=100004965990710";
 locale = "en_US";
 name = "John Smith";
 "updated_time" = "2013-04-03T17:19:48+0000";
 
 Sarah:
 "first_name" = Sarah;
 gender = female;
 id = 605819155;
 "last_name" = Cardey;
 link = "https://www.facebook.com/sarah.cardey";
 locale = "en_US";
 name = "Sarah Cardey";
 "updated_time" = "2014-05-01T16:25:50+0000";
 username = "sarah.cardey";
 work =     (
 {
 employer =             {
 id = 551159538283727;
 name = Wyldfire;
 };
 location =             {
 id = 110970792260960;
 name = "Los Angeles, California";
 };
 position =             {
 id = 142587042419517;
 name = "Operations & Marketing Manager";
 };
 "start_date" = "0000-00";
 }
 );
 
 Danny:
 {
 birthday = "12/14/1986";
 "first_name" = Danny;
 gender = male;
 hometown =     {
 id = 105658682801419;
 name = "Spokane, Washington";
 };
 id = 10723801;
 languages =     (
 {
 id = 106041969435776;
 name = Castellano;
 },
 {
 id = 106059522759137;
 name = English;
 }
 );
 "last_name" = Anderson;
 link = "https://www.facebook.com/thats.deadly";
 locale = "en_US";
 name = "Yulian Simeonov";
 "updated_time" = "2014-04-18T18:59:45+0000";
 username = "thats.deadly";
 }

 
 
 */
+ (void)getUserInfo:(long long)facebookID success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (facebookID > 0) {
        [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%lli/?fields=name,work,education",facebookID,nil]
                              completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                  if (!error) {
                                      NSLog(@"1 %@", result);
//
                                  } else {
                                      if (failure) failure(error.code);
                                  }
                              }];
        [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%lli/",facebookID,nil]
                              completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                  if (!error) {
                                      NSLog(@"2 %@", result);
                                      //
                                  } else {
                                      if (failure) failure(error.code);
                                  }
                              }];
        [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%lli/music",facebookID,nil]
                              completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                  if (!error) {
                                      NSLog(@"3 %@", result);
                                      //
                                  } else {
                                      if (failure) failure(error.code);
                                  }
                              }];
    } else {
        if (success) success(@[]);
    }
}

@end
