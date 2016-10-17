//
//  BlackBookViewController.m
//  Wyldfire
//
//  Created by Vlad Seryakov on 11/21/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

#import "UIActionSheet+util.h"

@interface BlackBookViewController () <UIActionSheetDelegate,ABNewPersonViewControllerDelegate,ABPeoplePickerNavigationControllerDelegate, UISearchBarDelegate>
    @property (nonatomic, strong) NSMutableArray* arrayOfArraysOfContacts;
    @property (nonatomic, strong) UISearchBar* searchBar;

    @property (nonatomic, strong) UIView* emptyView;
    @property (nonatomic, strong) NSIndexPath* selectedIndex;

    @property (nonatomic, strong) NSArray* unseenContacts;
@end

@implementation BlackBookViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Force refresh from the db
    [[APIClient sharedClient] getBlackbook:^(NSArray* accounts) {
        [[APIClient sharedClient] storeBlackbookContacts:accounts notify:YES];
    }];

    self.unseenContacts = [GVUserDefaults standardUserDefaults].unseenContacts;
    [[GVUserDefaults standardUserDefaults] clearNotebookUnseenAccounts];
    
    CGRect labelRect = CGRectMake(10, 0, 290, 300);
    UILabel* emptyView = [UILabel labelInRect:labelRect withText:@"No one has added their contact to your notebook yet. You can add your contact to someone’s notebook in any chat." color:GRAY_1 fontSize:17];
    emptyView.backgroundColor = nil;
    emptyView.opaque = NO;
    emptyView.numberOfLines = 0;
    self.emptyView = emptyView;
    
    [self addTable];
    self.tableRows = 1;
    self.tableSearch.placeholder = @"Search";
    self.table.backgroundColor = GRAY_8;
    self.table.sectionIndexColor = [UIColor lightGrayColor];
    
    [self addToolbar:@"Notebook"];
    
    [self createArrayOfContactsFromItems];
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.toolbar.frame), 320, 44)];
    searchBar.placeholder = @"Search";
    searchBar.delegate = self;
    self.searchBar = searchBar;
    
    [self.view addSubview:searchBar];
    
    float tableOriginY = CGRectGetMaxY(searchBar.frame);
    self.table.frame = CGRectMake(0, tableOriginY,
                                  320, CGRectGetMaxY(self.view.frame) - tableOriginY);
}

- (void)getItems {
    [self showActivity:YES];
    self.items = nil;
    self.itemsAll = [[DBAccount retrieveAccountsInBlackbook] mutableCopy];
    [self reloadTable];
    [self hideActivity:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.items.count == 0) [self getItems];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self reloadTable];
    
    if (searchText.length == 0) {
        [searchBar resignFirstResponder];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self reloadTable];
        
    [searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void)onRowSelect:(NSIndexPath *)indexPath selected:(BOOL)selected
{
    UITableViewCell *cell = [self.table cellForRowAtIndexPath:indexPath];
    if (selected) {
        [(UILabel*)[cell viewWithTag:900] setTextColor:[UIColor blackColor]];
        [(UILabel*)[cell viewWithTag:901] setTextColor:[UIColor blackColor]];
    } else {
        [(UILabel*)[cell viewWithTag:900] setTextColor:[UIColor darkTextColor]];
        [(UILabel*)[cell viewWithTag:901] setTextColor:[UIColor grayColor]];
    }
}

- (void)onPhone:(UITapGestureRecognizer *)sender
{
    NSIndexPath* path = objc_getAssociatedObject(sender.view, @"index");
    Account *item = self.arrayOfArraysOfContacts[path.section][path.row];
    self.selectedIndex = path;
    //[self.table selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionNone];
    //[self onRowSelect:path selected:YES];
    [self.table selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self.table deselectRowAtIndexPath:path animated:YES];
    
    DBAccount* dbAccount = [DBAccount retrieveDBAccountForAccountID:item.accountID];
    
    UIActionSheet *action;
    if (dbAccount.phone) {
        action = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"Contact %@",item.alias] delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"View Profile", @"Make a Call", @"Chat", @"Burn",nil];
    } else {
        action = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"Contact %@",item.alias] delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"View Profile", @"Chat", @"Burn",nil];
    }
    action.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [action showInView:self.view];
    [action styleWithTintColor:WYLD_RED];
}

