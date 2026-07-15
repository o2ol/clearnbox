#import "CBRootViewController.h"
#import "CBCleanManager.h"
#import "CBDetailViewController.h"
#import "CBSettings.h"
#import "CBAppCell.h"
#import "CBStorageInfo.h"
#import "CBStorageHeaderView.h"
#import "CBTheme.h"

@interface CBRootViewController () <UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *filterBar;
@property (nonatomic, strong) UIVisualEffectView *filterBlur;
@property (nonatomic, strong) NSArray<CBAppInfo *> *allApps;
@property (nonatomic, strong) NSArray<CBAppInfo *> *apps;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) UISegmentedControl *filter;
@property (nonatomic, assign) NSInteger filterIndex;
@property (nonatomic, strong) UIAlertController *progressAlert;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UILabel *progressLabel;
@property (nonatomic, assign) unsigned long long totalReclaimable;
@property (nonatomic, assign) unsigned long long totalOccupied;
@property (nonatomic, assign) unsigned long long maxOccupiedInList;
@property (nonatomic, assign) BOOL scanning;
@property (nonatomic, copy) NSString *sortMode;
@property (nonatomic, assign) BOOL sortDescending;
@property (nonatomic, assign) BOOL loadingIcons;
@property (nonatomic, strong) CBStorageInfo *storageInfo;
@property (nonatomic, strong) CBStorageHeaderView *storageHeader;
@end

@implementation CBRootViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = @"净匣";
	self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
	self.navigationController.navigationBar.prefersLargeTitles = YES;
	self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;

	// —— Sticky 筛选条（钉在导航栏下方，不随列表滚走）——
	self.filterBar = [UIView new];
	self.filterBar.translatesAutoresizingMaskIntoConstraints = NO;
	self.filterBar.backgroundColor = UIColor.clearColor;
	[self.view addSubview:self.filterBar];

	self.filterBlur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterial]];
	self.filterBlur.translatesAutoresizingMaskIntoConstraints = NO;
	[self.filterBar addSubview:self.filterBlur];

	UIView *sep = [UIView new];
	sep.translatesAutoresizingMaskIntoConstraints = NO;
	sep.backgroundColor = UIColor.separatorColor;
	sep.tag = 88;
	[self.filterBar addSubview:sep];

	self.filter = [[UISegmentedControl alloc] initWithItems:@[@"全部", @"系统", @"用户", @"可清"]];
	self.filter.translatesAutoresizingMaskIntoConstraints = NO;
	self.filter.selectedSegmentIndex = 0;
	[self.filter addTarget:self action:@selector(filterChanged) forControlEvents:UIControlEventValueChanged];
	[self.filterBar addSubview:self.filter];

	// —— 列表 ——
	self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
	self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
	self.tableView.separatorColor = UIColor.separatorColor;
	self.tableView.rowHeight = UITableViewAutomaticDimension;
	self.tableView.estimatedRowHeight = 64;
	self.tableView.separatorInset = UIEdgeInsetsMake(0, 68, 0, 0);
	if (@available(iOS 15.0, *)) self.tableView.sectionHeaderTopPadding = 4;
	[self.tableView registerClass:CBAppCell.class forCellReuseIdentifier:@"app"];
	[self.view addSubview:self.tableView];

	UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
	[NSLayoutConstraint activateConstraints:@[
		[self.filterBar.topAnchor constraintEqualToAnchor:safe.topAnchor],
		[self.filterBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
		[self.filterBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],

		[self.filterBlur.topAnchor constraintEqualToAnchor:self.filterBar.topAnchor],
		[self.filterBlur.leadingAnchor constraintEqualToAnchor:self.filterBar.leadingAnchor],
		[self.filterBlur.trailingAnchor constraintEqualToAnchor:self.filterBar.trailingAnchor],
		[self.filterBlur.bottomAnchor constraintEqualToAnchor:self.filterBar.bottomAnchor],

		[self.filter.topAnchor constraintEqualToAnchor:self.filterBar.topAnchor constant:8],
		[self.filter.leadingAnchor constraintEqualToAnchor:self.filterBar.leadingAnchor constant:16],
		[self.filter.trailingAnchor constraintEqualToAnchor:self.filterBar.trailingAnchor constant:-16],
		[self.filter.heightAnchor constraintEqualToConstant:32],
		[self.filter.bottomAnchor constraintEqualToAnchor:self.filterBar.bottomAnchor constant:-8],

		[sep.leadingAnchor constraintEqualToAnchor:self.filterBar.leadingAnchor],
		[sep.trailingAnchor constraintEqualToAnchor:self.filterBar.trailingAnchor],
		[sep.bottomAnchor constraintEqualToAnchor:self.filterBar.bottomAnchor],
		[sep.heightAnchor constraintEqualToConstant:1.0 / UIScreen.mainScreen.scale],

		[self.tableView.topAnchor constraintEqualToAnchor:self.filterBar.bottomAnchor],
		[self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
		[self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
		[self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
	]];

	self.storageInfo = [CBStorageInfo current];
	self.storageHeader = [[CBStorageHeaderView alloc] initWithFrame:CGRectZero];
	[self.storageHeader applyInfo:self.storageInfo];
	[self layoutStorageHeader];

	self.sortMode = CBSettingsString(CBSettingSortMode);
	if (!self.sortMode.length) self.sortMode = @"size";
	self.sortDescending = [CBSettingsDefaults() objectForKey:CBSettingSortDescending]
		? CBSettingsBool(CBSettingSortDescending) : YES;

	UIImageSymbolConfiguration *sym = [UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightRegular];
	UIBarButtonItem *sort = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"arrow.up.arrow.down" withConfiguration:sym]
															 style:UIBarButtonItemStylePlain
															target:self
															action:@selector(showSortMenu:)];
	sort.accessibilityLabel = @"排序";
	UIBarButtonItem *scan = [[UIBarButtonItem alloc] initWithTitle:@"扫描"
															 style:UIBarButtonItemStyleDone
															target:self
															action:@selector(scanAll)];
	self.navigationItem.rightBarButtonItems = @[sort, scan];

	self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
	self.searchController.searchResultsUpdater = self;
	self.searchController.obscuresBackgroundDuringPresentation = NO;
	self.searchController.searchBar.placeholder = @"搜索";
	self.navigationItem.searchController = self.searchController;
	self.navigationItem.hidesSearchBarWhenScrolling = YES;
	self.definesPresentationContext = YES;

	UIRefreshControl *rc = [UIRefreshControl new];
	[rc addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];
	self.tableView.refreshControl = rc;

	UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
	lp.minimumPressDuration = 0.45;
	[self.tableView addGestureRecognizer:lp];

	[self reload];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self refreshStorageHeader];
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	CGFloat w = self.tableView.bounds.size.width;
	if (fabs(self.storageHeader.bounds.size.width - w) > 0.5) {
		[self layoutStorageHeader];
	}
}

