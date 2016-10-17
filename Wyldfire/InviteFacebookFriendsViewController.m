//
//  InviteFacebookFriends.m
//  Wyldfire
//
//  Created by Vlad Seryakov on 11/23/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//
#import <AddressBook/AddressBook.h>
#import <MessageUI/MessageUI.h>

@interface InviteFacebookFriendsViewController () <MFMessageComposeViewControllerDelegate>
@property (nonatomic) CGRect nextRect;
@property (strong, nonatomic) UIButton *sendBtn;
@property (strong, nonatomic) NSDictionary *selectedUser;
@property (strong, nonatomic) NSString *selectedPhoneNum;
@property (nonatomic) NSInteger selectedRow;
@property (nonatomic, strong) UIActivityIndicatorView* activity;
@end

@implementation InviteFacebookFriendsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.selectedRow = -1;
    
    [self addTable];
    self.tableRows = 2;
    self.table.allowsMultipleSelection = NO;
    self.table.backgroundColor = GRAY_8;
    
    self.tableSearch.placeholder = @"Search name or enter number";
    // self.tableSearch.frame = CGRectInset(self.tableSearch.frame, 5, 0);
    
    CGRect rctFrame = self.tableSearch.frame;
    rctFrame.size.width -= 46;
    self.tableSearch.frame = CGRectInset(rctFrame, 5, 0);
    
    self.sendBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.sendBtn setTitle:@"Send" forState:UIControlStateNormal];
    [self.sendBtn addTarget:self action:@selector(onSend:) forControlEvents:UIControlEventTouchUpInside];
    
    [self addToolbar:@""];
    [self loadFriends];
    [self updateToolbarTitle];
    [self loadActivityView];
}

- (void)onSend:(id)sender
{
    if (self.selectedUser && [self.selectedUser[@"name"] isEqualToString:self.tableSearch.text]) {
        [self.view endEditing:YES];
        
        NSArray *phoneNumbers = self.selectedUser[@"phones"];
        NSArray *phoneLabels = self.selectedUser[@"labels"];
        
        UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:@"Send Text" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        
        for (int i = 0; i < [phoneNumbers count]; i++) {
            NSString *buttonTitle = [NSString stringWithFormat:@"%@: %@", phoneLabels[i], phoneNumbers[i]];
            [action addButtonWithTitle:buttonTitle];
        }
        [action addButtonWithTitle:@"Cancel"];
        action.cancelButtonIndex = [phoneNumbers count];
        
        action.tag = ACTIONSHEET_PHONE;
        action.actionSheetStyle = UIActionSheetStyleBlackOpaque;
        [action showInView:self.view];
        [action styleWithTintColor:WYLD_RED];
    } else {
        NSString *phoneNumber = self.tableSearch.text;
        if ([phoneNumber length] >= 7 && [phoneNumber rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location != NSNotFound) {
            [self.view endEditing:YES];
            
            UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:@"Send Text" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:phoneNumber, nil];
            
            action.tag = ACTIONSHEET_PHONE;
            action.actionSheetStyle = UIActionSheetStyleBlackOpaque;
            [action showInView:self.view];
            [action styleWithTintColor:WYLD_RED];
        }
    }
}

- (void)updateToolbarTitle
{
    int invitesRemaining = [WFCore get].accountStructure.stats.maxInvites;
    self.toolbarTitle.text = [NSString stringWithFormat:@"%i Invite%@ Left", invitesRemaining, invitesRemaining > 1 ? @"s" : @""];
}