- (void)onTableSelect:(NSIndexPath *)indexPath selected:(BOOL)selected
{
    //[self onRowSelect:indexPath selected:selected];
    [self.table selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self.table deselectRowAtIndexPath:indexPath animated:YES];
    
    if (selected) {
        self.selectedIndex = indexPath;
        Account *item = self.arrayOfArraysOfContacts[self.selectedIndex.section][self.selectedIndex.row];
        
        [WFCore showViewController:self
                              name:@"Match"
                              mode:@"push"
                            params:@{@"account" : item,
                                     @"profileview" : @(YES)}];
    }
}

- (void)onTableCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    Account *item = self.arrayOfArraysOfContacts[indexPath.section][indexPath.row];
    
    BOOL unseen = ([self.unseenContacts containsObject:item.accountID]);
    
    UIImageView *avatar = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"avatar_eclipse"]];
    avatar.center = CGPointMake(avatar.image.size.width/2 + self.tableIndent, self.table.rowHeight/2 );
    [cell addSubview:avatar];
    
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, avatar.image.size.width-3, avatar.image.size.width-3)];
    imgView.center = avatar.center;
    imgView.contentMode = UIViewContentModeScaleAspectFill;
    imgView.layer.cornerRadius = imgView.frame.size.width/2;
    imgView.layer.masksToBounds = YES;
    [cell addSubview:imgView];
    
    float startX = avatar.frame.size.width+self.tableIndent*2 ;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(startX,
                                                               0,
                                                               cell.frame.size.width - startX,
                                                               self.table.rowHeight)];
    NSString* initialNumber = item.phone;
    
    NSString* formattedPhoneNumber = initialNumber;
//    [NSString stringWithFormat:@"1 (%@) %@-%@", [initialNumber substringToIndex:3],
//                                      [initialNumber substringWithRange:NSMakeRange(4, 3)],
//                                      [initialNumber substringWithRange:NSMakeRange(8, 4)]];
    if (item.phone) {
        label.text = [NSString stringWithFormat:@"%@: ", item.alias];
    } else {
        label.text = [NSString stringWithFormat:@"%@ ", item.alias];
    }
    label.textColor = [UIColor blackColor];
    label.font = [UIFont fontWithName:MAIN_FONT size:17];
    label.tag = 900;
    [cell addSubview:label];
    
    CGSize textSize = [[label text] sizeWithAttributes:@{NSFontAttributeName:[label font]}];
    if (item.phone) {
        UILabel *phone = [[UILabel alloc] initWithFrame:CGRectMake(startX + textSize.width,
                                                                   0,
                                                                   cell.frame.size.width - (startX + textSize.width),
                                                                   self.table.rowHeight)];
        phone.tag = 901;
        phone.text = formattedPhoneNumber;
        phone.textColor = [UIColor blackColor];
        phone.userInteractionEnabled = YES;
        phone.font = [UIFont fontWithName:BOLD_FONT size:17];
        objc_setAssociatedObject(phone, @"index", indexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [phone addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onPhone:)]];
        [cell addSubview:phone];
    }
    
    //cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_selected_dark"]];
    
    // Already cached
    if (item.avatarPhoto) {
        imgView.image = item.avatarPhoto;
    } else {
        [[APIClient sharedClient] getAccountImageOfType:1 account:item.accountID
            success:^(UIImage *image, NSString *url) {
                [item setImage:image forType:1];
                imgView.image = image;
            } failure:nil];
    }
    cell.backgroundColor = [UIColor whiteColor];
    
    if (unseen) {
        UIImageView* imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"red_circle"]];
        imgView.center = CGPointMake(cell.width - imgView.width - 50, (cell.height - imgView.height) / 2 + 12.5);
        //imgView.transform = CGAffineTransformMakeScale(2, 2);
        [cell addSubview:imgView];
    }
}

