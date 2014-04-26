/** dux - ux implementation for D
 *
 * Authors: Tomona Nanase
 * License: The MIT License (MIT)
 * Copyright: Copyright (c) 2014 Tomona Nanase
 */

module dux.Component.Part;

import std.math;
import std.conv;

import dux.Utils.Algorithm;
import dux.Component.Enums;
import dux.Component.Envelope;
import dux.Component.Handle;
import dux.Component.Waveform;
import dux.Component.Panpot;

/* 波形生成の単位となるパートクラスです。 */
class Part
{
private:
    static real[] noteFactor;
    static const float Amplifier = 0.5f;
    static const float A = 2.0;

private:
    immutable real sampleDeltaTime;
    Envelope envelope;
    immutable float samplingRate;

private:
    Waveform waveform;    
    float volume, expression, velocity, gain;
    real finetune, noteFreq, notePhase, noteFreqOld;
    real vibrateDepth, vibrateFreq, vibrateDelay, vibratePhase;
    real portamentSpeed;
    bool portament, vibrate;
    float[] smplBuffer, envlBuffer;
    double[] phasBuffer, freqBuffer;
    int sampleTime;
    Panpot panpot;
    int keyShift;
    float[] outputBuffer;

public:
    /* 生成された波形のバッファ配列を取得します。 */
    @property float[] buffer() { return this.outputBuffer; }

    /* このパートが発音状態にあるかを表す真偽値を取得します。 */
    @property bool isSounding() { return this.envelope.state != EnvelopeState.silence; }

private:
    static this()
    {
        noteFactor = new real[128];

        for (int i = 0; i < 128; i++)
            noteFactor[i] = (pow(2.0, (i - 69) / 12.0)) * 440.0;
    }
    
public:
    /* 新しい Part クラスのインスタンスを初期化します。
     * 
     * Params:
     *      samplingRate = マスタークラスでのサンプリング周波数。
     */
    this(float samplingRate)
    {
        this.envelope = new Envelope(samplingRate);
        this.outputBuffer = new float[0];
        this.reset();

        this.extendBuffers(0);
        this.sampleDeltaTime = 1.0 / samplingRate;
        this.samplingRate = samplingRate;
    }

public:
    /* 波形を生成します。
     * 
     * Params:
     *      sampleCount = 生成される波形のサンプル数。
     */
    void generate(size_t sampleCount)
    {
        // 未発音は除外
        if (!this.isSounding)
        {
            this.outputBuffer[] = 0.0f;
            return;
        }

        // サンプルバッファ更新
        if (this.smplBuffer.length < sampleCount)
            this.extendBuffers(sampleCount);
        
        // 出力バッファ更新
        if (this.outputBuffer.length < sampleCount * 2)
            this.outputBuffer = new float[to!int(sampleCount * 2.5)];
        else
            this.outputBuffer[] = 0.0f;
        
        // Generate Parameter
        for (int i = 0; i < sampleCount; i++)
        {
            // 目標周波数 - ビブラートを考慮
            double target_freq = this.noteFreq * this.finetune +
                ((this.vibrate && this.notePhase > this.vibrateDelay) ?
                 this.vibrateDepth * sin(2.0 * PI * this.vibrateFreq * this.vibratePhase) : 0.0);
            
            // 発音周波数 - ポルタメントを考慮
            double freq = (this.portament) ?
                this.noteFreqOld + (target_freq - this.noteFreqOld) * this.portamentSpeed : target_freq;
            
            // 位相修正
            this.notePhase *= (this.noteFreqOld / freq);
            
            // サンプルバッファへの代入
            this.freqBuffer[i] = freq;
            this.phasBuffer[i] = this.notePhase;
            
            // 時間と位相の加算
            this.notePhase += sampleDeltaTime;
            this.vibratePhase += sampleDeltaTime;
            this.noteFreqOld = freq;
        }
        
        // 波形生成
        this.envelope.generate(this.sampleTime, this.envlBuffer, sampleCount);
        this.waveform.getWaveforms(this.smplBuffer, this.freqBuffer, this.phasBuffer, this.sampleTime, sampleCount);
        
        // ログスケール計算。分母は各パラメータの標準値
        // (削除厳禁。最後の1.0はエンベロープ用)
        float vtmp = to!float((this.volume * this.expression * Part.Amplifier * this.velocity * this.gain) /
                              ( 1.0 * 1.0 * 1.0 * 1.0 * 1.0 * 1.0));
        
        // 波形出力
        for (int i = 0, j = 0; i < sampleCount; i++)
        {
            float c = this.smplBuffer[i] * (this.envlBuffer[i] * vtmp) ^^ Part.A;
            this.outputBuffer[j++] = c * this.panpot.l;
            this.outputBuffer[j++] = c * this.panpot.r;
        }
        
        this.sampleTime += sampleCount;
    }

