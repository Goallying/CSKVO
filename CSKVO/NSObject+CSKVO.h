//
//  NSObject+CSKVO.h
//  CSKVO
//
//  Created by 朱来飞 on 2018/3/23.
//  Copyright © 2018年 朱来飞. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^CallBack)(id observer ,NSString * keyPath ,id oldValue ,id newValue);

@interface NSObject (CSKVO)

- (void)cs_addOberserver:(id)observer keyPath:(NSString *)keyPath callBack:(CallBack)callBack ;


@end
