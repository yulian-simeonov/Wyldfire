#define TALL_SCREEN ([UIScreen mainScreen].bounds.size.height == 568)

//Colors
#define GRAY_1 [UIColor colorWithRed:51/255. green:51/255. blue:51/255. alpha:1.0]
#define GRAY_2 [UIColor colorWithRed:111/255. green:111/255. blue:111/255. alpha:1.0]
#define GRAY_3 [UIColor colorWithRed:132/255. green:132/255. blue:132/255. alpha:1.0]
#define GRAY_4 [UIColor colorWithRed:153/255. green:153/255. blue:153/255. alpha:1.0]
#define GRAY_5 [UIColor colorWithRed:178/255. green:178/255. blue:178/255. alpha:1.0]
#define GRAY_6 [UIColor colorWithRed:201/255. green:201/255. blue:201/255. alpha:1.0]
#define GRAY_7 [UIColor colorWithRed:220/255. green:220/255. blue:220/255. alpha:1.0]
#define GRAY_8 [UIColor colorWithRed:244/255. green:244/255. blue:244/255. alpha:1.0]

#define SETTINGS_HEADER_TEXT_COLOR [UIColor colorWithRed:77/255. green:77/255. blue:77/255. alpha:1.0]

#define WYLD_RED [UIColor colorWithRed:245/255. green:98/255. blue:98/255. alpha:1.0]
#define WYLD_BLUE [UIColor colorWithRed:90/255. green:198/255. blue:255/255. alpha:1.0]
#define FB_BLUE [UIColor colorWithRed:79/255. green:108/255. blue:167/255. alpha:1.0]

#define SIDEBAR_SEPARATOR_COLOR [UIColor colorWithRed:23/255. green:24/255. blue:26/255. alpha:1.0]

//Fonts
#define MAIN_FONT @"HelveticaNeue"
#define LIGHT_FONT @"HelveticaNeue-UltraLight"
#define BOLD_FONT @"HelveticaNeue-Medium"
#define CARD_OVERLAY_FONTFACE @"AvenirNext-UltraLight"
#define CARD_OVERLAY_FONTSIZE 60

#define CARD_OVERLAY_FONT [UIFont fontWithName:CARD_OVERLAY_FONTFACE size:CARD_OVERLAY_FONTSIZE]
#define FONT_MAIN(fontSize) [UIFont fontWithName:MAIN_FONT size:fontSize]
#define FONT_BOLD(fontSize) [UIFont fontWithName:BOLD_FONT size:fontSize]

#define GENERIC_FONT_SIZE 21

//Cards
#define CARD_WIDTH 302
#define CARD_HEIGHT ((TALL_SCREEN ? 490 : 402))
#define CARD_ORIGIN_X 9
#define CARD_ORIGIN_Y 72
#define CARD_FRAME CGRectMake(CARD_ORIGIN_X, CARD_ORIGIN_Y, CARD_WIDTH, CARD_HEIGHT)
#define LIKE_BUTTON_HEIGHT 43
#define PROFILE_IMAGE_HEIGHT (382 - (TALL_SCREEN ? 0 : 88) - (statusBarHeight > 20 ? 20 : 0))

//Sidebar
#define SIDEBAR_PROFILE_VIEW_HEIGHT 210
#define SIDEBAR_IMAGE_DIAMETER 100
#define SIDEBAR_IMAGE_ELLIPSE_DIAMETER 106
#define SIDEBAR_IMAGE_Y_OFFSET 45
#define DRAWER_WIDTH 40
#define SIDEBAR_PROFILE_NAME_FONTSIZE 17
#define SIDEBAR_PROFILE_LIKES_FONTSIZE 12
#define SIDEBAR_TABLE_CELL_HEIGHT 52
#define SIDEBAR_ANIMATION_TIME 0.5

//Profile
#define CIRCLE_GRAPH_DIAMETER 144
#define CIRCLE_GRAPH_PAD (CIRCLE_GRAPH_DIAMETER / 3)
#define MATCH_SECTION_HEIGHT (CIRCLE_GRAPH_PAD * 2 + CIRCLE_GRAPH_DIAMETER)
#define PROFILE_GRAPHS_LABEL_FONTSIZE 14
#define PROFILE_VIEWS_GRAPH_TOTALHEIGHT 240
#define PROFILE_VIEWS_GRAPH_PERCENT_FONTSIZE 9
#define PROFILE_VIEWS_BUBBLE_VIEW_SIZE 30
#define PROFILE_VIEWS_ANIMATION_DURATION 1.0f

//Chat
#define CHAT_LIST_IMAGE_FONTSIZE 44
#define CHAT_LIST_IMAGE_TEXT_INSET 16
#define CHAT_LIST_IMAGE_WIDTH 68

//Overall
#define TOOLBAR_HEIGHT 64
#define ACTIONSHEET_SHARE 159
#define ACTIONSHEET_PICK_PHOTO 1337
#define ACTIONSHEET_DECISIONS 42
#define ACTIONSHEET_CONTACTUS 160
#define ACTIONSHEET_PHONE 161

//Trending
#define TRENDING_CELL_PADDING 8

//Photos
#define ALBUM_PREVIEW_SIZE 68.5
#define PHOTO_CELL_SIZE 68
#define PHOTO_EDIT_VERTICAL_PAD 16
#define PHOTO_EDIT_HORIZONTAL_PAD 9

//Behavioral Constants