    /* このパートに割当てられている設定値をリセットします。 */
    void reset()
    {
        import dux.Component.BasicWaveform;

        this.waveform = new Square();
        this.volume = to!float(1.0 / 1.27);
        this.expression = 1.0f;
        this.gain = 1.0f;
        this.panpot = Panpot(1.0f, 1.0f);
        this.vibrateDepth = 4.0;
        this.vibrateFreq = 4.0;
        this.vibrateDelay = 0.0;
        this.vibratePhase = 0.0;
        this.portamentSpeed = 1.0 * 0.001;
        this.portament = false;
        this.vibrate = false;
        this.velocity = 1.0f;
        
        this.sampleTime = 0;
        this.notePhase = 0.0;
        this.noteFreq = 0.0;
        this.noteFreqOld = 0.0;
        
        this.finetune = 1.0;
        this.keyShift = 0;
        
        this.envelope.reset();
    }

    /* 長さ 0 で指定されたノートで内部状態を変更します。エンベロープはアタック状態に遷移せず、発音されません。
     * 
     * Params:
     *      note = ノート値。
     */
    void zeroGate(int note)
    {
        this.vibratePhase = 0.0;
        
        int key = note + this.keyShift;

        if (this.portament)
            this.noteFreqOld = (key < 128 && key >= 0) ? noteFactor[key] : 0.0;
        else
            this.noteFreq = (key < 128 && key >= 0) ? noteFactor[key] : 0.0;
    }

    /* 指定されたノートでエンベロープをアタック状態に遷移させます。
     * 
     * Params:
     *      note = ノート値。
     */
    void attack(int note)
    {
        this.sampleTime = 0;
        this.notePhase = 0.0;
        
        this.vibratePhase = 0.0;

        int key = note + this.keyShift;
        this.noteFreq = (key < 128 && key >= 0) ? noteFactor[key] : 0.0;
        
        this.envelope.attack();
        this.waveform.attack();
    }

    /* エンベロープをリリース状態に遷移させます。 */
    void release()
    {
        this.envelope.release(this.sampleTime);
        this.waveform.release(this.sampleTime);
    }

    /* エンベロープをサイレンス状態に遷移させます。 */
    void silence()
    {
        this.envelope.silence();
    }

    /* このパートにハンドルを適用します。
     * 
     * Params:
     *      handle = 適用されるハンドル。
     */
    void applyHandle(Handle handle)
    {
        switch (handle.type)
        {
            //パラメータリセット
            case HandleType.reset:
                this.reset();
                break;
                
                //サイレンス
            case HandleType.silence:
                this.silence();
                break;

                //ボリューム設定
            case HandleType.volume:
                this.applyForVolume(handle.data1, handle.data2);
                break;
                
                //パンポット
            case HandleType.panpot:
                this.panpot = Panpot(handle.data2);
                break;
                
                //ビブラート
            case HandleType.vibrate:
                this.applyForVibrate(handle.data1, handle.data2);
                break;

                //波形追加
            case HandleType.waveform:
                this.applyForWaveform(handle.data1, handle.data2);
                break;

                //波形編集
            case HandleType.editWaveform:
                this.waveform.setParameter(handle.data1, handle.data2);
                break;

                //エンベロープ
            case HandleType.envelope:
                this.envelope.setParameter(handle.data1, handle.data2);
                break;
                
                //ファインチューン
            case HandleType.fineTune:
                this.finetune = handle.data2.clamp!float(float.max, 0.0f);
                break;
                
                //キーシフト
            case HandleType.keyShift:
                this.keyShift = handle.data1.clamp!int(128, -128);
                break;

                //ポルタメント
            case HandleType.portament:
                this.applyForPortament(handle.data1, handle.data2);
                break;

                //ゼロゲート
            case HandleType.zeroGate:
                this.zeroGate(handle.data1);
                break;

                //ノートオフ
            case HandleType.noteOff:
                this.release();
                break;
                
                //ノートオン
            case HandleType.noteOn:
                this.attack(handle.data1);
                this.velocity = handle.data2.clamp!float(1.0f, 0.0f);
                break;
                
            default:
                break;
        }
    }

private:
    void extendBuffers(size_t requireCount)
    {
        this.smplBuffer = new float[requireCount];
        this.envlBuffer = new float[requireCount];
        this.freqBuffer = new double[requireCount];
        this.phasBuffer = new double[requireCount];
    }
    
