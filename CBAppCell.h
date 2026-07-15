#import <UIKit/UIKit.h>
@class CBAppInfo;

NS_ASSUME_NONNULL_BEGIN

@interface CBAppCell : UITableViewCell
- (void)configureWithApp:(CBAppInfo *)app maxOccupied:(unsigned long long)maxOccupied;
@end

NS_ASSUME_NONNULL_END
