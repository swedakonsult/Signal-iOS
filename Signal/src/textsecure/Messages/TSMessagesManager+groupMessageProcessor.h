//
//  TSMessagesManager+groupMessageProcessor.h
//  Signal
//
//  Created by Frederic Jacobs on 28/02/15.
//  Copyright (c) 2015 Open Whisper Systems. All rights reserved.
//

#import "TSMessagesManager.h"

@interface TSMessagesManager (groupMessageProcessor)

- (TSIncomingMessage*)processGroupMessage:(PushMessageContent *)content
                    message:(IncomingPushMessageSignal *)message
                transaction:(YapDatabaseReadWriteTransaction *)transaction
                      array:(NSArray *)attachments
                     thread:(TSThread *)thread
            incomingMessage:(TSIncomingMessage *)incomingMessage;

@end
