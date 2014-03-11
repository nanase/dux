/** dux - ux implementation for D
 *
 * Authors: Tomona Nanase
 * License: The MIT License (MIT)
 * Copyright: Copyright (c) 2014 Tomona Nanase
 */

module dux.Component.StepWaveform;

import std.algorithm;
import std.array;
import std.container;
import std.conv;
import std.math;
import std.range;
import std.typecons;

import dux.Component.Enums;
import dux.Component.Waveform;
import dux.Utils;

class StepWaveform : Waveform
{
private:
    static immutable byte[1] emptyData = [0];
    DList!byte queue;

protected:
    const static float PI2 = PI * 2.0f;
    const static float PI_2 = PI * 0.5f;
    const static int MaxDataSize = 65536;

    float[] value;
    float length;
    double freqFactor = 1.0;

public:
    this()
    {
        this.reset();
    }

public:
    void getWaveforms
        (float[] data, double[] frequency, double[] phase, int sampleTime, size_t count)
    {        
        for (int i = 0; i < count; i++)
        {
            float tmp = to!float(phase[i] * frequency[i] * this.freqFactor);

            if (tmp < 0.0f)
                data[i] = 0.0f;
            else
                data[i] = this.value[to!int(tmp * this.length) % this.value.length];
        }
    }

    void setParameter(int data1, float data2)
    {
        switch (data1)
        {
            case StepWaveformOperate.freqFactor:
                this.freqFactor = data2.clamp(float.max, 0.0f) * 0.001;
                break;
                
            case StepWaveformOperate.begin:
                this.queue.clear();
                this.queue.insertFront(to!byte(data2.clamp(255.0f, 0.0f)));
                break;
                
            case StepWaveformOperate.end:
                this.queue.insertFront(to!byte(data2.clamp(255.0f, 0.0f)));

                if (this.queue[].walkLength() <= MaxDataSize)
                {
                    byte[] reverseQueue = new byte[this.queue[].walkLength()];
                    this.queue[].copy(reverseQueue);
                    reverseQueue.reverse();
                    this.setStep(reverseQueue[]);
                }

                break;
                
            case StepWaveformOperate.queue:
                this.queue.insertFront(to!byte(data2.clamp(255.0f, 0.0f)));
                break;
                
            default:
                break;
        }
    }

    void attack()
    {
    }

    void release(int time)
    {
    }

    void reset()
    {
        this.setStep(this.emptyData[]);
    }

    void setStep(Range)(Range data)
    if (isInputRange!Range && !isInfinite!Range)
    in
    {
       assert(data.walkLength() <= StepWaveform.MaxDataSize);
    }
    body
    {
        float max = to!float(data.minCount!("a > b")()[0]);
        float min = to!float(data.minCount!("a < b")()[0]);
        float a = 2.0f / (max - min);

        size_t dataLength = data.walkLength();
        this.length = to!float(dataLength);
        this.value = new float[dataLength];

        if (max == min)
        {
            this.value[] = 0.0f;
            return;
        }

        int i = 0;
        foreach (e; data)
        {
            this.value[i] = (e - min) * a - 1.0f;
            i++;
        }
    }

    ///
    unittest
    {
        static void test(Range1, Range2)(Range1 input, Range2 goal)
        {
            StepWaveform waveform = new StepWaveform();
            waveform.setStep(input);

            assert(equal(waveform.value[], goal));
        }

        test([0], [0.0f]);
        test([0, 1], [-1.0f, 1.0f]);
        test([0, 0], [0.0f, 0.0f]);

        test([4, 1, 3, 0], [1.0f, -0.5f, 0.5f, -1.0f]);
        test([0, 1, 2, 1], [-1.0f, 0.0f, 1.0f, 0.0f]);
    }
}
