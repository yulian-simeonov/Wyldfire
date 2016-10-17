//
//  EventsViewController.m
//  Wyldfire
//
//  Created by Hafiz Zaily on 6/8/14.
//  Copyright (c) 2014 Wyldfire. All rights reserved.
//

@interface EventsViewController ()  <UITextViewDelegate>

@property (strong, nonatomic) UIImageView *popupViw;
@property (strong, nonatomic) UIImageView *comingViw;

@end

@implementation EventsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIImageView *backImg = [[UIImageView alloc] initWithFrame:self.view.bounds];
    backImg.image = [UIImage imageNamed:@"event_back"];
    [self.view addSubview:backImg];
    
    self.toolbarNextIcon = @"prefs";
    [self addToolbar:@"Upcoming Events"];
    [self.toolbar addSubview:self.toolbarNext];
    
    [self setupComingView];
    
    [self performSelector:@selector(showPopup) withObject:nil afterDelay:0.5];
}

- (void)setupComingView
{
    // setup coming view
    self.popupViw = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.popupViw.image = [UIImage imageNamed:@"popup_bg"];
    self.popupViw.userInteractionEnabled = YES;
    
    self.comingViw = [[UIImageView alloc] initWithFrame:CGRectMake(8, 113, 304, 322)];
    self.comingViw.image = [UIImage imageNamed:@"event_coming"];
    self.comingViw.userInteractionEnabled = YES;
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(64, 87, 176, 35)];
    button.backgroundColor = WYLD_RED;
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitle:@"Submit an Event" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(onSubmitEvent) forControlEvents:UIControlEventTouchUpInside];
    
    [self.comingViw addSubview:button];
    [self.popupViw addSubview:self.comingViw];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onPopup:)];
    [self.popupViw addGestureRecognizer:tap];
}

- (void)showPopup
{
    CGRect properRect = self.comingViw.frame;
    self.comingViw.frame = CGRectOffset(properRect, -320, 0);
    
    [UIView transitionWithView:self.view
                      duration:0.2
                       options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionTransitionCrossDissolve
                    animations:^ { [self.view addSubview:self.popupViw]; }
                    completion:^(BOOL finished) {
                        if (finished) {
                            
                            [UIView animateWithDuration:0.5 animations:^{
                                self.comingViw.frame = properRect;
                            }];
                        }
                    }];
}

- (void)dismissPopup:(UIPanGestureRecognizer *)recognizer
{
    UIView *view = recognizer.view;;
    [UIView transitionWithView:self.view
                      duration:0.5
                       options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionTransitionCrossDissolve
                    animations:^ { [view removeFromSuperview]; }
                    completion:^(BOOL finished) {
                        if ( [self respondsToSelector:@selector(onPopupClosed:)]) [self performSelector:@selector(onPopupClosed:) withObject:view];
                    }];
}

- (void)onPopupClosed:(UIView *)sender
{
    [self onBack:nil];
}

- (void)onSubmitEvent
{
    [self sendEmailWithSubject:@"Event Submission" recipient:@"events@wyldfireapp.com" body:@"Thanks for submitting an event. Please provide a link and a brief description of your event. We will consider including it in our weekly member updates."];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UITextView delegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)url inRange:(NSRange)characterRange
{
    [self sendEmailWithSubject:@"Event Submission" recipient:@"events@wyldfireapp.com" body:@"Thanks for submitting an event. Please provide a link and a brief description of your event. We will consider including it in our weekly member updates."];
    
    return NO;
}

- (void)sendEmailWithSubject:(NSString*)subject recipient:(NSString*)recipient body:(NSString*)body
{
    WFMailComposeViewController *mailViewController = [[WFMailComposeViewController alloc] init];
    mailViewController.navigationBar.tintColor = [UIColor blackColor];
    mailViewController.navigationBar.barTintColor = [UIColor blackColor];//WYLD_RED;
    //mailViewController.navigationBar.translucent = NO;
    mailViewController.mailComposeDelegate = self;
    mailViewController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor blackColor]};
    [mailViewController setSubject:subject];
    [mailViewController setMessageBody:body isHTML:NO];
    [mailViewController setToRecipients:@[recipient]];
    
    [[mailViewController navigationBar] setTintColor:[UIColor blackColor]];
    [self.navigationController presentViewController:mailViewController animated:YES completion:^{
        
    }];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
		  didFinishWithResult:(MFMailComposeResult)result
						error:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:^{
        [self onBack:nil];
    }];
}

@end
