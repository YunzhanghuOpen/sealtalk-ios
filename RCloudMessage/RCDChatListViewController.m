//
//  FirstViewController.m
//  RongCloud
//
//  Created by Liv on 14/10/31.
//  Copyright (c) 2014年 RongCloud. All rights reserved.
//

#import "RCDChatListViewController.h"
#import "KxMenu.h"
#import "RCDAddressBookViewController.h"
#import "RCDSearchFriendViewController.h"
#import "RCDSelectPersonViewController.h"
#import "RCDRCIMDataSource.h"
#import "RedpacketDemoViewController.h"
#import "UIColor+RCColor.h"
#import "RCDChatListCell.h"
#import "RCDAddFriendTableViewController.h"
#import "RCDHttpTool.h"
#import "UIImageView+WebCache.h"
#import <RongIMKit/RongIMKit.h>
#import "RCDUserInfo.h"
#import "RCDFriendInvitationTableViewController.h"
#import "RCDPublicServiceListViewController.h"
#import "RCDAddFriendViewController.h"
#import "RCDContactSelectedTableViewController.h"
#import "AFHttpTool.h"

@interface RCDChatListViewController ()

//@property (nonatomic,strong) NSMutableArray *myDataSource;
@property (nonatomic,strong) RCConversationModel *tempModel;

@property (nonatomic,assign) BOOL isClick;
- (void) updateBadgeValueForTabBarItem;

@end

@implementation RCDChatListViewController

/**
 *  此处使用storyboard初始化，代码初始化当前类时*****必须要设置会话类型和聚合类型*****
 *
 *  @param aDecoder aDecoder description
 *
 *  @return return value description
 */
