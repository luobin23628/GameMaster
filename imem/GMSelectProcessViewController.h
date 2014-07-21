//
//  GMSelectProcessViewController2TableViewController.h
//  GameMaster
//
//  Created by luobin on 14-7-5.
//
//

#import <UIKit/UIKit.h>

@interface GMSelectProcessViewController : UITableViewController

@property (nonatomic, copy) void(^didSelectProcessBlock)(int pid);

@end
