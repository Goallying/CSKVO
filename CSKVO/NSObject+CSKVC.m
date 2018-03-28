//
//  NSObject+CSKVC.m
//  CSKVO
//
//  Created by 朱来飞 on 2018/3/28.
//  Copyright © 2018年 朱来飞. All rights reserved.
//

#import "NSObject+CSKVC.h"
#import <objc/runtime.h>
@implementation NSObject (CSKVC)

- (void)csSetValue:(id)value forKey:(NSString *)key{
    
    unsigned int ct = 0 ;
    Ivar * ivars = class_copyIvarList(self.class, &ct);
    for (int i = 0; i<ct ; i++) {
        Ivar  var = ivars[i];
        const char * name =  ivar_getName(var);
        NSString * cname = [[NSString stringWithUTF8String:name] substringFromIndex:1];
        if ([key isEqualToString:cname]) {
            object_setIvar(self, var, value);
            break ;
        }
    }
    
}
@end
