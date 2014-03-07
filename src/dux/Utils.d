module dux.Utils;

public:
T clamp(T)(T max_value, T min_value, T value)
    in
    {
        assert(min_value <= max_value);
    }
    out(result)
    {
        assert(min_value <= result);
        assert(max_value >= result);
    }
    body
    {
        return (value < min_value) ? min_value : ((value > max_value) ? max_value : value);
    }