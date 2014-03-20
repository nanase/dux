/** dux - ux implementation for D
 *
 * Authors: Tomona Nanase
 * License: The MIT License (MIT)
 * Copyright: Copyright (c) 2014 Tomona Nanase
 */

module dux.Component.BasicWaveform;

import std.algorithm;
import std.conv;
import std.container;
import std.range;
import std.typecons;

import dux.Component.Enums;
import dux.Component.Waveform;
import dux.Component.StepWaveform;
import dux.Component.CachedWaveform;
import dux.Utils;

class BaseWaveformCache : CacheObject!BaseWaveformCache
{
private:
    float[] data;
    int stepSeed;
    
public:
    @property float[] dataValue() { return this.data; }
    @property float[] dataValue(float[] value) { return this.data = value; }
    
    @property int step() { return this.stepSeed; }
    
    @property size_t length() { return this.data.length; }
    
public:
    this(int step)
    {
        this.stepSeed = step;
    }
    
public:
    bool equals(BaseWaveformCache other)
    {
        return this.stepSeed == other.stepSeed;
    }
    
    bool canResize(BaseWaveformCache other)
    {
        return false;
    }
}

class Square : CachedWaveform!BaseWaveformCache
{
public:
    override void setParameter(int data1, float data2)
    {
        switch (data1)
        {
            case BasicWaveformOperate.duty:
                this.generateStep(data2.clamp(1.0f, 0.0f));
                break;
                
            default:
                super.setParameter(data1, data2);
                break;
        }
    }

    override void reset()
    {
        this.generateStep(0.5f);
    }
    
protected:
    override byte[] generate(BaseWaveformCache parameter)
    {
        bool reverse = parameter.step < 0;
        int onTime = (reverse) ? -parameter.step : parameter.step;
        
        byte[] l = new byte[onTime + 1];
        
        if (reverse)
            // 10, 110, 1110, ...
            l[0 .. $ - 1] = 1;
        else
            // 10, 100, 1000, ...
            l[0] = 1;
        
        return l;
    }
    
private:
    void generateStep(float duty)
    {
        if (duty <= 0.0f || duty >= 1.0f)
            return;
        
        int onTime = to!int(1.0f / (duty <= 0.5f ? duty : (1.0f - duty))) - 1;
        
        if (onTime < 0 || onTime > MaxDataSize)
            return;
        
        if (duty > 0.5f)
            onTime = -onTime;
        
        this.cache(new BaseWaveformCache(onTime));
    }
}

class Triangle : CachedWaveform!BaseWaveformCache
{
public:
    override void reset()
    {
        this.generateStep(16);
    }
    
protected:
    override byte[] generate(BaseWaveformCache parameter)
    {
        byte[] l = new byte[parameter.step * 2];
        
        for (int i = 0; i < parameter.step; i++)
            l[i] = to!byte(i);
        
        for (int i = parameter.step; i < parameter.step * 2; i++)
            l[i] = to!byte(parameter.step * 2 - i - 1);
        
        return l;
    }
    
private:
    void generateStep(int step)
    {
        if (step <= 0 || step > 256)
            return;
        
        this.cache(new BaseWaveformCache(step));
    }
}