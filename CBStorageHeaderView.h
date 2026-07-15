#import <UIKit/UIKit.h>
#import "CBStorageInfo.h"

NS_ASSUME_NONNULL_BEGIN

/// 紧凑储存概览（首页 section 0 用，高度可控）
@interface CBStorageHeaderView : UIView
- (void)applyInfo:(CBStorageInfo *)info;
- (void)sizeToFitWidth:(CGFloat)width;
@end

NS_ASSUME_NONNULL_END
