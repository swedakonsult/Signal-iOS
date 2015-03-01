//
//  TSMessagesManager+groupMessageProcessor.m
//  Signal
//
//  Created by Frederic Jacobs on 28/02/15.
//  Copyright (c) 2015 Open Whisper Systems. All rights reserved.
//

#import "TSMessagesManager+groupMessageProcessor.h"


#import "ContactsManager.h"
#import "Environment.h"
#import "TSInfoMessage.h"

@implementation TSMessagesManager (groupMessageProcessor)

- (TSIncomingMessage*)processGroupMessage:(PushMessageContent *)content
                                  message:(IncomingPushMessageSignal *)message
                              transaction:(YapDatabaseReadWriteTransaction *)transaction
                                    array:(NSArray *)attachments
                                   thread:(TSThread *)thread
                          incomingMessage:(TSIncomingMessage *)incomingMessage

{
    if (!content.hasGroup || !content.group.hasId) {
        DDLogError(@"Received group message without an identifier. Ignoring");
        return nil;
    }
    
    uint64_t timeStamp = message.timestamp;
    NSString *body     = content.body;

    PushMessageContentGroupContext *group       = content.group;
    NSData                         *groupId     = group.id;
    TSGroupThread                  *groupThread = [TSGroupThread threadWithGroupId:groupId transaction:transaction];
    TSGroupModel                   *record      = groupThread.groupModel;

    if (record && group.type == PushMessageContentGroupContextTypeUpdate) {
        [self handleGroupUpdate];
    } else if (!record && group.type == PushMessageContentGroupContextTypeUpdate) {
        [self handleGroupCreate];
    } else if (record && group.type == PushMessageContentGroupContextTypeQuit) {
        [self handleGroupLeave];
    } else {
        DDLogError(@"Received unknown group update type, ignoring");
    }
    
    TSGroupModel *model = [[TSGroupModel alloc] initWithTitle:content.group.name
                                                    memberIds:[[[NSSet setWithArray:content.group.members] allObjects] mutableCopy]
                                                        image:nil
                                                      groupId:content.group.id
                                       associatedAttachmentId:nil];
    
    TSGroupThread *gThread = [TSGroupThread getOrCreateThreadWithGroupModel:model
                                                                transaction:transaction];
    [gThread saveWithTransaction:transaction];
    
    if (content.group.type == PushMessageContentGroupContextTypeUpdate) {
        if ([attachments count] == 1) {
            NSString *avatarId = [attachments firstObject];
            TSAttachment *avatar = [TSAttachment fetchObjectWithUniqueID:avatarId];
            if ([avatar isKindOfClass:[TSAttachmentStream class]]) {
                TSAttachmentStream *stream = (TSAttachmentStream *)avatar;
                if ([stream isImage]) {
                    model.associatedAttachmentId = stream.uniqueId;
                    model.groupImage = [stream image];
                }
            }
        }
        
        NSString *updateGroupInfo = [gThread.groupModel getInfoStringAboutUpdateTo:model];
        gThread.groupModel = model;
        [gThread saveWithTransaction:transaction];
        [[[TSInfoMessage alloc] initWithTimestamp:timeStamp
                                         inThread:gThread
                                      messageType:TSInfoMessageTypeGroupUpdate
                                    customMessage:updateGroupInfo] saveWithTransaction:transaction];
    } else if (content.group.type == PushMessageContentGroupContextTypeQuit) {
        NSString *nameString = [[Environment.getCurrent contactsManager] nameStringForPhoneIdentifier:message.source];
        
        if (!nameString) {
            nameString = message.source;
        }
        
        NSString *updateGroupInfo =
        [NSString stringWithFormat:NSLocalizedString(@"GROUP_MEMBER_LEFT", @""), nameString];
        NSMutableArray *newGroupMembers = [NSMutableArray arrayWithArray:gThread.groupModel.groupMemberIds];
        [newGroupMembers removeObject:message.source];
        gThread.groupModel.groupMemberIds = newGroupMembers;
        
        [gThread saveWithTransaction:transaction];
        [[[TSInfoMessage alloc] initWithTimestamp:timeStamp
                                         inThread:gThread
                                      messageType:TSInfoMessageTypeGroupUpdate
                                    customMessage:updateGroupInfo] saveWithTransaction:transaction];
    } else {
        incomingMessage = [[TSIncomingMessage alloc] initWithTimestamp:timeStamp
                                                              inThread:gThread
                                                              authorId:message.source
                                                           messageBody:body
                                                           attachments:attachments];
        [incomingMessage saveWithTransaction:transaction];
    }
    
    thread = gThread;
}

#pragma mark Process Group Messages Actions

- (void)handleGroupCreate:(PushMessageContentGroupContext*)group
              transaction:(YapDatabaseReadWriteTransaction*)transaction {
    NSData *groupId = group.id;
    TSGroupModel *groupModel = 
    
}

- (void)handleGroupUpdate{
    
}

- (void)handleGroupLeave{
    
}



@end
