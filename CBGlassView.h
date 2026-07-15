#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CBGlassStyle) {
	/// 焦点大卡：储存总览 / 详情 Hero
	CBGlassStylePanel = 0,
	/// 指标小块
	CBGlassStyleTile,
};

/// 高质量玻璃面板（仅用于少量焦点组件，不做列表行）
@interface CBGlassView : UIView
@property (nonatomic, readonly) UIView *contentView;
@property (nonatomic, assign) CBGlassStyle style;
@property (nonatomic, assign) CGFloat cornerRadius;
- (instancetype)initWithStyle:(CBGlassStyle)style;
- (void)refreshAppearance;
@end

/// 极克制的氛围底：浅灰蓝径向柔光，不抢内容
@interface CBAmbientBackgroundView : UIView
- (void)refreshAppearance;
@end

NS_ASSUME_NONNULL_END
