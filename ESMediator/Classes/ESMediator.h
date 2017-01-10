//
//  ESMediator.h
//  ESMediator
//
//  Created by 翟泉 on 2017/1/10.
//  Copyright © 2017年 翟泉. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ESMediator : NSObject

+ (instancetype)sharedInstance;

// 远程App调用入口
- (id)performActionWithUrl:(NSURL *)url completion:(void(^)(NSDictionary *info))completion;
// 本地组件调用入口
- (id)performTarget:(NSString *)targetName action:(NSString *)actionName params:(NSDictionary *)params shouldCacheTarget:(BOOL)shouldCacheTarget;
- (void)releaseCachedTargetWithTargetName:(NSString *)targetName;

@end