-(id)initWithCoder:(NSCoder *)aDecoder
{
    self =[super initWithCoder:aDecoder];
    if (self) {
        //设置要显示的会话类型
        [self setDisplayConversationTypes:@[@(ConversationType_PRIVATE),@(ConversationType_DISCUSSION), @(ConversationType_APPSERVICE), @(ConversationType_PUBLICSERVICE),@(ConversationType_GROUP),@(ConversationType_SYSTEM)]];
        
        //聚合会话类型
        [self setCollectionConversationType:@[@(ConversationType_SYSTEM)]];
        

        //设置为不用默认渲染方式
        self.tabBarItem.image = [[UIImage imageNamed:@"icon_chat"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        self.tabBarItem.selectedImage = [[UIImage imageNamed:@"icon_chat_hover"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        
       // _myDataSource = [NSMutableArray new];
        
       // [self setConversationAvatarStyle:RCUserAvatarCycle];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.edgesForExtendedLayout = UIRectEdgeNone;

    //设置tableView样式
    self.conversationListTableView.separatorColor = [UIColor colorWithHexString:@"dfdfdf" alpha:1.0f];
    self.conversationListTableView.tableFooterView = [UIView new];
//    self.conversationListTableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 12)];
    
    //自定义空会话的背景View。当会话列表为空时，将显示该View
    //UIView *blankView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    //blankView.backgroundColor=[UIColor redColor];
    //self.emptyConversationView=blankView;
    // 设置在NavigatorBar中显示连接中的提示
    self.showConnectingStatusOnNavigatorBar = YES;
    
    //修改tabbar的背景色
    UIView *tabBarBG = [UIView new];
    tabBarBG.backgroundColor = HEXCOLOR(0xf9f9f9);
    tabBarBG.frame = self.tabBarController.tabBar.bounds;
    [[UITabBar appearance] insertSubview:tabBarBG atIndex:0];
    
    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:HEXCOLOR(0x999999), UITextAttributeTextColor, nil] forState:UIControlStateNormal];
    
    [[UITabBarItem appearance] setTitleTextAttributes:                                                         [NSDictionary dictionaryWithObjectsAndKeys:HEXCOLOR(0x0099ff),UITextAttributeTextColor, nil]forState:UIControlStateSelected];

}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _isClick = YES;
//    if (!self.isEnteredToCollectionViewController) {
//        UILabel *titleView = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
//        titleView.backgroundColor = [UIColor redColor];
//        titleView.font = [UIFont boldSystemFontOfSize:19];
//        titleView.textColor = [UIColor whiteColor];
//        titleView.textAlignment = NSTextAlignmentCenter;
//        titleView.text = @"会话";
//        self.tabBarController.navigationItem.titleView = titleView;
//    }
    //自定义rightBarButtonItem
    UIButton *rightBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 17, 17)];
    [rightBtn setImage:[UIImage imageNamed:@"add"] forState:UIControlStateNormal];
    [rightBtn addTarget:self action:@selector(showMenu:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithCustomView:rightBtn];
    [rightBtn setTintColor:[UIColor whiteColor]];
    self.tabBarController.navigationItem.rightBarButtonItem = rightButton;
    self.tabBarController.navigationItem.title = @"会话";
    
//    UIImageView *titleView = [[UIImageView alloc] initWithFrame: CGRectMake(160, 0, 71, 15)];
//    titleView.image = [UIImage imageNamed:@"sealtalk"];
//    self.tabBarController.navigationItem.titleView=titleView;

    
    [self notifyUpdateUnreadMessageCount];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(receiveNeedRefreshNotification:)
                                                name:@"kRCNeedReloadDiscussionListNotification"
                                              object:nil];
    RCUserInfo *groupNotify = [[RCUserInfo alloc] initWithUserId:@"__system__"
                                                            name:@"群组通知"
                                                        portrait:nil];
    [[RCIM sharedRCIM] refreshUserInfoCache:groupNotify withUserId:@"__system__"];
    
    //由于当天的消息会被补偿回来，导致如果重装了应用，当天退出的群组会出现在会话列表。判断群组通知消息的操作如果是退出群组，就直接从会话列表中删除。
    NSArray *conversationListArray = [[RCIMClient sharedRCIMClient] getConversationList:@[@(ConversationType_PRIVATE),@(ConversationType_DISCUSSION), @(ConversationType_APPSERVICE), @(ConversationType_PUBLICSERVICE),@(ConversationType_GROUP),@(ConversationType_SYSTEM)]];
    for (RCConversation *conversation in conversationListArray){
        if ([conversation.lastestMessage isKindOfClass:[RCGroupNotificationMessage class]])
        {
            RCGroupNotificationMessage *groupNotification = (RCGroupNotificationMessage*)conversation.lastestMessage;
            if ([groupNotification.operation isEqualToString:@"Quit"]) {
                NSData *jsonData = [groupNotification.data dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
                NSDictionary *data = [dictionary[@"data"] isKindOfClass:[NSDictionary class]]? dictionary[@"data"]: nil;
                NSString *nickName = [data[@"operatorNickname"] isKindOfClass:[NSString class]]? data[@"operatorNickname"]: nil;
                if ([nickName isEqualToString:[RCIM sharedRCIM].currentUserInfo.name]) {
                    [[RCIMClient sharedRCIMClient] removeConversation:conversation.conversationType targetId:conversation.targetId];
                    [self refreshConversationTableViewIfNeeded];
                }
                
            }
        }
    }
}


//由于demo使用了tabbarcontroller，当切换到其它tab时，不能更改tabbarcontroller的标题。
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"kRCNeedReloadDiscussionListNotification"
                                                  object:nil];
}

- (void)updateBadgeValueForTabBarItem
{
    __weak typeof(self) __weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        int count = [[RCIMClient sharedRCIMClient]getUnreadCount:self.displayConversationTypeArray];
        if (count>0) {
            __weakSelf.tabBarItem.badgeValue = [[NSString alloc]initWithFormat:@"%d",count];
        }else
        {
            __weakSelf.tabBarItem.badgeValue = nil;
        }
        
    });
}

/**
 *  点击进入会话界面
 *
 *  @param conversationModelType 会话类型
 *  @param model                 会话数据
 *  @param indexPath             indexPath description
 */
