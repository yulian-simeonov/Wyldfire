//
//  LikeRatioGraph.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/19/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LikeRatioGraph : UIView

- (void)setNumLikes:(int)likes andTimesBeenLiked:(int)liked;
- (void)animate;

@end
