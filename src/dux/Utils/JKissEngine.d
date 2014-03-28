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

///
unittest
{
    static assert(isUniformRNG!JKissEngine);
    static assert(isUniformRNG!(JKissEngine, uint));
    static assert(isSeedable!JKissEngine);
    static assert(isSeedable!(JKissEngine, uint));
}

unittest
{
    JKissEngine rnd0 = JKissEngine(0);

    auto checking0 =
        [ 1557129256,  687739796, 1336126677,  311463913, 1414710373, 1033677075, 1193125177,
          1166579185,  840243025, 1748026103, 1133765672, 1514247009,  442009313,  765237586,
           921903266,  550243400, 1546664895,  851469654, 1938094296, 1040049397, 1406146328,
          1644279074,  531180808,  670452989, 1647103312, 1580822771,   95135780, 1450399338,
           663959627, 1044028917,  718253148, 1311666036, 2031954187,  270433405,  665456440,
           427132938,   74234043,  174507040,  233958091,  810948788, 1654128136, 1471071267,
          1952998224, 1209390383, 1747038228,  537451765, 2074389706, 1553986948,  197244310,
            16463372 ];

    // next method check
    foreach (e; checking0)
    {
        assert(rnd0.front == e);
        rnd0.popFront();
    }

    JKissEngine rnd1 = JKissEngine(-123456789);

    auto checking1 =
        [   406533351, -1830611537,  1227843810, -1798096270, -1624374572,   902071072,
            -47063122,  -532829508, -1203077170,  -707348692,  2038593343,  -446927142,
            646316014, -2032788379,  1950666661,  2032897779,   652018112,   590355545,
          -2072033969, -1360551642,   105894935,   589773589,   790922415,  1714243976,
            598117679,   -74453264,  1073486259,  -697139311,   854598618, -1578675512,
          -1911363741,  1353544159, -1246247094,  1473607750,   711877631,  1954867665,
           -355053772,  1965018003,   272052124,  1389689751, -1984079209, -1246905914,
           -663388857,  1430564586,   345075811,  1201894280,  -678311683,  -528570449,
           -474105495, -2127647625,  -629266336 ];

    // next(uint, uint) method check
    foreach (e; checking1)
    {
        assert(rnd1.next(int.min, int.max) == e);
        rnd1.popFront();
    }

    // seed method check
    rnd0.seed(-123456789);

    foreach (e; checking1)
    {
        assert(rnd0.next(int.min, int.max) == e);
        rnd0.popFront();
    }
}