-(void)onSelectedTableRow:(RCConversationModelType)conversationModelType conversationModel:(RCConversationModel *)model atIndexPath:(NSIndexPath *)indexPath
{
    
    if (_isClick) {
        _isClick = NO;
        if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_PUBLIC_SERVICE) {
            RedpacketDemoViewController *_conversationVC = [[RedpacketDemoViewController alloc] init];
            _conversationVC.conversationType = model.conversationType;
            _conversationVC.targetId = model.targetId;
            _conversationVC.userName = model.conversationTitle;
            _conversationVC.title = model.conversationTitle;
            _conversationVC.conversation = model;
            _conversationVC.unReadMessage = model.unreadMessageCount;
            [self.navigationController pushViewController:_conversationVC animated:YES];
        }
        
        if (conversationModelType == RC_CONVERSATION_MODEL_TYPE_NORMAL) {
            RedpacketDemoViewController *_conversationVC = [[RedpacketDemoViewController alloc]init];
            _conversationVC.conversationType = model.conversationType;
            _conversationVC.targetId = model.targetId;
            _conversationVC.userName = model.conversationTitle;
            _conversationVC.title = model.conversationTitle;
            _conversationVC.conversation = model;
            _conversationVC.unReadMessage = model.unreadMessageCount;
            _conversationVC.enableNewComingMessageIcon=YES;//开启消息提醒
            _conversationVC.enableUnreadMessageIcon=YES;
            if (model.conversationType == ConversationType_SYSTEM) {
                _conversationVC.userName = @"系统消息";
                _conversationVC.title = @"系统消息";
            }
            if ([model.objectName isEqualToString:@"RC:ContactNtf"]) {
                UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                RCDAddressBookViewController *addressBookVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"RCDAddressBookViewController"];
                addressBookVC.needSyncFriendList = YES;
                [self.navigationController pushViewController:addressBookVC animated:YES];
                return;
            }
            //如果是单聊，不显示发送方昵称
            if (model.conversationType == ConversationType_PRIVATE) {
                _conversationVC.displayUserNameInCell = NO;
            }
            [self.navigationController pushViewController:_conversationVC animated:YES];
            
        }
        
        //聚合会话类型，此处自定设置。
        if (conversationModelType == RC_CONVERSATION_MODEL_TYPE_COLLECTION) {
            
            RCDChatListViewController *temp = [[RCDChatListViewController alloc] init];
            NSArray *array = [NSArray arrayWithObject:[NSNumber numberWithInt:model.conversationType]];
            [temp setDisplayConversationTypes:array];
            [temp setCollectionConversationType:nil];
            temp.isEnteredToCollectionViewController = YES;
            [self.navigationController pushViewController:temp animated:YES];
        }
        
        //自定义会话类型
        if (conversationModelType == RC_CONVERSATION_MODEL_TYPE_CUSTOMIZATION) {
            RCConversationModel *model = self.conversationListDataSource[indexPath.row];
            
            if ([model.objectName isEqualToString:@"RC:ContactNtf"]) {
                UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                RCDAddressBookViewController *addressBookVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"RCDAddressBookViewController"];
                [self.navigationController pushViewController:addressBookVC animated:YES];

            }
            
//            UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//            RCDFriendInvitationTableViewController *temp = [mainStoryboard instantiateViewControllerWithIdentifier:@"RCDFriendInvitationTableViewController"];
//            temp.conversationType = model.conversationType;
//            temp.targetId = model.targetId;
//            temp.userName = model.conversationTitle;
//            temp.title = model.conversationTitle;
//            temp.conversation = model;
//            [self.navigationController pushViewController:temp animated:YES];
        }

    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self refreshConversationTableViewIfNeeded];
    });
}

/**
 *  弹出层
 *
 *  @param sender sender description
 */
