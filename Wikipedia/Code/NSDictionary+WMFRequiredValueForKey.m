//
//  NSDictionary+WMFRequiredValueForKey.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/11/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "NSDictionary+WMFRequiredValueForKey.h"

NS_ASSUME_NONNULL_BEGIN

NSString* const WMFInvalidValueForKeyErrorDomain = @"WMFInvalidValueForKeyErrorDomain";
NSString* const WMFFailingDictionaryUserInfoKey = @"WMFFailingDictionaryUserInfoKey";

@implementation NSDictionary (WMFRequiredValueForKey)

- (nullable id)wmf_nonnullValueOfType:(Class)type
                               forKey:(NSString*)key
                                error:(NSError* _Nullable  __autoreleasing*)outError {
    NSParameterAssert(key);
    NSError*(^errorWithCode)(WMFInvalidValueForKeyError) = ^(WMFInvalidValueForKeyError code) {
        return [NSError errorWithDomain:WMFInvalidValueForKeyErrorDomain
                                   code:code
                               userInfo:@{
            WMFFailingDictionaryUserInfoKey: self
        }];
    };
    id value = self[key];
    if (!value) {
        DDLogError(@"Unexpected nil for key %@ in %@.", key, self);
        WMFSafeAssign(outError, errorWithCode(WMFInvalidValueForKeyErrorNoValue));
        return nil;
    } else if ([[NSNull null] isEqual:value]) {
        DDLogError(@"Unexpected null for key %@ in %@.", key, self);
        WMFSafeAssign(outError, errorWithCode(WMFInvalidValueForKeyErrorNullValue));
        return nil;
    } else if (![value isKindOfClass:type]) {
        DDLogError(@"Expected instance of %@, but got %@ for key %@", type, [value class], key);
        WMFSafeAssign(outError, errorWithCode(WMFInvalidValueForKeyErrorIncorrectType));
        return nil;
    } else {
        return value;
    }
}

@end

NS_ASSUME_NONNULL_END
