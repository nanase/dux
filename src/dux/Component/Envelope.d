module dux.Component.Envelope;

import dux.Component.Enums;
import dux.Component.EnvelopeState;
import dux.Utils;

public class Envelope
{
private:
    int releaseStartTime, t2, t3, t5, _attackTime, _peakTime, _decayTime, _releaseTime;
    float da, dd, dr, _sustainLevel, releaseStartLevel;
    EnvelopeState _state;

public:
    immutable float samplingRate;

public:
    @property EnvelopeState state() { return this._state; }

    @property float attackTime() { return this._attackTime / this.samplingRate; }
    @property float attackTime(float value) 
    {
        return this._attackTime = cast(int)(clamp(0.0f, float.max, value) * this.samplingRate);
    }

    @property float peakTime() { return this._peakTime / this.samplingRate; }
    @property float peakTime(float value) 
    {
        return this._peakTime = cast(int)(clamp(0.0f, float.max, value) * this.samplingRate);
    }

    @property float decayTime() { return this._decayTime / this.samplingRate; }
    @property float decayTime(float value) 
    {
        return this._decayTime = cast(int)(clamp(0.0f, float.max, value) * this.samplingRate);
    }

    @property float sustainLevel() { return this._sustainLevel; }
    @property float sustainLevel(float value) 
    {
        return this._sustainLevel = clamp(0.0f, 1.0f, value);
    }

    @property float releaseTime() { return this._releaseTime / this.samplingRate; }
    @property float releaseTime(float value) 
    {
        return this._releaseTime = cast(int)(clamp(0.0f, float.max, value) * this.samplingRate);
    }

public:
    this(float samplingRate)
    {
        this.samplingRate = samplingRate;
        this.reset();
    }

public:
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

    void silence()
        out
        {
            assert(this._state == EnvelopeState.silence);
        }
        body
        {
            this._state = EnvelopeState.silence;
        }

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

    void setParameter(int data1, float data2)
    {
        switch (cast(EnvelopeOperate)data1)
        {
            case EnvelopeOperate.attack:
                this._attackTime = cast(int)(clamp(0.0f, float.max, data2) * this.samplingRate);
                break;
                
            case EnvelopeOperate.peak:
                this._peakTime = cast(int)(clamp(0.0f, float.max, data2) * this.samplingRate);
                break;

            case EnvelopeOperate.decay:
                this._decayTime = cast(int)(clamp(0.0f, float.max, data2) * this.samplingRate);
                break;
                
            case EnvelopeOperate.sustain:
                this._sustainLevel = clamp(0.0f, 1.0f, data2);
                break;
                
            case EnvelopeOperate.release:
                this._releaseTime = cast(int)(clamp(0.0f, float.max, data2) * this.samplingRate);
                break;
                
            default:
                break;
        }
    }

public:
    static Envelope CreateConstant(float samplingRate)
        in
        {
            assert(samplingRate > 0.0f);
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
