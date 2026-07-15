#import "CBDetailViewController.h"
#import "CBCleanManager.h"
#import "CBSettings.h"
#import "CBCopyUtil.h"
#import "CBTheme.h"
#import "CBGlassView.h"

@interface CBDetailViewController ()
@property (nonatomic, strong) CBAppInfo *app;
@property (nonatomic, strong) NSArray<CBCategoryStat *> *stats;
@property (nonatomic, strong) NSMutableIndexSet *selected;
@property (nonatomic, strong) UIAlertController *progressAlert;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UILabel *progressLabel;
@property (nonatomic, assign) BOOL scanning;
@property (nonatomic, strong) UIView *heroView;
@property (nonatomic, strong) UIImageView *heroIcon;
@property (nonatomic, strong) UILabel *heroName;
@property (nonatomic, strong) UILabel *heroMeta;
@property (nonatomic, strong) UILabel *heroSize;
@property (nonatomic, strong) UILabel *heroReclaim;
@end

@implementation CBDetailViewController

- (instancetype)initWithApp:(CBAppInfo *)app {
	self = [super initWithStyle:UITableViewStyleInsetGrouped];
	if (self) _app = app;
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = self.app.name;
	self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
	self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
	self.tableView.backgroundColor = UIColor.clearColor;
	self.tableView.separatorColor = UIColor.separatorColor;
	CBAmbientBackgroundView *ambient = [[CBAmbientBackgroundView alloc] initWithFrame:CGRectZero];
	self.tableView.backgroundView = ambient;
	self.tableView.rowHeight = UITableViewAutomaticDimension;
	self.tableView.estimatedRowHeight = 56;

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"清理"
																			  style:UIBarButtonItemStyleDone
																			 target:self
																			 action:@selector(cleanSelected)];

	[self buildHero];
	self.stats = [CBCleanManager.shared emptyCategoryStats];
	self.selected = [NSMutableIndexSet indexSet];
	for (CBCategoryStat *st in self.stats) {
		if (st.enabledByDefault) [self.selected addIndex:st.category];
	}
	[self refreshHero];
	[self.tableView reloadData];
	[self rescan];

	if (!self.app.icon) {
		dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
			[CBCleanManager.shared loadIconForApp:self.app];
			dispatch_async(dispatch_get_main_queue(), ^{
				[self refreshHero];
			});
		});
	}
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	CGFloat w = self.tableView.bounds.size.width;
	if (fabs(self.heroView.bounds.size.width - w) > 0.5) {
		[self sizeHero:w];
	}
}