- (void)layoutStorageHeader {
	CGFloat w = self.tableView.bounds.size.width;
	if (w < 1) w = UIScreen.mainScreen.bounds.size.width;
	[self.storageHeader sizeToFitWidth:w];
	self.tableView.tableHeaderView = self.storageHeader;
}

- (void)refreshStorageHeader {
	[self.storageInfo refreshDevice];
	unsigned long long occ = self.totalOccupied;
	if (!occ) {
		for (CBAppInfo *a in self.allApps) occ += a.totalContainerBytes;
	}
	self.storageInfo.appBytes = occ;
	self.storageInfo.reclaimableBytes = self.totalReclaimable;
	[self.storageHeader applyInfo:self.storageInfo];
	[self layoutStorageHeader];
}

#pragma mark - Data

- (void)filterChanged {
	self.filterIndex = self.filter.selectedSegmentIndex;
	[self applyFilter:self.searchController.searchBar.text];
}

- (void)reload {
	dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
		NSArray *list = [CBCleanManager.shared listApps];
		dispatch_async(dispatch_get_main_queue(), ^{
			self.allApps = list;
			unsigned long long known = 0;
			for (CBAppInfo *a in list) known += a.totalContainerBytes;
			self.totalOccupied = known;
			[self applyFilter:self.searchController.searchBar.text];
			[self refreshStorageHeader];
			[self.tableView.refreshControl endRefreshing];
			[self loadVisibleIcons];
		});
	});
}

- (NSString *)sortModeTitle {
	NSString *m = self.sortMode ?: @"size";
	if ([m isEqualToString:@"name"]) return @"名称";
	if ([m isEqualToString:@"reclaimable"]) return @"可清理";
	if ([m isEqualToString:@"type"]) return @"类型";
	return @"占用";
}