#pragma mark - UIActionSheet methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    Account *item = self.arrayOfArraysOfContacts[self.selectedIndex.section][self.selectedIndex.row];
    
    
    DBAccount* dbAccount = [DBAccount retrieveDBAccountForAccountID:item.accountID];
    
    NSString *phone = [dbAccount.phone stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *action = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([action isEqualToString:@"Make a Call"]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", phone]]];
    }
    if ([action isEqualToString:@"Send a Text"]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"sms:%@", phone]]];
    }
    if ([action isEqualToString:@"View Profile"]) {
        [WFCore showViewController:self
                              name:@"Match"
                              mode:@"push"
                            params:@{@"account" : item,
                                     @"profileview" : @(YES),
                                     @"fromnotebook" : @(YES)}];    //Added by Yurii on 06/11/14}];
    }
    if ([action isEqualToString:@"Chat"]) {
        [WFCore showViewController:self
                              name:@"Messages"
                              mode:@"push"
                            params:@{@"account" : item}];
    }
    if ([action isEqualToString:@"Burn"]) {
        DBAccount* dbAccount = [DBAccount retrieveDBAccountForAccountID:item.accountID];
        dbAccount.burned = [NSNumber numberWithBool:YES];
        [dbAccount save];
        [[APIClient sharedClient] burnUser:item success:nil failure:nil];
        [self getItems];
    }
    if ([action isEqualToString:@"Create a New Contact"]) {
        ABRecordRef person = ABPersonCreate();
        ABRecordSetValue(person, kABPersonFirstNameProperty, (__bridge CFStringRef)item.alias, NULL);
        ABMutableMultiValueRef phone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        ABMultiValueAddValueAndLabel(phone, (__bridge CFStringRef)item.phone, kABPersonPhoneMainLabel, NULL);
        ABRecordSetValue(person, kABPersonPhoneProperty, phone, nil);
        CFRelease(phone);
//        if (item[@"image"]) {
//            CFErrorRef* error = NULL;
//            NSData *data = UIImagePNGRepresentation(item[@"image"]);
//            CFDataRef cfdata = CFDataCreate(NULL, [data bytes], [data length]);
//            ABPersonSetImageData(person, cfdata, error);
//            CFRelease(cfdata);
//        }
        ABNewPersonViewController *view = [[ABNewPersonViewController alloc] init];
        view.newPersonViewDelegate = self;
        view.displayedPerson = person;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:view];
        [self presentViewController:nav animated:YES completion:nil];
        CFRelease(person);
    }
    if ([action isEqualToString:@"Add to Existing Contact"]) {
        ABPeoplePickerNavigationController *view = [[ABPeoplePickerNavigationController alloc] init];
        view.peoplePickerDelegate = self;
        [self presentViewController:view animated:YES completion:nil];
    }
}

#pragma mark - ABNewPersonViewControllerDelegate methods

