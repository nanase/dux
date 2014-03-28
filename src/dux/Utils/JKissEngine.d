/** dux - ux implementation for D
 *
 * Authors: Tomona Nanase
 * License: The MIT License (MIT)
 * Copyright: Copyright (c) 2014 Tomona Nanase
 */

// refer to https://github.com/mono/mono/blob/mono-3.2.8/mcs/class/corlib/System/Random.cs

//
// System.Random.cs
//
// Authors:
// Bob Smith (bob@thestuff.net)
// Ben Maurer (bmaurer@users.sourceforge.net)
// Sebastien Pouliot <sebastien@xamarin.com>
//
// (C) 2001 Bob Smith. http://www.thestuff.net
// (C) 2003 Ben Maurer
// Copyright (C) 2004 Novell, Inc (http://www.novell.com)
// Copyright 2013 Xamarin Inc. (http://www.xamarin.com)
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

module dux.Utils.JKissEngine;

import std.random : isUniformRNG, isSeedable;

struct JKissEngine
{
private:
    uint x, y, z, c, r;
    
public:
    /// Mark this as a Rng
    enum bool isUniformRandom = true;

public:
    this(uint value)
    {
        this.seed(value);
    }

public:
    void seed(uint value)
    {
        this.x = value;
        this.y = 987654321u;
        this.z = 43219876u;
        this.c = 6543217u;

        popFront();
    }

    int next()
    out(result)
    {
        assert(result >= 0);
    }
    body
    {
        // returns a non-negative, [0 - Int32.MacValue], random number
        // but we want to avoid calls to Math.Abs (call cost and branching cost it requires)
        // and the fact it would throw for Int32.MinValue (so roughly 1 time out of 2^32)
        int random = cast(int) this.r;
        
        while (random == int.min)
        {
            this.popFront();
            random = cast(int) this.r;
        }

        int mask = random >> 31;
        random ^= mask;

        return cast(uint)(random + (mask & 1));
    }
    
    int next(int maxValue)
    {
        return maxValue > 0 ? cast(int)(this.r % maxValue) : 0;
    }
    
    int next(int minValue, int maxValue)
    in
    {
        assert(minValue <= maxValue);
    }
    out(result)
    {
        assert(result >= minValue && result < maxValue);
    }
    body
    {
        // special case: a difference of one (or less) will always return the minimum
        // e.g. -1,-1 or -1,0 will always return -1
        uint diff = cast(uint)(maxValue - minValue);
        
        if (diff <= 1)
            return minValue;
        
        return minValue + cast(int)(this.r % diff);
    }
    
    real nextReal()
    out(result)
    {
        assert(result >= 0.0 && result < 1.0);
    }
    body
    {
        // a single 32 bits random value is not enough to create a random double value
        uint a = this.r >> 6; // Upper 26 bits
        this.popFront();
        uint b = this.r >> 5; // Upper 27 bits
        return (a * 134217728.0 + b) / 9007199254740992.0;
    }
    
    void popFront()
    {
        this.r = this.JKiss();
    }
    
    @property uint front()
    {
        return this.next();
    }
    
    @property typeof(this) save()
    {
        return this;
    }
    
    enum bool empty = false;
    
private:
    uint JKiss()
    {
        this.x = 314527869u * this.x + 1234567u;
        this.y ^= this.y << 5;
        this.y ^= this.y >> 7;
        this.y ^= this.y << 22;
        ulong t = (4294584393UL * this.z + this.c);
        this.c = cast(uint)(t >> 32);
        this.z = cast(uint)t;
        return (this.x + this.y + this.z);
    }
}


unittest
{
    static assert(isUniformRNG!JKissEngine);
    static assert(isUniformRNG!(JKissEngine, uint));
    static assert(isSeedable!JKissEngine);
    static assert(isSeedable!(JKissEngine, uint));
}
