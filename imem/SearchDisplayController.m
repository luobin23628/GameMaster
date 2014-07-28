//
//  SearchDisplayController.m
//  iPhoneVideo
//
//  Created by LuoBin on 14-7-9.
//  Copyright (c) 2014年 SOHU. All rights reserved.
//

#import "SearchDisplayController.h"
#import <objc/runtime.h>

static char displayControllerKey;
static char searchResultsViewControllerKey;

@interface UIViewController(__SearchDisplayControllerSupport)

@property(nonatomic, readwrite, retain) SearchDisplayController *displayController;
@property(nonatomic, readwrite, retain) UIViewController *searchAssociateViewController;

@end

@implementation UIViewController (SearchDisplayControllerSupport)

- (SearchDisplayController *)displayController {
    return objc_getAssociatedObject(self, &displayControllerKey);
}

- (void)setDisplayController:(SearchDisplayController *)displayController {
    objc_setAssociatedObject(self, &displayControllerKey, displayController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
}

- (UIViewController *)searchAssociateViewController {
    return objc_getAssociatedObject(self, &searchResultsViewControllerKey);
}

- (void)setSearchAssociateViewController:(UIViewController *)searchAssociateViewController {
    objc_setAssociatedObject(self, &searchResultsViewControllerKey, searchAssociateViewController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


@interface SearchDisplayController ()<UISearchBarDelegate>

@property (nonatomic, readwrite, assign) UISearchBar *searchBar;
@property (nonatomic, readwrite, assign) UIViewController *searchContentsController;
@property (nonatomic, readwrite, assign) UIViewController<TableViewController> *searchAssociateViewController;

@end

@implementation SearchDisplayController

- (id)initWithSearchBar:(UISearchBar *)searchBar contentsController:(UIViewController *)viewController searchAssociateViewController:(UIViewController<TableViewController> *)searchAssociateViewController {
    self = [super init];
    if (self) {
        self.searchBar = searchBar;
        self.searchBar.delegate = self;
        self.searchContentsController = viewController;
        self.searchAssociateViewController = searchAssociateViewController;
        
        self.searchContentsController.displayController = self;
        self.searchContentsController.searchAssociateViewController = searchAssociateViewController;
        
        self.searchAssociateViewController.displayController = self;
    }
    return self;
}

- (void)dealloc {
    self.searchBar = nil;
    self.searchContentsController = nil;
    self.searchAssociateViewController = nil;
    [super dealloc];
}

- (void)setActive:(BOOL)active {
    [self setActive:active animated:NO];
}

- (void)setActive:(BOOL)visible animated:(BOOL)animated {
    if (_active != visible) {
        _active = visible;

        if (visible) {
            if (self.searchBar.window) {
                CGRect frame = [self.searchContentsController.view convertRect:self.searchBar.frame fromView:self.searchBar.superview];
                self.searchAssociateViewController.view.frame = self.searchContentsController.view.bounds;
                [self.searchContentsController.view insertSubview:self.searchAssociateViewController.view belowSubview:self.searchBar];
                self.searchAssociateViewController.tableView.contentInset = UIEdgeInsetsMake(CGRectGetMaxY(frame), 0, 0, 0);
                self.searchAssociateViewController.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(CGRectGetMaxY(frame), 0, 0, 0);
                [self.searchContentsController addChildViewController:self.searchAssociateViewController];
            }
        } else {
            [self.searchAssociateViewController.view removeFromSuperview];
            [self.searchAssociateViewController removeFromParentViewController];
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
    if ([searchBar.text length]) {
        [self setActive:YES animated:YES];
    }
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
    if ([searchBar.text length]) {
        [self setActive:YES animated:YES];
    } else {
        [self setActive:NO animated:YES];
    }
    
    BOOL shouldReloadTable = YES;
    if ([self.delegate respondsToSelector:@selector(searchDisplayController:shouldReloadTableForSearchString:)]) {
        shouldReloadTable = [self.delegate searchDisplayController:self shouldReloadTableForSearchString:searchBar.text];
    }
    if (shouldReloadTable) {
        [self.searchAssociateViewController.tableView reloadData];
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
        [self.searchAssociateViewController.tableView reloadData];
    }
}

@end

