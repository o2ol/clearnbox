#import "CBSettingsViewController.h"
#import "CBSettings.h"
#import "CBHelpViewController.h"
#import "CBAboutViewController.h"
#import "CBVersionViewController.h"
#import "CBTheme.h"
#import "CBGlassView.h"

@implementation CBSettingsViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = @"设置";
	self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
	self.navigationController.navigationBar.prefersLargeTitles = YES;
	self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
	self.tableView.backgroundColor = UIColor.clearColor;
	self.tableView.separatorColor = UIColor.separatorColor;
	CBAmbientBackgroundView *ambient = [[CBAmbientBackgroundView alloc] initWithFrame:CGRectZero];
	self.tableView.backgroundView = ambient;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)t { return 4; }
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s {
	return s == 0 ? 3 : (s == 1 ? 2 : (s == 2 ? 1 : 3));
}
- (NSString *)tableView:(UITableView *)t titleForHeaderInSection:(NSInteger)s {
	return @[@"清理", @"列表", @"外观", @"关于"][s];
}
- (NSString *)tableView:(UITableView *)t titleForFooterInSection:(NSInteger)s {
	if (s == 0) return @"仅清理安全缓存。不会清理 WebKit、HTTP 存储、Cookies 与登录数据。";
	if (s == 3) return @"净匣 · 安全释放空间";
	return nil;
}

- (UIImage *)glyph:(NSString *)name bg:(UIColor *)bg {
	CGSize size = CGSizeMake(29, 29);
	UIGraphicsBeginImageContextWithOptions(size, NO, 0);
	UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 29, 29) cornerRadius:7];
	[bg setFill];
	[path fill];
	UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightSemibold];
	UIImage *sym = [[UIImage systemImageNamed:name withConfiguration:cfg] imageWithTintColor:UIColor.whiteColor renderingMode:UIImageRenderingModeAlwaysOriginal];
	CGFloat side = 16;
	[sym drawInRect:CGRectMake((29 - side) / 2.0, (29 - side) / 2.0, side, side)];
	UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return img;
}

- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip {
	if (ip.section == 0 || ip.section == 1) {
		UITableViewCell *c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
		c.selectionStyle = UITableViewCellSelectionStyleNone;
		c.backgroundColor = CBTheme.cardBackground;
		c.backgroundView = nil;
		UISwitch *sw = [UISwitch new];
		sw.onTintColor = CBTheme.accent;
		if (ip.section == 0) {
			NSArray *keys = @[CBSettingConfirmBeforeClean, CBSettingKillBeforeClean, CBSettingCleanGroupCaches];
			NSArray *titles = @[@"清理前询问", @"清理前退出 App", @"包含 App 群组缓存"];
			NSArray *subs = @[@"每次清理前确认操作", @"避免文件被占用", @"共享容器中的缓存与临时文件"];
			NSArray *icons = @[@"hand.raised.fill", @"xmark.app.fill", @"rectangle.3.group.fill"];
			NSArray *colors = @[UIColor.systemOrangeColor, UIColor.systemRedColor, UIColor.systemTealColor];
			c.textLabel.text = titles[ip.row];
			c.textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
			c.detailTextLabel.text = subs[ip.row];
			c.detailTextLabel.textColor = UIColor.secondaryLabelColor;
			c.detailTextLabel.numberOfLines = 2;
			c.imageView.image = [self glyph:icons[ip.row] bg:colors[ip.row]];
			sw.on = CBSettingsBool(keys[ip.row]);
			sw.tag = (int)ip.row;
		} else {
			c.textLabel.text = ip.row == 0 ? @"显示系统 App" : @"显示用户 App";
			c.textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
			c.imageView.image = [self glyph:ip.row == 0 ? @"gearshape.fill" : @"person.crop.square.fill"
									  bg:ip.row == 0 ? UIColor.systemIndigoColor : UIColor.systemBlueColor];
			sw.on = CBSettingsBool(ip.row == 0 ? CBSettingShowSystemApps : CBSettingShowUserApps);
			sw.tag = ip.row == 0 ? 100 : 101;
		}
		[sw addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventValueChanged];
		c.accessoryView = sw;
		return c;
	}
	if (ip.section == 2) {
		UITableViewCell *c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
		c.backgroundColor = CBTheme.cardBackground;
		c.backgroundView = nil;
		c.textLabel.text = @"外观";
		c.textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
		c.imageView.image = [self glyph:@"circle.lefthalf.filled" bg:UIColor.systemGrayColor];
		NSString *m = CBSettingsString(CBSettingAppearance);
		c.detailTextLabel.text = [m isEqualToString:@"light"] ? @"浅色" : ([m isEqualToString:@"dark"] ? @"深色" : @"自动");
		c.detailTextLabel.textColor = UIColor.secondaryLabelColor;
		c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		return c;
	}
	UITableViewCell *c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	c.backgroundColor = CBTheme.cardBackground;
		c.backgroundView = nil;
	c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	NSArray *titles = @[@"帮助说明", @"版本信息", @"关于净匣"];
	NSArray *imgs = @[@"questionmark.circle.fill", @"info.circle.fill", @"sparkles"];
	NSArray *colors = @[UIColor.systemBlueColor, UIColor.systemTealColor, UIColor.systemPurpleColor];
	c.textLabel.text = titles[ip.row];
	c.textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
	c.imageView.image = [self glyph:imgs[ip.row] bg:colors[ip.row]];
	return c;
}

- (void)toggle:(UISwitch *)sw {
	NSDictionary *map = @{
		@0: CBSettingConfirmBeforeClean,
		@1: CBSettingKillBeforeClean,
		@2: CBSettingCleanGroupCaches,
		@100: CBSettingShowSystemApps,
		@101: CBSettingShowUserApps,
	};
	NSString *key = map[@(sw.tag)];
	if (key) [CBSettingsDefaults() setBool:sw.on forKey:key];
}

- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip {
	[t deselectRowAtIndexPath:ip animated:YES];
	if (ip.section == 2) {
		UIAlertController *a = [UIAlertController alertControllerWithTitle:@"外观" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
		void (^set)(NSString *) = ^(NSString *v) {
			[CBSettingsDefaults() setObject:v forKey:CBSettingAppearance];
			CBApplyAppearance();
			[self.tableView reloadData];
		};
		[a addAction:[UIAlertAction actionWithTitle:@"自动" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_) { set(@"system"); }]];
		[a addAction:[UIAlertAction actionWithTitle:@"浅色" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_) { set(@"light"); }]];
		[a addAction:[UIAlertAction actionWithTitle:@"深色" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_) { set(@"dark"); }]];
		[a addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
		[self presentViewController:a animated:YES completion:nil];
		return;
	}
	if (ip.section == 3) {
		UIViewController *vc = ip.row == 0 ? [CBHelpViewController new] : (ip.row == 1 ? [CBVersionViewController new] : [CBAboutViewController new]);
		[self.navigationController pushViewController:vc animated:YES];
	}
}

@end