- (void)newPersonViewController:(ABNewPersonViewController *)newPersonViewController didCompleteWithNewPerson:(ABRecordRef)person
{
    [newPersonViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - ABPeoplePickerNavigationController methods

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    Account *item = self.arrayOfArraysOfContacts[self.selectedIndex.section][self.selectedIndex.row];
    CFErrorRef* error = NULL;
    ABAddressBookRef ab = peoplePicker.addressBook;
    CFTypeRef phone = ABRecordCopyValue(person, kABPersonPhoneProperty);
    ABMutableMultiValueRef phones = ABMultiValueCreateMutableCopy(phone);
    ABMultiValueAddValueAndLabel(phone, (__bridge CFTypeRef)item.phone, kABPersonPhoneOtherFAXLabel, NULL);
    ABRecordSetValue(person, kABPersonPhoneProperty, phone, nil);
    
//    if (item[@"image"]) {
//        NSData *data = UIImagePNGRepresentation(item[@"image"]);
//        CFDataRef cfdata = CFDataCreate(NULL, [data bytes], [data length]);
//        if (ABPersonHasImageData(person)) {
//            ABPersonRemoveImageData(person, error);
//            ABAddressBookSave(ab, error);
//        }
//        ABPersonSetImageData(person, cfdata, error);
//        CFRelease(cfdata);
//    }
    ABAddressBookSave(ab, error);
    CFRelease(phone);
    CFRelease(phones);
    [peoplePicker dismissViewControllerAnimated:YES completion:nil];
    return NO;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    [peoplePicker dismissViewControllerAnimated:YES completion:nil];
    return NO;
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    [peoplePicker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ((NSArray*)self.arrayOfArraysOfContacts[section]).count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.arrayOfArraysOfContacts.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 24;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGFloat height = [self tableView:tableView heightForHeaderInSection:section];
    UIView* vHeader = [[UIView alloc] init];
    vHeader.frame = CGRectMake(0, 0, 320, height);
    UILabel* label = [[UILabel alloc] init];
    
    label.font = [UIFont fontWithName:MAIN_FONT size:17];
    [label setTextColor:[UIColor blackColor]];
    label.frame = CGRectMake(24,  height - 24,
                             320 - 24,
                             24);
    [vHeader addSubview:label];
    vHeader.backgroundColor = GRAY_8;
    
    label.text = [[self tableView:tableView titleForHeaderInSection:section] uppercaseString];
    
    return vHeader;
}

- (NSMutableArray*)filterItems:(NSArray*)items
{
    if (!self.searchText.length) return [items mutableCopy];
    
    NSMutableArray *list = [@[] mutableCopy];
    for (int i = 0; i < items.count; i++) {
        Account *item = items[i];
        if (item.name && [item.name rangeOfString:self.searchText options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [list addObject:item];
        } else
            if (item.alias && [item.alias rangeOfString:self.searchText options:NSCaseInsensitiveSearch].location != NSNotFound) {
                [list addObject:item];
            }
    }
    return list;
}

- (void)reloadTable
{
    self.searchText = self.searchBar.text;

    if (self.itemsAll.count) self.items = [self filterItems:self.itemsAll];
    
    [self createArrayOfContactsFromItems];
    
    [self.table reloadData];
    
    [self showOrHideEmptyView];
}

- (void)showOrHideEmptyView
{
    if (self.items.count == 0) {
        [self.table addSubview:self.emptyView];
    } else {
        [self.emptyView removeFromSuperview];
    }
}

- (void)createArrayOfContactsFromItems
{
    self.arrayOfArraysOfContacts = [NSMutableArray new];
    
    if (self.items.count > 0) {
        //Sort Contacts
        NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"alias" ascending:YES];
        NSArray* itemsOrdered = [self.items sortedArrayUsingDescriptors:@[sortDescriptor]];
        
        //Segment by First Letter
        NSMutableArray* currentArrayForLetter;
        NSString* currentLetter;
        
        for (Account* item in itemsOrdered) {
            NSString* name = item.alias ?: item.name;
            NSString* firstLetter = (name.length > 0 ? [name substringToIndex:1] : @"");
            
            if (![currentLetter isEqualToString:firstLetter]) {
                if (currentArrayForLetter.count > 0)
                    [self.arrayOfArraysOfContacts addObject:currentArrayForLetter];
                
                currentArrayForLetter = [NSMutableArray new];
                currentLetter = firstLetter;
            }
            
            [currentArrayForLetter addObject:item];
        }
        
        if (currentArrayForLetter.count > 0)
            [self.arrayOfArraysOfContacts addObject:currentArrayForLetter];
    }
}

#pragma Mark Section Indexing
/*
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
}
*/
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    Account *accountItem = self.arrayOfArraysOfContacts[section][0];
    if ([accountItem.alias length] > 0) {
        return [accountItem.alias substringToIndex:1];
    } else {
        return @"";
    }
}
/*
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index];
}
*/
#pragma mark - Delete Items

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView beginUpdates];
        
        NSInteger sectionCount = ((NSArray*)self.arrayOfArraysOfContacts[indexPath.section]).count;
        
        [self deleteItemAtIndexPath:indexPath];
        
        if (sectionCount == 1) {
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        [tableView endUpdates];
    }
}

- (void)deleteItemAtIndexPath:(NSIndexPath*)indexPath
{
    Account *item = self.arrayOfArraysOfContacts[indexPath.section][indexPath.row];
    
    DBAccount* dbAccount = [DBAccount retrieveDBAccountForAccountID:item.accountID];
    dbAccount.burned = [NSNumber numberWithBool:YES];
    [dbAccount save];
    
    [self getItems];
}

-(void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath{
    [self inEditMode:YES];
}

-(void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath{
    [self inEditMode:NO];
}
//on self.editButtonItem click
-(void)setEditing:(BOOL)editing animated:(BOOL)animated{
    [super setEditing:editing animated:animated];
    [self inEditMode:editing];
}

-(void)inEditMode:(BOOL)inEditMode{
    if (inEditMode) { //hide index while in edit mode
        self.table.sectionIndexMinimumDisplayRowCount = NSIntegerMax;
    }else{
        self.table.sectionIndexMinimumDisplayRowCount = NSIntegerMin;
    }
    [self.table reloadSectionIndexTitles];
}


@end
