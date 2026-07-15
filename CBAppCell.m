#import "CBAppCell.h"
#import "CBCleanManager.h"
#import "CBTheme.h"

@interface CBAppCell ()
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *sizeLabel;
@property (nonatomic, strong) UILabel *reclaimLabel;
@end

@implementation CBAppCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
	if (self) {
		self.selectionStyle = UITableViewCellSelectionStyleDefault;
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		self.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;

		_iconView = [UIImageView new];
		_iconView.translatesAutoresizingMaskIntoConstraints = NO;
		_iconView.contentMode = UIViewContentModeScaleAspectFill;
		_iconView.clipsToBounds = YES;
		[CBTheme applyContinuousCorner:_iconView radius:10];
		_iconView.backgroundColor = UIColor.tertiarySystemFillColor;
		[self.contentView addSubview:_iconView];

		_nameLabel = [UILabel new];
		_nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
		_nameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
		_nameLabel.textColor = UIColor.labelColor;
		_nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
		[self.contentView addSubview:_nameLabel];

		_subtitleLabel = [UILabel new];
		_subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
		_subtitleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
		_subtitleLabel.textColor = UIColor.secondaryLabelColor;
		_subtitleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
		[self.contentView addSubview:_subtitleLabel];

		_sizeLabel = [UILabel new];
		_sizeLabel.translatesAutoresizingMaskIntoConstraints = NO;
		_sizeLabel.font = [UIFont monospacedDigitSystemFontOfSize:15 weight:UIFontWeightRegular];
		_sizeLabel.textColor = UIColor.secondaryLabelColor;
		_sizeLabel.textAlignment = NSTextAlignmentRight;
		[_sizeLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
		[self.contentView addSubview:_sizeLabel];

		_reclaimLabel = [UILabel new];
		_reclaimLabel.translatesAutoresizingMaskIntoConstraints = NO;
		_reclaimLabel.font = [UIFont monospacedDigitSystemFontOfSize:11 weight:UIFontWeightMedium];
		_reclaimLabel.textColor = CBTheme.reclaimable;
		_reclaimLabel.textAlignment = NSTextAlignmentRight;
		[self.contentView addSubview:_reclaimLabel];

		UILayoutGuide *g = self.contentView.layoutMarginsGuide;
		[NSLayoutConstraint activateConstraints:@[
			[_iconView.leadingAnchor constraintEqualToAnchor:g.leadingAnchor],
			[_iconView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
			[_iconView.widthAnchor constraintEqualToConstant:40],
			[_iconView.heightAnchor constraintEqualToConstant:40],

			[_nameLabel.leadingAnchor constraintEqualToAnchor:_iconView.trailingAnchor constant:12],
			[_nameLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:10],
			[_nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_sizeLabel.leadingAnchor constant:-10],

			[_subtitleLabel.leadingAnchor constraintEqualToAnchor:_nameLabel.leadingAnchor],
			[_subtitleLabel.topAnchor constraintEqualToAnchor:_nameLabel.bottomAnchor constant:2],
			[_subtitleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_reclaimLabel.leadingAnchor constant:-8],
			[_subtitleLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-10],

			[_sizeLabel.trailingAnchor constraintEqualToAnchor:g.trailingAnchor],
			[_sizeLabel.centerYAnchor constraintEqualToAnchor:_nameLabel.centerYAnchor],

			[_reclaimLabel.trailingAnchor constraintEqualToAnchor:_sizeLabel.trailingAnchor],
			[_reclaimLabel.centerYAnchor constraintEqualToAnchor:_subtitleLabel.centerYAnchor],
		]];
	}
	return self;
}

- (void)configureWithApp:(CBAppInfo *)app maxOccupied:(unsigned long long)maxOccupied {
	(void)maxOccupied;
	self.nameLabel.text = app.name.length ? app.name : app.bundleID;

	if (app.icon) {
		self.iconView.image = app.icon;
		self.iconView.contentMode = UIViewContentModeScaleAspectFill;
		self.iconView.tintColor = nil;
		self.iconView.backgroundColor = UIColor.clearColor;
	} else {
		UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightRegular];
		self.iconView.image = [UIImage systemImageNamed:app.isSystem ? @"gearshape.fill" : @"app.fill" withConfiguration:cfg];
		self.iconView.contentMode = UIViewContentModeCenter;
		self.iconView.tintColor = UIColor.secondaryLabelColor;
		self.iconView.backgroundColor = UIColor.tertiarySystemFillColor;
	}

	self.subtitleLabel.text = [NSString stringWithFormat:@"%@ · %@", app.isSystem ? @"系统" : @"用户", app.bundleID ?: @""];
	self.sizeLabel.text = app.totalContainerBytes > 0 ? [CBCleanManager.shared humanSize:app.totalContainerBytes] : @"—";

	if (app.reclaimableBytes > 0) {
		self.reclaimLabel.text = [NSString stringWithFormat:@"可清 %@", [CBCleanManager.shared humanSize:app.reclaimableBytes]];
		self.reclaimLabel.hidden = NO;
	} else {
		self.reclaimLabel.text = @"";
		self.reclaimLabel.hidden = YES;
	}
}

- (void)prepareForReuse {
	[super prepareForReuse];
	self.iconView.image = nil;
	self.nameLabel.text = nil;
	self.subtitleLabel.text = nil;
	self.sizeLabel.text = nil;
	self.reclaimLabel.text = nil;
}

@end