- (void)buildHero {
	self.heroView = [UIView new];
	self.heroView.backgroundColor = UIColor.clearColor;

	CBGlassView *card = [[CBGlassView alloc] initWithStyle:CBGlassStylePanel];
	card.translatesAutoresizingMaskIntoConstraints = NO;
	card.tag = 100;
	card.cornerRadius = 24;
	UIView *inner = card.contentView;
	inner.tag = 101;
	[self.heroView addSubview:card];

	self.heroIcon = [UIImageView new];
	self.heroIcon.translatesAutoresizingMaskIntoConstraints = NO;
	self.heroIcon.contentMode = UIViewContentModeScaleAspectFill;
	self.heroIcon.clipsToBounds = YES;
	[CBTheme applyContinuousCorner:self.heroIcon radius:16];
	self.heroIcon.backgroundColor = UIColor.tertiarySystemFillColor;
	self.heroIcon.layer.borderWidth = 0.5;
	self.heroIcon.layer.borderColor = CBTheme.hairline.CGColor;
	[inner addSubview:self.heroIcon];

	self.heroName = [UILabel new];
	self.heroName.translatesAutoresizingMaskIntoConstraints = NO;
	self.heroName.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
	self.heroName.textColor = UIColor.labelColor;
	self.heroName.numberOfLines = 2;
	[inner addSubview:self.heroName];

	self.heroMeta = [UILabel new];
	self.heroMeta.translatesAutoresizingMaskIntoConstraints = NO;
	self.heroMeta.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
	self.heroMeta.textColor = UIColor.secondaryLabelColor;
	self.heroMeta.numberOfLines = 2;
	self.heroMeta.lineBreakMode = NSLineBreakByTruncatingMiddle;
	[inner addSubview:self.heroMeta];

	UIStackView *metrics = [[UIStackView alloc] init];
	metrics.translatesAutoresizingMaskIntoConstraints = NO;
	metrics.axis = UILayoutConstraintAxisHorizontal;
	metrics.spacing = 8;
	metrics.distribution = UIStackViewDistributionFillEqually;
	metrics.tag = 102;
	[inner addSubview:metrics];

	UILabel *sizeLab = nil;
	UILabel *recLab = nil;
	UIView *occCard = [self miniMetricTitle:@"占用" valueLabel:&sizeLab color:CBTheme.accent];
	UIView *recCard = [self miniMetricTitle:@"可释放" valueLabel:&recLab color:CBTheme.reclaimable];
	self.heroSize = sizeLab;
	self.heroReclaim = recLab;
	[metrics addArrangedSubview:occCard];
	[metrics addArrangedSubview:recCard];

	UILayoutGuide *mg = self.heroView.layoutMarginsGuide;
	self.heroView.layoutMargins = UIEdgeInsetsMake(8, 0, 12, 0);

	[NSLayoutConstraint activateConstraints:@[
		[card.topAnchor constraintEqualToAnchor:mg.topAnchor],
		[card.leadingAnchor constraintEqualToAnchor:mg.leadingAnchor],
		[card.trailingAnchor constraintEqualToAnchor:mg.trailingAnchor],
		[card.bottomAnchor constraintEqualToAnchor:mg.bottomAnchor],

		[self.heroIcon.leadingAnchor constraintEqualToAnchor:inner.leadingAnchor constant:18],
		[self.heroIcon.topAnchor constraintEqualToAnchor:inner.topAnchor constant:18],
		[self.heroIcon.widthAnchor constraintEqualToConstant:60],
		[self.heroIcon.heightAnchor constraintEqualToConstant:60],

		[self.heroName.leadingAnchor constraintEqualToAnchor:self.heroIcon.trailingAnchor constant:14],
		[self.heroName.topAnchor constraintEqualToAnchor:self.heroIcon.topAnchor constant:4],
		[self.heroName.trailingAnchor constraintEqualToAnchor:inner.trailingAnchor constant:-18],

		[self.heroMeta.leadingAnchor constraintEqualToAnchor:self.heroName.leadingAnchor],
		[self.heroMeta.topAnchor constraintEqualToAnchor:self.heroName.bottomAnchor constant:4],
		[self.heroMeta.trailingAnchor constraintEqualToAnchor:self.heroName.trailingAnchor],

		[metrics.topAnchor constraintEqualToAnchor:self.heroIcon.bottomAnchor constant:16],
		[metrics.leadingAnchor constraintEqualToAnchor:inner.leadingAnchor constant:14],
		[metrics.trailingAnchor constraintEqualToAnchor:inner.trailingAnchor constant:-14],
		[metrics.bottomAnchor constraintEqualToAnchor:inner.bottomAnchor constant:-16],
		[metrics.heightAnchor constraintEqualToConstant:58],
	]];

	[self sizeHero:UIScreen.mainScreen.bounds.size.width];
	self.tableView.tableHeaderView = self.heroView;
}

