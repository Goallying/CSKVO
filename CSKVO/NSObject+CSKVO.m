//
//  NSObject+CSKVO.m
//  CSKVO
//
//  Created by 朱来飞 on 2018/3/23.
//  Copyright © 2018年 朱来飞. All rights reserved.
//

#import "NSObject+CSKVO.h"
#import <objc/runtime.h>
#import <objc/message.h>

//KVO 实现原理: aObject 调用addObserver系统会动态创建一个Aobject 的子类，重写改子类的的keyPath 的set方法，在set方法里面调用super setV:alueForKey: 来告诉aObject的属性值有所变化。系统的- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context 方法就是在调用set方法时候调用的.
@interface KVOInfo:NSObject

@property (nonatomic , weak) id observer ;
@property (nonatomic , copy) NSString * keyPath ;
@property (nonatomic , copy) CallBack callBack ;
@end

@implementation KVOInfo

- (instancetype)initWithObserver:(id)observer keyPath:(NSString *)keyPath callBack:(CallBack)callBack{
    
    if (self = [super init]) {
        _observer = observer ;
        _keyPath = keyPath ;
        _callBack = callBack ;
    }
    return self ;
}

@end


static  NSString * const CSKOVPrefix = @"CSKOVPrefix";
static  void * const KeyPathesKey = "KeyPathesKey";
@implementation NSObject (CSKVO)

- (void)cs_addOberserver:(id)observer keyPath:(NSString *)keyPath callBack:(CallBack)callBack {
    
    // set方法
    SEL setter = setterForKeyPath(keyPath);
    Class cls = [self class];
    Method setterMethod = class_getInstanceMethod(cls, setter);
    if (!setterMethod) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"invalid setter"] userInfo:nil];
    }
    //创建子类
    // self = AObject
    Class subCls = generateSubclsForClsName(cls);
    object_setClass(self, subCls);
    //self = CSKOVPrefixAObject
    
    //给子类添加setter方法并在IMP中重写。
    if (!clsDidImplementedSelector(subCls, setter)) {
//        class_addMethod(<#Class  _Nullable __unsafe_unretained cls#>, <#SEL  _Nonnull name#>, <#IMP  _Nonnull imp#>, <#const char * _Nullable types#>)
        const char * types = method_getTypeEncoding(setterMethod);
        class_addMethod(subCls, setter, (IMP)csSetter, types);
    }
    
    //保存监听事件，在重写set方法的时候需要。
    KVOInfo * info = [[KVOInfo alloc]initWithObserver:observer keyPath:keyPath callBack:callBack];
    // 可能会监听多个keyPath
    NSMutableArray * keyPathes = objc_getAssociatedObject(self, KeyPathesKey);
    if (!keyPathes) {
        keyPathes = [NSMutableArray array];
        objc_setAssociatedObject(self, KeyPathesKey, keyPathes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [keyPathes addObject:info];
    
}

// core Implement.
void csSetter(id self ,SEL _cmd ,id newValue){
    
    NSString * getterName = getterNameForSetter(_cmd);
    if (!getterName) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"invalid getterName" userInfo:nil];
        return;
    }
    id oldValue = [self valueForKey:getterName];
    [self willChangeValueForKey:getterName];
    
    struct objc_super superObj = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
//    objc_msgSendSuper(<#struct objc_super * _Nonnull super#>, <#SEL  _Nonnull op, ...#>)
//    struct objc_super {
//        /// Specifies an instance of a class.
//        __unsafe_unretained _Nonnull id receiver;
//
//        /// Specifies the particular superclass of the instance to message.
//#if !defined(__cplusplus)  &&  !__OBJC2__
//        /* For compatibility with old objc-runtime.h header */
//        __unsafe_unretained _Nonnull Class class;
//#else
//        __unsafe_unretained _Nonnull Class super_class;
//#endif
//        /* super_class is the first class to search */
//    };
    objc_msgSendSuper(&superObj, _cmd ,newValue);
    [self didChangeValueForKey:getterName];
    
    //在改完值之后，回调
    NSMutableArray * keyPathes = objc_getAssociatedObject(self, KeyPathesKey);
    for (KVOInfo * info in keyPathes) {
        if ([info.keyPath isEqualToString:getterName]) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                if (info.callBack) {
                    info.callBack(self, info.keyPath, oldValue, newValue);
                }
            });
        }
    }
    
}
BOOL clsDidImplementedSelector(Class cls ,SEL selector){
    
    unsigned int methodCount = 0 ;
    Method * methodList = class_copyMethodList(cls, &methodCount);
    for (int i = 0 ; i < methodCount; i++) {
        SEL sel = method_getName(methodList[i]);
        if (selector == sel) {
            return YES;
        }
    }
    free(methodList);
    return NO ;
}

Class generateSubclsForClsName(Class superCls){
    
    NSString * subClsName = [CSKOVPrefix stringByAppendingString:NSStringFromClass(superCls)]; ;
    Class subCls = NSClassFromString(subClsName);
    if (subCls) {return  subCls ;}
    
    //开始创建子类
//    subCls = objc_allocateClassPair(<#Class  _Nullable __unsafe_unretained superclass#>, <#const char * _Nonnull name#>, <#size_t extraBytes#>)
    subCls = objc_allocateClassPair(superCls, subClsName.UTF8String, 0);
    
    //不添加类方法的话，输出的就会是子类对象
    Method classMethod = class_getClassMethod(superCls, @selector(class));
    const char *types = method_getTypeEncoding(classMethod);
    class_addMethod(subCls, @selector(class), (IMP)CS_Class, types);
    
    objc_registerClassPair(subCls);
    
    return subCls ;
}
static Class CS_Class(id self){
    return class_getSuperclass(object_getClass(self));
}
NSString * getterNameForSetter(SEL setter){
    
    NSString * setterString = NSStringFromSelector(setter);
    if (setterString.length <= 0 || ![setterString hasPrefix:@"set"] || ![setterString hasSuffix:@":"]) { return nil;}
    NSRange range = NSMakeRange(3, setterString.length-4);
    NSString *getter = [setterString substringWithRange:range];
    NSString *firstString = [[getter substringToIndex:1] lowercaseString];
    getter = [getter stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstString];
    return getter;
}
// 获取keyPath 的setter 方法。
SEL setterForKeyPath(NSString *keyPath) {
    
    if (keyPath.length == 0 || [keyPath isEqualToString:@""]) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"invalid keyPath !"] userInfo:nil];
        return nil ;
    }
    NSString * firstCharacter = [[keyPath substringToIndex:1] uppercaseString];
    NSString * leftCharacter = [keyPath substringFromIndex:1];
    
    NSString * setterString = [NSString stringWithFormat:@"set%@%@:",firstCharacter ,leftCharacter];
    return NSSelectorFromString(setterString);
}
@end
