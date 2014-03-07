/** dux - ux implementation for D
 *
 * Authors: Tomona Nanase
 * License: The MIT License (MIT)
 * Copyright: Copyright (c) 2014 Tomona Nanase
 */

module dux.Component.Envelope;

import std.math;
import dux.Component.Enums;
import dux.Utils;

/** 時間によって変化するパラメータを実装するためのエンベロープ (包絡線) クラスです。 */
public class Envelope
{
private:
    int releaseStartTime, t2, t3, t5, _attackTime, _peakTime, _decayTime, _releaseTime;
    float da, dd, dr, _sustainLevel, releaseStartLevel;
    EnvelopeState _state;

public:
    /** このエンベロープで使われるサンプリング周波数です。 */
    immutable float samplingRate;

public:
    /** 現在のエンベロープの状態を表す列挙値を取得します。
     * 
     * Returns: エンベロープの状態を表す dux.Complent.EnvelopeState 列挙値。
     */
    @property EnvelopeState state() { return this._state; }

    /** ノートが開始されてピークに達するまでの遷移時間を取得します。
     * 
     * Returns: アタック時間(秒)。
     */
    @property float attackTime() { return this._attackTime / this.samplingRate; }

    /** ノートが開始されてピークに達するまでの遷移時間を設定します。
     * 
     * Params:
     *      value = 設定される 0.0 以上の値。
     * 
     * Returns: アタック時間(秒)。
     */
    @property float attackTime(float value) 
    {
        return this._attackTime = cast(int)(clamp(float.max, 0.0f, value) * this.samplingRate);
    }

    /** ピークを維持する時間を取得します。
     * 
     * Returns: ピーク時間(秒)。
     */
    @property float peakTime() { return this._peakTime / this.samplingRate; }

    /** ピークを維持する時間を設定します。
     * 
     * Params:
     *      value = 設定される 0.0 以上の値。
     * 
     * Returns: ピーク時間(秒)。
     */
    @property float peakTime(float value) 
    {
        return this._peakTime = cast(int)(clamp(float.max, 0.0f, value) * this.samplingRate);
    }

    /** ピークからサスティンレベルに達するまでの遷移時間を取得します。
     * 
     * Returns: ディケイ時間(秒)。
     */
    @property float decayTime() { return this._decayTime / this.samplingRate; }

    /** ピークからサスティンレベルに達するまでの遷移時間を設定します。
     * 
     * Params:
     *      value = 設定される 0.0 以上の値。
     * 
     * Returns: ディケイ時間(秒)。
     */
    @property float decayTime(float value) 
    {
        return this._decayTime = cast(int)(clamp(float.max, 0.0f, value) * this.samplingRate);
    }

    /** エンベロープがリリースされるまで持続するサスティンレベルを取得します。
     * 
     * Returns: サスティンレベル。
     */
    @property float sustainLevel() { return this._sustainLevel; }

    /** エンベロープがリリースされるまで持続するサスティンレベルを設定します。
     * 
     * Params:
     *      value = 設定される 0.0 以上 1.0 以下の値。
     * 
     * Returns: サスティンレベル。
     */
    @property float sustainLevel(float value) 
    {
        return this._sustainLevel = clamp(1.0f, 0.0f, value);
    }

    /** リリースされてからエンベロープが消滅するまでの時間を取得します。
     * 
     * Returns: リリース時間(秒)。
     */
    @property float releaseTime() { return this._releaseTime / this.samplingRate; }

    /** リリースされてからエンベロープが消滅するまでの時間を設定します。
     * 
     * Params:
     *      value = 設定される 0.0 以上の値。
     * 
     * Returns: リリース時間(秒)。
     */
    @property float releaseTime(float value) 
    {
        return this._releaseTime = cast(int)(clamp(float.max, 0.0f, value) * this.samplingRate);
    }

public:
    /** サンプリング周波数を指定して新しい Envelope クラスのインスタンスを初期化します。
     * 
     * Params:
     *      samplingRate = サンプリング周波数。 
     */
    this(float samplingRate)
        in
        {
            assert(samplingRate > 0.0f);
            assert(isFinite(samplingRate));
        }
        body
        {
            this.samplingRate = samplingRate;
            this.reset();
        }

public:
    /** このインスタンスにおけるすべてのパラメータを既定値に戻します。 */
    void reset()
        out
        {
            assert(this._state == EnvelopeState.silence);
        }
        body
        {
            this._attackTime = cast(int)(0.05f * this.samplingRate);
            this._peakTime = cast(int)(0.0f * this.samplingRate);
            this._decayTime = cast(int)(0.0f * this.samplingRate);
            this._sustainLevel = 1.0f;
            this._releaseTime = cast(int)(0.2f * this.samplingRate);
            this._state = EnvelopeState.silence;
        }

