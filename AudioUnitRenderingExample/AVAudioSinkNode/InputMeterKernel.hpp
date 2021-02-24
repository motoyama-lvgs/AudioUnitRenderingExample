//
//  InputMeterKernel.hpp
//  AudioUnitRenderingExample
//
//  Created by Yuki Yasoshima on 2020/08/05.
//  Copyright © 2020 Yuki Yasoshima. All rights reserved.
//

// hppはcppのheaderという位置づけ。protcolっぽさ。

// 誤って2回同じファイルをインクルードした時の多重定義エラーの防止
#pragma once

// c++のクラス
#include <atomic>

// class: デフォルトprivate
// struct: デフォルトpublic
struct InputMeterKernel {
    /// メーターに表示する値2つをアトミックに扱うための共用体
    /// そんなに厳密にアトミックにするほどのものではないがサンプルとして使っている
    // unionはmemoryを共有するらしい(?)
    union Value {
        // void型ポインタ
        void *v;
        struct {
            float const level;
            float const peak;
        };
    };
    /// Valueのサイズがvoid *のサイズを超えていないことをコンパイル時にチェック
    // static_assert: コンパイル時にfalseになるとエラーを吐く
    static_assert(sizeof(Value) == sizeof(void *), "");
    
    /// メーターに表示する値をメインスレッドから取得する。アトミック
    Value value() const;

    /// 入力されたデータを渡しメーターの値をオーディオIOスレッドから更新する
    void updateLevel(float const * const * const buffers,
                     int const bufferCount,
                     int const frameCount,
                     double const sampleRate);
    
private:
    std::atomic<void *> atomicValue;
    double peakDuration = 0.0;
};
