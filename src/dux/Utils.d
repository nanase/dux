module dux.Utils;

public:
T clamp(T)(T max_value, T min_value, T value)
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
        return (value < min_value) ? min_value : ((value > max_value) ? max_value : value);
    }