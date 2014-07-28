//
//  SearchDisplayController.m
//  iPhoneVideo
//
//  Created by LuoBin on 14-7-9.
//  Copyright (c) 2014年 SOHU. All rights reserved.
//

#import "SearchDisplayController.h"

static char displayControllerKey;
static char searchResultsViewControllerKey;

@interface UIViewController(__SearchDisplayControllerSupport)

@property(nonatomic, readwrite, retain) SearchDisplayController *displayController;
@property(nonatomic, readwrite, retain) UIViewController *searchResultsViewController;

@end

@implementation UIViewController (SearchDisplayControllerSupport)

- (SearchDisplayController *)displayController {
    return objc_getAssociatedObject(self, &displayControllerKey);
}

- (void)setDisplayController:(SearchDisplayController *)displayController {
    objc_setAssociatedObject(self, &displayControllerKey, displayController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
}

- (UIViewController *)searchResultsViewController {
    return objc_getAssociatedObject(self, &searchResultsViewControllerKey);
}

- (void)setSearchResultsViewController:(UIViewController *)searchResultsViewController {
    objc_setAssociatedObject(self, &searchResultsViewControllerKey, searchResultsViewController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


@interface SearchDisplayController ()<UISearchBarDelegate>

@property (nonatomic, readwrite, assign) UISearchBar *searchBar;
@property (nonatomic, readwrite, assign) UIViewController *searchContentsController;
@property (nonatomic, readwrite, assign) UIViewController<TableViewController> *searchResultsViewController;

@end

@implementation SearchDisplayController

- (id)initWithSearchBar:(UISearchBar *)searchBar contentsController:(UIViewController *)viewController searchResultsTableViewController:(UIViewController<TableViewController> *)searchResultsViewController {
    self = [super init];
    if (self) {
        self.searchBar = searchBar;
        self.searchBar.delegate = self;
        self.searchContentsController = viewController;
        self.searchResultsViewController = searchResultsViewController;
        
        self.searchContentsController.displayController = self;
        self.searchContentsController.searchResultsViewController = searchResultsViewController;
        
        self.searchResultsViewController.displayController = self;
    }
    return self;
}

- (void)dealloc {
    self.searchBar = nil;
    self.searchContentsController = nil;
    self.searchResultsViewController = nil;
    [super dealloc];
}

- (void)setActive:(BOOL)active {
    [self setActive:active animated:NO];
}

- (void)setActive:(BOOL)visible animated:(BOOL)animated {
    if (_active != visible) {
        _active = visible;

        if (self.searchContentsController) {
            if (self.searchBar.window) {
                CGRect frame = [self.searchContentsController.view convertRect:self.searchBar.frame fromView:self.searchBar.superview];
                self.searchResultsViewController.view.frame = self.searchContentsController.view.bounds;
                [self.searchContentsController.view addSubview:self.searchResultsViewController.view];
                self.searchResultsViewController.tableView.contentInset = UIEdgeInsetsMake(CGRectGetMaxY(frame), 0, 0, 0);
                self.searchResultsViewController.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(CGRectGetMaxY(frame), 0, 0, 0);
                [self.searchContentsController addChildViewController:self.searchResultsViewController];
            }
        } else {
            [self.searchBar resignFirstResponder];
            [self.searchResultsViewController.view removeFromSuperview];
            [self.searchResultsViewController removeFromParentViewController];
        }
    }
}

#pragma mark - UISearchBarDelegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    if ([self.delegate respondsToSelector:@selector(searchDisplayControllerWillBeginSearch:)]) {
        [self.delegate searchDisplayControllerWillBeginSearch:self];
    }
    return YES;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self setActive:YES animated:YES];
    
    if ([self.delegate respondsToSelector:@selector(searchDisplayControllerDidBeginSearch:)]) {
        [self.delegate searchDisplayControllerDidBeginSearch:self];
    }
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    if ([self.delegate respondsToSelector:@selector(searchDisplayControllerWillEndSearch:)]) {
        [self.delegate searchDisplayControllerWillEndSearch:self];
    }
    return YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    if ([self.delegate respondsToSelector:@selector(searchDisplayControllerDidEndSearch:)]) {
        [self.delegate searchDisplayControllerDidEndSearch:self];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    BOOL shouldReloadTable = YES;
    if ([self.delegate respondsToSelector:@selector(searchDisplayController:shouldReloadTableForSearchString:)]) {
        shouldReloadTable = [self.delegate searchDisplayController:self shouldReloadTableForSearchString:searchBar.text];
    }
    if (shouldReloadTable) {
        [self.searchResultsViewController.tableView reloadData];
    }
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]){
        return YES;
    }
    
    NSString * toBeString = [searchBar.text stringByReplacingCharactersInRange:range withString:text];
    if (toBeString.length > 40) {
        return NO;
    }
    
    if ([self.delegate respondsToSelector:@selector(searchDisplayController:shouldChangeTextInRange:replacementText:)]) {
        return [self.delegate searchDisplayController:self shouldChangeTextInRange:range replacementText:text];
    }
    
    return YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    if ([self.delegate respondsToSelector:@selector(searchDisplayControllerDidSearch:)]) {
        [self.delegate searchDisplayControllerDidSearch:self];
    }
}

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar {
    
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar {
    if ([self.delegate respondsToSelector:@selector(searchDisplayControllerDidCancel:)]) {
        [self.delegate searchDisplayControllerDidCancel:self];
    }
}

- (void)searchBarResultsListButtonClicked:(UISearchBar *)searchBar {
    
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    BOOL shouldReloadTable = YES;
    if ([self.delegate respondsToSelector:@selector(searchDisplayController:shouldReloadTableForSearchScope:)]) {
        shouldReloadTable = [self.delegate searchDisplayController:self shouldReloadTableForSearchScope:selectedScope];
    }
    if (shouldReloadTable) {
        [self.searchResultsViewController.tableView reloadData];
    }
}

@end

