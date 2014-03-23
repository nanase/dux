/** dux - ux implementation for D
 *
 * Authors: Tomona Nanase
 * License: The MIT License (MIT)
 * Copyright: Copyright (c) 2014 Tomona Nanase
 */

module dux.Component.CachedWaveform;

import std.array;
import std.container;
import std.conv;
import std.range;

import dux.Component.StepWaveform;

/** ステップ音源をキャッシュするための機能と制約を提供します。 */
abstract class CachedWaveform(T) : StepWaveform
if (is(T : CacheObject!T))
{
protected:
    /** キャッシュされたステップ音源を格納するリストです。 */
    static DList!T cacheObjects;
    
protected:
    /** 派生クラスでオーバーライドされ、この音源で格納できるキャッシュ数を取得します。
     *
     * Returns: この音源で格納できるキャッシュ数。
     */
    @property size_t maxCacheSize()
    out(result)
    {
        assert(result != 0);
    }
    body
    {
        return 32;
    }

    /** 派生クラスでオーバーライドされ、
     * この音源がキャッシュに格納されたステップ波形をリサイズ可能かの真偽値を取得します。
     *
     * Returns: ステップ波形をリサイズ可能かの真偽値。
     */
    @property bool canResizeData() { return false; }

    /** 派生クラスでオーバーライドされ、
     * この音源がステップ波形ではなく直接浮動小数点数の値を出力するかの真偽値を取得します。
     *
     * Returns: 直接浮動小数点数の値を出力するかの真偽値。
     */
    @property bool generatingFloat() { return false; }
    
protected:
    /** 浮動小数点数としてステップ波形を生成します。
     *
     * Params:
     *      parameter = キャッシュオブジェクト。
     *
     * Returns: 生成されたステップ波形。
     */
    float[] generateFloat(T parameter)
    in
    {
        assert(parameter !is null);
    }
    out(result)
    {
        assert(result.length > 0);
    }
    body
    {
        return new float[1];
    }

    /** 整数値としてステップ波形を生成します。
     *
     * Params:
     *      parameter = キャッシュオブジェクト。
     *
     * Returns: 生成されたステップ波形。
     */
    ubyte[] generate(T parameter)
    in
    {
        assert(parameter !is null);
    }
    out(result)
    {
        assert(result.length > 0);
    }
    body
    {
        return new ubyte[1];
    }

    /** キャッシュオブジェクトを用いてキャッシュを照会し、必要に応じて波形を生成します。
     *
     * Params:
     *      parameter = キャッシュオブジェクト。
     */
    void cache(T parameter)
    in
    {
        assert(parameter !is null);
    }
    body
    {
        foreach (now; cacheObjects)
        {
            if (now.equals(parameter))
            {
                this.value = now.dataValue;
                this.length = to!float(this.value.length);
                return;
            }
            else if (this.canResizeData && now.canResize(parameter))
            {
                this.value = new float[parameter.length];
                this.length = to!float(this.value.length);
                
                this.value[0 .. parameter.length] = now.dataValue[0 .. parameter.length];
                
                parameter.dataValue = this.value;
                this.pushCache(parameter);
                return;
            }
        }
        
        if (this.generatingFloat)
        {
            this.value = this.generateFloat(parameter);
            this.length = to!float(this.value.length);
        }
        else
            this.setStep(this.generate(parameter)[]);
        
        parameter.dataValue = this.value;
        this.pushCache(parameter);
    }

private:
    void pushCache(T parameter)
    in
    {
        assert(parameter !is null);
    }
    body
    {
        cacheObjects.insertFront(parameter);
        
        if (cacheObjects[].walkLength() > this.maxCacheSize)
            cacheObjects.removeBack();
    }
}

/** キャッシュに格納された音源を識別するためのキャッシュオブジェクトです。 */
interface CacheObject(T)
{
    /** ステップ波形の生データを取得します。
     *
     * Returns: ステップ波形の生データ。
     */
    @property float[] dataValue();

    /** ステップ波形の生データを設定します。
     *
     * Params:
     *      value = ステップ波形の生データを表す配列。
     *
     * Returns: ステップ波形の生データ。
     */
    @property float[] dataValue(float[] value)
    in
    {
        assert(value.length > 0);
    }

    /** ステップ波形の長さを取得します。
     *
     * Returns: ステップ波形の長さ。
     */
    @property size_t length();

    /** このオブジェクトの dataValue 以外のプロパティが、
     * 比較されるオブジェクト other と一致するかどうかの真偽値を取得します。
     *
     * Params:
     *      other = 比較されるオブジェクト。
     *
     * Returns: 比較の結果、2つのオブジェクトが同一であるとき true、
     *          それ以外のとき false。
     */
    bool equals(T other)
    in
    {
        assert(other !is null);
    }

    /** 比較されるオブジェクト other を比較し、リサイズを行って波形を再構築できるかの真偽値を取得します。
     *
     * Params:
     *      other = 比較されるオブジェクト。
     *
     * Returns: 比較の結果、リサイズが可能であるとき true、
     *          それ以外のとき false。
     */
    bool canResize(T other)
    in
    {
        assert(other !is null);
    }
}