- (void)applyFilter:(NSString *)text {
	NSString *q = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].lowercaseString;
	NSMutableArray *m = [NSMutableArray array];
	for (CBAppInfo *a in self.allApps) {
		if (self.filterIndex == 1 && !a.isSystem) continue;
		if (self.filterIndex == 2 && a.isSystem) continue;
		if (self.filterIndex == 3 && a.reclaimableBytes == 0) continue;
		if (q.length) {
			if (![a.name.lowercaseString containsString:q] && ![a.bundleID.lowercaseString containsString:q]) continue;
		}
		[m addObject:a];
	}
	[self sortAppsArray:m];
	self.apps = m;
	unsigned long long maxB = 0;
	for (CBAppInfo *a in m) {
		if (a.totalContainerBytes > maxB) maxB = a.totalContainerBytes;
	}
	self.maxOccupiedInList = maxB;
	[self.tableView reloadData];
	dispatch_async(dispatch_get_main_queue(), ^{ [self loadVisibleIcons]; });
}

- (void)sortAppsArray:(NSMutableArray<CBAppInfo *> *)m {
	NSString *mode = self.sortMode.length ? self.sortMode : @"size";
	BOOL desc = self.sortDescending;
	[m sortUsingComparator:^NSComparisonResult(CBAppInfo *a, CBAppInfo *b) {
		NSComparisonResult r = NSOrderedSame;
		if ([mode isEqualToString:@"name"]) {
			r = [a.name localizedStandardCompare:b.name];
		} else if ([mode isEqualToString:@"reclaimable"]) {
			if (a.reclaimableBytes < b.reclaimableBytes) r = NSOrderedAscending;
			else if (a.reclaimableBytes > b.reclaimableBytes) r = NSOrderedDescending;
			else r = [a.name localizedStandardCompare:b.name];
		} else if ([mode isEqualToString:@"type"]) {
			if (a.isSystem != b.isSystem) r = a.isSystem ? NSOrderedAscending : NSOrderedDescending;
			else r = [a.name localizedStandardCompare:b.name];
		} else {
			if (a.totalContainerBytes < b.totalContainerBytes) r = NSOrderedAscending;
			else if (a.totalContainerBytes > b.totalContainerBytes) r = NSOrderedDescending;
			else r = [a.name localizedStandardCompare:b.name];
		}
		if (desc) {
			if (r == NSOrderedAscending) return NSOrderedDescending;
			if (r == NSOrderedDescending) return NSOrderedAscending;
		}
		return r;
	}];
}

- (void)showSortMenu:(id)sender {
	UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"排序方式" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	__weak typeof(self) weakSelf = self;
	void (^pick)(NSString *) = ^(NSString *mode) {
		weakSelf.sortMode = mode;
		[CBSettingsDefaults() setObject:mode forKey:CBSettingSortMode];
		[weakSelf applyFilter:weakSelf.searchController.searchBar.text];
	};
	for (NSArray *item in @[@[@"size", @"占用空间"], @[@"reclaimable", @"可清理空间"], @[@"name", @"名称"], @[@"type", @"类型"]]) {
		NSString *title = item[1];
		if ([item[0] isEqualToString:self.sortMode]) title = [@"✓ " stringByAppendingString:title];
		[sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *_) { pick(item[0]); }]];
	}
	[sheet addAction:[UIAlertAction actionWithTitle:self.sortDescending ? @"升序" : @"降序" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_) {
		weakSelf.sortDescending = !weakSelf.sortDescending;
		[CBSettingsDefaults() setBool:weakSelf.sortDescending forKey:CBSettingSortDescending];
		[weakSelf applyFilter:weakSelf.searchController.searchBar.text];
	}]];
	[sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
	if ([sender isKindOfClass:UIBarButtonItem.class]) sheet.popoverPresentationController.barButtonItem = sender;
	[self presentViewController:sheet animated:YES completion:nil];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
	[self applyFilter:searchController.searchBar.text];
}

