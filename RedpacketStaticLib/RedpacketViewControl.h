//
//  RedpacketViewControl.h
//  ChatDemo-UI3.0
//
//  Created by Mr.Yang on 16/3/8.
//  Copyright © 2016年 Mr.Yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "RedpacketMessageModel.h"

typedef NS_ENUM(NSInteger,RPSendRedPacketViewControllerType){
    RPSendRedPacketViewControllerSingle, //点对点红包
    RPSendRedPacketViewControllerGroup,  //普通群红包
    RPSendRedPacketViewControllerMember, //包含专属红包的群红包
    RPSendRedPacketViewControllerRand,   //小额度随机红包
};

@protocol RedpacketViewControlDelegate <NSObject>

@optional
- (NSArray<RedpacketUserInfo *> *)groupMemberList __deprecated_msg("请用getGroupMemberListCompletionHandle：方法替换");
- (void)getGroupMemberListCompletionHandle:(void (^)(NSArray<RedpacketUserInfo *> * groupMemberList))completionHandle;

@end

//  抢红包成功回调
typedef void(^RedpacketGrabBlock)(RedpacketMessageModel *messageModel);

//  环信接口发送红包消息回调
typedef void(^RedpacketSendBlock)(RedpacketMessageModel *model);

/**
 *  发红包的控制器
 */
@interface RedpacketViewControl : NSObject

/**
 *  当前窗口的会话信息，个人或者群组
 */
@property (nonatomic, strong) RedpacketUserInfo *converstationInfo;

/**
 *  当前的聊天窗口
 */
@property (nonatomic, weak) UIViewController *conversationController;

/**
 *  定向红包获取群成员的代理
 */
@property (nonatomic, weak) id <RedpacketViewControlDelegate> delegate;

/**
 *  零钱接口返回零钱
 */
+ (void)getChangeMoney:(void (^)(NSString *amount))amount;

/**
 *  用户抢红包触发事件
 *
 *  @param messageModel 消息Model
 */
- (void)redpacketCellTouchedWithMessageModel:(RedpacketMessageModel *)messageModel;

/**
 *  设置发送红包，抢红包成功回调
 *
 *  @param grabTouch 抢红包回调
 *  @param sendBlock 发红包回调
 */
- (void)setRedpacketGrabBlock:(RedpacketGrabBlock)grabTouch andRedpacketBlock:(RedpacketSendBlock)sendBlock;

@end


@interface RedpacketViewControl (RedpacketControllers)
/**
 *  弹出红包控制器
 *
 *  @param rpType 红包页面类型
 *  @param count  群红包群人数，如果是单聊，请传入0
 */
- (void)presentRedPacketViewControllerWithType:(RPSendRedPacketViewControllerType)rpType memberCount:(NSInteger)count;

/**
 *  转账控制器
 *  @param userInfo 接收人的用户信息
 */
- (void)presentTransferViewControllerWithReceiver:(RedpacketUserInfo *)userInfo;

/**
 *  转账详情控制器
 */
- (void)presentTransferDetailViewController:(RedpacketMessageModel *)model;

/**
 *  生成红包Controller
 *
 *  @param rpType 红包页面类型
 *  @param count  群红包群人数
 */
- (UIViewController *)redPacketViewControllerWithType:(RPSendRedPacketViewControllerType)rpType memberCount:(NSInteger)count;

/**
 *  显示零钱页面
 */
- (void)presentChangeMoneyViewController;

/**
 *  零钱页面
 *
 *  @return 零钱页面，App可以放在需要的位置
 */
+ (UIViewController *)changeMoneyController;

/**
 *  零钱明细页面
 *
 *  @return 零钱明细页面，App可以放在需要的位置
 */
+ (UIViewController *)changeMoneyListController;


@end

@interface RedpacketViewControl (Deprecated_Nonfunctional)

/*
 *  以下方法不再使用，请替换
 */
- (UIViewController *)redpacketViewController __deprecated_msg("请用presentRedPacketViewControllerWithType: memberCount:替换");
- (UIViewController *)redPacketMoreViewControllerWithGroupMembers:(NSArray *)groupMemberArray __deprecated_msg("请用presentRedPacketViewControllerWithType: memberCount:替换");
- (void)presentRedPacketMoreViewControllerWithGroupMembers:(NSArray *)groupMemberArray __deprecated_msg("请用presentRedPacketViewControllerWithType: memberCount:替换");
- (void)presentRedPacketViewController __deprecated_msg("请用presentRedPacketViewControllerWithType: memberCount:替换");

@end