    /** エンベロープの状態をアタック状態に変更します。 */
    void attack()
        out
        {
            assert(this._state == EnvelopeState.attack);
        }
        body
        {
            this._state = EnvelopeState.attack;
            
            //precalc
            this.t2 = this._attackTime + this._peakTime;
            this.t3 = t2 + this._decayTime;
            this.da = 1.0f / this._attackTime;
            this.dd = (1.0f - this._sustainLevel) / this._decayTime;
        }

    /** エンベロープの状態をリリース状態に変更します。
     * 
     * Params:
     *      time = リリースが開始された時間値。 
     */
    void release(int time)
        in
        {
            assert(time >= 0);
        }
        out
        {
            assert(this._state != EnvelopeState.attack);
        }
        body
        {
            if (this._state == EnvelopeState.attack)
            {
                this._state = EnvelopeState.release;
                this.releaseStartTime = time;
                
                //precalc
                this.releaseStartLevel = (time < this._attackTime) ? time * this.da :
                (time < this.t2) ? 1.0f :
                (time < this.t3) ? 1.0f - (time - this.t2) * this.dd : this._sustainLevel;
                this.t5 = time + this._releaseTime;
                this.dr = this.releaseStartLevel / this._releaseTime;
            }
        }

    /** エンベロープの状態をサイレンス状態に変更します。 */
    void silence()
        out
        {
            assert(this._state == EnvelopeState.silence);
        }
        body
        {
            this._state = EnvelopeState.silence;
        }

    /** 現在のエンベロープの状態に基づき、エンベロープ値を出力します。
     * 
     * Params:
     *      time      = エンベロープの開始時間値。
     *      envelopes = 出力が格納される実数の配列。
     *      offset    = 代入が開始される配列のインデックス。
     *      count     = 代入される実数値の数。
     */
    void generate(int time, float[] envelopes, int count)
        in
        {
            assert(time >= 0);
            assert(envelopes != null);
            assert(count >= 0);
            assert(envelopes.length <= count);
        }
        body
        {
            float res;
            for (int i = 0; i < count; i++, time++)
            {
                if (this._state == EnvelopeState.attack)
                    res = (time < this._attackTime) ? time * this.da :
                    (time < this.t2) ? 1.0f :
                    (time < this.t3) ? 1.0f - (time - this.t2) * this.dd : this._sustainLevel;
                else if (this._state == EnvelopeState.release)
                {
                    if (time < this.t5)
                        res = this.releaseStartLevel - (time - this.releaseStartTime) * this.dr;
                    else
                    {
                        res = 0.0f;
                        this._state = EnvelopeState.silence;
                    }
                }
                else
                    res = 0.0f;
                
                envelopes[i] = res;
            }
        }

    /** パラメータを用いてこのエンベロープの設定値を変更します。
     * 
     * Params:
     *      data1 = 整数パラメータ。
     *      data2 = 実数パラメータ。
     */
    void setParameter(int data1, float data2)
    {
        switch (cast(EnvelopeOperate)data1)
        {
            case EnvelopeOperate.attack:
                this._attackTime = cast(int)(clamp(float.max, 0.0f, data2) * this.samplingRate);
                break;
                
            case EnvelopeOperate.peak:
                this._peakTime = cast(int)(clamp(float.max, 0.0f, data2) * this.samplingRate);
                break;

            case EnvelopeOperate.decay:
                this._decayTime = cast(int)(clamp(float.max, 0.0f, data2) * this.samplingRate);
                break;
                
            case EnvelopeOperate.sustain:
                this._sustainLevel = clamp(1.0f, 0.0f, data2);
                break;
                
            case EnvelopeOperate.release:
                this._releaseTime = cast(int)(clamp(float.max, 0.0f, data2) * this.samplingRate);
                break;
                
            default:
                break;
        }
    }

public:
    /** 値の変化しない、常に一定値を出力するエンベロープを作成します。
     * 
     * Params:
     *      samplingRate = サンプリング周波数。
     * 
     * Returns: 一定出力値を持つエンベロープ。
     */
    static Envelope CreateConstant(float samplingRate)
        in
        {
            assert(samplingRate > 0.0f);
            assert(isFinite(samplingRate));
        }
        body
        {
            Envelope envelope = new Envelope(samplingRate);
            envelope.attackTime = 0;
            envelope.peakTime = 0;
            envelope.decayTime = 0;
            envelope.sustainLevel = 1.0f;
            envelope.releaseTime = 0;
            
            return envelope;
        } 
        unittest
        {
            Envelope envelope = Envelope.CreateConstant(100.0f);
            assert(envelope.samplingRate == 100.0f);
        }
}
