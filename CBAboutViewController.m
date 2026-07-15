#import "CBAboutViewController.h"
#import "CBCopyUtil.h"
#import "CBTheme.h"
#import "CBGlassView.h"

static NSString * const kCBOpenSourceURL = @"https://github.com/o2ol/clearnbox";

@implementation CBAboutViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = @"关于";
	self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
	self.tableView.backgroundColor = UIColor.clearColor;
	self.tableView.separatorColor = UIColor.separatorColor;
	self.tableView.backgroundView = [[CBAmbientBackgroundView alloc] initWithFrame:CGRectZero];
	[self buildHeader];
}

- (void)buildHeader {
	UIView *wrap = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 168)];
	wrap.backgroundColor = UIColor.clearColor;

	UIView *badge = [CBTheme symbolBadge:@"internaldrive.fill" color:CBTheme.accent size:72];
	badge.translatesAutoresizingMaskIntoConstraints = NO;
	[wrap addSubview:badge];

	UILabel *name = [UILabel new];
	name.translatesAutoresizingMaskIntoConstraints = NO;
	name.text = @"净匣";
	name.font = [UIFont systemFontOfSize:26 weight:UIFontWeightBold];
	name.textAlignment = NSTextAlignmentCenter;
	[wrap addSubview:name];

	UILabel *sub = [UILabel new];
	sub.translatesAutoresizingMaskIntoConstraints = NO;
	sub.text = @"安全释放空间 · CleanBox";
	sub.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
	sub.textColor = UIColor.secondaryLabelColor;
	sub.textAlignment = NSTextAlignmentCenter;
	[wrap addSubview:sub];

	[NSLayoutConstraint activateConstraints:@[
		[badge.centerXAnchor constraintEqualToAnchor:wrap.centerXAnchor],
		[badge.topAnchor constraintEqualToAnchor:wrap.topAnchor constant:20],
		[name.topAnchor constraintEqualToAnchor:badge.bottomAnchor constant:14],
		[name.leadingAnchor constraintEqualToAnchor:wrap.leadingAnchor constant:20],
		[name.trailingAnchor constraintEqualToAnchor:wrap.trailingAnchor constant:-20],
		[sub.topAnchor constraintEqualToAnchor:name.bottomAnchor constant:4],
		[sub.leadingAnchor constraintEqualToAnchor:name.leadingAnchor],
		[sub.trailingAnchor constraintEqualToAnchor:name.trailingAnchor],
	]];
	self.tableView.tableHeaderView = wrap;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return 2; }

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
	return s == 0 ? 5 : 2;
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s {
	return s == 0 ? @"应用" : @"开源";
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
	UITableViewCell *c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
	c.backgroundColor = CBTheme.cardBackground;
	c.backgroundView = nil;
	c.textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
	c.detailTextLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
	c.detailTextLabel.textColor = UIColor.secondaryLabelColor;
	c.detailTextLabel.numberOfLines = 2;
	c.detailTextLabel.adjustsFontSizeToFitWidth = YES;
	c.detailTextLabel.minimumScaleFactor = 0.7;

	if (ip.section == 0) {
		switch (ip.row) {
			case 0:
				c.textLabel.text = @"名称";
				c.detailTextLabel.text = @"净匣 CleanBox";
				c.selectionStyle = UITableViewCellSelectionStyleNone;
				break;
			case 1:
				c.textLabel.text = @"作者";
				c.detailTextLabel.text = @"o2ol";
				c.selectionStyle = UITableViewCellSelectionStyleNone;
				break;
			case 2:
				c.textLabel.text = @"Bundle ID";
				c.detailTextLabel.text = @"com.o2ol.cleanbox";
				c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				break;
			case 3:
				c.textLabel.text = @"形态";
				c.detailTextLabel.text = @"纯巨魔 TrollStore App";
				c.selectionStyle = UITableViewCellSelectionStyleNone;
				break;
			case 4:
				c.textLabel.text = @"定位";
				c.detailTextLabel.text = @"系统 / 用户 App 安全清理";
				c.selectionStyle = UITableViewCellSelectionStyleNone;
				break;
		}
		return c;
	}

	// 开源
	if (ip.row == 0) {
		c.textLabel.text = @"开源地址";
		c.detailTextLabel.text = @"github.com/o2ol/clearnbox";
		c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		c.detailTextLabel.textColor = UIColor.systemBlueColor;
	} else {
		c.textLabel.text = @"许可证";
		c.detailTextLabel.text = @"MIT";
		c.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	return c;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
	[tv deselectRowAtIndexPath:ip animated:YES];
	if (ip.section == 0 && ip.row == 2) {
		[CBCopyUtil copyText:@"com.o2ol.cleanbox" from:self title:@"已复制"];
		return;
	}
	if (ip.section == 1 && ip.row == 0) {
		UIAlertController *a = [UIAlertController alertControllerWithTitle:@"开源地址"
																   message:kCBOpenSourceURL
															preferredStyle:UIAlertControllerStyleActionSheet];
		[a addAction:[UIAlertAction actionWithTitle:@"在浏览器打开" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_) {
			NSURL *url = [NSURL URLWithString:kCBOpenSourceURL];
			if (url) [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
		}]];
		[a addAction:[UIAlertAction actionWithTitle:@"复制链接" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_) {
			[CBCopyUtil copyText:kCBOpenSourceURL from:self title:@"已复制开源地址"];
		}]];
		[a addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
		UITableViewCell *cell = [tv cellForRowAtIndexPath:ip];
		if (cell) a.popoverPresentationController.sourceView = cell;
		[self presentViewController:a animated:YES completion:nil];
	}
}

- (NSString *)tableView:(UITableView *)tv titleForFooterInSection:(NSInteger)s {
	if (s == 1) {
		return @"源码托管于 GitHub，欢迎 Star / Issue / PR。仅用于清理可回收缓存以释放空间，请自行评估风险。";
	}
	return nil;
}

@end
