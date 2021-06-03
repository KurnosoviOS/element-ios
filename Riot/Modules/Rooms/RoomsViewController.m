/*
 Copyright 2017 Vector Creations Ltd

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "RoomsViewController.h"

#import "RecentsDataSource.h"

#import "DirectoryServerPickerViewController.h"

#import "Riot-Swift.h"

@interface RoomsViewController ()
{
    RecentsDataSource *recentsDataSource;

    // The animated view displayed at the table view bottom when paginating the room directory
    UIView* footerSpinnerView;
}

@end

@implementation RoomsViewController

+ (instancetype)instantiate
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    RoomsViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"RoomsViewController"];
    return viewController;
}

- (void)finalizeInit
{
    [super finalizeInit];
    
    self.screenName = @"Rooms";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.accessibilityIdentifier = @"RoomsVCView";
    self.recentsTableView.accessibilityIdentifier = @"RoomsVCTableView";
    
    // Tag the recents table with the its recents data source mode.
    // This will be used by the shared RecentsDataSource instance for sanity checks (see UITableViewDataSource methods).
    self.recentsTableView.tag = RecentsDataSourceModeRooms;
    
    // Add the (+) button programmatically
    plusButtonImageView = [self vc_addFABWithImage:[UIImage imageNamed:@"rooms_floating_action"]
                                            target:self
                                            action:@selector(onPlusButtonPressed)];
    
    self.enableStickyHeaders = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [AppDelegate theDelegate].masterTabBarController.navigationItem.title = NSLocalizedStringFromTable(@"title_rooms", @"Vector", nil);
    [AppDelegate theDelegate].masterTabBarController.tabBar.tintColor = ThemeService.shared.theme.tintColor;
    
    // TODO: Notify RiotSettings.shared.showNSFWPublicRooms change for iPad as viewWillAppear may not be called
    recentsDataSource.publicRoomsDirectoryDataSource.showNSFWRooms = RiotSettings.shared.showNSFWPublicRooms;
    
    if ([self.dataSource isKindOfClass:RecentsDataSource.class])
    {
        BOOL isFirstTime = (recentsDataSource != self.dataSource);

        // Take the lead on the shared data source.
        recentsDataSource = (RecentsDataSource*)self.dataSource;
        recentsDataSource.areSectionsShrinkable = NO;
        [recentsDataSource setDelegate:self andRecentsDataSourceMode:RecentsDataSourceModeRooms];

        if (isFirstTime)
        {
            // The first time the screen is displayed, make publicRoomsDirectoryDataSource
            // start loading data
            [recentsDataSource.publicRoomsDirectoryDataSource paginate:nil failure:nil];
        }
    }
}

- (void)destroy
{
    [super destroy];
}

#pragma mark - Override RecentsViewController

- (void)refreshCurrentSelectedCell:(BOOL)forceVisible
{
    // Check whether the recents data source is correctly configured.
    if (recentsDataSource.recentsDataSourceMode != RecentsDataSourceModeRooms)
    {
        return;
    }
    
    [super refreshCurrentSelectedCell:forceVisible];
}

- (UIView *)tableView:(UITableView *)tableView viewForStickyHeaderInSection:(NSInteger)section
{
    CGRect frame = [tableView rectForHeaderInSection:section];
    frame.size.height = self.stickyHeaderHeight;
    
    return [recentsDataSource viewForHeaderInSection:section withFrame:frame];
}

- (void)dataSource:(MXKDataSource *)dataSource didRecognizeAction:(NSString *)actionIdentifier inCell:(id<MXKCellRendering>)cell userInfo:(NSDictionary *)userInfo
{
    if ([actionIdentifier isEqualToString:kRecentsDataSourceTapOnDirectoryServerChange])
    {
        // Show the directory server picker
        [self performSegueWithIdentifier:@"presentDirectoryServerPicker" sender:self];
    }
    else
    {
        [super dataSource:dataSource didRecognizeAction:actionIdentifier inCell:cell userInfo:userInfo];
    }
}

- (void)onPlusButtonPressed
{
    [self showRoomDirectory];
}

#pragma mark - 

- (void)scrollToNextRoomWithMissedNotifications
{
    // Check whether the recents data source is correctly configured.
    if (recentsDataSource.recentsDataSourceMode == RecentsDataSourceModeRooms)
    {
        [self scrollToTheTopTheNextRoomWithMissedNotificationsInSection:recentsDataSource.conversationSection];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];

    UIViewController *pushedViewController = [segue destinationViewController];

    if ([[segue identifier] isEqualToString:@"presentDirectoryServerPicker"])
    {
        UINavigationController *pushedNavigationViewController = (UINavigationController*)pushedViewController;
        DirectoryServerPickerViewController* directoryServerPickerViewController = (DirectoryServerPickerViewController*)pushedNavigationViewController.viewControllers.firstObject;

        MXKDirectoryServersDataSource *directoryServersDataSource = [[MXKDirectoryServersDataSource alloc] initWithMatrixSession:recentsDataSource.publicRoomsDirectoryDataSource.mxSession];
        [directoryServersDataSource finalizeInitialization];

        // Add directory servers from the app settings
        directoryServersDataSource.roomDirectoryServers = BuildSettings.publicRoomsDirectoryServers;

        __weak typeof(self) weakSelf = self;

        [directoryServerPickerViewController displayWithDataSource:directoryServersDataSource onComplete:^(id<MXKDirectoryServerCellDataStoring> cellData) {
            if (weakSelf && cellData)
            {
                typeof(self) self = weakSelf;

                // Use the selected directory server
                if (cellData.thirdPartyProtocolInstance)
                {
                    self->recentsDataSource.publicRoomsDirectoryDataSource.thirdpartyProtocolInstance = cellData.thirdPartyProtocolInstance;
                }
                else if (cellData.homeserver)
                {
                    self->recentsDataSource.publicRoomsDirectoryDataSource.includeAllNetworks = cellData.includeAllNetworks;
                    self->recentsDataSource.publicRoomsDirectoryDataSource.homeserver = cellData.homeserver;
                }

                // Refresh data
                [self addSpinnerFooterView];

                [self->recentsDataSource.publicRoomsDirectoryDataSource paginate:^(NSUInteger roomsAdded) {

                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;

                        // The table view is automatically filled
                        [self removeSpinnerFooterView];

                        // Make the directory section appear full-page
                        [self.recentsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:self->recentsDataSource.directorySection] atScrollPosition:UITableViewScrollPositionTop animated:YES];
                    }

                } failure:^(NSError *error) {

                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        [self removeSpinnerFooterView];
                    }
                }];
            }
        }];

        // Hide back button title
        pushedViewController.navigationController.navigationItem.backBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    }
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == recentsDataSource.directorySection)
    {
        // Let the recents dataSource provide the height of this section header
        return [recentsDataSource heightForHeaderInSection:section];
    }

    return [super tableView:tableView heightForHeaderInSection:section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == recentsDataSource.directorySection)
    {
        // Sanity check
        MXPublicRoom *publicRoom = [recentsDataSource.publicRoomsDirectoryDataSource roomAtIndexPath:indexPath];
        if (publicRoom)
        {
            [self openPublicRoomAtIndexPath:indexPath];
        }
    }
    else
    {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
        // Trigger inconspicuous pagination on directy when user scrolls down
    if ((scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.frame.size.height) < 300)
    {
        [self triggerDirectoryPagination];
    }
    
    [super scrollViewDidScroll:scrollView];
}

#pragma mark - Private methods

- (void)openPublicRoomAtIndexPath:(NSIndexPath *)indexPath
{
    MXPublicRoom *publicRoom = [recentsDataSource.publicRoomsDirectoryDataSource roomAtIndexPath:indexPath];
    
    [self openPublicRoom:publicRoom];
}

- (void)triggerDirectoryPagination
{
    if (!recentsDataSource
        || recentsDataSource.state == MXKDataSourceStateUnknown
        || recentsDataSource.publicRoomsDirectoryDataSource.hasReachedPaginationEnd
        || footerSpinnerView)
    {
        // We are not yet ready or being killed or we got all public rooms or we are already paginating
        // Do nothing
        return;
    }

    [self addSpinnerFooterView];

    [recentsDataSource.publicRoomsDirectoryDataSource paginate:^(NSUInteger roomsAdded) {

        // The table view is automatically filled
        [self removeSpinnerFooterView];

    } failure:^(NSError *error) {

        [self removeSpinnerFooterView];
    }];
}

- (void)addSpinnerFooterView
{
    if (!footerSpinnerView)
    {
        UIActivityIndicatorView* spinner  = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        spinner.transform = CGAffineTransformMakeScale(0.75f, 0.75f);
        CGRect frame = spinner.frame;
        frame.size.height = 80; // 80 * 0.75 = 60
        spinner.bounds = frame;

        spinner.color = [UIColor darkGrayColor];
        spinner.hidesWhenStopped = NO;
        spinner.backgroundColor = [UIColor clearColor];
        [spinner startAnimating];

        // No need to manage constraints here, iOS defines them
        self.recentsTableView.tableFooterView = footerSpinnerView = spinner;
    }
}

- (void)removeSpinnerFooterView
{
    if (footerSpinnerView)
    {
        footerSpinnerView = nil;

        // Hide line separators of empty cells
        self.recentsTableView.tableFooterView = [[UIView alloc] init];;
    }
}

#pragma mark - Empty view management

- (void)updateEmptyView
{
    [self.emptyView fillWith:[self emptyViewArtwork]
                       title:NSLocalizedStringFromTable(@"rooms_empty_view_title", @"Vector", nil)
             informationText:NSLocalizedStringFromTable(@"rooms_empty_view_information", @"Vector", nil)];
}

- (UIImage*)emptyViewArtwork
{
    if (ThemeService.shared.isCurrentThemeDark)
    {
        return [UIImage imageNamed:@"rooms_empty_screen_artwork_dark"];
    }
    else
    {
        return [UIImage imageNamed:@"rooms_empty_screen_artwork"];
    }
}

- (BOOL)shouldShowEmptyView
{
    // Do not present empty screen while searching
    if (recentsDataSource.searchPatternsList.count)
    {
        return NO;
    }
    
    // Otherwise check the number of items to display
    return [self totalItemCounts] == 0;
}

// Total items to display on the screen
- (NSUInteger)totalItemCounts
{
    return recentsDataSource.conversationCellDataArray.count
    + recentsDataSource.publicRoomsDirectoryDataSource.roomsCount
    + recentsDataSource.invitesCellDataArray.count;
}

@end
