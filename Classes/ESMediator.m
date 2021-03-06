//
//  ESMediator.m
//  ESMediator
//
//  Created by 翟泉 on 2017/1/10.
//  Copyright © 2017年 翟泉. All rights reserved.
//

#import "ESMediator.h"
#import <objc/runtime.h>
#import <objc/message.h>

@interface ESMediator ()

@property (nonatomic, strong) NSMutableDictionary *cachedTarget;

@end

@implementation ESMediator

#pragma mark - public methods
+ (instancetype)sharedInstance {
    static id mediator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mediator = [[self alloc] init];
    });
    return mediator;
}

+ (id)performTarget:(NSString *)targetName action:(NSString *)actionName params:(NSDictionary *)params {
    Class target = NSClassFromString(targetName);
    if (!target) {
        return nil;
    }
    @try {
        NSString *actionString = [NSString stringWithFormat:@"%@:", actionName];
        SEL action = NSSelectorFromString(actionString);
        return ((id (*)(Class, SEL, id))objc_msgSend)(target, action, params);
    } @catch (NSException *exception) {
        @try {
            NSString *actionString = [NSString stringWithFormat:@"%@WithParams:", actionName];
            SEL action = NSSelectorFromString(actionString);
            return ((id (*)(Class, SEL, id))objc_msgSend)(target, action, params);
        } @catch (NSException *exception) {
            return nil;
        }
    }
}

+ (id)performClass:(Class)class selector:(SEL)selector params:(NSDictionary *)params {
    
    NSMethodSignature  *signature = [class instanceMethodSignatureForSelector:selector];
    NSLog(@"%s", signature.methodReturnType);
    
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    if (params) {
        [invocation setArgument:(__bridge void * _Nonnull)(params) atIndex:0];
    }
    [invocation invoke];
    
    
    
    return nil;
}


/*
 scheme://[target]/[action]?[params]
 
 url sample:
 aaa://targetA/actionB?id=1234
 */

- (id)performActionWithUrl:(NSURL *)url completion:(void (^)(NSDictionary *))completion {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSString *urlString = [url query];
    for (NSString *param in [urlString componentsSeparatedByString:@"&"]) {
        NSArray *elts = [param componentsSeparatedByString:@"="];
        if([elts count] < 2) continue;
        [params setObject:[elts lastObject] forKey:[elts firstObject]];
    }
    
    // 这里这么写主要是出于安全考虑，防止黑客通过远程方式调用本地模块。这里的做法足以应对绝大多数场景，如果要求更加严苛，也可以做更加复杂的安全逻辑。
    NSString *actionName = [url.path stringByReplacingOccurrencesOfString:@"/" withString:@""];
    if ([actionName hasPrefix:@"native"]) {
        return @(NO);
    }
    
    // 这个demo针对URL的路由处理非常简单，就只是取对应的target名字和method名字，但这已经足以应对绝大部份需求。如果需要拓展，可以在这个方法调用之前加入完整的路由逻辑
    id result = [self performTarget:url.host action:actionName params:params shouldCacheTarget:NO];
    if (completion) {
        if (result) {
            completion(@{@"result":result});
        } else {
            completion(nil);
        }
    }
    return result;
}

- (id)performTarget:(NSString *)targetName action:(NSString *)actionName params:(NSDictionary *)params shouldCacheTarget:(BOOL)shouldCacheTarget {
    
    NSString *targetClassString = [NSString stringWithFormat:@"Target_%@", targetName];
    NSString *actionString = [NSString stringWithFormat:@"Action_%@:", actionName];
    Class targetClass;
    
    NSObject *target = self.cachedTarget[targetClassString];
    if (target == nil) {
        targetClass = NSClassFromString(targetClassString);
        target = [[targetClass alloc] init];
    }
    
    SEL action = NSSelectorFromString(actionString);
    
    if (target == nil) {
        // 这里是处理无响应请求的地方之一，这个demo做得比较简单，如果没有可以响应的target，就直接return了。实际开发过程中是可以事先给一个固定的target专门用于在这个时候顶上，然后处理这种请求的
        return nil;
    }
    
    if (shouldCacheTarget) {
        self.cachedTarget[targetClassString] = target;
    }
    
    if ([target respondsToSelector:action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [target performSelector:action withObject:params];
#pragma clang diagnostic pop
    } else {
        // 有可能target是Swift对象
        actionString = [NSString stringWithFormat:@"Action_%@WithParams:", actionName];
        action = NSSelectorFromString(actionString);
        if ([target respondsToSelector:action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            return [target performSelector:action withObject:params];
#pragma clang diagnostic pop
        } else {
            // 这里是处理无响应请求的地方，如果无响应，则尝试调用对应target的notFound方法统一处理
            SEL action = NSSelectorFromString(@"notFound:");
            if ([target respondsToSelector:action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                return [target performSelector:action withObject:params];
#pragma clang diagnostic pop
            } else {
                // 这里也是处理无响应请求的地方，在notFound都没有的时候，这个demo是直接return了。实际开发过程中，可以用前面提到的固定的target顶上的。
                [self.cachedTarget removeObjectForKey:targetClassString];
                return nil;
            }
        }
    }
}

- (void)releaseCachedTargetWithTargetName:(NSString *)targetName {
    NSString *targetClassString = [NSString stringWithFormat:@"Target_%@", targetName];
    [self.cachedTarget removeObjectForKey:targetClassString];
}

#pragma mark - getters and setters
- (NSMutableDictionary *)cachedTarget {
    if (_cachedTarget == nil) {
        _cachedTarget = [[NSMutableDictionary alloc] init];
    }
    return _cachedTarget;
}

@end
