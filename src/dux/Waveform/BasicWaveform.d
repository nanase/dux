/** dux - ux implementation for D
 *
 * Authors: Tomona Nanase
 * License: The MIT License (MIT)
 * Copyright: Copyright (c) 2014 Tomona Nanase
 */

module dux.Component.BasicWaveform;

import std.algorithm;
import std.conv;
import std.container;
import std.range;

import dux.Component.Enums;
import dux.Component.Waveform;
import dux.Component.StepWaveform;
import dux.Component.CachedWaveform;
import dux.Utils.Algorithm;

/** 基本波形に対するキャッシュオブジェクトを提供します。 */
class BaseWaveformCache : CacheObject!BaseWaveformCache
{
private:
    float[] data;
    int stepSeed;
    
public:
    /** ステップ波形の生データを取得します。
     *
     * Returns: ステップ波形の生データ。
     */
    @property float[] dataValue() { return this.data; }

    /** ステップ波形の生データを設定します。
     *
     * Params:
     *      value = ステップ波形の生データを表す配列。
     *
     * Returns: ステップ波形の生データ。
     */
    @property float[] dataValue(float[] value) { return this.data = value; }

    /** 基本波形のステップ数を取得します。
     *
     * Returns: 基本波形のステップ数。
     */
    @property int step() { return this.stepSeed; }

    /** ステップ波形の長さを取得します。
     *
     * Returns: ステップ波形の長さ。
     */
    @property size_t length() { return this.data.length; }
    
public:
    /** ステップ数を指定して新しい BaseWaveformCache クラスのインスタンスを初期化します。
     *
     * Params:
     *      step = 基本波形のステップ数。
     */
    this(int step)
    {
        this.stepSeed = step;
    }
    
public:
    /** このオブジェクトの dataValue 以外のプロパティが、
     * 比較されるオブジェクト other と一致するかどうかの真偽値を取得します。
     *
     * Params:
     *      other = 比較されるオブジェクト。
     *
     * Returns: 比較の結果、2つのオブジェクトが同一であるとき true、
     *          それ以外のとき false。
     */
    bool equals(BaseWaveformCache other)
    {
        return this.stepSeed == other.stepSeed;
    }

    /** 比較されるオブジェクト other を比較し、リサイズを行って波形を再構築できるかの真偽値を取得します。
     *
     * Params:
     *      other = 比較されるオブジェクト。
     *
     * Returns: 比較の結果、リサイズが可能であるとき true、
     *          それ以外のとき false。
     */
    bool canResize(BaseWaveformCache other)
    {
        return false;
    }
}

/** 矩形波を生成する波形ジェネレータクラスです。 */
class Square : CachedWaveform!BaseWaveformCache
{
public:
    /** パラメータを指定して波形の設定値を変更します。
     *
     * Params:
     *      data1 = 整数パラメータ。
     *      data2 = 実数パラメータ。
     */
    override void setParameter(int data1, float data2)
    {
        switch (data1)
        {
            case BasicWaveformOperate.duty:
                this.generateStep(data2.clamp(1.0f, 0.0f));
                break;
                
            default:
                super.setParameter(data1, data2);
                break;
        }
    }

    /** 波形のパラメータをリセットします。 */
    override void reset()
    {
        this.generateStep(0.5f);
    }
    
protected:
    /** 整数値としてステップ波形を生成します。
     *
     * Params:
     *      parameter = キャッシュオブジェクト。
     *
     * Returns: 生成されたステップ波形。
     */
    override ubyte[] generate(BaseWaveformCache parameter)
    {
        bool reverse = parameter.step < 0;
        int onTime = (reverse) ? -parameter.step : parameter.step;
        
        ubyte[] l = new ubyte[onTime + 1];
        
        if (reverse)
            // 10, 110, 1110, ...
            l[0 .. $ - 1] = 1;
        else
            // 10, 100, 1000, ...
            l[0] = 1;
        
        return l;
    }
    
private:
    void generateStep(float duty)
    {
        if (duty <= 0.0f || duty >= 1.0f)
            return;
        
        int onTime = to!int(1.0f / (duty <= 0.5f ? duty : (1.0f - duty))) - 1;
        
        if (onTime < 0 || onTime > MaxDataSize)
            return;
        
        if (duty > 0.5f)
            onTime = -onTime;
        
        this.cache(new BaseWaveformCache(onTime));
    }
}

/** 擬似三角波を生成する波形ジェネレータクラスです。 */
class Triangle : CachedWaveform!BaseWaveformCache
{
public:
    /** 波形のパラメータをリセットします。 */
    override void reset()
    {
        this.generateStep(16);
    }

    /** パラメータを指定して波形の設定値を変更します。
     *
     * Params:
     *      data1 = 整数パラメータ。
     *      data2 = 実数パラメータ。
     */
    override void setParameter(int data1, float data2)
    {
        switch (data1)
        {
            case BasicWaveformOperate.type:
                this.generateStep(to!int(data2).clamp(int.max, 1));
                break;
                
            default:
                super.setParameter(data1, data2);
                break;
        }
    }
    
protected:
    /** 整数値としてステップ波形を生成します。
     *
     * Params:
     *      parameter = キャッシュオブジェクト。
     *
     * Returns: 生成されたステップ波形。
     */
    override ubyte[] generate(BaseWaveformCache parameter)
    {
        ubyte[] l = new ubyte[parameter.step * 2];
        
        for (int i = 0; i < parameter.step; i++)
            l[i] = to!ubyte(i);
        
        for (int i = parameter.step; i < parameter.step * 2; i++)
            l[i] = to!ubyte(parameter.step * 2 - i - 1);
        
        return l;
    }
    
private:
    void generateStep(int step)
    {
        if (step <= 0 || step > 256)
            return;
        
        this.cache(new BaseWaveformCache(step));
    }
}