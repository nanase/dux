/** dux - ux implementation for D
 *
 * Authors: Tomona Nanase
 * License: The MIT License (MIT)
 * Copyright: Copyright (c) 2014 Tomona Nanase
 */

module dux.Component.Panpot;

import std.algorithm;
import std.math;
import dux.Utils;

/** 音の定位 (左右チャネルのバランス) を表す実数値を格納する構造体です。 */
public struct Panpot
{
public:
    /** 左チャネルのレベル。 */
    immutable float l;

    /** 右チャネルのレベル。 */
    immutable float r;

public:
    /** 左右チャネルのレベルを指定して新しい Panpot 構造体のインスタンスを初期化します。
     * 
     * Params:
     *      lChannel = 左チャネルのレベル。
     *      rChannel = 右チャネルのレベル。
     */
    this(float lChannel, float rChannel)
    {
        this.l = lChannel.clamp(1.0f, 0.0f);
        this.r = rChannel.clamp(1.0f, 0.0f);
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
            this.l = value >= 0.0f ? cast(float)sin((value + 1f) * PI / 2.0) : 1.0f;
            this.r = value <= 0.0f ? cast(float)sin((-value + 1f) * PI / 2.0) : 1.0f;
        }

    invariant()
    {
        assert(this.l >= 0.0f && this.l <= 1.0f);
        assert(this.r >= 0.0f && this.r <= 1.0f);
    }
}