- (IBAction)showMenu:(UIButton *)sender {
    NSArray *menuItems =
    @[
      
      [KxMenuItem menuItem:@"发起聊天"
                     image:[UIImage imageNamed:@"startchat_icon"]
                    target:self
                    action:@selector(pushChat:)],
      
      [KxMenuItem menuItem:@"创建群组"
                     image:[UIImage imageNamed:@"creategroup_icon"]
                    target:self
                    action:@selector(pushContactSelected:)],
      
      [KxMenuItem menuItem:@"添加好友"
                     image:[UIImage imageNamed:@"addfriend_icon"]
                    target:self
                    action:@selector(pushAddFriend:)],
      
//      [KxMenuItem menuItem:@"新朋友"
//                     image:[UIImage imageNamed:@"contact_icon"]
//                    target:self
//                    action:@selector(pushAddressBook:)],
//      
//      [KxMenuItem menuItem:@"公众账号"
//                     image:[UIImage imageNamed:@"public_account"]
//                    target:self
//                    action:@selector(pushPublicService:)],
//      
//      [KxMenuItem menuItem:@"添加公众号"
//                     image:[UIImage imageNamed:@"add_public_account"]
//                    target:self
//                    action:@selector(pushAddPublicService:)],
      ];
    
    CGRect targetFrame = self.tabBarController.navigationItem.rightBarButtonItem.customView.frame;
    targetFrame.origin.y = targetFrame.origin.y + 15;
    [KxMenu setTintColor:HEXCOLOR(0x000000)];
    [KxMenu setTitleFont:[UIFont systemFontOfSize:17]];
    [KxMenu showMenuInView:self.tabBarController.navigationController.navigationBar.superview
                  fromRect:targetFrame
                 menuItems:menuItems];
}


/**
 *  发起聊天
 *
 *  @param sender sender description
 */
- (void) pushChat:(id)sender
{
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    RCDContactSelectedTableViewController *contactSelectedVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"RCDContactSelectedTableViewController"];
//    contactSelectedVC.forCreatingDiscussionGroup = YES;
    contactSelectedVC.isAllowsMultipleSelection = NO;
    contactSelectedVC.titleStr = @"发起聊天";
    [self.navigationController pushViewController:contactSelectedVC animated:YES];
    
//    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//    RCDSelectPersonViewController *selectPersonVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"RCDSelectPersonViewController"];
//    
//    //设置点击确定之后回传被选择联系人操作
//    __weak typeof(&*self)  weakSelf = self;
//    selectPersonVC.clickDoneCompletion = ^(RCDSelectPersonViewController *selectPersonViewController,NSArray *selectedUsers)
//    {
//        if(selectedUsers.count == 1)
//        {
//            RCUserInfo *user = selectedUsers[0];
//            RCDChatViewController *chat =[[RCDChatViewController alloc]init];
//            chat.targetId                      = user.userId;
//            chat.userName                    = user.name;
//            chat.conversationType              = ConversationType_PRIVATE;
//            chat.title                         = user.name;
//            
//            //跳转到会话页面
//            dispatch_async(dispatch_get_main_queue(), ^{
//                UITabBarController *tabbarVC = weakSelf.navigationController.viewControllers[0];
//                [weakSelf.navigationController popToViewController:tabbarVC animated:NO];
//                [tabbarVC.navigationController  pushViewController:chat animated:YES];
//            });
//
//        }
//        //选择多人则创建讨论组
//        else if(selectedUsers.count > 1)
//        {
//            
//            NSMutableString *discussionTitle = [NSMutableString string];
//            NSMutableArray *userIdList = [NSMutableArray new];
//            for (RCUserInfo *user in selectedUsers) {
//                [discussionTitle appendString:[NSString stringWithFormat:@"%@%@", user.name,@","]];
//                [userIdList addObject:user.userId];
//            }
//            [discussionTitle deleteCharactersInRange:NSMakeRange(discussionTitle.length - 1, 1)];
//
//            [[RCIMClient sharedRCIMClient] createDiscussion:discussionTitle userIdList:userIdList success:^(RCDiscussion *discussion) {
//                NSLog(@"create discussion ssucceed!");
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    RCDChatViewController *chat =[[RCDChatViewController alloc]init];
//                    chat.targetId                      = discussion.discussionId;
//                    chat.userName                    = discussion.discussionName;
//                    chat.conversationType              = ConversationType_DISCUSSION;
//                    chat.title                         = @"讨论组";
//                    
//                    
//                    UITabBarController *tabbarVC = weakSelf.navigationController.viewControllers[0];
//                    [weakSelf.navigationController popViewControllerAnimated:NO];
//                    [tabbarVC.navigationController  pushViewController:chat animated:YES];
//                });
//            } error:^(RCErrorCode status) {
//                NSLog(@"create discussion Failed > %ld!", (long)status);
//            }];
//            return;
//        }
//    };
//
//    [self.navigationController pushViewController :selectPersonVC animated:YES];
}

