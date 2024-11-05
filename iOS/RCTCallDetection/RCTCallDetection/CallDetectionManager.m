#import "CallDetectionManager.h"
@import CallKit;

typedef void (^CallBack)();
@interface CallDetectionManager()

@property(strong, nonatomic) RCTResponseSenderBlock block;
@property(strong, nonatomic) CXCallObserver* callObserver;

@end
@implementation CallDetectionManager

- (NSArray<NSString *> *)supportedEvents {
    return @[@"PhoneCallStateUpdate"];
}

+ (BOOL)requiresMainQueueSetup {
    return YES;
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(addCallBlock:(RCTResponseSenderBlock) block) {
    self.block = block;
    if (!self.callObserver) {
        self.callObserver = [[CXCallObserver alloc] init];
        [self.callObserver setDelegate:self queue:nil];
    }
}

RCT_EXPORT_METHOD(startListener) {
    if (!self.callObserver) {
        self.callObserver = [[CXCallObserver alloc] init];
        [self.callObserver setDelegate:self queue:nil];
    }
}

RCT_EXPORT_METHOD(stopListener) {
    self.callObserver = nil;
}

- (void)callObserver:(CXCallObserver *)callObserver callChanged:(CXCall *)call {
    if (!self.bridge) {
        return;
    }
    NSString *state;
    if (call.hasEnded) {
        state = @"Disconnected";
    } else if (call.hasConnected) {
        state = @"Connected";
    } else if (call.isOutgoing) {
        state = @"Dialing";
    } else {
        state = @"Incoming";
    }
    [self sendEventWithName:@"PhoneCallStateUpdate" body:state];
}

@end
