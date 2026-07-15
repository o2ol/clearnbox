#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CBCleanCategory) {
	CBCleanCategoryCaches = 0,
	CBCleanCategoryTmp,
	CBCleanCategoryLogs,
	CBCleanCategoryWebKit,
	CBCleanCategoryHTTPStorages,
	CBCleanCategorySnapshots,
	CBCleanCategoryGroupCaches,
	CBCleanCategoryCount
};

@interface CBAppInfo : NSObject
@property (nonatomic, copy) NSString *bundleID;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy, nullable) NSString *dataPath;
@property (nonatomic, copy, nullable) NSString *bundlePath;
@property (nonatomic, copy, nullable) NSString *appType; // System / User
@property (nonatomic, assign) BOOL isSystem;
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *groupPaths;
@property (nonatomic, strong, nullable) UIImage *icon;
@property (nonatomic, assign) unsigned long long reclaimableBytes; // last scan
@property (nonatomic, assign) unsigned long long totalContainerBytes; // data container / dynamic usage
@property (nonatomic, assign) unsigned long long staticDiskBytes; // app binary if known
@end

@interface CBCategoryStat : NSObject
@property (nonatomic, assign) CBCleanCategory category;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *detail;
@property (nonatomic, assign) unsigned long long bytes;
@property (nonatomic, copy) NSArray<NSString *> *paths;
@property (nonatomic, assign) BOOL enabledByDefault;
@property (nonatomic, assign) BOOL risky; // may affect login/session
@end

typedef void (^CBProgressBlock)(NSString *message, double progress);
typedef void (^CBDoneBlock)(NSError * _Nullable error, unsigned long long freedBytes);

@interface CBCleanManager : NSObject
+ (instancetype)shared;

- (NSArray<CBAppInfo *> *)listApps; // system + user with data containers
- (nullable CBAppInfo *)appInfoForBundleID:(NSString *)bundleID;

- (NSArray<CBCategoryStat *> *)emptyCategoryStats;
- (NSArray<CBCategoryStat *> *)scanCategoriesForApp:(CBAppInfo *)app;
/// 快速：只扫默认可清理路径；measureContainer=YES 时额外递归整个容器（详情页用，较慢）
- (unsigned long long)scanReclaimableForApp:(CBAppInfo *)app;
- (unsigned long long)scanReclaimableForApp:(CBAppInfo *)app measureContainer:(BOOL)measureContainer;
/// 批量并发扫描（比逐个串行快很多）
- (void)scanApps:(NSArray<CBAppInfo *> *)apps
		progress:(nullable CBProgressBlock)progress
	  completion:(void (^)(unsigned long long totalReclaimable))completion;

- (void)cleanApp:(CBAppInfo *)app
	  categories:(NSIndexSet *)categories
		progress:(nullable CBProgressBlock)progress
	  completion:(CBDoneBlock)completion;

- (void)cleanApps:(NSArray<CBAppInfo *> *)apps
	   categories:(NSIndexSet *)categories
		 progress:(nullable CBProgressBlock)progress
	   completion:(CBDoneBlock)completion;

- (BOOL)terminateApp:(NSString *)bundleID error:(NSError * _Nullable * _Nullable)error;
- (BOOL)openApp:(NSString *)bundleID error:(NSError * _Nullable * _Nullable)error;
- (NSString *)humanSize:(unsigned long long)bytes;
- (unsigned long long)directorySizePublic:(NSString *)path;
- (unsigned long long)directorySizeApprox:(NSString *)path;
- (void)loadIconForApp:(CBAppInfo *)app;
- (void)ensureGroupsForApp:(CBAppInfo *)app;
- (NSString *)titleForCategory:(CBCleanCategory)cat;
- (NSIndexSet *)defaultCategoryIndexSet;
@end

NS_ASSUME_NONNULL_END
