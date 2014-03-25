/** dux - ux implementation for D
 *
 * Authors: Tomona Nanase
 * License: The MIT License (MIT)
 * Copyright: Copyright (c) 2014 Tomona Nanase
 */

module dux.Component.Panpot;

import std.algorithm;
import std.math;

import dux.Utils.Algorithm;

/** 音の定位 (左右チャネルのバランス) を表す実数値を格納する構造体です。 */
struct Panpot
{
pure nothrow @safe: // 純粋な値型
private:
    float _l, _r;

public:

    /** 左右チャネルのレベルを指定して新しい Panpot 構造体のインスタンスを初期化します。
     * 
     * Params:
     *      lChannel = 左チャネルのレベル。
     *      rChannel = 右チャネルのレベル。
     */
    this(float lChannel, float rChannel)
    {
        this._l = lChannel.clamp(1.0f, 0.0f);
        this._r = rChannel.clamp(1.0f, 0.0f);
    }

    /** 左右チャネルのレベルを制御するパンポット値を指定して新しい Panpot 構造体のインスタンスを初期化します。
     * 
     * Params:
     *      value = パンポット値。
     */
    this(float value)
    in
    {
        assert(isFinite(value));
        assert(value >= -1.0f && value <= 1.0f);
    }
    body
    {
        this._l = value >= 0.0f ? sin((value + 1f) * PI / 2.0) : 1.0f;
        this._r = value <= 0.0f ? sin((-value + 1f) * PI / 2.0) : 1.0f;
    }

const:

    /** 左チャネルのレベル。 */
    float l() @property { return _l; }

    /** 右チャネルのレベル。 */
    float r() @property { return _r; }


    invariant()
    {
        assert(this._l >= 0.0f && this._l <= 1.0f);
        assert(this._r >= 0.0f && this._r <= 1.0f);
    }
}

pure nothrow @safe
unittest
{
    Panpot ppt;

    ppt = Panpot(0.5, 0.5);
    ppt = Panpot(0.8);

    static assert(!is(typeof({
        ppt.l = 0.2;    // NG
        ppt.r = 0.3;    // NG
    })));

    ppt = ppt;  // OK
}