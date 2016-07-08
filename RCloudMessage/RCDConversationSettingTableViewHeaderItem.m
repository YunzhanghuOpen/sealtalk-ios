//
//  RCDConversationSettingTableViewHeaderItem.m
//  RCloudMessage
//
//  Created by 杜立召 on 15/7/21.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCDConversationSettingTableViewHeaderItem.h"
#import "DefaultPortraitView.h"
#import "RCDUtilities.h"
#import "UIImageView+WebCache.h"
#import "UIColor+RCColor.h"

@implementation RCDConversationSettingTableViewHeaderItem

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    UIView *myView = [[UIView alloc] initWithFrame:CGRectZero];

    _ivAva = [[UIImageView alloc] initWithFrame:CGRectZero];
    _ivAva.clipsToBounds = YES;
    _ivAva.layer.cornerRadius = 5.f;
    //_ivAva.placeholderImage = IMAGE_BY_NAMED(@"default_portrait_msg");
    [_ivAva setBackgroundColor:[UIColor clearColor]];
    [myView addSubview:_ivAva];

    _titleLabel = [UILabel new];
    [_titleLabel setTextColor:[UIColor colorWithHexString:@"0x999999" alpha:1.0]];
    [_titleLabel setFont:[UIFont systemFontOfSize:14]];
    [_titleLabel setTextAlignment:NSTextAlignmentCenter];
    [myView addSubview:_titleLabel];

    _btnImg = [[UIButton alloc] initWithFrame:CGRectZero];
    [_btnImg setHidden:YES];
    [_btnImg setImage:[RCDUtilities imageNamed:@"delete_member_tip"
                                      ofBundle:@"RongCloud.bundle"]
             forState:UIControlStateNormal];
    [_btnImg addTarget:self
                  action:@selector(deleteItem:)
        forControlEvents:UIControlEventTouchUpInside];
    [myView addSubview:_btnImg];

    [self.contentView addSubview:myView];

    // add contraints
    [myView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_ivAva setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_btnImg setTranslatesAutoresizingMaskIntoConstraints:NO];

    UIView *tempContentView = self.contentView;

    [self.contentView
        addConstraints:
            [NSLayoutConstraint
                constraintsWithVisualFormat:@"H:|[myView]|"
                                    options:kNilOptions
                                    metrics:nil
                                      views:NSDictionaryOfVariableBindings(
                                                myView, tempContentView)]];
    [self.contentView
        addConstraints:
            [NSLayoutConstraint
                constraintsWithVisualFormat:@"V:|[myView]|"
                                    options:kNilOptions
                                    metrics:nil
                                      views:NSDictionaryOfVariableBindings(
                                                myView, tempContentView)]];

    [self.contentView
        addConstraints:
            [NSLayoutConstraint
                constraintsWithVisualFormat:@"H:|[_ivAva]|"
                                    options:kNilOptions
                                    metrics:nil
                                      views:NSDictionaryOfVariableBindings(
                                                _ivAva)]];

    [self.contentView
        addConstraints:
            [NSLayoutConstraint
                constraintsWithVisualFormat:@"H:|[_titleLabel]|"
                                    options:kNilOptions
                                    metrics:nil
                                      views:NSDictionaryOfVariableBindings(
                                                _titleLabel, myView)]];
    [self.contentView
        addConstraints:
            [NSLayoutConstraint
                constraintsWithVisualFormat:
                    @"V:|[_ivAva(55)]-10-[_titleLabel(==15)]"
                                    options:kNilOptions
                                    metrics:nil
                                      views:NSDictionaryOfVariableBindings(
                                                _titleLabel, _ivAva)]];

    [self.contentView
        addConstraints:
            [NSLayoutConstraint
                constraintsWithVisualFormat:@"H:|[_btnImg(25)]"
                                    options:kNilOptions
                                    metrics:nil
                                      views:NSDictionaryOfVariableBindings(
                                                _btnImg)]];
    [self.contentView
        addConstraints:
            [NSLayoutConstraint
                constraintsWithVisualFormat:@"V:|[_btnImg(25)]"
                                    options:kNilOptions
                                    metrics:nil
                                      views:NSDictionaryOfVariableBindings(
                                                _btnImg)]];
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_titleLabel
                                                                attribute:NSLayoutAttributeCenterX
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_ivAva
                                                                attribute:NSLayoutAttributeCenterX
                                                               multiplier:1.0f
                                                                 constant:0
                                     ]];
    
  }
  return self;
}

- (void)deleteItem:(id)sender {
  if (self.delegate &&
      [self.delegate respondsToSelector:@selector(deleteTipButtonClicked:)]) {
    [self.delegate deleteTipButtonClicked:self];
  }
}

- (void)setUserModel:(RCUserInfo *)userModel {
  self.ivAva.image = nil;
  self.userId = userModel.userId;
  self.titleLabel.text = userModel.name;
  if ([userModel.portraitUri isEqualToString:@""]) {
    DefaultPortraitView *defaultPortrait =
        [[DefaultPortraitView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    [defaultPortrait setColorAndLabel:userModel.userId Nickname:userModel.name];
    UIImage *portrait = [defaultPortrait imageFromView];
    self.ivAva.image = portrait;
  } else {
    [self.ivAva sd_setImageWithURL:nil
                  placeholderImage:[UIImage imageNamed:@"icon_person"]];
    [self.ivAva sd_setImageWithURL:[NSURL URLWithString:userModel.portraitUri]
                  placeholderImage:[UIImage imageNamed:@"icon_person"]];
  }
}

@end
