// erkanyildiz
// 20190420-1535+0900
//
// EYGistRemoteConfig.h

#import <Foundation/Foundation.h>

@interface EYGistRemoteConfig : NSObject

/**
 * Fetches the gist with given gist ID, stores it locally and executes completion block with the result.
 * @discussion It first fetches gist info, and compares latest commit ID with locally stored commit ID.
 * If they are the same, it just executes the completion block with locally stored config as @c config, @c NO as @c updated flag, and @c nil as @c error.
 * If they are different, then it fetches the latest gist content, stores it locally and executes the completion block with fetched config as @c config, @c YES as @c updated flag, and @c nil as @c error.
 * @discussion If there is an error, it executes the completion block with @c nil as @c config, @c NO as @c updated flag, and the error as @c error.
 * @param gistID GitHub gist ID
 * @param completion Completion block to be executed when fetching is completed with result
 */
+ (void)fetchRemoteConfigWithGistID:(NSString *)gistID completion:(void(^)(id config, BOOL updated, NSError* error))completion;

/**
 * Clears locally stored gist with given gist ID
 * @param gistID GitHub gist ID
 */
+ (void)clearLocalConfigWithGistID:(NSString *)gistID;

/**
 * Returns locally stored gist with given gist ID
 * @discussion If there is no locally stored, it returns @c nil.
 * @param gistID GitHub gist ID
 */
+ (id)latestLocalConfigWithGistID:(NSString *)gistID;
@end