- (UIView *)miniMetricTitle:(NSString *)title valueLabel:(UILabel * __strong *)out color:(UIColor *)color {
	UIView *box = [UIView new];
	box.backgroundColor = [color colorWithAlphaComponent:0.10];
	[CBTheme applyContinuousCorner:box radius:12];

	UILabel *t = [UILabel new];
	t.translatesAutoresizingMaskIntoConstraints = NO;
	t.text = title;
	t.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
	t.textColor = UIColor.secondaryLabelColor;

	UILabel *v = [UILabel new];
	v.translatesAutoresizingMaskIntoConstraints = NO;
	v.font = [UIFont monospacedDigitSystemFontOfSize:17 weight:UIFontWeightBold];
	v.textColor = UIColor.labelColor;
	v.adjustsFontSizeToFitWidth = YES;
	v.minimumScaleFactor = 0.7;
	*out = v;

	UIView *bar = [UIView new];
	bar.translatesAutoresizingMaskIntoConstraints = NO;
	bar.backgroundColor = color;
	[CBTheme applyContinuousCorner:bar radius:1.5];

	[box addSubview:bar];
	[box addSubview:t];
	[box addSubview:v];
	[NSLayoutConstraint activateConstraints:@[
		[bar.leadingAnchor constraintEqualToAnchor:box.leadingAnchor constant:12],
		[bar.topAnchor constraintEqualToAnchor:box.topAnchor constant:12],
		[bar.widthAnchor constraintEqualToConstant:3],
		[bar.heightAnchor constraintEqualToConstant:11],
		[t.leadingAnchor constraintEqualToAnchor:bar.trailingAnchor constant:6],
		[t.centerYAnchor constraintEqualToAnchor:bar.centerYAnchor],
		[t.trailingAnchor constraintEqualToAnchor:box.trailingAnchor constant:-12],
		[v.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:4],
		[v.leadingAnchor constraintEqualToAnchor:box.leadingAnchor constant:12],
		[v.trailingAnchor constraintEqualToAnchor:box.trailingAnchor constant:-12],
		[v.bottomAnchor constraintEqualToAnchor:box.bottomAnchor constant:-10],
	]];
	return box;
}

- (void)sizeHero:(CGFloat)width {
	if (width < 1) width = UIScreen.mainScreen.bounds.size.width;
	self.heroView.bounds = CGRectMake(0, 0, width, 1);
	[self.heroView setNeedsLayout];
	[self.heroView layoutIfNeeded];
	CGSize size = [self.heroView systemLayoutSizeFittingSize:CGSizeMake(width, UILayoutFittingCompressedSize.height)
							   withHorizontalFittingPriority:UILayoutPriorityRequired
									 verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
	self.heroView.frame = CGRectMake(0, 0, width, ceil(size.height));
	self.tableView.tableHeaderView = self.heroView;
}

- (void)refreshHero {
	self.heroName.text = self.app.name.length ? self.app.name : self.app.bundleID;
	NSString *kind = self.app.isSystem ? @"系统 App" : @"用户 App";
	self.heroMeta.text = [NSString stringWithFormat:@"%@ · %@", kind, self.app.bundleID ?: @""];

	if (self.app.icon) {
		self.heroIcon.image = self.app.icon;
		self.heroIcon.contentMode = UIViewContentModeScaleAspectFill;
		self.heroIcon.tintColor = nil;
		self.heroIcon.backgroundColor = UIColor.clearColor;
	} else {
		UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:26 weight:UIImageSymbolWeightRegular];
		self.heroIcon.image = [UIImage systemImageNamed:self.app.isSystem ? @"gearshape.fill" : @"app.fill" withConfiguration:cfg];
		self.heroIcon.contentMode = UIViewContentModeCenter;
		self.heroIcon.tintColor = UIColor.secondaryLabelColor;
		self.heroIcon.backgroundColor = UIColor.tertiarySystemFillColor;
	}

	self.heroSize.text = self.app.totalContainerBytes > 0
		? [CBCleanManager.shared humanSize:self.app.totalContainerBytes] : @"—";
	self.heroReclaim.text = self.app.reclaimableBytes > 0
		? [CBCleanManager.shared humanSize:self.app.reclaimableBytes]
		: (self.scanning ? @"…" : @"—");
	[self sizeHero:self.tableView.bounds.size.width > 0 ? self.tableView.bounds.size.width : UIScreen.mainScreen.bounds.size.width];
}

- (void)rescan {
	if (self.scanning) return;
	self.scanning = YES;
	for (CBCategoryStat *st in self.stats) { st.detail = @"正在计算…"; st.bytes = 0; }
	[self refreshHero];
	[self.tableView reloadData];

	CBAppInfo *app = self.app;
	dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
		NSArray *stats = [CBCleanManager.shared scanCategoriesForApp:app];
		[CBCleanManager.shared scanReclaimableForApp:app measureContainer:YES];
		dispatch_async(dispatch_get_main_queue(), ^{
			self.scanning = NO;
			if (stats.count) {
				self.stats = stats;
				if (!self.selected.count) {
					self.selected = [NSMutableIndexSet indexSet];
					for (CBCategoryStat *st in stats) {
						if (st.enabledByDefault) [self.selected addIndex:st.category];
					}
				}
			}
			[self refreshHero];
			[self.tableView reloadData];
		});
	});
}

