/** dux - ux implementation for D
 *
 * Authors: Tomona Nanase
 * License: The MIT License (MIT)
 * Copyright: Copyright (c) 2014 Tomona Nanase
 */

module dux.Component.StepWaveform;

import std.algorithm;
import std.array;
import std.container;
import std.conv;
import std.math;
import std.range;
import std.typecons;

import dux.Component.Enums;
import dux.Component.Waveform;
import dux.Utils.Algorithm;

/** ステップ (階段状) 波形を生成できるジェネレータクラスです。 */
class StepWaveform : Waveform
{
private:
    static immutable ubyte[1] emptyData = [0];
    DList!ubyte queue;

protected:
    /** 円周率 Math.PI を 2 倍した定数値です。 */
    const static float PI2 = PI * 2.0f;

    /** 円周率 Math.PI を 0.5 倍した定数値です。 */
    const static float PI_2 = PI * 0.5f;

    /** データとして保持できるステップ数を表した定数値です。 */
    const static int MaxDataSize = 65536;

    /** 波形生成に用いられる生データの配列です。 */
    float[] value;

    /** 波形生成に用いられるデータ長の長さです。 */
    float length = 0.0f;

    /** 波形生成に用いられる周波数補正係数です。 */
    double freqFactor = 1.0;

public:
    /** 空の波形データを使って新しい StepWaveform クラスのインスタンスを初期化します。 */
    this()
    {
        this.reset();
    }

public:
    /** 与えられた周波数と位相からステップ波形を生成します。
     *
     * Params:
     *      data       = 生成された波形データが代入される配列。
     *      frequency  = 生成に使用される周波数の配列。
     *      phase      = 生成に使用される位相の配列。
     *      sampleTime = 波形が開始されるサンプル時間。
     *      count      = 配列に代入されるデータの数。
     */
    void getWaveforms
        (float[] data, double[] frequency, double[] phase, int sampleTime, size_t count)
    {
        for (int i = 0; i < count; i++)
        {
            float tmp = to!float(phase[i] * frequency[i] * this.freqFactor);

            if (tmp < 0.0f)
                data[i] = 0.0f;
            else
                data[i] = this.value[to!int(tmp * this.length) % this.value.length];
        }
    }

    /** パラメータを指定して波形の設定値を変更します。
     *
     * Params:
     *      data1 = 整数パラメータ。
     *      data2 = 実数パラメータ。
     */
    void setParameter(int data1, float data2)
    {
        switch (data1)
        {
            case StepWaveformOperate.freqFactor:
                this.freqFactor = data2.clamp(float.max, 0.0f) * 0.001;
                break;
                
            case StepWaveformOperate.begin:
                this.queue.clear();
                this.queue.insertFront(to!ubyte(data2.clamp(255.0f, 0.0f)));
                break;
                
            case StepWaveformOperate.end:
                this.queue.insertFront(to!ubyte(data2.clamp(255.0f, 0.0f)));

                if (this.queue[].walkLength() <= MaxDataSize)
                {
                    ubyte[] reverseQueue = new ubyte[this.queue[].walkLength()];
                    this.queue[].copy(reverseQueue);
                    reverseQueue.reverse();
                    this.setStep(reverseQueue[]);
                }

                break;
                
            case StepWaveformOperate.queue:
                this.queue.insertFront(to!ubyte(data2.clamp(255.0f, 0.0f)));
                break;
                
            default:
                break;
        }
    }

    /** エンベロープをアタック状態に遷移させます。 **/
    void attack()
    {
    }

    /** エンベロープをリリース状態に遷移させます。
     *
     * Params:
     *      time = リリースされたサンプル時間。
     */
    void release(int time)
    {
    }

    /** 波形のパラメータをリセットします。 */
    void reset()
    {
        this.setStep(this.emptyData[]);
    }

    /** 指定されたステップデータから波形生成用のデータを作成します。
     *
     * Params:
     *      data = 波形生成のベースとなるステップデータを格納したレンジ。
     */
    void setStep(Range)(Range data)
    if (isInputRange!Range && !isInfinite!Range)
    in
    {
       assert(data.walkLength() <= StepWaveform.MaxDataSize);
    }
    body
    {
        auto min_max = data.reduce!(min, max);
        float a = 2.0f / (min_max[1] - min_max[0]);

        size_t dataLength = data.walkLength();
        this.length = to!float(dataLength);
        this.value = new float[dataLength];

        if (min_max[0] == min_max[1])
        {
            this.value[] = 0.0f;
            return;
        }

        int i = 0;
        foreach (e; data)
        {
            this.value[i] = (e - min_max[0]) * a - 1.0f;
            i++;
        }
    }

    invariant()
    {
        assert(isFinite(this.freqFactor));
        assert(this.freqFactor >= 0.0);

        assert(isFinite(this.length));
        assert(this.length >= 0.0f);
    }

    ///
    unittest
    {
        static void test(Range1, Range2)(Range1 input, Range2 goal)
        {
            StepWaveform waveform = new StepWaveform();
            waveform.setStep(input);

            assert(equal(waveform.value[], goal));
        }

        test([0], [0.0f]);
        test([0, 1], [-1.0f, 1.0f]);
        test([0, 0], [0.0f, 0.0f]);

        test([4, 1, 3, 0], [1.0f, -0.5f, 0.5f, -1.0f]);
        test([0, 1, 2, 1], [-1.0f, 0.0f, 1.0f, 0.0f]);
    }
}