- (void)loadVisibleIcons {
	if (self.loadingIcons) return;
	NSArray<NSIndexPath *> *paths = [self.tableView indexPathsForVisibleRows];
	NSMutableArray<CBAppInfo *> *need = [NSMutableArray array];
	if (!paths.count) {
		NSInteger n = MIN((NSInteger)self.apps.count, 24);
		for (NSInteger i = 0; i < n; i++) {
			CBAppInfo *a = self.apps[i];
			if (!a.icon) [need addObject:a];
		}
	} else {
		for (NSIndexPath *ip in paths) {
			if (ip.section != 1) continue;
			if (ip.row < (NSInteger)self.apps.count) {
				CBAppInfo *a = self.apps[ip.row];
				if (!a.icon) [need addObject:a];
			}
		}
	}
	if (!need.count) return;
	self.loadingIcons = YES;
	__weak typeof(self) weakSelf = self;
	dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
		for (CBAppInfo *app in need) {
			@autoreleasepool { [CBCleanManager.shared loadIconForApp:app]; }
		}
		dispatch_async(dispatch_get_main_queue(), ^{
			__strong typeof(weakSelf) self = weakSelf;
			if (!self) return;
			self.loadingIcons = NO;
			NSArray *visible = [self.tableView indexPathsForVisibleRows];
			NSMutableArray *reload = [NSMutableArray array];
			for (NSIndexPath *ip in visible) {
				if (ip.section == 1) [reload addObject:ip];
			}
			if (reload.count) [self.tableView reloadRowsAtIndexPaths:reload withRowAnimation:UITableViewRowAnimationNone];
		});
	});
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if (!decelerate) [self loadVisibleIcons];
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	[self loadVisibleIcons];
}

#pragma mark - Scan / Clean

