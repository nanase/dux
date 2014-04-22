/** dux - ux implementation for D
 *
 * Authors: Tomona Nanase
 * License: The MIT License (MIT)
 * Copyright: Copyright (c) 2014 Tomona Nanase
 */

module dux.Utils.Algorithm;

import std.algorithm;

T clamp(T)(T value, T maxValue, T minValue)
if(is(typeof(maxValue > minValue)))
in
{
    assert(minValue <= maxValue);
}
out(result)
{
    assert(minValue <= result);
    assert(maxValue >= result);
}
body
{
    return min(max(value, minValue), maxValue);
}

///
unittest
{
    assert(clamp(3.0, 2.0, 1.0) == 2.0);
    assert(clamp(1.9, 2.0, 1.0) == 1.9);
    assert(clamp(1.1, 2.0, 1.0) == 1.1);
    assert(0.9.clamp(2.0, 1.0) == 1.0);     // UFCS, value.clamp(max, min)

    // user-defined type
    import std.datetime;
    auto minDate = Date(2014, 3, 1),
         maxDate = Date(2014, 3, 7);

    assert(Date(2014, 3, 8).clamp(maxDate, minDate) == Date(2014, 3, 7));
    assert(Date(2014, 3, 6).clamp(maxDate, minDate) == Date(2014, 3, 6));
    assert(Date(2014, 3, 2).clamp(maxDate, minDate) == Date(2014, 3, 2));
    assert(Date(2014, 2, 28).clamp(maxDate, minDate) == Date(2014, 3, 1));
}