    void applyForVolume(int data1, float data2)
    {
        switch (data1)
        {
            case VolumeOperate.volume:
                this.volume = data2.clamp(1.0f, 0.0f);
                break;
                
            case VolumeOperate.expression:
                this.expression = data2.clamp(1.0f, 0.0f);
                break;

            case VolumeOperate.velocity:
                this.velocity = data2.clamp(1.0f, 0.0f);
                break;
                
            case VolumeOperate.gain:
                this.gain = data2.clamp(2.0f, 0.0f);
                break;
                
            default:
                break;
        }
    }
    
    void applyForVibrate(int data1, float data2)
    {
        switch (data1)
        {
            // ビブラート無効化
            case VibrateOperate.off:
                this.vibrate = false;
                break;
                
                // ビブラート有効化
            case VibrateOperate.on:
                this.vibrate = true;
                break;
                
                // ビブラートディレイ
            case VibrateOperate.delay:
                this.vibrateDelay = data2.clamp(float.max, 0.0f);
                break;

                // ビブラート深度
            case VibrateOperate.depth:
                this.vibrateDepth = data2.clamp(float.max, 0.0f);
                break;
                
                // ビブラート周波数
            case VibrateOperate.freq:
                this.vibrateFreq = data2.clamp(float.max, 0.0f);
                break;
                
            default:
                break;
        }
    }

    void applyForWaveform(int data1, float data2)
    {
        import dux.Component.BasicWaveform;
        import dux.Component.Noise;
        import dux.Component.StepWaveform;
        import dux.Component.FM;

        this.waveform.reset();

        switch (data1)
        {
            case WaveformType.square:
                if (!cast(Square)this.waveform)
                    this.waveform = new Square();
                break;
                
            case WaveformType.triangle:
                if (!cast(Triangle)this.waveform)
                    this.waveform = new Triangle();
                break;

            case WaveformType.shortNoise:
                if (!cast(ShortNoise)this.waveform)
                    this.waveform = new ShortNoise();
                break;
                
            case WaveformType.longNoise:
                if (!cast(LongNoise)this.waveform)
                    this.waveform = new LongNoise();
                break;
                
            case WaveformType.randomNoise:
                if (!cast(RandomNoise)this.waveform)
                    this.waveform = new RandomNoise();
                break;
                
            case WaveformType.fm:
                if (!cast(FM)this.waveform)
                    this.waveform = new FM(this.samplingRate);
                break;
                
            default:
                break;
        }
    }
    
    void applyForPortament(int data1, float data2)
    {
        switch (data1)
        {
            // ポルタメント無効化
            case PortamentOperate.off:
                this.portament = false;
                break;
                
                // ポルタメント有効化
            case PortamentOperate.on:
                this.portament = true;
                break;

                // ポルタメントスピード
            case PortamentOperate.speed:
                this.portamentSpeed = data2.clamp(1000.0f, float.epsilon * 1000.0f) *
                                      (0.001 * 44100.0) * this.sampleDeltaTime;
                break;
                
            default:
                break;
        }
    }
}