#import "CBCopyUtil.h"

@implementation CBCopyUtil
+ (void)copyText:(NSString *)text from:(UIViewController *)vc title:(NSString *)title {
	if (!text.length) return;
	UIPasteboard.generalPasteboard.string = text;
	UIAlertController *a = [UIAlertController alertControllerWithTitle:title ?: @"已复制"
															   message:text
														preferredStyle:UIAlertControllerStyleAlert];
	[a addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
	[vc presentViewController:a animated:YES completion:nil];
}
@end
