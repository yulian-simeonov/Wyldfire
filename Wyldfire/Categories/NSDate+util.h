//
//  NSDate+util.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 4/9/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (util)

- (NSDate *) toLocalTime;
- (NSDateComponents*)components;

@end
