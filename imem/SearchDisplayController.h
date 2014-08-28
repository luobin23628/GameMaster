//
//  SearchDisplayController.h
//  iPhoneVideo
//
//  Created by LuoBin on 14-7-9.
//  Copyright (c) 2014年 SOHU. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TableViewController

@property (nonatomic, retain) UITableView *tableView;

@end

@protocol SearchDisplayDelegate;

@interface SearchDisplayController : NSObject

- (id)initWithSearchBar:(UISearchBar *)searchBar contentsController:(UIViewController *)viewController searchAssociateViewController:(UIViewController<TableViewController> *)searchResultsViewController;

@property (nonatomic, assign) id<SearchDisplayDelegate> delegate;

@property (nonatomic, getter=isActive)  BOOL active;
- (void)setActive:(BOOL)visible animated:(BOOL)animated;

@property (nonatomic, readonly) UISearchBar *searchBar;
@property (nonatomic, readonly) UIViewController *searchContentsController;
@property (nonatomic, readonly) UIViewController<TableViewController> *searchAssociateViewController;

@end

@protocol SearchDisplayDelegate <NSObject>

@optional

// when we start/end showing the search UI
- (void) searchDisplayControllerWillBeginSearch:(SearchDisplayController *)controller;
- (void) searchDisplayControllerDidBeginSearch:(SearchDisplayController *)controller;
- (void) searchDisplayControllerWillEndSearch:(SearchDisplayController *)controller;
- (void) searchDisplayControllerDidEndSearch:(SearchDisplayController *)controller;

- (void) searchDisplayControllerDidCancel:(SearchDisplayController *)controller;
- (void) searchDisplayControllerDidSearch:(SearchDisplayController *)controller;

- (BOOL)searchDisplayController:(SearchDisplayController *)controller shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;

// return YES to reload table. called when search string/option changes. convenience methods on top UISearchBar delegate methods
- (BOOL)searchDisplayController:(SearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString;
- (BOOL)searchDisplayController:(SearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption;

@end

@interface UIViewController (SearchDisplayControllerSupport)

@property(nonatomic, readonly, retain) SearchDisplayController *displayController;
@property(nonatomic, readonly, retain) UIViewController *searchAssociateViewController;

@end
