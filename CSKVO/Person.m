//
//  Person.m
//  CSKVO
//
//  Created by 朱来飞 on 2018/3/24.
//  Copyright © 2018年 朱来飞. All rights reserved.
//

#import "Person.h"

@implementation Person

- (instancetype)init{
    if (self = [super init]) {
        _pet = [Pet new];
    }
    return self ;
}
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key{
    
    return YES ;
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(NSString *)key{
    
    if ([key isEqualToString:@"pet"]) {
       return [NSSet setWithObjects:@"_pet.petName", nil];
    }
    return [super keyPathsForValuesAffectingValueForKey:key];
    
}


@end