- (unsigned long long)selectedBytes {
	unsigned long long s = 0;
	for (CBCategoryStat *st in self.stats) {
		if ([self.selected containsIndex:st.category]) s += st.bytes;
	}
	return s;
}

- (void)cleanSelected {
	if (!self.selected.count) {
		[self alert:@"未选择项目" msg:@"请在下方选择要清理的类别。"];
		return;
	}
	void (^run)(void) = ^{
		[self showProgress:@"正在清理…"];
		[CBCleanManager.shared cleanApp:self.app categories:self.selected progress:^(NSString *message, double progress) {
			self.progressLabel.text = message;
			self.progressView.progress = (float)progress;
		} completion:^(NSError *error, unsigned long long freedBytes) {
			[self.progressAlert dismissViewControllerAnimated:YES completion:^{
				[self alert:@"完成" msg:[NSString stringWithFormat:@"释放约 %@", [CBCleanManager.shared humanSize:freedBytes]]];
				[self rescan];
			}];
		}];
	};
	if (CBSettingsBool(CBSettingConfirmBeforeClean)) {
		NSString *msg = self.scanning ? @"将按所选类别清理安全缓存。" :
			[NSString stringWithFormat:@"预计 %@", [CBCleanManager.shared humanSize:[self selectedBytes]]];
		UIAlertController *a = [UIAlertController alertControllerWithTitle:@"确认清理？" message:msg preferredStyle:UIAlertControllerStyleAlert];
		[a addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
		[a addAction:[UIAlertAction actionWithTitle:@"清理" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *_) { run(); }]];
		[self presentViewController:a animated:YES completion:nil];
	} else run();
}

- (void)showProgress:(NSString *)title {
	self.progressAlert = [UIAlertController alertControllerWithTitle:title message:@"\n\n" preferredStyle:UIAlertControllerStyleAlert];
	self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
	self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
	self.progressLabel = [UILabel new];
	self.progressLabel.translatesAutoresizingMaskIntoConstraints = NO;
	self.progressLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
	self.progressLabel.textAlignment = NSTextAlignmentCenter;
	self.progressLabel.numberOfLines = 2;
	self.progressLabel.textColor = UIColor.secondaryLabelColor;
	[self.progressAlert.view addSubview:self.progressView];
	[self.progressAlert.view addSubview:self.progressLabel];
	[NSLayoutConstraint activateConstraints:@[
		[self.progressView.leadingAnchor constraintEqualToAnchor:self.progressAlert.view.leadingAnchor constant:20],
		[self.progressView.trailingAnchor constraintEqualToAnchor:self.progressAlert.view.trailingAnchor constant:-20],
		[self.progressView.topAnchor constraintEqualToAnchor:self.progressAlert.view.topAnchor constant:56],
		[self.progressLabel.leadingAnchor constraintEqualToAnchor:self.progressAlert.view.leadingAnchor constant:16],
		[self.progressLabel.trailingAnchor constraintEqualToAnchor:self.progressAlert.view.trailingAnchor constant:-16],
		[self.progressLabel.topAnchor constraintEqualToAnchor:self.progressView.bottomAnchor constant:10],
		[self.progressAlert.view.heightAnchor constraintGreaterThanOrEqualToConstant:120],
	]];
	[self presentViewController:self.progressAlert animated:YES completion:nil];
}

- (void)alert:(NSString *)title msg:(NSString *)msg {
	UIAlertController *a = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
	[a addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
	[self presentViewController:a animated:YES completion:nil];
}

#pragma mark - Table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 3; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0) return 2; // 信息
	if (section == 1) return self.stats.count;
	return 2; // 重新扫描 / 打开
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0) return @"信息";
	if (section == 1) return @"清理类别";
	return @"更多";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	if (section == 1) {
		unsigned long long sel = [self selectedBytes];
		return [NSString stringWithFormat:@"已选预计可释放 %@。不会清理登录相关数据。",
				sel > 0 ? [CBCleanManager.shared humanSize:sel] : @"—"];
	}
	return nil;
}