- (void)scanAll {
	if (self.scanning) return;
	self.scanning = YES;
	[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
	[self showProgress:@"正在扫描…"];
	NSArray *targets = self.allApps ?: @[];
	__weak typeof(self) weakSelf = self;
	[CBCleanManager.shared scanApps:targets progress:^(NSString *message, double progress) {
		[weakSelf updateProgress:message value:progress];
	} completion:^(unsigned long long sum) {
		__strong typeof(weakSelf) self = weakSelf;
		if (!self) return;
		self.totalReclaimable = sum;
		self.scanning = NO;
		[self hideProgress];
		[self applyFilter:self.searchController.searchBar.text];
		[self refreshStorageHeader];
		UIAlertController *a = [UIAlertController alertControllerWithTitle:@"扫描完成"
																   message:[NSString stringWithFormat:@"预计可释放 %@。\n不会清理登录相关数据。", [CBCleanManager.shared humanSize:sum]]
															preferredStyle:UIAlertControllerStyleAlert];
		[a addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
		[self presentViewController:a animated:YES completion:nil];
	}];
}

- (void)cleanVisible {
	NSMutableArray *withSize = [NSMutableArray array];
	unsigned long long sum = 0;
	for (CBAppInfo *a in self.apps) {
		if (a.reclaimableBytes > 0) { [withSize addObject:a]; sum += a.reclaimableBytes; }
	}
	if (!withSize.count) {
		UIAlertController *a = [UIAlertController alertControllerWithTitle:@"无法清理" message:@"请先扫描可清理空间。" preferredStyle:UIAlertControllerStyleAlert];
		[a addAction:[UIAlertAction actionWithTitle:@"扫描" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_) { [self scanAll]; }]];
		[a addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
		[self presentViewController:a animated:YES completion:nil];
		return;
	}
	void (^doClean)(void) = ^{
		[self showProgress:@"正在清理…"];
		[CBCleanManager.shared cleanApps:withSize categories:[CBCleanManager.shared defaultCategoryIndexSet] progress:^(NSString *message, double progress) {
			[self updateProgress:message value:progress];
		} completion:^(NSError *error, unsigned long long freedBytes) {
			[self hideProgress];
			[self alert:@"完成" msg:[NSString stringWithFormat:@"已处理 %lu 个 App，释放约 %@", (unsigned long)withSize.count, [CBCleanManager.shared humanSize:freedBytes]]];
			[self scanAll];
		}];
	};
	if (CBSettingsBool(CBSettingConfirmBeforeClean)) {
		UIAlertController *a = [UIAlertController alertControllerWithTitle:@"清理当前列表中的 App？"
																   message:[NSString stringWithFormat:@"%lu 个 · 预计 %@", (unsigned long)withSize.count, [CBCleanManager.shared humanSize:sum]]
															preferredStyle:UIAlertControllerStyleAlert];
		[a addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
		[a addAction:[UIAlertAction actionWithTitle:@"清理" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *_) { doClean(); }]];
		[self presentViewController:a animated:YES completion:nil];
	} else doClean();
}

- (void)showProgress:(NSString *)title {
	self.progressAlert = [UIAlertController alertControllerWithTitle:title message:@"\n\n" preferredStyle:UIAlertControllerStyleAlert];
	self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
	self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
	self.progressLabel = [UILabel new];
	self.progressLabel.translatesAutoresizingMaskIntoConstraints = NO;
	self.progressLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
	self.progressLabel.textColor = UIColor.secondaryLabelColor;
	self.progressLabel.textAlignment = NSTextAlignmentCenter;
	self.progressLabel.numberOfLines = 2;
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

- (void)updateProgress:(NSString *)message value:(double)value {
	dispatch_async(dispatch_get_main_queue(), ^{
		self.progressView.progress = (float)value;
		self.progressLabel.text = message ?: @"";
	});
}

- (void)hideProgress {
	[self.progressAlert dismissViewControllerAnimated:YES completion:nil];
	self.progressAlert = nil;
	self.progressView = nil;
	self.progressLabel = nil;
}

- (void)alert:(NSString *)title msg:(NSString *)msg {
	UIAlertController *a = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
	[a addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
	[self presentViewController:a animated:YES completion:nil];
}

#pragma mark - Long press

- (void)handleLongPress:(UILongPressGestureRecognizer *)gr {
	if (gr.state != UIGestureRecognizerStateBegan) return;
	CGPoint p = [gr locationInView:self.tableView];
	NSIndexPath *ip = [self.tableView indexPathForRowAtPoint:p];
	if (!ip || ip.section != 1 || ip.row >= (NSInteger)self.apps.count) return;
	CBAppInfo *app = self.apps[ip.row];
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:ip];
	UIAlertController *sheet = [UIAlertController alertControllerWithTitle:app.name message:app.bundleID preferredStyle:UIAlertControllerStyleActionSheet];
	__weak typeof(self) weakSelf = self;
	[sheet addAction:[UIAlertAction actionWithTitle:@"安全清理" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *_) {
		[weakSelf quickClean:app];
	}]];
	[sheet addAction:[UIAlertAction actionWithTitle:@"打开" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_) {
		[CBCleanManager.shared openApp:app.bundleID error:nil];
	}]];
	[sheet addAction:[UIAlertAction actionWithTitle:@"拷贝标识符" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_) {
		UIPasteboard.generalPasteboard.string = app.bundleID;
	}]];
	[sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
	if (cell) sheet.popoverPresentationController.sourceView = cell;
	[self presentViewController:sheet animated:YES completion:nil];
}

- (void)quickClean:(CBAppInfo *)app {
	void (^run)(void) = ^{
		[self showProgress:@"正在清理…"];
		[CBCleanManager.shared cleanApp:app categories:[CBCleanManager.shared defaultCategoryIndexSet] progress:^(NSString *message, double progress) {
			[self updateProgress:message value:progress];
		} completion:^(NSError *error, unsigned long long freedBytes) {
			[self hideProgress];
			[CBCleanManager.shared scanReclaimableForApp:app];
			unsigned long long sum = 0;
			for (CBAppInfo *a in self.allApps) sum += a.reclaimableBytes;
			self.totalReclaimable = sum;
			[self applyFilter:self.searchController.searchBar.text];
			[self refreshStorageHeader];
			[self alert:@"完成" msg:[NSString stringWithFormat:@"释放约 %@", [CBCleanManager.shared humanSize:freedBytes]]];
		}];
	};
	if (CBSettingsBool(CBSettingConfirmBeforeClean)) {
		UIAlertController *a = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"清理“%@”？", app.name]
																   message:@"将清理安全缓存，不会删除登录数据。"
															preferredStyle:UIAlertControllerStyleAlert];
		[a addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
		[a addAction:[UIAlertAction actionWithTitle:@"清理" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *_) { run(); }]];
		[self presentViewController:a animated:YES completion:nil];
	} else run();
}

#pragma mark - Table

