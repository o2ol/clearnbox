#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CBStorageInfo : NSObject
@property (nonatomic, assign) unsigned long long totalBytes;
@property (nonatomic, assign) unsigned long long freeBytes;
@property (nonatomic, assign) unsigned long long usedBytes;
/// 列表内 App 数据占用合计
@property (nonatomic, assign) unsigned long long appBytes;
/// 扫描后的可释放
@property (nonatomic, assign) unsigned long long reclaimableBytes;
/// used - app（其余：系统/媒体/其它）
@property (nonatomic, assign, readonly) unsigned long long otherBytes;
/// app - reclaimable（App 中不可清部分，粗略）
@property (nonatomic, assign, readonly) unsigned long long appKeptBytes;

+ (instancetype)current;
- (void)refreshDevice;
@end

NS_ASSUME_NONNULL_END