- (void)loadFriends
{
    CFErrorRef error = nil;
    ABAddressBookRef book = ABAddressBookCreateWithOptions(NULL, &error);
    if (!book) return;
    ABAddressBookRequestAccessWithCompletion(book, ^(bool granted, CFErrorRef error) {
        if (!granted) return;
        NSMutableArray* phoneContacts = [NSMutableArray new];
        
        NSArray *contacts = CFBridgingRelease(ABAddressBookCopyArrayOfAllPeople(book));
        for (int i = 0; i < contacts.count; i++) {
            ABRecordRef person = (__bridge ABRecordRef) [contacts objectAtIndex:i];
            ABMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
            if (!phones || ABMultiValueGetCount(phones) <= 0) {
                CFRelease(phones);
                continue;
            }
            
            if (ABMultiValueGetCount(phones) == 0) {
                CFRelease(phones);
                continue;
            }
            
            NSMutableDictionary *item = [@{} mutableCopy];
            item[@"phones"] = [@[] mutableCopy];
            item[@"labels"] = [@[] mutableCopy];
            for (CFIndex i = 0; i < ABMultiValueGetCount(phones); i++) {
                [item[@"phones"] addObject:CFBridgingRelease(ABMultiValueCopyValueAtIndex(phones, i))];
                CFStringRef phoneLabel = ABMultiValueCopyLabelAtIndex(phones, i);
                [item[@"labels"] addObject:[self phoneTypeFromLabel:phoneLabel]];
                if (phoneLabel) CFRelease(phoneLabel);
            }
            CFRelease(phones);
            
            // Apparently if exported from Exchange servers these can actually be NULL hence the check
            // Not sure if you want to continue or what else you wish to do here, but this will avoid the
            // Crashing that occurred in #14
            NSString *compositeName = CFBridgingRelease(ABRecordCopyCompositeName(person));
            if (compositeName == nil) continue;

            item[@"name"] = compositeName;
            if (ABPersonHasImageData(person)) {
                item[@"icon"] = [UIImage imageWithData:(NSData *)CFBridgingRelease(ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail))];
            }
            [phoneContacts addObject:item];
        }
        [phoneContacts sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
        self.itemsAll = phoneContacts;
        
        CFRelease(book);
        [self performSelectorOnMainThread:@selector(reloadTable) withObject:self waitUntilDone:YES];
    });
}

