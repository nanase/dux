/** dux - ux implementation for D
 *
 * Authors: Tomona Nanase
 * License: The MIT License (MIT)
 * Copyright: Copyright (c) 2014 Tomona Nanase
 */

module dux.Component.Exception;

import std.conv;

class OutOfRangeException : Exception
{
    this(string file = __FILE__, int line = __LINE__)
    {
        super("Value is out of range.", file, line);
    }

    this(T)(string parameterName, T parameter, string message, string file = __FILE__, int line = __LINE__)
    {
        super(parameterName ~ " (" ~ parameter.to!string ~ ") is out of range." ~ message, file, line);
    }
}

