//  Created by Monte Hurd on 7/30/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>

@class TitleOverlayLabel;
@interface TitleOverlayModel : NSObject

@property (nonatomic, strong) NSLayoutConstraint* topConstraint;
@property (nonatomic, strong) NSString* anchor;
@property (nonatomic, strong) NSString* title;
@property (nonatomic) CGFloat yOffset;

@property (nonatomic, strong) TitleOverlayLabel* label;

@end
