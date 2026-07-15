#import "CBStorageHeaderView.h"
#import "CBCleanManager.h"
#import "CBTheme.h"

@interface CBStorageHeaderView ()
@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) UILabel *usedLabel;
@property (nonatomic, strong) UILabel *freeLabel;
@property (nonatomic, strong) UIView *track;
@property (nonatomic, strong) NSArray<UIView *> *segments;
@property (nonatomic, strong) UILabel *summaryLabel;
@property (nonatomic, copy) NSArray<NSNumber *> *fractions;
@end

@implementation CBStorageHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) [self build];
	return self;
}

- (void)build {
	self.backgroundColor = UIColor.clearColor;
	self.layoutMargins = UIEdgeInsetsMake(4, 0, 2, 0);

	_card = [UIView new];
	_card.translatesAutoresizingMaskIntoConstraints = NO;
	_card.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
	[CBTheme applyContinuousCorner:_card radius:14];
	[self addSubview:_card];

	_usedLabel = [UILabel new];
	_usedLabel.translatesAutoresizingMaskIntoConstraints = NO;
	_usedLabel.font = [UIFont monospacedDigitSystemFontOfSize:15 weight:UIFontWeightSemibold];
	_usedLabel.textColor = UIColor.labelColor;
	_usedLabel.adjustsFontSizeToFitWidth = YES;
	_usedLabel.minimumScaleFactor = 0.75;
	[_card addSubview:_usedLabel];

	_freeLabel = [UILabel new];
	_freeLabel.translatesAutoresizingMaskIntoConstraints = NO;
	_freeLabel.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightMedium];
	_freeLabel.textColor = UIColor.secondaryLabelColor;
	_freeLabel.textAlignment = NSTextAlignmentRight;
	[_card addSubview:_freeLabel];

	_track = [UIView new];
	_track.translatesAutoresizingMaskIntoConstraints = NO;
	_track.backgroundColor = UIColor.tertiarySystemFillColor;
	[CBTheme applyContinuousCorner:_track radius:3.5];
	_track.clipsToBounds = YES;
	[_card addSubview:_track];

	NSMutableArray *segs = [NSMutableArray array];
	for (int i = 0; i < 4; i++) {
		UIView *s = [UIView new];
		[_track addSubview:s];
		[segs addObject:s];
	}
	_segments = segs;

	_summaryLabel = [UILabel new];
	_summaryLabel.translatesAutoresizingMaskIntoConstraints = NO;
	_summaryLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
	_summaryLabel.textColor = UIColor.tertiaryLabelColor;
	_summaryLabel.adjustsFontSizeToFitWidth = YES;
	_summaryLabel.minimumScaleFactor = 0.8;
	[_card addSubview:_summaryLabel];

	UILayoutGuide *g = self.layoutMarginsGuide;
	[NSLayoutConstraint activateConstraints:@[
		[_card.topAnchor constraintEqualToAnchor:g.topAnchor],
		[_card.leadingAnchor constraintEqualToAnchor:g.leadingAnchor],
		[_card.trailingAnchor constraintEqualToAnchor:g.trailingAnchor],
		[_card.bottomAnchor constraintEqualToAnchor:g.bottomAnchor],

		[_usedLabel.topAnchor constraintEqualToAnchor:_card.topAnchor constant:10],
		[_usedLabel.leadingAnchor constraintEqualToAnchor:_card.leadingAnchor constant:14],

		[_freeLabel.centerYAnchor constraintEqualToAnchor:_usedLabel.centerYAnchor],
		[_freeLabel.trailingAnchor constraintEqualToAnchor:_card.trailingAnchor constant:-14],
		[_freeLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:_usedLabel.trailingAnchor constant:8],

		[_track.topAnchor constraintEqualToAnchor:_usedLabel.bottomAnchor constant:8],
		[_track.leadingAnchor constraintEqualToAnchor:_card.leadingAnchor constant:14],
		[_track.trailingAnchor constraintEqualToAnchor:_card.trailingAnchor constant:-14],
		[_track.heightAnchor constraintEqualToConstant:7],

		[_summaryLabel.topAnchor constraintEqualToAnchor:_track.bottomAnchor constant:7],
		[_summaryLabel.leadingAnchor constraintEqualToAnchor:_card.leadingAnchor constant:14],
		[_summaryLabel.trailingAnchor constraintEqualToAnchor:_card.trailingAnchor constant:-14],
		[_summaryLabel.bottomAnchor constraintEqualToAnchor:_card.bottomAnchor constant:-10],
	]];
}

- (void)applyInfo:(CBStorageInfo *)info {
	NSString *(^hs)(unsigned long long) = ^NSString *(unsigned long long b) {
		return [CBCleanManager.shared humanSize:b];
	};
	self.usedLabel.text = [NSString stringWithFormat:@"已用 %@ / %@", hs(info.usedBytes), hs(info.totalBytes)];
	self.freeLabel.text = [NSString stringWithFormat:@"可用 %@", hs(info.freeBytes)];
	NSString *app = info.appBytes ? hs(info.appBytes) : @"—";
	NSString *rec = info.reclaimableBytes > 0 ? hs(info.reclaimableBytes) : @"待扫描";
	self.summaryLabel.text = [NSString stringWithFormat:@"App %@ · 可释放 %@ · 其它 %@", app, rec, hs(info.otherBytes)];

	double total = MAX(1.0, (double)info.totalBytes);
	double aKeep = (double)info.appKeptBytes / total;
	double aClean = (double)info.reclaimableBytes / total;
	double otherR = (double)info.otherBytes / total;
	double free = (double)info.freeBytes / total;
	double sum = aKeep + aClean + otherR + free;
	if (sum > 1.001 && sum > 0) { aKeep /= sum; aClean /= sum; otherR /= sum; free /= sum; }
	self.fractions = @[@(aKeep), @(aClean), @(otherR), @(free)];
	NSArray *colors = @[CBTheme.accent, CBTheme.reclaimable, CBTheme.otherStorage, CBTheme.freeStorage];
	for (NSInteger i = 0; i < 4; i++) self.segments[i].backgroundColor = colors[i];
	[self setNeedsLayout];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	if (self.fractions.count < 4) return;
	CGFloat w = self.track.bounds.size.width;
	CGFloat h = self.track.bounds.size.height;
	if (w < 1) return;
	CGFloat x = 0;
	for (NSInteger i = 0; i < 4; i++) {
		CGFloat fw = w * MAX(0, [self.fractions[i] doubleValue]);
		if ([self.fractions[i] doubleValue] > 0.0005 && fw < 1.5) fw = 1.5;
		if (x + fw > w) fw = MAX(0, w - x);
		CGFloat gap = (i < 3 && fw > 2) ? 1.0 : 0;
		self.segments[i].frame = CGRectMake(x, 0, MAX(0, fw - gap), h);
		x += fw;
	}
}

- (void)sizeToFitWidth:(CGFloat)width {
	if (width < 1) width = UIScreen.mainScreen.bounds.size.width;
	self.bounds = CGRectMake(0, 0, width, 1);
	[self setNeedsLayout];
	[self layoutIfNeeded];
	CGSize size = [self systemLayoutSizeFittingSize:CGSizeMake(width, UILayoutFittingCompressedSize.height)
						  withHorizontalFittingPriority:UILayoutPriorityRequired
								verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
	self.frame = CGRectMake(0, 0, width, ceil(size.height));
}

@end
