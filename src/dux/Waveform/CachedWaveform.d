/** dux - ux implementation for D
 *
 * Authors: Tomona Nanase
 * License: The MIT License (MIT)
 * Copyright: Copyright (c) 2014 Tomona Nanase
 */

module dux.Component.CachedWaveform;

import std.array;
import std.container;
import std.conv;
import std.range;
import std.typecons;
import std.typetuple;
import std.traits;

import dux.Component.StepWaveform;

abstract class CachedWaveform(T) : StepWaveform
if (staticIndexOf!(CacheObject!T, InterfacesTuple!T) >= 0)
{
protected:
    static DList!T cacheObjects;
    
protected:
    @property int maxCacheSize() { return 32; }
    
    @property bool canResizeData() { return false; }
    
    @property bool generatingFloat() { return false; }
    
protected:
    float[] generateFloat(T parameter)
    {
        return new float[1];
    }
    
    byte[] generate(T parameter)
    {
        return new byte[1];
    }
    
    void cache(T parameter)
    {
        foreach (now; cacheObjects)
        {
            if (now.equals(parameter))
            {
                this.value = now.dataValue;
                this.length = to!float(this.value.length);
                return;
            }
            else if (this.canResizeData && now.canResize(parameter))
            {
                this.value = new float[parameter.length];
                this.length = to!float(this.value.length);
                
                this.value[0 .. parameter.length] = now.dataValue[0 .. parameter.length];
                //Array.Copy(now.Value.DataValue, this.value, parameter.Length);
                
                parameter.dataValue = this.value;
                this.pushCache(parameter);
                return;
            }
        }
        
        if (this.generatingFloat)
        {
            this.value = this.generateFloat(parameter);
            this.length = to!float(this.value.length);
        }
        else
            this.setStep(this.generate(parameter)[]);
        
        parameter.dataValue = this.value;
        this.pushCache(parameter);
    }
    
    void pushCache(T parameter)
    {
        cacheObjects.insertFront(parameter);
        
        if (cacheObjects[].walkLength() > this.maxCacheSize)
            cacheObjects.removeBack();
    }
}

interface CacheObject(T)
{
    @property float[] dataValue();
    @property float[] dataValue(float[] value);

    @property size_t length();

    bool equals(T other);
    bool canResize(T other);
}
