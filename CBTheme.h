#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 净匣设计系统 — 统一色板、圆角、阴影与辅助视图
@interface CBTheme : NSObject

+ (UIColor *)accent;          // 主色
+ (UIColor *)reclaimable;     // 可释放
+ (UIColor *)otherStorage;    // 其它占用
+ (UIColor *)freeStorage;     // 可用条段
+ (UIColor *)systemBadge;     // 系统 App
+ (UIColor *)userBadge;       // 用户 App
+ (UIColor *)cardBackground;
+ (UIColor *)groupedBackground;
+ (UIColor *)hairline;

+ (CGFloat)cardRadius;
+ (CGFloat)chipRadius;
+ (CGFloat)iconRadius;

+ (void)applyCardShadow:(UIView *)view;
+ (void)applyContinuousCorner:(UIView *)view radius:(CGFloat)radius;

+ (UIFont *)largeTitleFont;
+ (UIFont *)metricFont;
+ (UIFont *)metricSmallFont;
+ (UIFont *)sectionLabelFont;
+ (UIFont *)bodySemibold;
+ (UIFont *)captionMedium;

/// iOS 设置风格彩色图标底板
+ (UIImageView *)settingsGlyph:(NSString *)symbolName color:(UIColor *)color;

/// 空状态 / 页头用装饰图标圆
+ (UIView *)symbolBadge:(NSString *)name color:(UIColor *)color size:(CGFloat)size;

@end

NS_ASSUME_NONNULL_END
