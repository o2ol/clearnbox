#import "CBTheme.h"

@implementation CBTheme

+ (UIColor *)accent { return UIColor.systemBlueColor; }
+ (UIColor *)reclaimable { return UIColor.systemTealColor; }
+ (UIColor *)otherStorage { return UIColor.systemIndigoColor; }
+ (UIColor *)freeStorage {
	return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *t) {
		if (t.userInterfaceStyle == UIUserInterfaceStyleDark) {
			return [UIColor colorWithWhite:1 alpha:0.14];
		}
		return [UIColor colorWithWhite:0.82 alpha:1];
	}];
}
+ (UIColor *)systemBadge { return UIColor.systemIndigoColor; }
+ (UIColor *)userBadge { return UIColor.systemBlueColor; }
// 列表行用系统二级分组底，干净利落
+ (UIColor *)cardBackground { return UIColor.secondarySystemGroupedBackgroundColor; }
+ (UIColor *)groupedBackground { return UIColor.systemGroupedBackgroundColor; }
+ (UIColor *)hairline {
	return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *t) {
		return t.userInterfaceStyle == UIUserInterfaceStyleDark
			? [UIColor colorWithWhite:1 alpha:0.10]
			: [UIColor colorWithWhite:0 alpha:0.06];
	}];
}

+ (CGFloat)cardRadius { return 24; }
+ (CGFloat)chipRadius { return 14; }
+ (CGFloat)iconRadius { return 12; }

+ (void)applyCardShadow:(UIView *)view {
	view.layer.shadowColor = [UIColor blackColor].CGColor;
	view.layer.shadowOpacity = 0.10;
	view.layer.shadowRadius = 20;
	view.layer.shadowOffset = CGSizeMake(0, 10);
	view.layer.masksToBounds = NO;
}

+ (void)applyContinuousCorner:(UIView *)view radius:(CGFloat)radius {
	view.layer.cornerRadius = radius;
	if (@available(iOS 13.0, *)) {
		view.layer.cornerCurve = kCACornerCurveContinuous;
	}
}

+ (UIFont *)largeTitleFont { return [UIFont systemFontOfSize:34 weight:UIFontWeightBold]; }
+ (UIFont *)metricFont { return [UIFont monospacedDigitSystemFontOfSize:34 weight:UIFontWeightBold]; }
+ (UIFont *)metricSmallFont { return [UIFont monospacedDigitSystemFontOfSize:15 weight:UIFontWeightSemibold]; }
+ (UIFont *)sectionLabelFont { return [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold]; }
+ (UIFont *)bodySemibold { return [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold]; }
+ (UIFont *)captionMedium { return [UIFont systemFontOfSize:12 weight:UIFontWeightMedium]; }

+ (UIImageView *)settingsGlyph:(NSString *)symbolName color:(UIColor *)color {
	UIView *box = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 29, 29)];
	box.backgroundColor = color;
	[self applyContinuousCorner:box radius:7];
	UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:15 weight:UIImageSymbolWeightSemibold];
	UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:symbolName withConfiguration:cfg]];
	iv.tintColor = UIColor.whiteColor;
	iv.contentMode = UIViewContentModeCenter;
	iv.frame = box.bounds;
	iv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[box addSubview:iv];
	UIGraphicsBeginImageContextWithOptions(box.bounds.size, NO, 0);
	[box.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	UIImageView *out = [[UIImageView alloc] initWithImage:img];
	out.contentMode = UIViewContentModeScaleAspectFit;
	return out;
}

+ (UIView *)symbolBadge:(NSString *)name color:(UIColor *)color size:(CGFloat)size {
	UIView *wrap = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size, size)];
	wrap.translatesAutoresizingMaskIntoConstraints = NO;
	[wrap.widthAnchor constraintEqualToConstant:size].active = YES;
	[wrap.heightAnchor constraintEqualToConstant:size].active = YES;
	[self applyContinuousCorner:wrap radius:size * 0.224];
	wrap.backgroundColor = [color colorWithAlphaComponent:0.12];
	UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:size * 0.40 weight:UIImageSymbolWeightMedium];
	UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:name withConfiguration:cfg]];
	iv.translatesAutoresizingMaskIntoConstraints = NO;
	iv.tintColor = color;
	iv.contentMode = UIViewContentModeScaleAspectFit;
	[wrap addSubview:iv];
	[NSLayoutConstraint activateConstraints:@[
		[iv.centerXAnchor constraintEqualToAnchor:wrap.centerXAnchor],
		[iv.centerYAnchor constraintEqualToAnchor:wrap.centerYAnchor],
		[iv.widthAnchor constraintEqualToConstant:size * 0.46],
		[iv.heightAnchor constraintEqualToConstant:size * 0.46],
	]];
	return wrap;
}

@end