- (UIImage *)symbol:(NSString *)name {
	return [UIImage systemImageNamed:name withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightMedium]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
		cell.backgroundColor = CBTheme.cardBackground;
		cell.backgroundView = nil;
		if (indexPath.row == 0) {
			cell.textLabel.text = @"标识符";
			cell.detailTextLabel.text = self.app.bundleID;
			cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
			cell.detailTextLabel.minimumScaleFactor = 0.6;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		} else {
			cell.textLabel.text = @"类型";
			cell.detailTextLabel.text = self.app.isSystem ? @"系统" : @"用户";
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
		return cell;
	}

	if (indexPath.section == 1) {
		CBCategoryStat *st = self.stats[indexPath.row];
		UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
		cell.backgroundColor = CBTheme.cardBackground;
		cell.backgroundView = nil;
		cell.selectionStyle = UITableViewCellSelectionStyleDefault;

		UIListContentConfiguration *cfg = [UIListContentConfiguration subtitleCellConfiguration];
		cfg.text = st.title.length ? st.title : [CBCleanManager.shared titleForCategory:st.category];
		NSString *sizeText = st.bytes > 0 ? [CBCleanManager.shared humanSize:st.bytes] : (self.scanning ? @"计算中…" : @"0 KB");
		cfg.secondaryText = sizeText;
		cfg.textProperties.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
		cfg.secondaryTextProperties.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightMedium];
		cfg.secondaryTextProperties.color = st.bytes > 0 ? CBTheme.reclaimable : UIColor.tertiaryLabelColor;
		cfg.image = [self symbolForCategory:st.category];
		cfg.imageProperties.tintColor = CBTheme.accent;
		cfg.imageProperties.preferredSymbolConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightMedium];
		cell.contentConfiguration = cfg;

		BOOL on = [self.selected containsIndex:st.category];
		cell.accessoryType = on ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
		cell.tintColor = CBTheme.accent;
		return cell;
	}

	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	cell.backgroundColor = CBTheme.cardBackground;
		cell.backgroundView = nil;
	UIListContentConfiguration *cfg = [UIListContentConfiguration cellConfiguration];
	cfg.textProperties.font = CBTheme.bodySemibold;
	if (indexPath.row == 0) {
		cfg.text = self.scanning ? @"正在扫描…" : @"重新扫描";
		cfg.textProperties.color = self.scanning ? UIColor.secondaryLabelColor : CBTheme.accent;
		cfg.image = [UIImage systemImageNamed:@"arrow.clockwise.circle.fill"];
		cfg.imageProperties.tintColor = cfg.textProperties.color;
	} else {
		cfg.text = @"打开 App";
		cfg.textProperties.color = CBTheme.accent;
		cfg.image = [UIImage systemImageNamed:@"arrow.up.forward.app.fill"];
		cfg.imageProperties.tintColor = CBTheme.accent;
	}
	cell.contentConfiguration = cfg;
	return cell;
}

- (UIImage *)symbolForCategory:(CBCleanCategory)cat {
	NSString *name = @"folder.fill";
	switch (cat) {
		case CBCleanCategoryCaches: name = @"internaldrive.fill"; break;
		case CBCleanCategoryTmp: name = @"clock.fill"; break;
		case CBCleanCategoryLogs: name = @"doc.text.fill"; break;
		case CBCleanCategoryWebKit: name = @"globe"; break;
		case CBCleanCategoryHTTPStorages: name = @"network"; break;
		case CBCleanCategorySnapshots: name = @"camera.viewfinder"; break;
		case CBCleanCategoryGroupCaches: name = @"rectangle.3.group.fill"; break;
		default: name = @"folder.fill"; break;
	}
	return [UIImage systemImageNamed:name];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.section == 0 && indexPath.row == 0) {
		[CBCopyUtil copyText:self.app.bundleID ?: @"" from:self title:@"已复制标识符"];
		return;
	}
	if (indexPath.section == 1) {
		CBCategoryStat *st = self.stats[indexPath.row];
		if ([self.selected containsIndex:st.category]) [self.selected removeIndex:st.category];
		else [self.selected addIndex:st.category];
		[tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
		return;
	}
	if (indexPath.section == 2) {
		if (indexPath.row == 0 && !self.scanning) [self rescan];
		else if (indexPath.row == 1) [CBCleanManager.shared openApp:self.app.bundleID error:nil];
	}
}

@end
