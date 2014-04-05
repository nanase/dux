﻿/** dux - ux implementation for D
 *
 * Authors: Tomona Nanase
 * License: The MIT License (MIT)
 * Copyright: Copyright (c) 2014 Tomona Nanase
 */

module dux.Master;

import std.algorithm;
import std.container;
import std.math;
import std.range;

import dux.Utils.Algorithm;
import dux.Component.Exception;
import dux.Component.Handle;
import dux.Component.Part;

class Master
{
private:
    static const float DefaultSamplingRate = 44100.0f;
    static const size_t DefaultPartCount = 16;

private:
    immutable float _samplingRate;
    immutable size_t _partCount;

private:
    Part[] parts;
    DList!Handle handleQueue;
    float _masterVolume = 1.0f;
    bool _isPlaying;

    float gain, upover, downover;
    float compressorThreshold = 0.8f;
    float compressorRatio = 1.0f / 2.0f;

public:
    @property float samplingRate() { return this._samplingRate; }
    
    @property bool isPlaying() { return this._isPlaying; }
    
    @property size_t partCount() { return this._partCount; }
    
    @property size_t toneCount() { return this.parts.count!("a.isSounding"); }
    
    @property float threshold() { return this.compressorThreshold; }

    @property float threshold(float value)
    {
        if (!isFinite(value))
            throw new OutOfRangeException();
       
        if (value < 0.0f)
            throw new OutOfRangeException();
            
        this.compressorThreshold = value;
            
        this.prepareCompressor();

        return value;
    }
    
    @property float ratio() { return this.compressorRatio; }

    @property float ratio(float value)
    {
        if (!isFinite(value))
            throw new OutOfRangeException();

        if (value < 0.0f)
            throw new OutOfRangeException();
            
        this.compressorRatio = value;
            
        this.prepareCompressor();

        return value;
    }
    
    @property float masterVolume() { return this._masterVolume; }

    @property float masterVolume(float value) 
    {
        if (!isFinite(value))
            throw new OutOfRangeException();

        this.masterVolume = value.clamp(2.0f, 0.0f);

        return value;
    }
    
public:
    this()
    {
        this(DefaultSamplingRate, DefaultPartCount);
    }

    this(float samplingRate, size_t partCount)
    {
        if (samplingRate > 0.0f && samplingRate <= float.max)
            this._samplingRate = samplingRate;
        else
            throw new OutOfRangeException("samplingRate",
                                                  samplingRate,
                                                  "指定されたサンプリング周波数は無効です。");

        if (partCount < 0)
            throw new OutOfRangeException("partCount",
                                                  partCount,
                                                  "無効なパート数が渡されました。");
        
        this._partCount = partCount;
        
        this.parts = new Part[partCount];
        
        for (size_t i = 0; i < this.partCount; i++)
            this.parts[i] = new Part(this.samplingRate);
        
        this.reset();
        this.prepareCompressor();
    }

public:
    void play()
    {
        this._isPlaying = true;
    }
    
    void stop()
    {
        if (!this._isPlaying)
            return;
        
        this.release();
        this._isPlaying = false;
    }

    void release()
    {
        for (int i = 0; i < this.partCount; i++)
            this.parts[i].release();
    }
    
    void silence()
    {
        for (int i = 0; i < this.partCount; i++)
            this.parts[i].silence();
    }

    void pushHandle(Handle handle)
    {
        synchronized (this)
            this.handleQueue.insertBack(handle);
    }
    
    void pushHandle(Range)(Handle handle, Range targetParts)
    {
        synchronized (this)
            foreach (int i; targetParts)
                this.handleQueue.insertBack(new Handle(handle, i));
    }
    
    void pushHandle(Range)(Range handles)
    {
        synchronized (this)
            foreach (Handle handle; handles)
                this.handleQueue.insertBack(handle);
    }
    
    void pushHandle(Range)(Range handles, int targetPart)
    {
        synchronized (this)
            foreach (Handle handle; handles)
                this.handleQueue.insertBack(new Handle(handle, targetPart));
    }

    void pushHandle(Range1, Range2)(Range1 handles, Range2 targetParts)
    {
        synchronized (this)
        {
            foreach (int part; parts)
                foreach (Handle handle; handles)
                    this.handleQueue.insertBack(new Handle(handle, part));
        }
    }
    
    int read(real[] buffer, int offset, int count)
    {
        // バッファクリア
        buffer.fill(0.0);

        // ハンドルの適用
        this.applyHandle();
        
        // count は バイト数
        // Part.Generate にはサンプル数を与える
        for (int k = 0; k < this.partCount; k++)
        {
            Part part = this.parts[k];
            
            if (part.isSounding)
            {
                part.generate(count / 2);
                
                // 波形合成
                for (int i = offset, j = 0; j < count; i++, j++)
                    buffer[i] += part.buffer[j];
            }
        }
        
        for (int i = offset, length = offset + count; i < length; i++)
        {
            real output = buffer[i] * this.masterVolume * this.gain;
            
            if (output == 0.0)
            {
                buffer[i] = 0.0;
            }
            else
            {
                // 圧縮
                if (output > this.compressorThreshold)
                    output = this.upover + this.compressorRatio * output;
                else if (output < -this.compressorThreshold)
                    output = this.downover + this.compressorRatio * output;
                
                // クリッピングと代入
                buffer[i] = output.clamp!real(1.0, -1.0);
            }
        }
        
        return count;
    }

    void reset()
    {
        for (int i = 0; i < this.partCount; i++)
            this.parts[i].reset();
    }

private:
    void applyHandle()
    {
        if (this.handleQueue[].walkLength == 0)
            return;
        
        synchronized (this)
        {
            foreach (Handle handle; this.handleQueue)
            {                
                if (handle.targetPart > 0 && handle.targetPart <= this.partCount)
                    this.parts[handle.targetPart - 1].applyHandle(handle);
            }
            
            this.handleQueue.clear();
        }
    }
    
    private void prepareCompressor()
    {
        float threshold = this.compressorThreshold;
        float ratio = this.compressorRatio;
        this.gain = 1.0f / (threshold + (1.0f - threshold) * ratio);
        this.upover = threshold * (1.0f - ratio);
        this.downover = -threshold * (1.0f - ratio);
    }
}