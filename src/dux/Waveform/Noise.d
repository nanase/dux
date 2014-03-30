/** dux - ux implementation for D
 *
 * Authors: Tomona Nanase
 * License: The MIT License (MIT)
 * Copyright: Copyright (c) 2014 Tomona Nanase
 */

module dux.Component.Noise;

import std.algorithm;
import std.conv;

import dux.Component.Enums;
import dux.Component.Waveform;
import dux.Component.StepWaveform;
import dux.Component.CachedWaveform;
import dux.Utils.JKissEngine;

class LongNoise : StepWaveform
{
private:
    static float[] data;
    static const int DataSize = 32767;

private:
    static this()
    {
        ushort reg = 0xffff;
        ushort output = 1;
        
        data = new float[DataSize];
        
        for (int i = 0; i < DataSize; i++)
        {
            reg += cast(ushort)(reg + (((reg >> 14) ^ (reg >> 13)) & 1));
            data[i] = (output ^= cast(ushort)(reg & 1)) * 2.0f - 1.0f;
        }
    }

public:
    override void reset()
    {
        this.freqFactor = 0.001;
        this.value = data;
        this.length = DataSize;
    }
}

class ShortNoise : StepWaveform
{
private:
    static float[] data;
    static const int DataSize = 127;

private:
    static this()
    {
        ushort reg = 0xffff;
        ushort output = 1;
        
        data = new float[DataSize];
        
        for (int i = 0; i < DataSize; i++)
        {
            reg += cast(ushort)(reg + (((reg >> 6) ^ (reg >> 5)) & 1));
            data[i] = (output ^= cast(ushort)(reg & 1)) * 2.0f - 1.0f;
        }
    }
    
public:
    override void reset()
    {
        this.freqFactor = 0.001;
        this.value = data;
        this.length = DataSize;
    }
}

class RandomNoiseCache : CacheObject!RandomNoiseCache
{
private:
    float[] data;
    int stepSeed;
    size_t arrayLength;
    
public:
    @property float[] dataValue() { return this.data; }

    @property float[] dataValue(float[] value) { return this.data = value; }

    @property int seed() { return this.stepSeed; }

    @property size_t length() { return this.arrayLength; }

public:  
    this(int seed, size_t length)
    {
        this.stepSeed = seed;
        this.arrayLength = length;
    }

public:
    bool equals(RandomNoiseCache other)
    {
        return this.stepSeed == other.stepSeed && this.arrayLength == other.arrayLength;
    }
    
    bool canResize(RandomNoiseCache other)
    {
        return this.stepSeed == other.stepSeed && this.arrayLength >= other.arrayLength;
    }
}

class RandomNoise : CachedWaveform!RandomNoiseCache
{
private:
    RandomNoiseCache param;


protected:
    @property override bool canResizeData() { return true; }
    
    @property override bool generatingFloat() { return true; }

public:
    override void reset()
    {
        this.freqFactor = 1.0;
        this.param = new RandomNoiseCache(0, 1024);
        this.generateStep();
    }
    
    override void setParameter(int data1, float data2)
    {
        switch (data1)
        {
            case RandomNoiseOperate.seed:
                this.param = new RandomNoiseCache(to!int(data2), this.param.length);
                break;

            case RandomNoiseOperate.length:
                int length = to!int(data2);
                if (length > 0 && length <= MaxDataSize)
                    this.param = new RandomNoiseCache(this.param.seed, length);
                break;
                
            default:
                super.setParameter(data1, data2);
                break;
        }
        
        this.generateStep();
    }

protected:
    override float[] generateFloat(RandomNoiseCache parameter)
    {
        float[] value = new float[parameter.length];
        
        JKissEngine r = JKissEngine(parameter.seed);
        
        for (int i = 0; i < parameter.length; i++)
        {
            value[i] = to!float(r.nextReal() * 2.0 - 1.0);
            r.popFront();
        }

        return value;
    }

private:
    void generateStep()
    {
        this.cache(this.param);
    }
}
