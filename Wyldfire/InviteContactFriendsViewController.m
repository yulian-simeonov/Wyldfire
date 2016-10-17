//
//  InviteContactFriendsViewController.m
//  Wyldfire
//
//  Created by Vlad Seryakov on 11/23/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

#import <AddressBook/AddressBook.h>

@interface InviteContactFriendsViewController () <UITextFieldDelegate>
@end;

@implementation InviteContactFriendsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self addTable];
    self.tableRows = 3;
    self.table.allowsMultipleSelection = YES;
    self.tableSearch.placeholder = @"Search contacts w/email";

    [self addToolbar:@"Invite Friends"];
    
    CFErrorRef error = nil;
    ABAddressBookRef book = ABAddressBookCreateWithOptions(NULL, &error);
    if (!book) return;
    ABAddressBookRequestAccessWithCompletion(book, ^(bool granted, CFErrorRef error) {
        if (!granted) return;
        NSArray *contacts = CFBridgingRelease(ABAddressBookCopyArrayOfAllPeople(book));
        for (int i = 0; i < contacts.count; i++) {
            ABRecordRef person = (__bridge ABRecordRef) [contacts objectAtIndex:i];
            ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
            if (!emails) continue;
            
            NSMutableDictionary *item = [@{} mutableCopy];
            for (CFIndex i = 0; i < ABMultiValueGetCount(emails); i++) {
                [item[@"emails"] addObject:CFBridgingRelease(ABMultiValueCopyValueAtIndex(emails, i))];
            }
            item[@"emails"] = [@[] mutableCopy];
            CFRelease(emails);
            
            item[@"name"] = CFBridgingRelease(ABRecordCopyCompositeName(person));
            if (ABPersonHasImageData(person)) {
                item[@"icon"] = [UIImage imageWithData:(NSData *)CFBridgingRelease(ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail))];
            }
            [self.itemsAll addObject:item];
        }
        CFRelease(book);
        [self performSelectorOnMainThread:@selector(reloadTable) withObject:self waitUntilDone:YES];
    });
}

- (void)onInvite:(id)sender
{
    Debug(@"%@", [self.table indexPathsForSelectedRows]);
}

- (void)onCheckAll:(id)sender
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

- (void)onTableSelect:(NSIndexPath *)indexPath selected:(BOOL)selected
{
    [self.view endEditing:YES];
    if (indexPath.row < 3) return;
    UITableViewCell *cell = [self.table cellForRowAtIndexPath:indexPath];
    [(UIImageView*)cell.accessoryView setImage:[UIImage imageNamed:selected ? @"black_check" : @"gray_circle"]];
}

- (void)onTableCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    switch (indexPath.row) {
        case 0: {
            self.tableSearch.frame = CGRectInset(cell.frame, 5, 5);
            [cell addSubview:self.tableSearch];
            break;
        }
        case 1: {
            UILabel *label = [[UILabel alloc] initWithFrame:cell.frame];
            label.textAlignment = NSTextAlignmentCenter;
            label.textColor = [UIColor grayColor];
            label.text = [NSString stringWithFormat:@"%lu Contacts", (unsigned long)self.items.count];
            [cell addSubview:label];
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            [button setTitle:@"invite" forState:UIControlStateNormal];
            [button sizeToFit];
            [button addTarget:self action:@selector(onInvite:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = button;
            break;
        }
        case 2: {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            [button setTitle:@"check all" forState:UIControlStateNormal];
            [button sizeToFit];
            [button addTarget:self action:@selector(onCheckAll:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = button;
            break;
        }
        default: {
            NSDictionary *item = [self getItem:indexPath];
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gray_circle"]];
            
            UIImageView *avatar = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"avatar_eclipse"]];
            avatar.center = CGPointMake(avatar.image.size.width/2 + self.tableIndent, self.table.rowHeight/2 );
            [cell addSubview:avatar];
            
            UIImageView *image = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, avatar.image.size.width-3, avatar.image.size.width-3)];
            image.center = avatar.center;
            image.contentMode = UIViewContentModeScaleAspectFill;
            image.layer.cornerRadius = image.frame.size.width/2;
            image.layer.masksToBounds = YES;
            if (item[@"icon"]) image.image = item[@"icon"];
            [cell addSubview:image];

            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(avatar.frame.size.width+self.tableIndent*2, 0, cell.frame.size.width - 100, cell.frame.size.height)];
            label.textColor = [UIColor grayColor];
            label.text = item[@"name"];
            [cell addSubview:label];
        }
    }
}

@end
