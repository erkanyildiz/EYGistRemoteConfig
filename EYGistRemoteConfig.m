// erkanyildiz
// 20190420-1535+0900
//
// EYGistRemoteConfig.m

#import "EYGistRemoteConfig.h"
#include <CommonCrypto/CommonDigest.h>

@implementation EYGistRemoteConfig

+ (void)fetchRemoteConfigWithGistID:(NSString *)gistID completion:(void(^)(id config, BOOL updated, NSError* error))completion
{
    NSString* gistInfoURL = [NSString stringWithFormat:@"https://api.github.com/gists/%@/commits", gistID];

    [self fetchJSONForURLString:gistInfoURL completion:^(NSArray* gistInfo, NSError *error)
    {
        if (error)
        {
            completion(nil, NO, error);
            return;
        }

        NSString* lastLocalCommitID = [NSUserDefaults.standardUserDefaults objectForKey:[self UDKey_lastLocalCommitID:gistID]];
        NSString* lastRemoteCommitID = gistInfo.firstObject[@"version"];
        id localContent = [NSUserDefaults.standardUserDefaults objectForKey:[self UDKey_localContent:gistID]];

        //NOTE: Latest version of the gist is already in local.
        if ([lastLocalCommitID isEqualToString:lastRemoteCommitID])
        {
            completion(localContent, NO, nil);
            return;
        }

        //NOTE: Assuming there is only one file in the gist. If not, first file is used.
        NSString* user = gistInfo.firstObject[@"user"][@"login"];
        NSString* gistRawURL = [NSString stringWithFormat:@"https://gist.githubusercontent.com/%@/%@/raw", user, gistID];
        [self fetchJSONForURLString:gistRawURL completion:^(id remoteContent, NSError *error)
        {
            if (error)
            {
                completion(nil, NO, error);
                return;
            }

            //NOTE: In case GitHub server is caching raw gist contents.
            NSString* localContentHash = [self SHA256:[self JSONString:localContent]];
            NSString* remoteContentHash = [self SHA256:[self JSONString:remoteContent]];
            if ([localContentHash isEqualToString:remoteContentHash])
            {
                completion(localContent, NO, nil);
                return;
            }

            [NSUserDefaults.standardUserDefaults setObject:remoteContent forKey:[self UDKey_localContent:gistID]];
            [NSUserDefaults.standardUserDefaults setObject:lastRemoteCommitID forKey:[self UDKey_lastLocalCommitID:gistID]];
            [NSUserDefaults.standardUserDefaults synchronize];
            completion(remoteContent, YES, nil);
        }];
    }];
}


+ (void)fetchJSONForURLString:(NSString *)URLString completion:(void (^)(id JSONResponse, NSError* error))completion
{
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0];
    NSURLSessionTask* task = [NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData* data, NSURLResponse* response, NSError* error)
    {
        if (error)
        {
            NSMutableDictionary* userInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
            userInfo[@"response"] = response;
            NSError* errorWithResponse = [NSError.alloc initWithDomain:error.domain code:error.code userInfo:userInfo];

            dispatch_async(dispatch_get_main_queue(), ^
            {
                completion(nil, errorWithResponse);
            });

            return;
        }

        NSError* JSONError = nil;
        id JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&JSONError];
        dispatch_async(dispatch_get_main_queue(), ^
        {
             completion(JSON, JSONError);
        });
    }];

    [task resume];
}


+ (NSString *)UDKey_localContent:(NSString *)gistID
{
    NSString* const kEYGistRemoteConfigLocalContentKey = @"kEYGistRemoteConfigUDKeyLocalContent_";
    return [kEYGistRemoteConfigLocalContentKey stringByAppendingString:gistID];
}


+ (NSString *)UDKey_lastLocalCommitID:(NSString *)gistID
{
    NSString* const kEYGistRemoteConfigLastLocalCommitIDKey = @"kEYGistRemoteConfigUDKeyLastLocalCommitID_";
    return [kEYGistRemoteConfigLastLocalCommitIDKey stringByAppendingString:gistID];
}


+ (id)latestLocalConfigWithGistID:(NSString *)gistID
{
    return [NSUserDefaults.standardUserDefaults objectForKey:[self UDKey_localContent:gistID]];
}


+ (void)clearLocalConfigWithGistID:(NSString *)gistID
{
    [NSUserDefaults.standardUserDefaults removeObjectForKey:[self UDKey_localContent:gistID]];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:[self UDKey_lastLocalCommitID:gistID]];
    [NSUserDefaults.standardUserDefaults synchronize];
}


+ (NSString *)JSONString:(id)object
{
    if (![NSJSONSerialization isValidJSONObject:object])
        return nil;

    NSData* data = [NSJSONSerialization dataWithJSONObject:object options:0 error:nil];
    return [NSString.alloc initWithData:data encoding:NSUTF8StringEncoding];
}


+ (NSString *)SHA256:(NSString *)string
{
    if (!string.length)
        return nil;

    const char* s = string.UTF8String;
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(s, (CC_LONG)strlen(s), digest);

    NSMutableString* hash = NSMutableString.new;
    for(int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++)
        [hash appendFormat:@"%02x", digest[i]];

    return hash;
}

@end
