//
//  ESMediator+Home.m
//  ESMediator
//
//  Created by 翟泉 on 2017/1/10.
//  Copyright © 2017年 翟泉. All rights reserved.
//

#import "ESMediator+Home.h"

@implementation ESMediator (Home)

+ (void)setupCartCount:(NSInteger)cartCount {
    [self performTarget:@"HomeInterface" action:@"setupCartCount" params:@{@"count": @(cartCount)}];
}

@end