/**
 *  创建群组
 *
 *  @param sender sender description
 */
- (void) pushContactSelected:(id) sender
{
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    RCDContactSelectedTableViewController *contactSelectedVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"RCDContactSelectedTableViewController"];
    contactSelectedVC.forCreatingGroup = YES;
    contactSelectedVC.isAllowsMultipleSelection = YES;
    contactSelectedVC.titleStr = @"选择联系人";
    [self.navigationController pushViewController:contactSelectedVC animated:YES];
    
}

/**
 *  公众号会话
 *
 *  @param sender sender description
 */
- (void) pushPublicService:(id) sender
{
        RCDPublicServiceListViewController *publicServiceVC = [[RCDPublicServiceListViewController alloc] init];
        [self.navigationController pushViewController:publicServiceVC  animated:YES];
    
}


/**
 *  添加好友
 *
 *  @param sender sender description
 */
- (void) pushAddFriend:(id) sender
{
    RCDSearchFriendViewController *searchFirendVC = [RCDSearchFriendViewController searchFriendViewController];
    [self.navigationController pushViewController:searchFirendVC  animated:YES];
}

/**
 *  通讯录
 *
 *  @param sender sender description
 */
-(void) pushAddressBook:(id) sender
{
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    RCDAddressBookViewController *addressBookVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"RCDAddressBookViewController"];
    [self.navigationController pushViewController:addressBookVC animated:YES];

}

/**
 *  添加公众号
 *
 *  @param sender sender description
 */
- (void) pushAddPublicService:(id) sender
{
    RCPublicServiceSearchViewController *searchFirendVC = [[RCPublicServiceSearchViewController alloc] init];
    [self.navigationController pushViewController:searchFirendVC  animated:YES];
    
}


//*********************插入自定义Cell*********************//

//插入自定义会话model
-(NSMutableArray *)willReloadTableData:(NSMutableArray *)dataSource
{

    for (int i=0; i<dataSource.count; i++) {
        RCConversationModel *model = dataSource[i];
        //筛选请求添加好友的系统消息，用于生成自定义会话类型的cell
        if(model.conversationType == ConversationType_SYSTEM && [model.lastestMessage isMemberOfClass:[RCContactNotificationMessage class]])
        {
            model.conversationModelType = RC_CONVERSATION_MODEL_TYPE_CUSTOMIZATION;
        }
        if ([model.lastestMessage isKindOfClass:[RCGroupNotificationMessage class]])
        {
            RCGroupNotificationMessage *groupNotification = (RCGroupNotificationMessage*)model.lastestMessage;
            if ([groupNotification.operation isEqualToString:@"Quit"]) {
                NSData *jsonData = [groupNotification.data dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
                NSDictionary *data = [dictionary[@"data"] isKindOfClass:[NSDictionary class]]? dictionary[@"data"]: nil;
                NSString *nickName = [data[@"operatorNickname"] isKindOfClass:[NSString class]]? data[@"operatorNickname"]: nil;
                if ([nickName isEqualToString:[RCIM sharedRCIM].currentUserInfo.name]) {
                    [[RCIMClient sharedRCIMClient] removeConversation:model.conversationType targetId:model.targetId];
                    [self refreshConversationTableViewIfNeeded];
                }
                
            }
        }
    }

    return dataSource;
}

//左滑删除
-(void)rcConversationListTableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //可以从数据库删除数据
    RCConversationModel *model = self.conversationListDataSource[indexPath.row];
    [[RCIMClient sharedRCIMClient] removeConversation:ConversationType_SYSTEM targetId:model.targetId];
    [self.conversationListDataSource removeObjectAtIndex:indexPath.row];
    [self.conversationListTableView reloadData];
}

