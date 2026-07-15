#import "CBGlassView.h"
#import "CBTheme.h"

@interface CBGlassView ()
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UIView *fill;
@property (nonatomic, strong) UIView *rim;
@property (nonatomic, strong) UIView *specular;
@property (nonatomic, strong) UIView *contentHost;
@end

@implementation CBGlassView

- (instancetype)initWithStyle:(CBGlassStyle)style {
	self = [super initWithFrame:CGRectZero];
	if (self) {
		_style = style;
		_cornerRadius = (style == CBGlassStyleTile) ? 14.0 : 24.0;
		[self build];
	}
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
	return [self initWithStyle:CBGlassStylePanel];
}

- (void)build {
	self.backgroundColor = UIColor.clearColor;
	self.layer.masksToBounds = NO;

	// 1) 系统材质 — 比 UltraThin 更干净、更接近系统控件
	UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];
	_blurView = [[UIVisualEffectView alloc] initWithEffect:effect];
	_blurView.translatesAutoresizingMaskIntoConstraints = NO;
	_blurView.clipsToBounds = YES;
	[self addSubview:_blurView];

	// 2) 极薄色罩，统一玻璃色温（避免彩虹脏感）
	_fill = [UIView new];
	_fill.translatesAutoresizingMaskIntoConstraints = NO;
	_fill.userInteractionEnabled = NO;
	[_blurView.contentView addSubview:_fill];

	// 3) 1pt 描边容器（实色 alpha，不用渐变 mask，更稳）
	_rim = [UIView new];
	_rim.translatesAutoresizingMaskIntoConstraints = NO;
	_rim.userInteractionEnabled = NO;
	_rim.backgroundColor = UIColor.clearColor;
	[self addSubview:_rim];

	// 4) 顶部高光线（苹果玻璃的关键：一条细 specular）
	_specular = [UIView new];
	_specular.translatesAutoresizingMaskIntoConstraints = NO;
	_specular.userInteractionEnabled = NO;
	[self addSubview:_specular];

	_contentHost = [UIView new];
	_contentHost.translatesAutoresizingMaskIntoConstraints = NO;
	_contentHost.backgroundColor = UIColor.clearColor;
	[self addSubview:_contentHost];

	[NSLayoutConstraint activateConstraints:@[
		[_blurView.topAnchor constraintEqualToAnchor:self.topAnchor],
		[_blurView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
		[_blurView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
		[_blurView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],

		[_fill.topAnchor constraintEqualToAnchor:_blurView.contentView.topAnchor],
		[_fill.leadingAnchor constraintEqualToAnchor:_blurView.contentView.leadingAnchor],
		[_fill.trailingAnchor constraintEqualToAnchor:_blurView.contentView.trailingAnchor],
		[_fill.bottomAnchor constraintEqualToAnchor:_blurView.contentView.bottomAnchor],

		[_rim.topAnchor constraintEqualToAnchor:self.topAnchor],
		[_rim.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
		[_rim.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
		[_rim.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],

		[_specular.topAnchor constraintEqualToAnchor:self.topAnchor constant:0.5],
		[_specular.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:14],
		[_specular.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-14],
		[_specular.heightAnchor constraintEqualToConstant:0.66],

		[_contentHost.topAnchor constraintEqualToAnchor:self.topAnchor],
		[_contentHost.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
		[_contentHost.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
		[_contentHost.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
	]];

	[self refreshAppearance];
}

- (UIView *)contentView { return self.contentHost; }

- (void)setCornerRadius:(CGFloat)cornerRadius {
	_cornerRadius = cornerRadius;
	[self refreshAppearance];
}

- (void)setStyle:(CBGlassStyle)style {
	_style = style;
	[self refreshAppearance];
}

- (void)refreshAppearance {
	BOOL dark = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
	CGFloat r = self.cornerRadius;

	[CBTheme applyContinuousCorner:self.blurView radius:r];
	[CBTheme applyContinuousCorner:self.rim radius:r];
	[CBTheme applyContinuousCorner:self.contentHost radius:r];
	[CBTheme applyContinuousCorner:self.specular radius:0.5];

	self.blurView.layer.cornerRadius = r;
	self.blurView.clipsToBounds = YES;
	self.rim.layer.cornerRadius = r;
	self.rim.layer.borderWidth = 1.0 / UIScreen.mainScreen.scale * 2.0; // ~1pt hairline-ish
	// 真正 1pt
	self.rim.layer.borderWidth = 1.0;

	if (dark) {
		self.fill.backgroundColor = [UIColor colorWithWhite:1 alpha:0.04];
		self.rim.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.14].CGColor;
		self.specular.backgroundColor = [UIColor colorWithWhite:1 alpha:0.22];
		self.layer.shadowColor = [UIColor blackColor].CGColor;
		self.layer.shadowOpacity = 0.45;
		self.layer.shadowRadius = 28;
		self.layer.shadowOffset = CGSizeMake(0, 14);
	} else {
		// 浅色：玻璃略提亮，描边用冷白
		self.fill.backgroundColor = [UIColor colorWithWhite:1 alpha:0.28];
		self.rim.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.65].CGColor;
		self.specular.backgroundColor = [UIColor colorWithWhite:1 alpha:0.75];
		self.layer.shadowColor = [UIColor colorWithRed:0.15 green:0.22 blue:0.40 alpha:1].CGColor;
		self.layer.shadowOpacity = 0.14;
		self.layer.shadowRadius = 24;
		self.layer.shadowOffset = CGSizeMake(0, 12);
	}

	if (self.style == CBGlassStyleTile) {
		self.layer.shadowOpacity *= 0.55;
		self.layer.shadowRadius = 12;
		self.layer.shadowOffset = CGSizeMake(0, 6);
		if (dark) {
			self.fill.backgroundColor = [UIColor colorWithWhite:1 alpha:0.06];
		} else {
			self.fill.backgroundColor = [UIColor colorWithWhite:1 alpha:0.36];
		}
	}
	[self setNeedsLayout];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.cornerRadius].CGPath;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
	[super traitCollectionDidChange:previousTraitCollection];
	[self refreshAppearance];
}

@end

@interface CBAmbientBackgroundView ()
@property (nonatomic, strong) CAGradientLayer *base;
@property (nonatomic, strong) CAGradientLayer *glow;
@end

@implementation CBAmbientBackgroundView

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		self.userInteractionEnabled = NO;
		_base = [CAGradientLayer layer];
		_base.startPoint = CGPointMake(0.5, 0.0);
		_base.endPoint = CGPointMake(0.5, 1.0);
		[self.layer addSublayer:_base];

		_glow = [CAGradientLayer layer];
		_glow.type = kCAGradientLayerRadial;
		_glow.startPoint = CGPointMake(0.5, 0.0);
		_glow.endPoint = CGPointMake(1.0, 1.0);
		[self.layer addSublayer:_glow];

		[self refreshAppearance];
	}
	return self;
}

- (void)refreshAppearance {
	BOOL dark = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
	if (dark) {
		// 近系统 grouped 深色，只多一点点冷调
		self.base.colors = @[
			(id)[UIColor colorWithRed:0.07 green:0.08 blue:0.10 alpha:1].CGColor,
			(id)[UIColor colorWithRed:0.04 green:0.045 blue:0.055 alpha:1].CGColor,
		];
		self.glow.colors = @[
			(id)[UIColor colorWithRed:0.22 green:0.36 blue:0.62 alpha:0.22].CGColor,
			(id)[UIColor colorWithRed:0.22 green:0.36 blue:0.62 alpha:0.0].CGColor,
		];
	} else {
		// 接近 systemGroupedBackground，顶部微微冷光
		self.base.colors = @[
			(id)[UIColor colorWithRed:0.945 green:0.950 blue:0.965 alpha:1].CGColor,
			(id)[UIColor colorWithRed:0.925 green:0.930 blue:0.945 alpha:1].CGColor,
		];
		self.glow.colors = @[
			(id)[UIColor colorWithRed:0.55 green:0.68 blue:0.95 alpha:0.18].CGColor,
			(id)[UIColor colorWithRed:0.55 green:0.68 blue:0.95 alpha:0.0].CGColor,
		];
	}
	[self setNeedsLayout];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	self.base.frame = self.bounds;
	CGFloat w = self.bounds.size.width;
	CGFloat h = self.bounds.size.height;
	// 顶部中央一抹柔光即可
	self.glow.frame = CGRectMake(-w * 0.15, -h * 0.08, w * 1.3, h * 0.55);
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
	[super traitCollectionDidChange:previousTraitCollection];
	[self refreshAppearance];
}

@end
