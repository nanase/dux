module dux.Utils;

import std.algorithm;

public:
T clamp(T)(T min_value, T max_value, T value)
    in
    {
        assert(min_value <= max_value);
    }
    out
    {
        assert(min_value <= value);
        assert(max_value >= value);
    }
    body
    {
        return max(min_value, min(max_value, value));
    }