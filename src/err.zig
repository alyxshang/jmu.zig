// JMU.ZIG by Alyx Shang.
// Licensed under the FSL v1.

/// A data structure to catch
/// and handle errors in this
/// library.
pub const JMUErr = error {
    EmptyStr,
    WriteErr,
    AllocErr,
    ParseIntErr,
    ValueTypeErr,
    ParseFloatErr,
    UnexpectedChar,
    NoSuchFieldErr,
    UnexpectedToken,
    NumberParsingErr,
    UnexpectedStreamEnd
};
