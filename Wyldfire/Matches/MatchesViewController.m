//
//  MatchesViewController.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/19/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "MatchesViewController.h"
#import "DBAccount+util.h"

@interface MatchesViewController () <UITextViewDelegate>
    @property (nonatomic) BOOL singleMatch;
    //Added by Yurii on 06/11/14
    @property (nonatomic) BOOL notebookMode;
    @property (nonatomic) BOOL profileMode;

    @property (nonatomic, strong) NSMutableArray* matchItems;

    @property (strong, nonatomic) BrowseCardView* currentCard;
    @property (strong, nonatomic) BrowseCardView* nextCardCached;
    @property (atomic) BOOL currentlySearching;

    @property (nonatomic) BOOL initialized;

    @property (nonatomic, strong) UITextView* emptyLabel;
@end

@implementation MatchesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.params[@"profileview"]) {
        self.profileMode = YES;
    }
    //Added by Yurii on 06/11/14
    if (self.params[@"fromnotebook"])
        self.notebookMode = YES;
    
    NSString* title = self.profileMode ? @"Profile" : @"Matches";
    
    [self initialize];
    self.toolbarNextIcon = @"matchInfo";
    [self addToolbar:title];
    
    NSMutableAttributedString* str = [[NSMutableAttributedString alloc] initWithString:@"You have no active Matches. Sending a “HINT!” increases the likelihood of a match. Send one in Browse."];
    
    [str addAttribute:NSLinkAttributeName value:@"browse" range:[str.string rangeOfString:@"Browse"]];
    [str addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:[str.string rangeOfString:@"Browse"]];
    
    self.emptyLabel = [self addEmptyViewWithText:str];
    self.emptyLabel.delegate = self;
    self.emptyLabel.alpha = 0.0;
    
    [self subscribeToNotifications];
    
    //CGPoint pt = CGPointMake(75, 30);
    //[self addToolbarImage:@"buttonMatchesActive" atPoint:pt];
    
    //[self.toolbar addSubview:self.toolbarNext];
    
    UIButton* btnLink = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnLink setFrame:CGRectMake(170, 25, 100, 50)];
    btnLink.backgroundColor = [UIColor clearColor];
    [btnLink addTarget:self action:@selector(onClickBtn:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark Button Action HyperlinkButton

- (void) onClickBtn:(id) sender {
    
    // [WFCore showAlert:@"Alert" msg:@"Hyperlink Clicked" delegate:nil confirmHandler:nil];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)addToolbarImage:(NSString*)imageName atPoint:(CGPoint)point
{
    UIImageView* imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    imgView.origin = point;
    [self.view addSubview:imgView];
}

- (void)onNext:(id)sender
{
    [FacebookUtility getUserInfo:self.currentCard.account.facebookID success:^(id obj) {
        //
    } failure:^(NSInteger code) {
        //
    }];
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)url inRange:(NSRange)characterRange
{
    [self.navigationController popToRootViewControllerAnimated:YES];
    return NO;
}

- (void)firstMatchPopup
{
    if (![GVUserDefaults standardUserDefaults].firstViewMatch) {
        [GVUserDefaults standardUserDefaults].firstViewMatch = TRUE;
        [WFCore showAlert:@"Don’t leave them hanging" text:@"Choose to either burn or chat with your latest match before viewing the next one." delegate:nil cancelButtonText:@"OK" otherButtonTitles:nil tag:MATCH_FIRST_VIEW_ALERT];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.params[@"account"]) {      //Matches was brought up for a single account (new match or blackbook)
        self.singleMatch = YES;
        Account* account = self.params[@"account"];
        
        BrowseCardView* card = [self cardForAccount:account];
        [self.view addSubview:card];
        self.currentCard = card;
        if (self.profileMode) {
            self.toolbarTitle.text = account.alias;
            [card cropButtons];
            card.clipsToBounds = YES;
            card.origin = CGPointMake(9, self.toolbar.bottom + 8);
            card.revealableInfo = YES;
        }
        [self firstMatchPopup];
    } else {                            //Matches as brought up to view all pending matches
        [self retrieveData];
    }
}

- (void)initialize
{
    self.view.backgroundColor = GRAY_8;
    self.matchItems = [NSMutableArray new];
}

- (void)retrieveData
{
    NSArray* pendingMatches = [DBAccount getAccountsForPendingMatches];
    
    if (pendingMatches.count == 0) {
        [self downloadData];
    } else {
        [self addPendingMatchesToItems:pendingMatches];
        [self showCard];
    }
}

//- (void)viewDidAppear:(BOOL)animated
//{
//    [super viewDidAppear:animated];
//    if (!self.singleMatch) {
//        if (self.matchItems.count > 0 && self.currentCard == nil)
//            [self showCard:[self nextCard]];
//            
//    }
//}

- (void)showCard
{
    [self hideActivity];
    if (self.currentCard == nil) {
        [self showNextCard];
    } else if (self.nextCardCached == nil){
        self.nextCardCached = [self nextCard];
    }
}

- (void)downloadData
{
    [self showActivity];
    [[APIClient sharedClient] getPendingMatches:^(NSArray *matches) {
        if (matches == nil) {
            if ([self.navigationController topViewController] == self) [self setEmptyLabelAlpha:1.0];
            [self hideActivity];
            return;
        }
        [[APIClient sharedClient] storePendingMatches:matches];
        
        NSArray* pendingMatches = [DBAccount getAccountsForPendingMatches];
        if (pendingMatches.count > 0) {
            [self addPendingMatchesToItems:pendingMatches];
            [self setEmptyLabelAlpha:0.0];
            [self showCard];
        } else {
            if ([self.navigationController topViewController] == self)    //May just need time to load the match
                [self setEmptyLabelAlpha:1.0];
        }
        [self hideActivity];
    }];
}

- (BrowseCardView*)nextCard
{
    BrowseCardView* card = nil;
    
    if (self.nextCardCached != nil) {
        BrowseCardView* card = self.nextCardCached;
        self.nextCardCached = nil;
        return card;
    }
    
    if (self.matchItems.count > 0) {
        Account* firstItem = self.matchItems[0];
        [self.matchItems removeObjectAtIndex:0];
        
        card = [self cardForAccount:firstItem];
        card.revealableInfo = YES;
        card.clipsToBounds = YES;
        
        [card loadOtherImages:4];
    }
    return card;
}

- (BrowseCardView *)cardForAccount:(Account*)account
{
    BrowseCardView* card = [BrowseCardView cardForAccount:account inBrowse:NO inTrending:NO inMatches:YES inProfile:self.profileMode];
    card.isFromNotebook = self.notebookMode;    //Added by Yurii on 06/11/14
    
    [card.likeButton setTitle:@"Chat" forState:UIControlStateNormal];
    [card.passButton setTitle:@"Burn" forState:UIControlStateNormal];
    card.delegate = self;
    
    return card;
}

- (void)showCard:(BrowseCardView*)card
{
    if (card == nil) return;
    
    if (self.currentCard == nil) {
        [self firstMatchPopup];
        
        if (!self.initialized) {
            self.initialized = YES;
            [self.view addSubview:card];
        } else {
            [self animateInCardFromTop:card];
        }
    } else {
        //[self flipFromView:self.currentCard toView:card];
    }
    
    self.currentCard = card;
    
    //Cache next card
    self.nextCardCached = nil;
    BrowseCardView* nextCard = [self nextCard];
    if (self.nextCardCached == nil) self.nextCardCached = nextCard;
}

- (void)showNextCard
{
    if (self.singleMatch) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        BrowseCardView* next = [self nextCard];
        if (next) {
            [self showCard:next];
        } else {
            [self setEmptyLabelAlpha:1.0];
        }
    }
}

- (void)setEmptyLabelAlpha:(float)alphaValue
{
    [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionTransitionCrossDissolve
                     animations:^{
                         self.emptyLabel.alpha = alphaValue;
                     } completion:nil];
}

#pragma mark Card Delegate

- (void)cardLikeTapped:(BrowseCardView *)card
{
    DBAccount* dbAccount = [DBAccount retrieveDBAccountForAccountID:card.account.accountID];
    dbAccount.inChat = @(YES);
    dbAccount.showInMatches = [NSNumber numberWithBool:NO];
    [dbAccount save];
    
    [WFCore showViewController:self name:@"Messages" mode:@"push" params:@{@"account"     : card.account,
                                                                           @"fromMatches" : @(YES),
                                                                           @"singleMatch" : [NSNumber numberWithBool:self.singleMatch]}];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (self.singleMatch) {
            NSMutableArray* vcs = [[self.navigationController viewControllers] mutableCopy];
            [vcs removeObject:self];
            [self.navigationController setViewControllers:vcs animated:NO];
        } else {
            [self.currentCard removeFromSuperview];
            self.currentCard = nil;
            //self.initialized = NO;
            //if (self.matchItems.count > 0 || self.nextCardCached != nil)
            //    [self showCard:[self nextCard]];
            //[self enablePop:YES];
        }
    });
}