// Section 0: 操作（单行双按钮）
// Section 1: App 列表
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 2; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0) return 1;
	return self.apps.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	if (section == 0) {
		return @"仅清理 Caches、临时文件、日志与快照，不会影响登录。";
	}
	if (section == 1) {
		return [NSString stringWithFormat:@"%lu 个 · %@%@",
				(unsigned long)self.apps.count,
				[self sortModeTitle],
				self.sortDescending ? @"降序" : @"升序"];
	}
	return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return UITableViewAutomaticDimension;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 1) return @"App";
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"actions"];
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"actions"];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;

			UIButton *scanBtn = [UIButton buttonWithType:UIButtonTypeSystem];
			scanBtn.tag = 101;
			scanBtn.translatesAutoresizingMaskIntoConstraints = NO;
			scanBtn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
			[scanBtn setTitle:@"扫描可清理" forState:UIControlStateNormal];
			scanBtn.backgroundColor = [UIColor.systemBlueColor colorWithAlphaComponent:0.12];
			[scanBtn setTitleColor:UIColor.systemBlueColor forState:UIControlStateNormal];
			scanBtn.layer.cornerRadius = 12;
			if (@available(iOS 13.0, *)) scanBtn.layer.cornerCurve = kCACornerCurveContinuous;
			[scanBtn addTarget:self action:@selector(scanAll) forControlEvents:UIControlEventTouchUpInside];
			[cell.contentView addSubview:scanBtn];

			UIButton *cleanBtn = [UIButton buttonWithType:UIButtonTypeSystem];
			cleanBtn.tag = 102;
			cleanBtn.translatesAutoresizingMaskIntoConstraints = NO;
			cleanBtn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
			[cleanBtn setTitle:@"清理列表" forState:UIControlStateNormal];
			cleanBtn.backgroundColor = [UIColor.systemRedColor colorWithAlphaComponent:0.10];
			[cleanBtn setTitleColor:UIColor.systemRedColor forState:UIControlStateNormal];
			cleanBtn.layer.cornerRadius = 12;
			if (@available(iOS 13.0, *)) cleanBtn.layer.cornerCurve = kCACornerCurveContinuous;
			[cleanBtn addTarget:self action:@selector(cleanVisible) forControlEvents:UIControlEventTouchUpInside];
			[cell.contentView addSubview:cleanBtn];

			UILayoutGuide *g = cell.contentView.layoutMarginsGuide;
			[NSLayoutConstraint activateConstraints:@[
				[scanBtn.leadingAnchor constraintEqualToAnchor:g.leadingAnchor],
				[scanBtn.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:12],
				[scanBtn.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor constant:-12],
				[scanBtn.heightAnchor constraintEqualToConstant:44],

				[cleanBtn.leadingAnchor constraintEqualToAnchor:scanBtn.trailingAnchor constant:10],
				[cleanBtn.trailingAnchor constraintEqualToAnchor:g.trailingAnchor],
				[cleanBtn.topAnchor constraintEqualToAnchor:scanBtn.topAnchor],
				[cleanBtn.bottomAnchor constraintEqualToAnchor:scanBtn.bottomAnchor],
				[cleanBtn.widthAnchor constraintEqualToAnchor:scanBtn.widthAnchor],
			]];
		}
		UIButton *scanBtn = [cell.contentView viewWithTag:101];
		scanBtn.enabled = !self.scanning;
		scanBtn.alpha = self.scanning ? 0.5 : 1.0;
		[scanBtn setTitle:self.scanning ? @"扫描中…" : @"扫描可清理" forState:UIControlStateNormal];
		return cell;
	}

	CBAppCell *cell = [tableView dequeueReusableCellWithIdentifier:@"app" forIndexPath:indexPath];
	[cell configureWithApp:self.apps[indexPath.row] maxOccupied:self.maxOccupiedInList];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.section == 0) return;
	CBAppInfo *app = self.apps[indexPath.row];
	[self.navigationController pushViewController:[[CBDetailViewController alloc] initWithApp:app] animated:YES];
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point {
	if (indexPath.section != 1) return nil;
	CBAppInfo *app = self.apps[indexPath.row];
	__weak typeof(self) weakSelf = self;
	return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil actionProvider:^UIMenu *(NSArray *suggested) {
		UIAction *clean = [UIAction actionWithTitle:@"安全清理" image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(__kindof UIAction *_) { [weakSelf quickClean:app]; }];
		clean.attributes = UIMenuElementAttributesDestructive;
		UIAction *open = [UIAction actionWithTitle:@"打开" image:[UIImage systemImageNamed:@"arrow.up.forward.app"] identifier:nil handler:^(__kindof UIAction *_) { [CBCleanManager.shared openApp:app.bundleID error:nil]; }];
		UIAction *copy = [UIAction actionWithTitle:@"拷贝标识符" image:[UIImage systemImageNamed:@"doc.on.doc"] identifier:nil handler:^(__kindof UIAction *_) { UIPasteboard.generalPasteboard.string = app.bundleID; }];
		return [UIMenu menuWithTitle:@"" children:@[clean, open, copy]];
	}];
}

@end