//高度
-(CGFloat)rcConversationListTableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 67.0f;
}

//自定义cell
-(RCConversationBaseCell *)rcConversationListTableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RCConversationModel *model = self.conversationListDataSource[indexPath.row];
    
    __block NSString *userName    = nil;
    __block NSString *portraitUri = nil;
    
    __weak RCDChatListViewController *weakSelf = self;
    //此处需要添加根据userid来获取用户信息的逻辑，extend字段不存在于DB中，当数据来自db时没有extend字段内容，只有userid
    if (nil == model.extend) {
        // Not finished yet, To Be Continue...
        if(model.conversationType == ConversationType_SYSTEM && [model.lastestMessage isMemberOfClass:[RCContactNotificationMessage class]])
        {
            RCContactNotificationMessage *_contactNotificationMsg = (RCContactNotificationMessage *)model.lastestMessage;
            if (_contactNotificationMsg.sourceUserId == nil) {
                RCDChatListCell *cell = [[RCDChatListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
                cell.lblDetail.text = @"好友请求";
                [cell.ivAva sd_setImageWithURL:[NSURL URLWithString:portraitUri] placeholderImage:[UIImage imageNamed:@"system_notice"]];
                return cell;
                
            }
            NSDictionary *_cache_userinfo = [[NSUserDefaults standardUserDefaults]objectForKey:_contactNotificationMsg.sourceUserId];
            if (_cache_userinfo) {
                userName = _cache_userinfo[@"username"];
                portraitUri = _cache_userinfo[@"portraitUri"];
            } else {
                NSDictionary *emptyDic = @{};
                [[NSUserDefaults standardUserDefaults]setObject:emptyDic forKey:_contactNotificationMsg.sourceUserId];
                [[NSUserDefaults standardUserDefaults]synchronize];
                [RCDHTTPTOOL getUserInfoByUserID:_contactNotificationMsg.sourceUserId
                                      completion:^(RCUserInfo *user) {
                                          if (user == nil) {
                                              return;
                                          }
                                          RCDUserInfo *rcduserinfo_ = [RCDUserInfo new];
                                          rcduserinfo_.name = user.name;
                                          rcduserinfo_.userId = user.userId;
                                          rcduserinfo_.portraitUri = user.portraitUri;
                                          
                                          model.extend = rcduserinfo_;
                                          
                                          //local cache for userInfo
                                          NSDictionary *userinfoDic = @{@"username": rcduserinfo_.name,
                                                                        @"portraitUri":rcduserinfo_.portraitUri
                                                                        };
                                          [[NSUserDefaults standardUserDefaults]setObject:userinfoDic forKey:_contactNotificationMsg.sourceUserId];
                                          [[NSUserDefaults standardUserDefaults]synchronize];
                                          
                                          [weakSelf.conversationListTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                                      }];
            }
        }
        
    }else{
        RCDUserInfo *user = (RCDUserInfo *)model.extend;
        userName    = user.name;
        portraitUri = user.portraitUri;
    }
    
    RCDChatListCell *cell = [[RCDChatListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
    cell.lblDetail.text =[NSString stringWithFormat:@"来自%@的好友请求",userName];
    [cell.ivAva sd_setImageWithURL:[NSURL URLWithString:portraitUri] placeholderImage:[UIImage imageNamed:@"system_notice"]];
    cell.labelTime.text = [self ConvertMessageTime:model.sentTime / 1000];
    cell.model = model;
    return cell;
}

#pragma mark - private
- (NSString *)ConvertMessageTime:(long long)secs {
    NSString *timeText = nil;
    
    NSDate *messageDate = [NSDate dateWithTimeIntervalSince1970:secs];
    
    //    DebugLog(@"messageDate==>%@",messageDate);
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    
    NSString *strMsgDay = [formatter stringFromDate:messageDate];
    
    NSDate *now = [NSDate date];
    NSString *strToday = [formatter stringFromDate:now];
    NSDate *yesterday = [[NSDate alloc] initWithTimeIntervalSinceNow:-(24 * 60 * 60)];
    NSString *strYesterday = [formatter stringFromDate:yesterday];
    
    NSString *_yesterday = nil;
    if ([strMsgDay isEqualToString:strToday]) {
        [formatter setDateFormat:@"HH':'mm"];
    } else if ([strMsgDay isEqualToString:strYesterday]) {
        _yesterday = NSLocalizedStringFromTable(@"Yesterday", @"RongCloudKit", nil);
        //[formatter setDateFormat:@"HH:mm"];
    }
    
    if (nil != _yesterday) {
        timeText = _yesterday; //[_yesterday stringByAppendingFormat:@" %@", timeText];
    } else {
        timeText = [formatter stringFromDate:messageDate];
    }
    
    return timeText;
}

//*********************插入自定义Cell*********************//


#pragma mark - 收到消息监听
-(void)didReceiveMessageNotification:(NSNotification *)notification
{
    __weak typeof(&*self) blockSelf_ = self;
    //处理好友请求
    RCMessage *message = notification.object;
    if ([message.content isMemberOfClass:[RCContactNotificationMessage class]]) {
        
        if (message.conversationType != ConversationType_SYSTEM) {
            NSLog(@"好友消息要发系统消息！！！");
#if DEBUG
                @throw  [[NSException alloc] initWithName:@"error" reason:@"好友消息要发系统消息！！！" userInfo:nil];
#endif
        }
        RCContactNotificationMessage *_contactNotificationMsg = (RCContactNotificationMessage *)message.content;
        if (_contactNotificationMsg.sourceUserId == nil || _contactNotificationMsg.sourceUserId .length ==0) {
            return;
        }
        //该接口需要替换为从消息体获取好友请求的用户信息
        [RCDHTTPTOOL getUserInfoByUserID:_contactNotificationMsg.sourceUserId
                              completion:^(RCUserInfo *user) {
                                  RCDUserInfo *rcduserinfo_ = [RCDUserInfo new];
                                  rcduserinfo_.name = user.name;
                                  rcduserinfo_.userId = user.userId;
                                  rcduserinfo_.portraitUri = user.portraitUri;
                                  
            RCConversationModel *customModel = [RCConversationModel new];
            customModel.conversationModelType = RC_CONVERSATION_MODEL_TYPE_CUSTOMIZATION;
            customModel.extend = rcduserinfo_;
            customModel.senderUserId = message.senderUserId;
            customModel.lastestMessage = _contactNotificationMsg;
            //[_myDataSource insertObject:customModel atIndex:0];
                                  
                                  //local cache for userInfo
                                  NSDictionary *userinfoDic = @{@"username": rcduserinfo_.name,
                                                                @"portraitUri":rcduserinfo_.portraitUri
                                                                };
                                  [[NSUserDefaults standardUserDefaults]setObject:userinfoDic forKey:_contactNotificationMsg.sourceUserId];
                                  [[NSUserDefaults standardUserDefaults]synchronize];
                                  
          dispatch_async(dispatch_get_main_queue(), ^{
              //调用父类刷新未读消息数
              [blockSelf_ refreshConversationTableViewWithConversationModel:customModel];
              //[super didReceiveMessageNotification:notification];
//              [blockSelf_ resetConversationListBackgroundViewIfNeeded];
              [self notifyUpdateUnreadMessageCount];
              
              //当消息为RCContactNotificationMessage时，没有调用super，如果是最后一条消息，可能需要刷新一下整个列表。
              //原因请查看super didReceiveMessageNotification的注释。
              NSNumber *left = [notification.userInfo objectForKey:@"left"];
              if (0 == left.integerValue) {
                  [super refreshConversationTableViewIfNeeded];
              }
          });
        }];
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            //调用父类刷新未读消息数
            [super didReceiveMessageNotification:notification];
//            [blockSelf_ resetConversationListBackgroundViewIfNeeded];
//            [self notifyUpdateUnreadMessageCount]; super会调用notifyUpdateUnreadMessageCount
        });
    }
}
-(void)didTapCellPortrait:(RCConversationModel *)model
{
    if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_PUBLIC_SERVICE) {
        RedpacketDemoViewController *_conversationVC = [[RedpacketDemoViewController alloc] init];
        _conversationVC.conversationType = model.conversationType;
        _conversationVC.targetId = model.targetId;
        _conversationVC.userName = model.conversationTitle;
        _conversationVC.title = model.conversationTitle;
        _conversationVC.conversation = model;
        _conversationVC.unReadMessage = model.unreadMessageCount;
        [self.navigationController pushViewController:_conversationVC animated:YES];
    }
    
    if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_NORMAL) {
        RedpacketDemoViewController *_conversationVC = [[RedpacketDemoViewController alloc]init];
        _conversationVC.conversationType = model.conversationType;
        _conversationVC.targetId = model.targetId;
        _conversationVC.userName = model.conversationTitle;
        _conversationVC.title = model.conversationTitle;
        _conversationVC.conversation = model;
        _conversationVC.unReadMessage = model.unreadMessageCount;
        _conversationVC.enableNewComingMessageIcon=YES;//开启消息提醒
        _conversationVC.enableUnreadMessageIcon=YES;
        if (model.conversationType == ConversationType_SYSTEM) {
            _conversationVC.userName = @"系统消息";
            _conversationVC.title = @"系统消息";
        }
        if ([model.objectName isEqualToString:@"RC:ContactNtf"]) {
            UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            RCDAddressBookViewController *addressBookVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"RCDAddressBookViewController"];
            addressBookVC.needSyncFriendList = YES;
            [self.navigationController pushViewController:addressBookVC animated:YES];
            return;
        }
        [self.navigationController pushViewController:_conversationVC animated:YES];
    }
    
    //聚合会话类型，此处自定设置。
    if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_COLLECTION) {
        
        RCDChatListViewController *temp = [[RCDChatListViewController alloc] init];
        NSArray *array = [NSArray arrayWithObject:[NSNumber numberWithInt:model.conversationType]];
        [temp setDisplayConversationTypes:array];
        [temp setCollectionConversationType:nil];
        temp.isEnteredToCollectionViewController = YES;
        [self.navigationController pushViewController:temp animated:YES];
    }
    
    //自定义会话类型
    if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_CUSTOMIZATION) {
//        RCConversationModel *model = self.conversationListDataSource[indexPath.row];
        
        if ([model.objectName isEqualToString:@"RC:ContactNtf"]) {
            UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            RCDAddressBookViewController *addressBookVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"RCDAddressBookViewController"];
            [self.navigationController pushViewController:addressBookVC animated:YES];
            
        }
    }

}
//会话有新消息通知的时候显示数字提醒，设置为NO,不显示数字只显示红点
//-(void)willDisplayConversationTableCell:(RCConversationBaseCell *)cell atIndexPath:(NSIndexPath *)indexPath
//{
//    RCConversationModel *model= self.conversationListDataSource[indexPath.row];
//    
//    if (model.conversationType == ConversationType_PRIVATE) {
//        ((RCConversationCell *)cell).isShowNotificationNumber = NO;
//    }
//}
- (void)notifyUpdateUnreadMessageCount
{
    [self updateBadgeValueForTabBarItem];
}

- (void)receiveNeedRefreshNotification:(NSNotification *)status {
    __weak typeof(&*self) __blockSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (__blockSelf.displayConversationTypeArray.count == 1 && [self.displayConversationTypeArray[0] integerValue]== ConversationType_DISCUSSION) {
            [__blockSelf refreshConversationTableViewIfNeeded];
        }
        
    });
}

@end
