//
//  InputMeterUtils.h
//  AudioUnitRenderingExample
//
//  Created by Yuki Yasoshima on 2020/08/05.
//  Copyright © 2020 Yuki Yasoshima. All rights reserved.
//

#pragma once

#include <math.h>

// 10の(decibel / 20.0f)乗。デシベル->長さに変換
float linearFromDecibel(float const decibel) {
    return powf(10.0f, decibel / 20.0f);
}

// 長さ -> デシベルに変換
float decibelFromLinear(float const linear) {
    return 20.0f * log10f(linear);
}
