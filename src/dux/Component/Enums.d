/** dux - ux implementation for D
 *
 * Authors: Tomona Nanase
 * License: The MIT License (MIT)
 * Copyright: Copyright (c) 2014 Tomona Nanase
 */

module dux.Component.Enums;

/** 内部で扱われるハンドルのタイプを表す列挙体です。 */
public enum HandleType
{
    /** ゼロのゲートを持ち、発音されないノートを表します。 */
    zeroGate,
    
    /** パートまたはマスターの各パラメータをリセットします。 */
    reset,
    
    /** ノートのエンベロープをサイレンス状態に移行させ、無音状態にします。 */
    silence,
    
    /** ノートのエンベロープをリリース状態に移行させます。 */
    noteOff,
    
    /** ボリューム (音量) を変更します。 */
    volume,
    
    /** パンポット (定位) を変更します。 */
    panpot,
    
    /** ビブラートに関するパラメータを設定します。 */
    vibrate,
    
    /** パートに波形を割り当てます。 */
    waveform,
    
    /** 波形のパラメータを編集します。 */
    editWaveform,

    /** 波形のパラメータを編集します。 */
    edit = editWaveform,
    
    /** パートの音量エンベロープを変更します。 */
    envelope,
    
    /** パートのファインチューン値を変更します。 */
    fineTune,
    
    /** パートの発音ノートキーをシフトします。 */
    keyShift,
    
    /** ポルタメント効果に関するパラメータを設定します。 */
    portament,
    
    /** パートを指定されたノートまたは周波数でアタック状態にします。 */
    noteOn
}

/** エンベロープの状態を表す列挙体です。 */
public enum EnvelopeState
{
    /** 無音状態。 */
    silence,

    /** アタック(立ち上がり)状態。 */
    attack,

    /** リリース(余韻)状態。 */
    release,
}

/** 擬似乱数ジェネレータに作用するオプションを表した列挙体です。 */
public enum RandomNoiseOperate
{
    /** 擬似乱数ジェネレータのシード値。 */
    seed = 0x0100,

    /** 擬似乱数の周期。 */
    length,
}

/** 基本波形クラスに作用するオプションを表した列挙体です。 */
public enum BasicWaveformOperate
{
    /** デューティ比。 */
    duty = 0x0100,

    /** 波形タイプ。 */
    type,
}

/** ステップ波形クラスに作用するオプションを表した列挙体です。 */
public enum StepWaveformOperate
{
    /** 周波数計数。
     * 指定された値が周波数計数に乗算されます。 */
    freqFactor = 0x0000,

    /** ユーザ波形の開始。
     * このパラメータの実数値からユーザ波形として登録します。 */
    begin,

    /** ユーザ波形の終了。
     * このパラメータの実数値までユーザ波形として登録します。 */
    end,

    /** ユーザ波形のキューイング。 */
    queue,
}

/** FM 音源クラスに作用するオプションを表した列挙体です。 */
public enum FMOperate
{
    /** オペレータ 0 に対する変調指数。 */
    send0 = 0x0000,

    /** オペレータ 1 に対する変調指数。 */
    send1 = 0x0100,

    /** オペレータ 2 に対する変調指数。 */
    send2 = 0x0200,

    /** オペレータ 3 に対する変調指数。 */
    send3 = 0x0300,

    /** 出力キャリア振幅。 */
    output = 0x0400,

    /** 出力キャリア振幅。 */
    Out = output,
    //out = output,

    /** キャリア周波数。 */
    frequency = 0x0500,

    /** キャリア周波数。 */
    freq = frequency,

    /** オペレータ 0。 */
    operator0 = 0x0000,

    /** オペレータ 0。 */
    op0 = operator0,

    /** オペレータ 1。 */
    operator1 = 0x1000,

    /** オペレータ 1。 */
    op1 = operator1,

    /** オペレータ 2。 */
    operator2 = 0x2000,

    /** オペレータ 2。 */
    op2 = operator2,

    /** オペレータ 3。 */
    operator3 = 0x3000,

    /** オペレータ 3。 */
    op3 = operator3,
}

/** エンベロープに作用するオプションを表した列挙体です。 */
public enum EnvelopeOperate
{
    /** オプションなし。 
     * これは音源に対するオプションと組み合わせるために用意されています。
     */
    none = 0x00,

    /** アタック時間。 */
    attack = 0x01,

    /** アタック時間。 */
    a = attack,

    /** ピーク時間。 */
    peak = 0x02,

    /** ピーク時間。 */
    p = peak,

    /** ディケイ時間。 */
    decay = 0x03,

    /** ディケイ時間。 */
    d = decay,

    /** サスティンレベル。 */
    sustain = 0x04,

    /** サスティンレベル。 */
    s = sustain,

    /** リリース時間。 */
    release = 0x05,

    /** リリース時間。 */
    r = release,
}

/** ボリュームに作用するオプションを表した列挙体です。 */
public enum VolumeOperate
{
    /** 変化を伴わない音量。ボリューム。 */
    volume,

    /** 変化を伴う音量。抑揚。 */
    expression,

    /** 発音の強さ。ベロシティ。 */
    velocity,

    /** 発音の増幅度。ゲイン。 */
    gain,
}

/** ビブラートに作用するオプションを表した列挙体です。 */
public enum VibrateOperate
{
    /** ビブラート無効。 */
    off,

    /** ビブラート有効。 */
    on,

    /** ビブラートが開始される遅延時間。 */
    delay,

    /** ビブラートの深さ。 */
    depth,

    /** ビブラートの周波数。 */
    freq,
}

/** 音源の種類を表した列挙体です。 */
public enum WaveformType
{
    /** 矩形波。 */
    square,

    /** 三角波。 */
    triangle,

    /** 線形帰還シフトレジスタによる短周期ノイズ。 */
    shortNoise,

    /** 線形帰還シフトレジスタによる長周期ノイズ。 */
    longNoise,

    /** 擬似乱数ジェネレータによるノイズ。 */
    randomNoise,

    /** FM 音源。 */
    fm,
}

/** ポルタメントに作用するオプションを表した列挙体です。 */
public enum PortamentOperate
{
    /** ポルタメント無効。 */
    off,

    /** ポルタメント有効。 */
    on,

    /** ポルタメントの速さ。 */
    speed,
}
