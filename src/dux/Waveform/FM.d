/** dux - ux implementation for D
 *
 * Authors: Tomona Nanase
 * License: The MIT License (MIT)
 * Copyright: Copyright (c) 2014 Tomona Nanase
 */

module dux.Component.FM;

import std.math;

import dux.Utils.Algorithm;
import dux.Component.Enums;
import dux.Component.Envelope;
import dux.Component.Waveform;

class FM : Waveform
{
private:
    immutable float samplingRate;
    Operator op0, op1, op2, op3;

public:
    this(float samplingRate)
    {
        this.reset();
        this.samplingRate = samplingRate;
    }

public:
    void getWaveforms
        (float[] data, double[] frequency, double[] phase, int sampleTime, size_t count)
    {
        double omega, old0, old1, old2, old3, tmp;

        this.op0.generateEnvelope(sampleTime, count);
        this.op1.generateEnvelope(sampleTime, count);
        this.op2.generateEnvelope(sampleTime, count);
        this.op3.generateEnvelope(sampleTime, count);

        old0 = op0.old;
        old1 = op1.old;
        old2 = op2.old;
        old3 = op3.old;
        
        for (int i = 0; i < count; i++)
        {
            omega = 2.0 * PI * phase[i] * frequency[i];
            tmp = 0.0;
            
            if (op0.isSelected)
            {
                old0 =
                    sin(omega * op0.freqFactor +
                        op0.send0 * old0 * op0.send0EnvelopeBuffer[i] +
                        op1.send0 * old1 * op1.send0EnvelopeBuffer[i] +
                        op2.send0 * old2 * op2.send0EnvelopeBuffer[i] +
                        op3.send0 * old3 * op3.send0EnvelopeBuffer[i]);
                tmp += op0.outAmplifier * old0 * op0.outAmplifierEnvelopeBuffer[i];
            }

            if (op1.isSelected)
            {
                old1 =
                    sin(omega * op1.freqFactor +
                        op0.send1 * old0 * op0.send1EnvelopeBuffer[i] +
                        op1.send1 * old1 * op1.send1EnvelopeBuffer[i] +
                        op2.send1 * old2 * op2.send1EnvelopeBuffer[i] +
                        op3.send1 * old3 * op3.send1EnvelopeBuffer[i]);
                tmp += op1.outAmplifier * old1 * op1.outAmplifierEnvelopeBuffer[i];
            }

            if (op2.isSelected)
            {
                old2 =
                    sin(omega * op2.freqFactor +
                        op0.send2 * old0 * op0.send2EnvelopeBuffer[i] +
                        op1.send2 * old1 * op1.send2EnvelopeBuffer[i] +
                        op2.send2 * old2 * op2.send2EnvelopeBuffer[i] +
                        op3.send2 * old3 * op3.send2EnvelopeBuffer[i]);
                tmp += op2.outAmplifier * old2 * op2.outAmplifierEnvelopeBuffer[i];
            }

            if (op3.isSelected)
            {
                old3 =
                    sin(omega * op3.freqFactor +
                        op0.send3 * old0 * op0.send3EnvelopeBuffer[i] +
                        op1.send3 * old1 * op1.send3EnvelopeBuffer[i] +
                        op2.send3 * old2 * op2.send3EnvelopeBuffer[i] +
                        op3.send3 * old3 * op3.send3EnvelopeBuffer[i]);
                tmp += op3.outAmplifier * old3 * op3.outAmplifierEnvelopeBuffer[i];
            }
            
            data[i] = cast(float)tmp;
        }
        
        this.op0.old = old0;
        this.op1.old = old1;
        this.op2.old = old2;
        this.op3.old = old3;
    }