- (void)cardPassTapped:(BrowseCardView *)card
{
    if (![GVUserDefaults standardUserDefaults].hasBurnedMatch) {
        [WFCore showAlert:@"Burn" text:[NSString stringWithFormat:@"Are you sure you want to burn %@? This will remove them from your network and cannot be undone.", card.account.alias] delegate:self cancelButtonText:@"Cancel" otherButtonTitles:@[@"OK"] tag:CHAT_BURN_ALERT];
        [GVUserDefaults standardUserDefaults].hasBurnedMatch = YES;
    } else {
    
        DBAccount* dbAccount = [DBAccount retrieveDBAccountForAccountID:card.account.accountID];
        dbAccount.showInMatches = [NSNumber numberWithBool:NO];
        dbAccount.inChat = [NSNumber numberWithBool:NO];
        dbAccount.burned = [NSNumber numberWithBool:YES];
        [dbAccount save];
        [[APIClient sharedClient] burnUser:card.account success:nil failure:nil];
        
        [self animateCardToLeft];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    alertView.delegate = nil;
    if (alertView.tag == CHAT_BURN_ALERT) {
        if (buttonIndex == 1) {
            [self cardPassTapped:self.currentCard];
        }
    }
}

- (void)trendingCardTapped:(BrowseCardView *)card
{
    
}

- (void)enablePop:(BOOL)enabled
{
    self.toolbarBack.enabled = enabled;
}

- (void)animateCardToRight
{
    [self enablePop:NO];
    [UIView animateWithDuration:0.7 delay:0.0 options:0
                     animations:^{
                         self.currentCard.frame = CGRectOffset(self.currentCard.frame, 400, 0.0);
                     } completion:^(BOOL finished) {
                         if (finished) {
                             [self.currentCard removeFromSuperview];
                             self.currentCard = nil;
                             [self showNextCard];
                             [self enablePop:YES];
                         }
                     }];
}

- (void)animateCardToLeft
{
    [self enablePop:NO];
    [UIView animateWithDuration:0.25 delay:0.0 options:0
                     animations:^{
                         self.currentCard.frame = CGRectOffset(self.currentCard.frame, -400, 0.0);
                     } completion:^(BOOL finished) {
                         if (finished) {
                             [self.currentCard removeFromSuperview];
                             self.currentCard = nil;
                             [self showNextCard];
                             [self enablePop:YES];
                         }
                     }];
}

- (void)animateInCardFromTop:(UIView*)card
{
    [self.view addSubview:card];
    CGRect originalFrame = card.frame;
    card.frame = CGRectOffset(originalFrame, 0, -CGRectGetHeight(self.view.frame));
    
    [UIView animateWithDuration:0.7 delay:0.0 options:0
                     animations:^{
                         card.frame = originalFrame;
                     } completion:^(BOOL finished) {
                         
                     }];
}

#pragma mark - Notifications

- (void)subscribeToNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reload)
                                                 name:NOTIFICATION_UPDATED_PENDING_MATCHES
                                               object:nil];
}

- (void)reload
{
    NSArray* pendingMatches = [DBAccount getAccountsForPendingMatches];
    if (!self.singleMatch && pendingMatches.count > 0) {

        [self addPendingMatchesToItems:pendingMatches];
        
        if (self.matchItems.count > 0 && !self.currentCard) {
            [self setEmptyLabelAlpha:0.0];
            [self showCard];
        }
    }
}

- (void)addPendingMatchesToItems:(NSArray*)pendingMatches
{
    NSArray* accountIDs = [self.matchItems valueForKeyPath:@"@unionOfObjects.accountID"];
    
    for (int i = 0; i < pendingMatches.count; i++) {
        DBAccount* account = pendingMatches[i];
    
        if (!([accountIDs containsObject:account.accountID] ||
              [self.currentCard.account.accountID isEqualToString:account.accountID] ||
              [self.nextCardCached.account.accountID isEqualToString:account.accountID]))
        {
            [self.matchItems addObject:account];
            accountIDs = [self.matchItems valueForKeyPath:@"@unionOfObjects.accountID"];
        }
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
