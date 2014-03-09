/** dux - ux implementation for D
 *
 * Authors: Tomona Nanase
 * License: The MIT License (MIT)
 * Copyright: Copyright (c) 2014 Tomona Nanase
 */

module dux.Component.Waveform;

/** 周波数と位相から波形を生成するウェーブジェネレータのインタフェースです。 **/
interface Waveform
{
public:
    /** 与えられた周波数と位相から波形を生成します。
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
    in
    {
        assert(data.length == frequency.length);
        assert(data.length == phase.length);

        assert(sampleTime >= 0);
        assert(count <= data.length);
    }
    
    /** パラメータを指定して波形の設定値を変更します。
     *
     * Params:
     *      data1 = 整数パラメータ。
     *      data2 = 実数パラメータ。
     */
    void setParameter(int data1, float data2);
    
    /** エンベロープをアタック状態に遷移させます。 **/
    void attack();
    
    /** エンベロープをリリース状態に遷移させます。
     *
     * Params:
     *      time = リリースされたサンプル時間。
     */
    void release(int time)
    in
    {
        assert(time >= 0);
    }
    
    /** 波形のパラメータをリセットします。 */
    void reset();
}

