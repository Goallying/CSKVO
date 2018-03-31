//
//  Person.h
//  CSKVO
//
//  Created by 朱来飞 on 2018/3/24.
//  Copyright © 2018年 朱来飞. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Pet.h"
@interface Person : NSObject

@property (nonatomic ,copy) NSString * name ;
@property (nonatomic ,strong) Pet * pet ;

@end
