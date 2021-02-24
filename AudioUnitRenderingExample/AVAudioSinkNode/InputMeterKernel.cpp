//
//  InputMeterKernel.cpp
//  AudioUnitRenderingExample
//
//  Created by Yuki Yasoshima on 2020/08/05.
//  Copyright © 2020 Yuki Yasoshima. All rights reserved.
//

#include "InputMeterKernel.hpp"
#include "InputMeterUtils.h"
#include <cmath>
#include <Accelerate/Accelerate.h>

// 構造体名からアクセスしないとだめっぽい。普通にmethod名と返り値のtypeかと
InputMeterKernel::Value InputMeterKernel::value() const {
    // 正確にはInputMeterKernel::Value.v にアクセスしてるってことだと思う。多分
    // そしてそのままそれを返している
    return InputMeterKernel::Value{.v = atomicValue};
}

void InputMeterKernel::updateLevel(float const * const * const buffers,
                                 int const bufferCount,
                                 int const frameCount,
                                 double const sampleRate) {
    float currentLinear = 0.0f;
    
    int bufferIndex = 0;
    while (bufferIndex < bufferCount) {
        float max = 0.0f;
        // 第三引数に絶対値の最大値を格納する
        // https://developer.apple.com/documentation/accelerate/1449986-vdsp_maxmgv
        vDSP_maxmgv(buffers[bufferIndex], 1, &max, frameCount);
        // 大きい方を返す。確か音のレベルを線の長さで表していたのでそのあたりのロジック
        currentLinear = std::fmax(max, currentLinear);
        // 次のbufferに進む。bufferCountを超えたらおしまい
        ++bufferIndex;
    }
    
    // 0~1の間で制御するために、1.0fで最大値に蓋をしている
    currentLinear = std::fmin(currentLinear, 1.0f);
    
    peakDuration += (double)frameCount / sampleRate;
    
    // 1つ前の値
    auto const prevValue = value();
    // 1つ前のデシベル
    auto const prevDecibel = decibelFromLinear(prevValue.level) - (float)frameCount / (float)sampleRate * 30.0f;
    // 1つ前のリニア
    auto const prevLinear = linearFromDecibel(prevDecibel);
    // 次のリニア(1つ前と今のリニアの大きい方)
    auto const nextLinear = std::fmax(prevLinear, currentLinear);
    // 1つ前より次のリニアの方が大きい || peakDurationが1より大きいなら、updateする
    auto const updatePeak = (prevValue.peak < nextLinear) || (peakDuration > 1.0);
    
    if (updatePeak) {
        peakDuration = 0.0;
    }
    
    Value const value{
        .level = nextLinear,
        .peak = updatePeak ? nextLinear : prevValue.peak
    };
    
    // 値をポインタで保管
    atomicValue = value.v;
}
