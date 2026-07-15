#import "CBVersionViewController.h"
#import "CBCopyUtil.h"
#import "CBTheme.h"
#import "CBGlassView.h"

@implementation CBVersionViewController
- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = @"版本信息";
	self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
	self.tableView.backgroundColor = UIColor.clearColor;
	self.tableView.separatorColor = UIColor.separatorColor;
	self.tableView.backgroundView = [[CBAmbientBackgroundView alloc] initWithFrame:CGRectZero];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return 2; }
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
	return s == 0 ? 5 : 1;
}
- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s {
	return s == 0 ? @"构建" : @"更新说明";
}
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
	if (ip.section == 1) {
		UITableViewCell *c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
		c.backgroundColor = CBTheme.cardBackground;
		c.backgroundView = nil;
		c.selectionStyle = UITableViewCellSelectionStyleNone;
		c.textLabel.numberOfLines = 0;
		c.textLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
		c.textLabel.textColor = UIColor.secondaryLabelColor;
		c.textLabel.text = @"0.0.1\n• 开源首发 · github.com/o2ol/clearnbox\n• 储存概览、sticky 筛选、安全清理\n• 关于页展示开源地址";
		return c;
	}
	UITableViewCell *c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
	c.backgroundColor = CBTheme.cardBackground;
		c.backgroundView = nil;
	c.textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
	c.detailTextLabel.font = [UIFont monospacedDigitSystemFontOfSize:15 weight:UIFontWeightRegular];
	c.detailTextLabel.textColor = UIColor.secondaryLabelColor;
	NSString *ver = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"1.0.0";
	NSString *build = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"100";
	switch (ip.row) {
		case 0: c.textLabel.text = @"版本"; c.detailTextLabel.text = ver; c.accessoryType = UITableViewCellAccessoryDisclosureIndicator; break;
		case 1: c.textLabel.text = @"Build"; c.detailTextLabel.text = build; c.selectionStyle = UITableViewCellSelectionStyleNone; break;
		case 2: c.textLabel.text = @"最低系统"; c.detailTextLabel.text = @"iOS 15.0"; c.selectionStyle = UITableViewCellSelectionStyleNone; break;
		case 3: c.textLabel.text = @"架构"; c.detailTextLabel.text = @"arm64"; c.selectionStyle = UITableViewCellSelectionStyleNone; break;
		case 4: c.textLabel.text = @"Scheme"; c.detailTextLabel.text = @"cleanbox://"; c.accessoryType = UITableViewCellAccessoryDisclosureIndicator; break;
	}
	return c;
}
- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
	[tv deselectRowAtIndexPath:ip animated:YES];
	if (ip.section != 0) return;
	if (ip.row == 0) {
		NSString *ver = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"1.0.0";
		[CBCopyUtil copyText:ver from:self title:@"已复制版本号"];
	} else if (ip.row == 4) {
		[CBCopyUtil copyText:@"cleanbox://" from:self title:@"已复制 Scheme"];
	}
}
@end
