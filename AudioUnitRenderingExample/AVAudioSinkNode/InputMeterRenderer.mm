//
//  InputMeterRenderer.mm
//  AudioUnitRenderingExample
//
//  Created by Yuki Yasoshima on 2020/08/05.
//  Copyright © 2020 Yuki Yasoshima. All rights reserved.
//

#import "InputMeterRenderer.h"
#include <memory>
#include "InputMeterKernel.hpp"

// 具体class. @endまで
@implementation InputMeterRenderer {
    // shared_ptr: 指定されたリソースへの所有権(ownership)を共有(share)するスマートポインタ
    // どのshared_ptrオブジェクトからもリソースが参照されなくなると、リソースが自動的に解放される。
    std::shared_ptr<InputMeterKernel> _kernel;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // make_shared: shared_ptr オブジェクトを構築する
        _kernel = std::make_shared<InputMeterKernel>();
    }
    return self;
}

- (InputMeterRendererValue)value {
    // c++のコードからvalueを取得して返す
    auto const dataValue = _kernel->value();
    return {.level = dataValue.level, .peak = dataValue.peak};
}

- (AVAudioSinkNode *)makeSinkNodeWithSampleRate:(double)sampleRate {
    // 外部からcallback内に値を渡したい時は[kernel = _kernel, sampleRate]こんな感じにするのかな。多分
    // 丸括弧の中は普通にcallbakのときに渡ってくる値っぽい
    return [[AVAudioSinkNode alloc] initWithReceiverBlock:[kernel = _kernel, sampleRate] (const AudioTimeStamp * _Nonnull timestamp, // 普通にこの辺引数っぽい
                                                                                          AVAudioFrameCount frameCount, // フレームの数
                                                                                          // AudioBufferListはAudioBufferの配列
                                                                                          // https://objective-audio.jp/2008/03/22/core-audio-audiobufferaudiobuf/
                                                                                          const AudioBufferList * _Nonnull inputData) {
        // mNumberBuffers: 配列の要素数=バッファの数
        auto const bufferCount = inputData->mNumberBuffers;
        // bufferの数をもつ配列を初期化する
        float *buffers[bufferCount];
        
        for (uint32_t i = 0; i < bufferCount; ++i) {
            // mData: オーディオデータのあるメモリ領域へのポインタ
            // static_cast: 暗黙の方変換が行われることをあえて明示する
            buffers[i] = static_cast<float *>(inputData->mBuffers[i].mData);
        }
        
        // c++のupdateLevelを呼び出している
        kernel->updateLevel(buffers, inputData->mNumberBuffers, frameCount, sampleRate);
        
        // OSレベル超低レベルのStatusっぽい
        return (OSStatus)noErr;
    }];
}
@end
// ここまで@implementation
