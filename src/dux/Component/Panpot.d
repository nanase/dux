module dux.Component.Panpot;

import std.algorithm;
import std.math;
import dux.Utils;

public struct Panpot
{
public:
    immutable float l, r;

public:
    this(float lChannel, float rChannel)
    {
        this.l = clamp(0.0f, 1.0f, lChannel);
        this.r = clamp(0.0f, 1.0f, rChannel);
    }

    this(float value)
        in
        {
            assert(isFinite(value));
        }
        body
        {
            this.l = value >= 0.0f ? cast(float)sin((value + 1f) * PI / 2.0) : 1.0f;
            this.r = value <= 0.0f ? cast(float)sin((-value + 1f) * PI / 2.0) : 1.0f;
        }

    invariant()
    {
        assert(this.l >= 0.0f && this.l <= 1.0f);
        assert(this.r >= 0.0f && this.r <= 1.0f);
    }
}

