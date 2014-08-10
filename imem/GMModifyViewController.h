//
//  GMModifyTableViewController.h
//  imem
//
//  Created by luobin on 14-7-19.
//
//

#import <UIKit/UIKit.h>

@interface GMModifyViewController : UITableViewController

@property (nonatomic, assign) GMOptType defaultOptType;
@property (nonatomic, copy) void(^didModifyBlock)(GMMemoryAccessObject *accessObject);

- (id)initWithAddress:(uint64_t)address;

@end
