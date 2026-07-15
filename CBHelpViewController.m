#import "CBHelpViewController.h"
#import "CBTheme.h"
#import "CBGlassView.h"

@implementation CBHelpViewController {
	NSArray<NSArray<NSString *> *> *_rows;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = @"使用说明";
	self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
	self.tableView.backgroundColor = UIColor.clearColor;
	self.tableView.separatorColor = UIColor.separatorColor;
	self.tableView.backgroundView = [[CBAmbientBackgroundView alloc] initWithFrame:CGRectZero];
	_rows = @[
		@[@"这是什么", @"净匣是 TrollStore（巨魔）专用的 App 缓存清理工具。可清理系统 App 与用户 App 容器内的可回收数据，释放空间。"],
		@[@"安全清理哪些", @"Caches（跳过 WebKit 等）、tmp、Logs、启动快照、可选 App Group 缓存。"],
		@[@"不会动哪些", @"Documents、Preferences、Cookies、WebKit 网站数据、HTTP 存储、钥匙串、登录相关缓存、App 本体。不会卸载系统 App。"],
		@[@"推荐流程", @"1) 首页点「扫描可清理项」\n2) 分段筛选：全部 / 系统 / 用户 / 可清\n3) 进入详情勾选类别\n4) 右上角清理，或列表一键清理\n5) 长按可快速安全清理"],
		@[@"储存卡片说明", @"顶部展示设备已用 / 总量。彩色条：App、可释放、其它（系统与媒体等）、可用。App 占用来自列表容器统计；可释放需先扫描。"],
		@[@"系统 App 注意", @"系统 App 清理缓存一般安全，但少数服务会短暂重建缓存。勿在通话 / 导航等关键场景强杀。"],
		@[@"清理后异常", @"重新打开 App 即可重建缓存。本版本不会清理登录相关数据。"],
		@[@"权限说明", @"需 TrollStore 安装以获得无沙盒与容器访问能力；普通签名安装无法清理其他 App。"],
	];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return _rows.count; }
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return 1; }
- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s { return _rows[s][0]; }
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
	UITableViewCell *c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	c.backgroundColor = CBTheme.cardBackground;
		c.backgroundView = nil;
	c.textLabel.text = _rows[ip.section][1];
	c.textLabel.numberOfLines = 0;
	c.textLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
	c.textLabel.textColor = UIColor.labelColor;
	c.selectionStyle = UITableViewCellSelectionStyleNone;
	return c;
}
@end
