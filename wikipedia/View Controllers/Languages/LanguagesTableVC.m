//  Created by Monte Hurd on 1/23/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "LanguagesTableVC.h"
#import "WikipediaAppUtils.h"
#import "SessionSingleton.h"
#import "DownloadLangLinksOp.h"
#import "QueuesSingleton.h"
#import "LanguagesCell.h"
#import "Defines.h"
#import "BundledJson.h"

#import "UIViewController+Alert.h"

#pragma mark - Defines

#define BACKGROUND_COLOR [UIColor colorWithWhite:1.0f alpha:1.0f]

#pragma mark - Private properties

@interface LanguagesTableVC ()

@property (strong, nonatomic) NSArray *languagesData;
@property (strong, nonatomic) NSMutableArray *filteredLanguagesData;

@property (strong, nonatomic) NSString *filterString;
@property (strong, nonatomic) UITextField *filterTextField;

@end

@implementation LanguagesTableVC

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.title = MWLocalizedString(@"article-languages-filter-placeholder", nil);

        //MWLocalizedString(@"article-languages-label", nil);

        self.navBarMode = NAVBAR_MODE_X_WITH_TEXT_FIELD;

        self.downloadLanguagesForCurrentArticle = NO;

    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    self.languagesData = @[];
    self.filteredLanguagesData = @[].mutableCopy;
    
    self.view.backgroundColor = BACKGROUND_COLOR;
 
    self.tableView.contentInset = UIEdgeInsetsMake(15, 0, 0, 0);

    self.filterString = @"";
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if(self.downloadLanguagesForCurrentArticle){
        [self downloadLangLinkData];
    }else{
        self.languagesData = [BundledJson arrayFromBundledJsonFile:BUNDLED_JSON_LANGUAGES];
        [self reloadTableDataFiltered];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self.filterTextField resignFirstResponder];

    [[QueuesSingleton sharedInstance].langLinksQ cancelAllOperations];

    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"NavItemTapped"
                                                  object: nil];

    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"NavTextFieldTextChanged"
                                                  object: nil];

    [super viewWillDisappear:animated];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Listen for nav bar taps.
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(navItemTappedNotification:)
                                                 name: @"NavItemTapped"
                                               object: nil];

    // Listen for nav text field text changes.
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(navTextFieldTextChangedNotification:)
                                                 name: @"NavTextFieldTextChanged"
                                               object: nil];
    
}

#pragma mark - Top menu

// Handle nav bar taps. (same way as any other view controller would)
- (void)navItemTappedNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    UIView *tappedItem = userInfo[@"tappedItem"];

    switch (tappedItem.tag) {
        case NAVBAR_BUTTON_X:
            [self hide];

            break;
        default:
            break;
    }
}

// Handle nav bar taps. (same way as any other view controller would)
- (void)navTextFieldTextChangedNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSString *text = userInfo[@"text"];

    self.filterString = text;
    [self reloadTableDataFiltered];
}

-(void)reloadTableDataFiltered
{
    if (self.filterString.length == 0){
        self.filteredLanguagesData = self.languagesData.mutableCopy;
        [self.tableView reloadData];
        return;
    }

    [self.filteredLanguagesData removeAllObjects];

    self.filteredLanguagesData =
        [self.languagesData filteredArrayUsingPredicate:
         [NSPredicate predicateWithFormat:@"\
              SELF.name contains[c] %@\
              || \
              SELF.canonical_name contains[c] %@\
              || \
              SELF.code == [c] %@\
          ", self.filterString, self.filterString, self.filterString]
        ].mutableCopy;

    [self.tableView reloadData];
}

#pragma mark - Article lang list download op

-(void)downloadLangLinkData
{
    [self showAlert:MWLocalizedString(@"article-languages-downloading", nil)];

    DownloadLangLinksOp *langLinksOp =
    [[DownloadLangLinksOp alloc] initForPageTitle: [SessionSingleton sharedInstance].currentArticleTitle
                                           domain: [SessionSingleton sharedInstance].currentArticleDomain
                                     allLanguages: [BundledJson arrayFromBundledJsonFile:BUNDLED_JSON_LANGUAGES]
                                  completionBlock: ^(NSArray *result){
                                      
                                      [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
                                          //[self showAlert:@"Language links loaded."];
                                          //[self fadeAlert];

                                          self.languagesData = result;
                                          [self reloadTableDataFiltered];
                                      }];
                                      
                                  } cancelledBlock: ^(NSError *error){
                                      //NSString *errorMsg = error.localizedDescription;
                                      [self fadeAlert];
                                      
                                  } errorBlock: ^(NSError *error){
                                      //NSString *errorMsg = error.localizedDescription;
                                      [self showAlert:error.localizedDescription];
                                      
                                  }];
    
    [[QueuesSingleton sharedInstance].langLinksQ cancelAllOperations];
    [[QueuesSingleton sharedInstance].langLinksQ addOperation:langLinksOp];
}

#pragma mark - Table protocol methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.filteredLanguagesData.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 48;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section;
{
    return 0;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellId = @"LanguagesCell";
    LanguagesCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
    
    NSDictionary *d = self.filteredLanguagesData[indexPath.row];

    cell.textLabel.text = d[@"name"];
    cell.canonicalLabel.text = d[@"canonical_name"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *selectedLangInfo = self.filteredLanguagesData[indexPath.row];

    [[NSNotificationCenter defaultCenter] postNotificationName: @"LanguageItemSelected"
                                                        object: self
                                                      userInfo: selectedLangInfo];
}

#pragma mark - Hiding

-(void)hide
{
    // Hide this view controller.
    if(!(self.isBeingPresented || self.isBeingDismissed)){
        [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
    }
}

#pragma mark - Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