- (NSString *)phoneTypeFromLabel:(CFStringRef)phoneLabel
{
    if (phoneLabel && CFStringGetLength(phoneLabel) > 0) {
        if (CFStringCompare(phoneLabel, kABPersonPhoneMobileLabel, kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
            return @"mobile";
        } else if (CFStringCompare(phoneLabel, kABPersonPhoneIPhoneLabel, kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
            return @"iPhone";
        } else if (CFStringCompare(phoneLabel, kABPersonPhoneMainLabel, kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
            return @"main";
        } else if (CFStringCompare(phoneLabel, kABPersonPhoneHomeFAXLabel, kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
            return @"home fax";
        } else if (CFStringCompare(phoneLabel, kABPersonPhoneWorkFAXLabel, kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
            return @"work fax";
        } else if (CFStringCompare(phoneLabel, kABPersonPhoneOtherFAXLabel, kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
            return @"other fax";
        } else if (CFStringCompare(phoneLabel, kABPersonPhonePagerLabel, kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
            return @"pager";
        }
    }
    
    return @"other";
}

- (void) onCheckAll:(id)sender
{
    NSArray *selected = [self.table indexPathsForSelectedRows];
    for (int i = 0; i < self.items.count; i++) {
        const NSUInteger idx[2] = { 0, i + 3 };
        NSIndexPath *path = [NSIndexPath indexPathWithIndexes:idx length:2];
        [self onTableSelect:path selected:selected.count ? NO : YES];
        if (selected.count == 0) {
            [self.table selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionNone];
        } else {
            [self.table deselectRowAtIndexPath:path animated:NO];
        }
    }
}

- (BOOL)isMale
{
    return [WFCore get].accountStructure.isMale;
}


- (void)onTableSelect:(NSIndexPath *)indexPath selected:(BOOL)selected
{
    [self.view endEditing:YES];
    if (indexPath.row < 2) return;
    
    if (selected) {
        self.selectedUser = self.items[indexPath.row - 2];
        self.tableSearch.text = self.selectedUser[@"name"];
        [self onSend:nil];
    }
    
    UITableViewCell *cell = [self.table cellForRowAtIndexPath:indexPath];
    UIImage *accessoryImg = (selected ? [UIImage imageNamed:@"red_circle"] : [UIImage imageNamed:@"gray_circle"]);
    cell.accessoryView = [[UIImageView alloc] initWithImage:accessoryImg];
    if (selected) {
        [self.table selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        self.selectedRow = indexPath.row;
    } else {
        [self.table deselectRowAtIndexPath:indexPath animated:NO];
        self.selectedRow = -1;
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == ACTIONSHEET_PHONE) {
        if (buttonIndex != actionSheet.cancelButtonIndex) {
            NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
            self.selectedPhoneNum = [[title componentsSeparatedByString:@": "] lastObject];
            NSLog(@"phone number: %@", self.selectedPhoneNum);
            if ([self isMale]) {
                [self showSMStoRecipients:@[self.selectedPhoneNum] inviteCode:nil];
            } else {
                [self getInviteCode];
            }
        }
    } else {
        NSLog(@"Code up the other actions");
    }
}

- (void)onTableCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    switch (indexPath.row) {
        case 0: {
            cell.backgroundColor = nil;
            CGFloat xStart = 16;
            CGRect firstLabelRect = CGRectMake(xStart, 14, cell.frame.size.width - 7, 17);
            UILabel *label = [[UILabel alloc] initWithFrame:firstLabelRect];
            label.textAlignment = NSTextAlignmentLeft;
            label.textColor = GRAY_2;
            label.font = [UIFont fontWithName:BOLD_FONT size:14];
            label.text = @"Invite others to join Wyldfire";
            [cell addSubview:label];
            
            CGRect subLabelRect = CGRectMake(xStart, CGRectGetHeight(firstLabelRect) + 14, cell.frame.size.width - 7, 15);
            UILabel *sublabel = [[UILabel alloc] initWithFrame:subLabelRect];
            sublabel.textAlignment = NSTextAlignmentLeft;
            sublabel.textColor = GRAY_2;
            sublabel.font = [UIFont fontWithName:BOLD_FONT size:12];
            sublabel.text = @"Our network is only as good as your taste";
            [cell addSubview:sublabel];
            break;
        }
        case 1: {
            CGRect rctFrame = cell.frame;
            rctFrame.size.width -= 46;
            rctFrame = CGRectInset(rctFrame, 10, 6.75);
            self.tableSearch.frame = rctFrame;
            
            rctFrame.origin.x = CGRectGetMaxX(rctFrame) + 6;
            rctFrame.size.width = 40;
            self.sendBtn.frame = rctFrame;
            
            self.tableSearch.textAlignment = NSTextAlignmentLeft;
            cell.backgroundColor = [UIColor whiteColor];
            [cell addSubview:self.tableSearch];
            
            [self.sendBtn removeFromSuperview];
            [cell addSubview:self.sendBtn];
            break;
        }
        default: {
            CGFloat rowHeight = [self tableView:self.table heightForRowAtIndexPath:indexPath];
            
            NSDictionary *item = [self getItem:[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section]];
            UIImage *accessoryImg = (indexPath.row == self.selectedRow) ? [UIImage imageNamed:@"red_circle"] : [UIImage imageNamed:@"gray_circle"];
            cell.accessoryView = [[UIImageView alloc] initWithImage:accessoryImg];
            
            UIImageView *avatar = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"avatar_eclipse"]];
            avatar.center = CGPointMake(avatar.image.size.width/2 + self.tableIndent, rowHeight/2 );
            [cell addSubview:avatar];
            
            UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, avatar.image.size.width-3, avatar.image.size.width-3)];
            imgView.center = avatar.center;
            imgView.contentMode = UIViewContentModeScaleAspectFill;
            imgView.layer.cornerRadius = imgView.frame.size.width/2;
            imgView.layer.masksToBounds = YES;
            [cell addSubview:imgView];
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(avatar.frame.size.width+self.tableIndent*2, 0, cell.frame.size.width/2, rowHeight)];
            label.text = item[@"name"];
            label.textColor = [UIColor darkGrayColor];
            label.tag = 900;
            [cell addSubview:label];
            
            if (item[@"icon"]) {
                imgView.image = item[@"icon"];
            } else {
                imgView.alpha = 0.0;
                avatar.alpha = 0.0;
                // cell.accessoryView.alpha = 0.0;
            }
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
            return 50;
        case 1:
            return 43;
        default:
            return 44;
    }
}

#pragma mark - Loading Animation

- (void)loadActivityView
{
    self.activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activity.hidesWhenStopped = YES;
    self.activity.hidden = YES;
    self.activity.layer.backgroundColor = [[UIColor colorWithWhite:0.0f alpha:0.4f] CGColor];
    self.activity.frame = CGRectMake(0, 0, 64, 64);
    self.activity.layer.masksToBounds = YES;
    self.activity.layer.cornerRadius = 8;
}

- (void)showActivityInView:(UIView*)view
{
    if (self.activity.superview) return;
    [view addSubview:self.activity];
    self.activity.center = view.center;
    self.activity.hidden = NO;
    [self.activity startAnimating];
}

- (void)hideActivity
{
    [self.activity stopAnimating];
    [self.activity removeFromSuperview];
}

#pragma mark - Get invite code

- (void)getInviteCode
{
    [self showActivityInView:self.view];
    
    [[APIClient sharedClient] getInviteCode:^(id obj) {
        NSString *code = [NSString stringWithFormat:@"%@", obj];
        [self successCode:code];
    } failure:^{
        [self failCode];
    }];
}

- (void)successCode:(NSString *)code
{
    [self hideActivity];
    
    [self showSMStoRecipients:@[self.selectedPhoneNum] inviteCode:code];
}

- (void)failCode
{
    [self hideActivity];
    
    [WFCore showAlert:@"We were unable to send this invite. Please try again." text:nil delegate:nil cancelButtonText:@"OK" otherButtonTitles:nil tag:FAIL_GET_INVITE_CODE];
}

#pragma Mark Section Indexing
/*
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [((Account*)self.arrayOfArraysOfContacts[section][0]).alias substringToIndex:1];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index];
}
*/

- (void)showSMStoRecipients:(NSArray*)recipients inviteCode:(NSString *)code
{
    if(![MFMessageComposeViewController canSendText]) {
        [WFCore showAlert:@"Error" msg:@"Your device doesn't support SMS!" delegate:nil confirmHandler:nil];
        return;
    }
    
    NSString *message = @"Hey, I think you would make a great addition to Wyldfire’s network. Download the app here: AppStore.com/Wyldfire or watch the commercial at youtu.be/BagXyAops9E";
    if ([code length] > 0) {
        message = [message stringByAppendingFormat:@"\nInvite Code: %@", code];
    }

    if ([self isMale]) message = @"Hey, do you think I belong on Wyldfire? It’s invite only and I need your approval :) Download the app here: AppStore.com/Wyldfire or watch the commercial at youtu.be/BagXyAops9E";
    
    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    messageController.messageComposeDelegate = self;
    [messageController setRecipients:recipients];
    [messageController setBody:message];
    
    // Present message view controller on screen
    [self presentViewController:messageController animated:YES completion:nil];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult) result
{
    switch (result) {
        case MessageComposeResultCancelled:
            break;
            
        case MessageComposeResultFailed:
            [WFCore showAlert:@"Error" msg:@"Failed to send SMS, please try again later!" delegate:nil confirmHandler:nil];
            break;
            
        case MessageComposeResultSent:{
            if ([self isMale]) break;
            [WFCore get].accountStructure.hasFeather = YES;
            [WFCore get].accountStructure.stats.sentInvites++;
            [WFCore get].accountStructure.stats.maxInvites--;
            [self updateToolbarTitle];
            break;
        }
        default:
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