#define MIN_FACEBOOK_FRIENDS 25
#define ADDITIONAL_PROFILE_PHOTO_COUNT 4
#define DELETE_ON_ENTRY 1234

//Browse
#define INITIAL_SWIPE_VELOCITY_TRIGGER -300
#define IN_PROGRESS_SWIPE_VELOCITY_TRIGGER -300

//Notifications
#define NOTIFICATION_UPDATED_ACCOUNT_PHOTOS     @"kNotificationUpdatedAccountPhotos"
#define NOTIFICATION_UPDATED_STATS              @"kNotificationUpdatedStats"
#define NOTIFICATION_UPDATED_LOCATION           @"kNotificationUpdatedLocation"
#define NOTIFICATION_UPDATED_PENDING_MATCHES    @"kNotificationUpdatedPendingMatches"
#define NOTIFICATION_UPDATED_MESSAGES           @"kNotificationUpdatedMessages"
#define NOTIFICATION_NEW_MESSAGES               @"kNotificationNewMessages"
#define NOTIFICATION_UPDATED_SETTINGS           @"kNotificationUpdatedSettings"
#define NOTIFICATION_ENTERED_FOREGROUND         @"kNotificationEnteredForeground"
#define NOTIFICATION_INTERNET_STATUS_CHANGED    @"kNotificationNoInternet"
#define NOTIFICATION_NEW_MATCHES                @"kNotificationUpdatedNewMatches"
#define NOTIFICATION_NEW_CONTACT                @"kNotificationUpdatedNewContact"
#define NOTIFICATION_RELOGIN_NEEDED             @"kNotificationNeedToRelogin"

//Edit Profile Screen
typedef NS_ENUM(NSInteger, EditProfileOrder) {
    EditProfileOrderPhone = 0,
    EditProfileOrderEmail,
    EditProfileOrderInstagram,
    EditProfileOrderShowcase,
    EditProfileOrderAvatar,
    EditProfileOrderProfile
};
#define EDIT_PROFILE_INFOCELL_HEIGHT 35
#define EDIT_PROFILE_IMAGECELL_HEIGHT 80
#define EDIT_PROFILE_TEXT_INSET 100

//API
#define API_MAX_REQUEST 10485760
#define PRIVACY_POLICY_URL @"http://www.wyldfireapp.com/privacy/"
#define TERMS_OF_SERVICE_URL @"http://www.wyldfireapp.com/terms/"

//Alerts
#define DELETE_ACCOUNT_ALERT            1
#define LOGOUT_ALERT                    2
#define MATCHABLE_ALERT                 3
#define TRENDING_ALERT                  4
#define EDIT_PROFILE_ALERT              5
#define CLICKED_MATCHES_PROFILE_ALERT   6
#define VISIT_PROFILE_ALERT             7
#define SWIPE_LEFT_BROWSE_ALERT         8
#define SWIPE_RIGHT_BROWSE_ALERT        9
#define CHAT_ENTER_ALERT                10
#define CHAT_BURN_ALERT                 11
#define CHAT_REPORT_ALERT               12
#define CHAT_FEMALE_SHARE_ALERT         13
#define CHAT_MALE_SHARE_ALERT           14
#define CHAT_NO_MESSAGES_REMAIN_ALERT   15
#define CHAT_NO_ACTION_ALERT            16
#define FEATHER_INVALID_CODE_ALERT      17
#define MATCH_FIRST_VIEW_ALERT          18
#define FAIL_GET_INVITE_CODE            19

//Notifications
#define NOTIFICATION_ACTION_MATCHES     @"Matches"
#define NOTIFICATION_ACTION_CHAT        @"Chat"
#define NOTIFICATION_ACTION_BLACKBOOK   @"Blackbook"

//Kiip
#define KIIP_REWARD_MOMENT_HINT_SPAM_MALE       @"hintSpammerMale"
#define KIIP_REWARD_MOMENT_HINT_SPAM_FEMALE     @"hintSpammerFemale"
#define KIIP_REWARD_MOMENT_UPDATED_2_PHOTOS     @"updated2Photos"
#define KIIP_REWARD_MOMENT_25_LIKES             @"25likes"
#define KIIP_REWARD_MOMENT_150_LIKES            @"150likes"
#define KIIP_REWARD_MOMENT_25_LIKES_DAY         @"25likesInDay"
#define KIIP_REWARD_MOMENT_TRENDING             @"trending"
#define KIIP_REWARD_MOMENT_SHARED_CONTACT       @"sharedContact"
#define KIIP_REWARD_MOMENT_RECEIVED_CONTACT     @"receivedContact"
#define KIIP_REWARD_MOMENT_RECEIVED_CON_EARLY   @"receivedContactEarly"
#define KIIP_REWARD_MOMENT_UPDATED_3_TIMES      @"updated3TimesInWeek"
#define KIIP_REWARD_MOMENT_LIKE_RATIO98         @"likeRatio98"
#define KIIP_REWARD_MOMENT_3_IN_NOTEBOOK        @"notebookCount3"
#define KIIP_REWARD_MOMENT_10_IN_NOTEBOOK       @"notebookCount10"
#define KIIP_REWARD_MOMENT_5_CHATS_MALE         @"5chatsMale"
#define KIIP_REWARD_MOMENT_10_CHATS_FEMALE      @"10chatsFemale"


#define KIIP_REWARD_MOMENT_PICKY                @"picky"
#define KIIP_REWARD_MOMENT_OVERSHARER           @"oversharer"











