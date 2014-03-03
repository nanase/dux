module dux.Component.Enums;

public enum RandomNoiseOperate
{
    seed = 0x0100,
    length,
}

public enum BasicWaveformOperate
{
    duty = 0x0100,
    type,
}

public enum StepWaveformOperate
{
    freqFactor = 0x0000,
    begin,
    end,
    queue,
}

public enum FMOperate
{
    send0 = 0x0000,
    send1 = 0x0100,
    send2 = 0x0200,
    send3 = 0x0300,

    output = 0x0400,
    //out = output,
    Out = output,

    frequency = 0x0500,
    freq = frequency,

    operator0 = 0x0000,
    op0 = operator0,

    operator1 = 0x1000,
    op1 = operator1,

    operator2 = 0x2000,
    op2 = operator2,

    operator3 = 0x3000,
    op3 = operator3,
}

public enum EnvelopeOperate
{
    none = 0x00,

    attack = 0x01,
    a = attack,

    peak = 0x02,
    p = peak,

    decay = 0x03,
    d = decay,

    sustain = 0x04,
    s = sustain,

    release = 0x05,
    r = release,
}

public enum VolumeOperate
{
    volume,
    expression,
    velocity,
    gain,
}

public enum VibrateOperate
{
    off,
    on,
    delay,
    depth,
    freq,
}

public enum WaveformType
{
    square,
    triangle,
    shortNoise,
    longNoise,
    randomNoise,
    fm,
}

public enum PortamentOperate
{
    off,
    on,
    speed,
}