    void setParameter(int data1, float data2)
    {
        Operator op;
        switch (data1 & 0xf000)
        {
            case FMOperate.operator0: op = this.op0; break;
            case FMOperate.operator1: op = this.op1; break;
            case FMOperate.operator2: op = this.op2; break;
            case FMOperate.operator3: op = this.op3; break;
            default:
                return;
        }
        
        if ((data1 & 0x00ff) == 0)
        {
            switch (data1 & 0x0f00)
            {
                case FMOperate.output:
                    op.outAmplifier = data2.clamp(2.0f, 0.0f);
                    break;
                    
                case FMOperate.frequency:
                    op.freqFactor = data2;
                    break;

                case FMOperate.send0:
                    op.send0 = data2;
                    break;

                case FMOperate.send1:
                    op.send1 = data2;
                    break;
                    
                case FMOperate.send2:
                    op.send2 = data2;
                    break;
                    
                case FMOperate.send3:
                    op.send3 = data2;
                    break;
                    
                default:
                    break;
            }
        }
        else
        {
            switch (data1 & 0x0f00)
            {
                case FMOperate.output:
                    if (op.outAmplifierEnvelope is null)
                        op.outAmplifierEnvelope = Envelope.createConstant(this.samplingRate);
                    
                    op.outAmplifierEnvelope.setParameter(data1 & 0x00ff, data2);
                    break;
                    
                case FMOperate.frequency:
                    // Frequency に対するエンベロープは実装していない
                    break;
                    
                case FMOperate.send0:
                    if (op.send0Envelope is null)
                        op.send0Envelope = Envelope.createConstant(this.samplingRate);
                    
                    op.send0Envelope.setParameter(data1 & 0x00ff, data2);
                    break;
                    
                case FMOperate.send1:
                    if (op.send1Envelope is null)
                        op.send1Envelope = Envelope.createConstant(this.samplingRate);
                    
                    op.send1Envelope.setParameter(data1 & 0x00ff, data2);
                    break;
                    
                case FMOperate.send2:
                    if (op.send2Envelope is null)
                        op.send2Envelope = Envelope.createConstant(this.samplingRate);
                    
                    op.send2Envelope.setParameter(data1 & 0x00ff, data2);
                    break;
                    
                case FMOperate.send3:
                    if (op.send3Envelope is null)
                        op.send3Envelope = Envelope.createConstant(this.samplingRate);
                    
                    op.send3Envelope.setParameter(data1 & 0x00ff, data2);
                    break;
                    
                default:
                    break;
            }
        }

        this.selectProcessingOperator();
    }

    void attack()
    {
        this.op0.attack();
        this.op1.attack();
        this.op2.attack();
        this.op3.attack();
    }

    void release(int time)
    {
        this.op0.release(time);
        this.op1.release(time);
        this.op2.release(time);
        this.op3.release(time);
    }

    void reset()
    {
        this.op0 = new Operator(samplingRate);
        this.op1 = new Operator(samplingRate);
        this.op2 = new Operator(samplingRate);
        this.op3 = new Operator(samplingRate);

        // default presets
        this.op0.outAmplifier = 1.0;
        this.op0.send0 = 0.75;
        this.op1.send0 = 0.5;
        
        this.selectProcessingOperator();
    }

private:
    void selectProcessingOperator()
    {
        this.op0.isSelected = (this.op0.outAmplifier != 0.0);
        this.op1.isSelected = (this.op1.outAmplifier != 0.0);
        this.op2.isSelected = (this.op2.outAmplifier != 0.0);
        this.op3.isSelected = (this.op3.outAmplifier != 0.0);
        
        if (this.op0.isSelected)
        {
            if (!this.op1.isSelected && this.op1.send0 != 0.0)
                this.op1.isSelected = true;

            if (!this.op2.isSelected && this.op2.send0 != 0.0)
                this.op2.isSelected = true;

            if (!this.op3.isSelected && this.op3.send0 != 0.0)
                this.op3.isSelected = true;
        }
        
        if (this.op1.isSelected)
        {
            if (!this.op0.isSelected && this.op0.send1 != 0.0)
                this.op0.isSelected = true;

            if (!this.op2.isSelected && this.op2.send1 != 0.0)
                this.op2.isSelected = true;

            if (!this.op3.isSelected && this.op3.send1 != 0.0)
                this.op3.isSelected = true;
        }

        if (this.op2.isSelected)
        {
            if (!this.op0.isSelected && this.op0.send2 != 0.0)
                this.op0.isSelected = true;

            if (!this.op1.isSelected && this.op1.send2 != 0.0)
                this.op1.isSelected = true;

            if (!this.op3.isSelected && this.op3.send2 != 0.0)
                this.op3.isSelected = true;
        }
        
        if (this.op3.isSelected)
        {
            if (!this.op0.isSelected && this.op0.send3 != 0.0)
                this.op0.isSelected = true;

            if (!this.op1.isSelected && this.op1.send3 != 0.0)
                this.op1.isSelected = true;

            if (!this.op2.isSelected && this.op2.send3 != 0.0)
                this.op2.isSelected = true;
        }
    }

