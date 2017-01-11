//
//  ViewController.m
//  ESMediator
//
//  Created by 翟泉 on 2017/1/10.
//  Copyright © 2017年 翟泉. All rights reserved.
//

#import "ViewController.h"
#import "ESMediator+Home.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "HomeInterface.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
//    NSMethodSignature  *signature = [[HomeInterface class] methodSignatureForSelector:@selector(setupCartCount:)];
//    NSLog(@"%s", signature.methodReturnType);
    
    [ESMediator setupCartCount:10086];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
