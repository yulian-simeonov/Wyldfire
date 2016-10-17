//
//  ChatViewController.m
//  Wyldfire
//
//  Created by Vlad Seryakov on 10/20/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

#import "ChatListImageView.h"
#import "Message+util.h"

@interface ChatViewController () <UITextViewDelegate>
@property (nonatomic, strong) UITextView* emptyLabel;
@end

@implementation ChatViewController

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setEmptyLabelTransparency];
}

- (void)setEmptyLabelTransparency
{
    float alphaValueFromBool = (CGFloat)(self.itemsAll.count == 0);
    self.emptyLabel.alpha = alphaValueFromBool;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self addTable];
    self.tableRows = 1;
    self.tableSearch.placeholder = @"Search Chats";
    [self addToolbar:@"Chats"];
    
    [self retrieveMessages];
    [self subscribeToNotifications];
    
    NSMutableAttributedString* str = [[NSMutableAttributedString alloc] initWithString:@"You have no active chats. Sending a “HINT!” increases the likelihood of a match. Send one in Browse."];
    
    [str addAttribute:NSLinkAttributeName value:@"browse" range:[str.string rangeOfString:@"Browse"]];
    [str addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:[str.string rangeOfString:@"Browse"]];
    
    
    self.emptyLabel = [self addEmptyViewWithText:str];
    self.emptyLabel.delegate = self;
    
    self.emptyLabel.alpha = 0.0;
    //CGPoint pt = CGPointMake(75, 34);
    //[self addToolbarImage:@"chat" atPoint:pt];
    
    UIButton* btnLink = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnLink setFrame:CGRectMake(170, 25, 100, 50)];
    btnLink.backgroundColor = [UIColor clearColor];
    [btnLink addTarget:self action:@selector(onClickBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.emptyLabel addSubview:btnLink];
}

#pragma mark Button Action HyperlinkButton

- (void) onClickBtn:(id) sender {
    
    [WFCore showAlert:@"Alert" msg:@"HyperLink Clicked" delegate:self confirmHandler:nil];
}

- (void)addToolbarImage:(NSString*)imageName atPoint:(CGPoint)point
{
    UIImageView* imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    imgView.origin = point;
    [self.view addSubview:imgView];
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)url inRange:(NSRange)characterRange
{
    [self.navigationController popToRootViewControllerAnimated:YES];
    return NO;
}

- (void)retrieveMessages
{
    self.itemsAll = [[Message retrieveAccountsInMessages] mutableCopy];
    
    if ([WFCore get].accountStructure.isMale) {
        if (self.itemsAll.count > 5) {
            [WFCore saveMoment:KIIP_REWARD_MOMENT_5_CHATS_MALE
                      onlyOnce:YES
                       topText:@"Master Multitask"
                    bottomText:@"Chatting with 5 women!" inNavC:self.navigationController];
        }
    } else {
        if (self.itemsAll.count > 10) {
            [WFCore saveMoment:KIIP_REWARD_MOMENT_10_CHATS_FEMALE
                      onlyOnce:YES
                       topText:@"Burning with Desire"
                    bottomText:@"Chatting with 10 men!" inNavC:self.navigationController];
        }
    }
    
    [self reloadTable];
    
    [self setEmptyLabelTransparency];
    
    [[APIClient sharedClient] downloadNewMessages];
}

- (NSMutableArray*)filterItems:(NSArray*)items
{
    if (self.searchText.length == 0) return [items mutableCopy];
    
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


- (void)onTableSelect:(NSIndexPath *)indexPath selected:(BOOL)selected
{
    if (!selected) return;
    
    Account* account = [self getItem:indexPath];
    if (account) {
        [WFCore showViewController:self name:@"Messages" mode:@"push" params:@{@"account" : account}];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.row == 0 ? 40 : 80);
}

- (void)onTableCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0: {
            self.tableSearch.frame = CGRectInset(cell.frame, 5, 5);
            [cell addSubview:self.tableSearch];
            self.table.contentOffset = CGPointMake(0, 40);
            break;
        }
            
        default: {
            Account *item = [self getItem:indexPath];
    
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            //Label
            [self addLabelsToCell:cell fromAccount:item];
            
            //Chat Cell Image View
            int countdownNumber = 20 - item.messageCount;
            if (countdownNumber < 0) countdownNumber = 0;
            
            CGFloat totalHeight = CGRectGetHeight(cell.frame);
            
            CGRect chatImageRect = CGRectMake(8,
                                              (totalHeight - CHAT_LIST_IMAGE_WIDTH) / 2,
                                              CHAT_LIST_IMAGE_WIDTH,
                                              CHAT_LIST_IMAGE_WIDTH);
            
            ChatListImageView* imageView = [ChatListImageView imageViewWithFrame:chatImageRect
                                                                          number:countdownNumber
                                                                           image:nil];
            [cell addSubview:imageView];
            
            if ([[DBAccount retrieveDBAccountForAccountID:item.accountID].sentShareTo boolValue]) {
                imageView.numberLabel.alpha = 0.0;
            }
            
            [self loadImageForItem:item
                     chatImageView:imageView
                         indexPath:indexPath];
        }
    }
}

- (void)addLabelsToCell:(UITableViewCell*)cell fromAccount:(Account*)item
{
    Message* lastMessage = [Message lastMessageForAccountID:item.accountID];
    
    CGFloat labelXOffset = CHAT_LIST_IMAGE_WIDTH + 20;
    CGFloat labelHeight = CGRectGetHeight(cell.frame) / 4;
    CGFloat labelWidth = CGRectGetWidth(cell.frame) - labelXOffset;
    
    CGRect topLabelRect = CGRectMake(labelXOffset,
                                 labelHeight,
                                 labelWidth, labelHeight);
    UIColor* color = [lastMessage.unread boolValue] ? WYLD_RED : [UIColor blackColor];
    UILabel* topLabel = [self labelInRect:topLabelRect withText:item.alias
                                    color:color
                                     font:[UIFont fontWithName:BOLD_FONT size:17]];
    [cell addSubview:topLabel];
    
    CGRect bottomLabelRect = CGRectOffset(topLabelRect, 0, labelHeight);
    color = [UIColor grayColor];
    
    UILabel* bottomLabel = [self labelInRect:bottomLabelRect
                                    withText:lastMessage.text
                                       color:color
                                        font:[UIFont fontWithName:MAIN_FONT size:14]];
    [cell addSubview:bottomLabel];
}

- (UILabel*)labelInRect:(CGRect)frame withText:(NSString*)text color:(UIColor*)color font:(UIFont*)font
{
    UILabel* label = [[UILabel alloc] initWithFrame:frame];
    
    label.text = text;
    label.textColor = color;
    label.font = font;
    label.textAlignment = NSTextAlignmentLeft;
    label.alpha = 1.0;
    
    return label;
}

- (void)loadImageForItem:(Account*)account chatImageView:(ChatListImageView*)imageView indexPath:(NSIndexPath*)indexPath
{
    if (account.showcasePhoto) {
        imageView.image = account.showcasePhoto;
    } else {
        [[APIClient sharedClient] getAccountImageOfType:0 account:account.accountID
            success:^(UIImage *image, NSString *url) {
                [account setImage:image forType:0];
                imageView.image = account.showcasePhoto;
            } failure:^(NSInteger code) {
                //
            }];
    }
}

#pragma mark Notifications

- (void)subscribeToNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadMessages) name:NOTIFICATION_UPDATED_MESSAGES object:nil];
}

- (void)reloadMessages
{
    self.itemsAll = [[Message retrieveAccountsInMessages] mutableCopy];
    
    [self reloadTable];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
