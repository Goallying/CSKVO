//
//  ViewController.m
//  CSKVO
//
//  Created by 朱来飞 on 2018/3/23.
//  Copyright © 2018年 朱来飞. All rights reserved.
//

#import "ViewController.h"
#import "Person.h"
#import "NSObject+CSKVO.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    Person  * p = [[Person alloc]init];
    p.name = @"Tom";
    [p cs_addOberserver:self keyPath:@"name" callBack:^(id observer, NSString *keyPath, id oldValue, id newValue) {
        NSLog(@"oldValue == %@ ,newValue == %@" ,oldValue ,newValue);
    }];
    p.name = @"Bob";
    NSLog(@"=== %@", [p class]);
}



@end