    ///
    unittest
    {
        FM fm = new FM(1);
        fm.op0.outAmplifier = 1.0;
        fm.op0.send0 = 0.75;
        fm.op1.send0 = 0.5;
        fm.selectProcessingOperator();

        assert(fm.op0.isSelected);
        assert(fm.op1.isSelected);
        assert(!fm.op2.isSelected);
        assert(!fm.op3.isSelected);

        //
        fm = new FM(1);
        fm.op0.outAmplifier = 1.0;
        fm.op0.send0 = 0.75;
        fm.op1.send0 = 0.0;
        fm.op1.send2 = 0.5;
        fm.op2.send1 = 0.75;
        fm.op3.send2 = 0.5;
        fm.selectProcessingOperator();
        
        assert(fm.op0.isSelected);
        assert(!fm.op1.isSelected);
        assert(!fm.op2.isSelected);
        assert(!fm.op3.isSelected);

        //
        fm = new FM(1);
        fm.op0.outAmplifier = 0.0;
        fm.op0.send0 = 0.5;
        fm.op0.send1 = 0.5;
        fm.op1.send2 = 0.5;
        fm.op2.send3 = 0.5;
        fm.op3.send0 = 0.5;
        fm.selectProcessingOperator();
        
        assert(!fm.op0.isSelected);
        assert(!fm.op1.isSelected);
        assert(!fm.op2.isSelected);
        assert(!fm.op3.isSelected);
    }
}

class Operator
{
public:
    double outAmplifier, freqFactor;
    double send0, send1, send2, send3;
    double old;
    bool isSelected;

    Envelope outAmplifierEnvelope;
    Envelope send0Envelope, send1Envelope, send2Envelope, send3Envelope;
    
    float[] outAmplifierEnvelopeBuffer;
    float[] send0EnvelopeBuffer, send1EnvelopeBuffer, send2EnvelopeBuffer, send3EnvelopeBuffer;
    float[] constantValues;

private:
    float samplingRate;

public:
    this(float samplingRate)
    {
        this.samplingRate = samplingRate;
        
        outAmplifier = 0.0f;
        freqFactor = 1.0f;
        send0 = 0.0f;
        send1 = 0.0f;
        send2 = 0.0f;
        send3 = 0.0f;
        old = 0.0f;
        isSelected = false;
        
        outAmplifierEnvelope = null;
        send0Envelope = null;
        send1Envelope = null;
        send2Envelope = null;
        send3Envelope = null;
        
        outAmplifierEnvelopeBuffer = new float[0];
        send0EnvelopeBuffer = new float[0];
        send1EnvelopeBuffer = new float[0];
        send2EnvelopeBuffer = new float[0];
        send3EnvelopeBuffer = new float[0];
    }

public:
    void attack()
    {
        if (this.outAmplifierEnvelope !is null)
            this.outAmplifierEnvelope.attack();
        
        if (this.send0Envelope !is null)
            this.send0Envelope.attack();
        
        if (this.send1Envelope !is null)
            this.send1Envelope.attack();
        
        if (this.send2Envelope !is null)
            this.send2Envelope.attack();
        
        if (this.send3Envelope !is null)
            this.send3Envelope.attack();
    }

    void release(int time)
    {
        if (this.outAmplifierEnvelope !is null)
            this.outAmplifierEnvelope.release(time);
        
        if (this.send0Envelope !is null)
            this.send0Envelope.release(time);
        
        if (this.send1Envelope !is null)
            this.send1Envelope.release(time);
        
        if (this.send2Envelope !is null)
            this.send2Envelope.release(time);
        
        if (this.send3Envelope !is null)
            this.send3Envelope.release(time);
    }
    
    void generateEnvelope(int sampleTime, size_t sampleCount)
    {
        if (this.outAmplifierEnvelopeBuffer.length < sampleCount)
            this.extendBuffer(sampleCount);
        
        if (this.outAmplifierEnvelope !is null)
            this.outAmplifierEnvelope.generate(sampleTime, this.outAmplifierEnvelopeBuffer, sampleCount);
        else
            this.outAmplifierEnvelopeBuffer[] = 1.0f;
        
        if (this.send0Envelope !is null)
            this.send0Envelope.generate(sampleTime, this.send0EnvelopeBuffer, sampleCount);
        else
            this.send0EnvelopeBuffer[] = 1.0f;
        
        if (this.send1Envelope !is null)
            this.send1Envelope.generate(sampleTime, this.send1EnvelopeBuffer, sampleCount);
        else
            this.send1EnvelopeBuffer[] = 1.0f;
        
        if (this.send2Envelope !is null)
            this.send2Envelope.generate(sampleTime, this.send2EnvelopeBuffer, sampleCount);
        else
            this.send2EnvelopeBuffer[] = 1.0f;
        
        if (this.send3Envelope !is null)
            this.send3Envelope.generate(sampleTime, this.send3EnvelopeBuffer, sampleCount);
        else
            this.send3EnvelopeBuffer[] = 1.0f;
    }

private:
    void extendBuffer(size_t length)
    {
        this.outAmplifierEnvelopeBuffer = new float[length];
        this.send0EnvelopeBuffer = new float[length];
        this.send1EnvelopeBuffer = new float[length];
        this.send2EnvelopeBuffer = new float[length];
        this.send3EnvelopeBuffer = new float[length];
    }
}