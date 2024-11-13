#import "CallDetectionManager.h"
@import CallKit;

typedef void (^CallBack)();

@interface CallDetectionManager() <CXCallObserverDelegate>

@property(strong, nonatomic) RCTResponseSenderBlock block;
@property(strong, nonatomic) CXCallObserver* callObserver;

@end

@implementation CallDetectionManager

- (NSArray<NSString *> *)supportedEvents {
    NSLog(@"RNCallDetection: supportedEvents called");
    return @[@"PhoneCallStateUpdate"];
}

+ (BOOL)requiresMainQueueSetup {
    NSLog(@"RNCallDetection: requiresMainQueueSetup called");
    return YES;
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(addCallBlock:(RCTResponseSenderBlock)block) {
    NSLog(@"RNCallDetection: addCallBlock called");
    self.block = block;
    if (!self.callObserver) {
        NSLog(@"RNCallDetection: Initializing callObserver in addCallBlock");
        self.callObserver = [[CXCallObserver alloc] init];
        [self.callObserver setDelegate:self queue:nil];
    }
}

RCT_EXPORT_METHOD(startListener) {
    NSLog(@"RNCallDetection: startListener called");
    if (!self.callObserver) {
        NSLog(@"RNCallDetection: Initializing callObserver in startListener");
        self.callObserver = [[CXCallObserver alloc] init];
        [self.callObserver setDelegate:self queue:nil];
    }
}

RCT_EXPORT_METHOD(stopListener) {
    NSLog(@"RNCallDetection: stopListener called, releasing callObserver and clearing block");
    self.callObserver = nil;
    self.block = nil;
}

- (void)callObserver:(CXCallObserver *)callObserver callChanged:(CXCall *)call {
    if (!self.bridge) {
        NSLog(@"RNCallDetection: callObserver triggered but bridge is nil");
        return;
    }
    
    NSString *state;
    if (call.isOutgoing && !call.hasConnected && !call.hasEnded) {
        state = @"Dialing";
    } else if (call.isOutgoing && call.hasConnected && !call.hasEnded) {
        state = @"Connected";
    } else if (!call.isOutgoing && !call.hasConnected && !call.hasEnded) {
        state = @"Incoming";
    } else if (!call.isOutgoing && call.hasConnected && !call.hasEnded) {
        state = @"Connected";
    } else if (call.isOutgoing && call.hasEnded) {
        state = @"Disconnected";
    } else if (!call.isOutgoing && call.hasEnded) {
        state = @"Disconnected";
    } else if (call.hasConnected && !call.hasEnded && !call.isOnHold) {
        state = @"Connected";
    } else if (call.isOutgoing && call.isOnHold) {
        state = @"onHold";
    } else if (!call.isOutgoing && call.isOnHold) {
        state = @"onHold";
    }
    
    NSLog(@"RNCallDetection: Call state changed to %@", state);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.bridge) {
            NSLog(@"RNCallDetection: Sending event with state %@", state);
            [self sendEventWithName:@"PhoneCallStateUpdate" body:state];
        }
    });
}

@end
