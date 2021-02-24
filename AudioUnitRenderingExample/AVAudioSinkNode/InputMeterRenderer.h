//
//  InputMeterRenderer.h
//  AudioUnitRenderingExample
//
//  Created by Yuki Yasoshima on 2020/08/05.
//  Copyright © 2020 Yuki Yasoshima. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

// nullを許容しない
NS_ASSUME_NONNULL_BEGIN

struct InputMeterRendererValue {
    float const level;
    float const peak;
};

// @endまでinterfaceっぽい
@interface InputMeterRenderer : NSObject

@property (nonatomic, readonly) struct InputMeterRendererValue value;

- (AVAudioSinkNode *)makeSinkNodeWithSampleRate:(double)sampleRate NS_SWIFT_NAME(makeSineNode(sampleRate:));
    // ↑swift側でこの名前で呼び出す

@end
// ここまで@interface

NS_ASSUME_NONNULL_END
