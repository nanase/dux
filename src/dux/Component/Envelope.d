/** dux - ux implementation for D
 *
 * Authors: Tomona Nanase
 * License: The MIT License (MIT)
 * Copyright: Copyright (c) 2014 Tomona Nanase
 */

module dux.Component.Envelope;

import std.algorithm;
import std.conv;
import std.math;
import std.range;

import dux.Component.Enums;
import dux.Utils.Algorithm;

/** 時間によって変化するパラメータを実装するためのエンベロープ (包絡線) クラスです。 */
class Envelope
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
        return this._attackTime = to!int(value.clamp(float.max, 0.0f) * this.samplingRate);
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
        return this._peakTime = to!int(value.clamp(float.max, 0.0f) * this.samplingRate);
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
        return this._decayTime = to!int(value.clamp(float.max, 0.0f) * this.samplingRate);
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
        return this._sustainLevel = value.clamp(1.0f, 0.0f);
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
        return this._releaseTime = to!int(value.clamp(float.max, 0.0f) * this.samplingRate);
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
        this._attackTime = to!int(0.05f * this.samplingRate);
        this._peakTime = to!int(0.0f * this.samplingRate);
        this._decayTime = to!int(0.0f * this.samplingRate);
        this._sustainLevel = 1.0f;
        this._releaseTime = to!int(0.2f * this.samplingRate);
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
     *      count     = 代入される実数値の数。
     */
    auto generate(int time, size_t count)
    in
    {
        assert(time >= 0);
        assert(count < uint.max);
    }
    body
    {
        static struct Result
        {
        pure nothrow @safe:

            /// range primitives
            float front() @property const { return _front; }

            /// ditto
            bool empty() @property const { return _time == _endTime; }

            /// ditto
            void popFront()
            {
                ++_time;

                if (!this.empty)
                    _front = generateEnvelope(_time);
            }

            /// ditto
            auto save() @property
            {
                return this;
            }

            /// ditto
            size_t length() @property const
            {
                return _endTime - _time;
            }

            /// ditto
            auto opSlice()
            {
                return this;
            }

            /// ditto
            auto opSlice(size_t a, size_t b)
            in
            {
                assert(a <= b);
                assert(a <= this.length);
                assert(b <= this.length);
                assert(a < uint.max);
                assert(b < uint.max);
            }
            body
            {
                auto dst = this;

                dst._time += a;
                dst._endTime = dst._time + cast(int)(b - a);
                dst._front = dst.generateEnvelope(_time);

                return dst;
            }


        private:
            int _time;
            int _endTime;
            Envelope _env;
            float _front;


            float generateEnvelope(int time)
            {
                float res;

                if (_env._state == EnvelopeState.attack)
                    res = (time < _env._attackTime) ? time * _env.da :
                    (time < _env.t2) ? 1.0f :
                    (time < _env.t3) ? 1.0f - (time - _env.t2) * _env.dd : _env._sustainLevel;
                else if (_env._state == EnvelopeState.release)
                {
                    if (time < _env.t5)
                        res = _env.releaseStartLevel - (time - _env.releaseStartTime) * _env.dr;
                    else
                    {
                        res = 0.0f;
                        _env._state = EnvelopeState.silence;
                    }
                }
                else
                    res = 0.0f;

                return res;
            }
        }


        auto dst = Result(time, cast(int)(time + count), this, float.nan);

        if (!dst.empty)
            dst._front = dst.generateEnvelope(time);

        return dst;
    }

    unittest
    {
        static void test(Envelope env)
        {
            auto r = env.generate(64, 1024);

            assert(r.length == 1024);
            assert(!r.empty);
            assert(r.front == r.generateEnvelope(64));

            r.popFront();
            assert(r.length == 1023);
            assert(!r.empty);
            assert(r.front == r.generateEnvelope(65));

            r.popFrontN(1022);
            assert(r.length == 1);
            assert(!r.empty);

            r.popFront();
            assert(r.length == 0);
            assert(r.empty);
        }

        // envを適切に初期化して、テストする必要があるので、
        // 書き直す必要あり
        Envelope env = new Envelope(64);
        env.attack();
        test(env);
    }


    /** 現在のエンベロープの状態に基づき、エンベロープ値を出力します。
     * 
     * Params:
     *      time      = エンベロープの開始時間値。
     *      envelopes = 出力が格納される実数のレンジ。
     *      count     = 代入される実数値の数。
     */
    void generate(R)(int time, R envelopes, size_t count)
    if (isOutputRange!(R, float))
    in
    {
        assert(time >= 0);
        assert(count >= 0);
    }
    body
    {
        generate(time, count).copy(envelopes);
    }

    unittest
    {
        static void test(Envelope env)
        {
            float[] fltArr = new float[24];
            env.generate(0, fltArr, 24);
            assert(fltArr.length == 24);

            auto app = appender!(float[])();
            env.generate(0, app, 24);
            assert(app.data.length == 24);
        }

        // envを適切に初期化して、テストする必要があるので、
        // 書き直す必要あり
        Envelope env = new Envelope(64);
        env.attack();
        test(env);
    }


    /** パラメータを用いてこのエンベロープの設定値を変更します。
     * 
     * Params:
     *      data1 = 整数パラメータ。
     *      data2 = 実数パラメータ。
     */
    void setParameter(int data1, float data2)
    in
    {
        assert(!isNaN(data2));
    }
    body
    {
        switch (cast(EnvelopeOperate)data1)
        {
            case EnvelopeOperate.attack:
                this._attackTime = to!int(data2.clamp(float.max, 0.0f) * this.samplingRate);
                break;
                
            case EnvelopeOperate.peak:
                this._peakTime = to!int(data2.clamp(float.max, 0.0f) * this.samplingRate);
                break;

            case EnvelopeOperate.decay:
                this._decayTime = to!int(data2.clamp(float.max, 0.0f) * this.samplingRate);
                break;
                
            case EnvelopeOperate.sustain:
                this._sustainLevel = data2.clamp(1.0f, 0.0f);
                break;
                
            case EnvelopeOperate.release:
                this._releaseTime = to!int(data2.clamp(float.max, 0.0f) * this.samplingRate);
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
    static Envelope createConstant(float samplingRate)
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
        Envelope envelope = Envelope.createConstant(100.0f);

        envelope.attack();
        {
            auto r = envelope.generate(0, 10);
            assert(r.length == 10);
            assert(!r.empty);
            r.popFront();
            assert(r.front == 1.0f);
        }

        envelope.release(10);
        {
            auto r = envelope.generate(10, 10);
            assert(r.length == 10);
            assert(!r.empty);
            r.popFront();
            assert(r.front == 0.0f);
        }
    }
}
