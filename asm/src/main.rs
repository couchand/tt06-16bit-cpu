enum Opcode {
    Text(u8),
    Nop,
    Halt,
    Trap,
    OutLo,
    OutHi,
    Push,
    Pop,
    Drop,
    Return,
    BranchIndirect,
    CallIndirect,
    Status,
    CallWord(u16),
    LoadImmediateWord(u16),
    Not,
    SetDataPointer,
    Test,
    LoadIndirect,// TODO: (AddressingMode),
    Load(Source),
    Store(Source),
    Add(Source),
    Sub(Source),
    And(Source),
    Or(Source),
    Xor(Source),
    Shift(Direction, ShiftSource),
    Branch(Target),
    Call(Target),
    If(Condition),
}

impl Opcode {
    fn encode(&self) -> Encoded {
        match self {
            Opcode::Text(v) => Encoded::U8(*v),
            Opcode::Nop => Encoded::U8(0x00),
            Opcode::Halt => Encoded::U8(0x01),
            Opcode::Trap => Encoded::U8(0x02),
            Opcode::Drop => Encoded::U8(0x03),
            Opcode::Push => Encoded::U8(0x04),
            Opcode::Pop => Encoded::U8(0x05),
            Opcode::Return => Encoded::U8(0x06),
            Opcode::Not => Encoded::U8(0x07),
            Opcode::OutLo => Encoded::U8(0x08),
            Opcode::OutHi => Encoded::U8(0x09),
            Opcode::SetDataPointer => Encoded::U8(0x0A),
            Opcode::Test => Encoded::U8(0x0B),
            Opcode::BranchIndirect => Encoded::U8(0x0C),
            Opcode::CallIndirect => Encoded::U8(0x0D),
            Opcode::Status => Encoded::U8(0x10),
            Opcode::CallWord(w) => Encoded::U8U16(0x3E, *w),
            Opcode::LoadImmediateWord(w) => Encoded::U8U16(0x3F, *w),
            //Opcode::LoadIndirect(m) => Encoded::U8(0x44 | m.encode()),
            Opcode::LoadIndirect => Encoded::U8(0x44),
            Opcode::Load(s) => s.encode(0x80),
            Opcode::Store(s) => s.encode(0x90),
            Opcode::Add(s) => s.encode(0x88),
            Opcode::Sub(s) => s.encode(0x98),
            Opcode::And(s) => s.encode(0xA0),
            Opcode::Or(s) => s.encode(0xA8),
            Opcode::Xor(s) => s.encode(0xB0),
            Opcode::Shift(d, s) => s.encode(0xB8, *d),
            Opcode::Branch(t) => t.encode(0xC0),
            Opcode::Call(t) => t.encode(0xD0),
            Opcode::If(c) => c.encode(0xF0),
        }
    }
}

enum Source {
    Const(ByteInWord, u8),
    Data(ByteInWord),
    Ram(RelativeTo, AddressingMode, u8),
}

impl Source {
    fn encode(&self, op: u8) -> Encoded {
        let mut res = u16::from(op) << 8;
        res |= match self {
            Source::Const(b, c) => b.encode() | u16::from(*c),
            Source::Data(b) => 0x0200 | b.encode(),
            Source::Ram(r, m, a) => {
                let opcode = 0x0400;
                let relative = u16::from(r.encode()) << 8;
                let mode = u16::from(m.encode()) << 8;
                let addr = u16::from(*a);
                opcode | relative | mode | addr
            }
        };
        Encoded::U16(res)
    }
}

#[derive(Clone, Copy)]
enum Direction {
    Left,
    Right,
}

impl Direction {
    fn encode(&self) -> u16 {
        match self {
            Direction::Left => 0,
            Direction::Right => 1,
        }
    }
}

enum ShiftSource {
    Const(u8),
    Data,
    Ram(RelativeTo, AddressingMode, u8),
}

impl ShiftSource {
    fn encode(&self, op: u8, d: Direction) -> Encoded {
        let mut res = u16::from(op) << 8;
        res |= match self {
            ShiftSource::Const(c) => (d.encode() << 8) | u16::from(*c),
            ShiftSource::Data => 0x0200 | d.encode(),
            ShiftSource::Ram(r, m, a) => {
                let opcode = 0x0400;
                let relative = u16::from(r.encode()) << 8;
                let mode = u16::from(m.encode()) << 8;
                let addr = 0xFFFE & u16::from(*a);
                opcode | relative | mode | addr | d.encode()
            }
        };
        Encoded::U16(res)
    }
}

enum RelativeTo {
    DataPointer,
    StackPointer,
}

impl RelativeTo {
    fn encode(&self) -> u8 {
        match self {
            RelativeTo::DataPointer => 0,
            RelativeTo::StackPointer => 2,
        }
    }
}

enum AddressingMode {
    Direct,
    Indirect,
}

impl AddressingMode {
    fn encode(&self) -> u8 {
        match self {
            AddressingMode::Direct => 0,
            AddressingMode::Indirect => 1,
        }
    }
}

enum ByteInWord {
    Lo,
    Hi,
}

impl ByteInWord {
    fn encode(&self) -> u16 {
        match self {
            ByteInWord::Lo => 0x0000,
            ByteInWord::Hi => 0x0100,
        }
    }
}

enum Target {
    I11(i16),
    U11(u16),
}

impl Target {
    fn encode(&self, op: u8) -> Encoded {
        let mut res = u16::from(op) << 8;
        res |= match self {
            Target::I11(v) => (*v as u16) & 0x07FF,
            Target::U11(v) => v & 0x07FF,
        };
        Encoded::U16(res)
    }
}

enum Condition {
    Zero,
    NotZero,
    Else,
    NotElse,
    Negative,
    NotNegative,
}

impl Condition {
    fn encode(&self, op: u8) -> Encoded {
        let mut res = u16::from(op) << 8;
        res |= match self {
            Condition::Zero        => 0x0000,
            Condition::NotZero     => 0x0001,
            Condition::Else        => 0x0002,
            Condition::NotElse     => 0x0003,
            Condition::Negative    => 0x0004,
            Condition::NotNegative => 0x0005,
            Condition::Carry       => 0x0006,
            Condition::NotCarry    => 0x0007,
        };
        Encoded::U16(res)
    }
}

enum Encoded {
    U16(u16),
    U8(u8),
    U8U16(u8, u16),
}

fn main() {
    let ops_insts = [
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Load(Source::Const(ByteInWord::Lo, 0x14)),
        Opcode::Add(Source::Const(ByteInWord::Lo, 0x1e)),
        Opcode::OutLo,
        Opcode::Nop,
        Opcode::Load(Source::Data(ByteInWord::Lo)),
        Opcode::Add(Source::Const(ByteInWord::Lo, 0x1e)),
        Opcode::OutLo,
        Opcode::Nop,
        Opcode::Load(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, 0x20)),
        Opcode::Add(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, 0x22)),
        Opcode::OutLo,
        Opcode::Nop,
        Opcode::Branch(Target::I11(0x0010)),
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Text(0x00),
        Opcode::Text(0x14),
        Opcode::Text(0x00),
        Opcode::Text(0x1e),
        Opcode::Load(Source::Const(ByteInWord::Lo, 0x5A)),
        Opcode::Branch(Target::I11(0x0008)),
        Opcode::Load(Source::Const(ByteInWord::Lo, 0xA5)),
        Opcode::OutLo,
        Opcode::Nop,
        Opcode::Load(Source::Const(ByteInWord::Lo, 0x00)),
        Opcode::Branch(Target::I11(0x07F4)),
        Opcode::OutLo,
        Opcode::Nop,
        Opcode::Load(Source::Data(ByteInWord::Lo)),
        Opcode::Test,
        Opcode::If(Condition::NotZero),
        Opcode::Branch(Target::I11(0x07F7)),
        Opcode::Load(Source::Const(ByteInWord::Lo, 0x09)),
        Opcode::Store(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, 0x20)),
        Opcode::Load(Source::Const(ByteInWord::Lo, 0x33)),
        Opcode::Load(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, 0x20)),
        Opcode::Add(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, 0x22)),
        Opcode::OutLo,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Load(Source::Const(ByteInWord::Lo, 0xFF)),
        Opcode::Sub(Source::Const(ByteInWord::Lo, 0xEE)),
        Opcode::OutLo,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Load(Source::Const(ByteInWord::Lo, 0xF0)),
        Opcode::And(Source::Const(ByteInWord::Lo, 0x3C)),
        Opcode::OutLo,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Load(Source::Const(ByteInWord::Lo, 0xF0)),
        Opcode::Or(Source::Const(ByteInWord::Lo, 0x3C)),
        Opcode::OutLo,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Load(Source::Const(ByteInWord::Lo, 0xF0)),
        Opcode::Xor(Source::Const(ByteInWord::Lo, 0x3C)),
        Opcode::OutLo,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Load(Source::Const(ByteInWord::Lo, 0xA5)),
        Opcode::Not,
        Opcode::OutLo,
        Opcode::Load(Source::Const(ByteInWord::Lo, 0x20)),
        Opcode::LoadIndirect,
        Opcode::OutLo,
        Opcode::Load(Source::Const(ByteInWord::Lo, 0x22)),
        Opcode::Store(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, 0x1E)),
        Opcode::Load(Source::Const(ByteInWord::Lo, 0)),
        Opcode::Load(Source::Ram(RelativeTo::DataPointer, AddressingMode::Indirect, 0x1E)),
        Opcode::OutLo,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Load(Source::Const(ByteInWord::Lo, 0x99)),
        Opcode::Push,
        Opcode::Nop,
        Opcode::Load(Source::Const(ByteInWord::Lo, 0x00)),
        Opcode::Load(Source::Ram(RelativeTo::StackPointer, AddressingMode::Direct, 0x00)),
        Opcode::OutLo,
        Opcode::Nop,
        Opcode::Load(Source::Const(ByteInWord::Lo, 0x00)),
        Opcode::Pop,
        Opcode::Nop,
        Opcode::Add(Source::Const(ByteInWord::Lo, 0x11)),
        Opcode::OutLo,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        // 0x90
        Opcode::Call(Target::U11(0x98)),
        Opcode::OutLo,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Branch(Target::I11(4)),
        // callee 0x98
        Opcode::Load(Source::Const(ByteInWord::Lo, 0x42)),
        Opcode::Return,
        Opcode::Nop,
        // after callee 0x9C
        Opcode::Load(Source::Const(ByteInWord::Lo, 0x22)),
        Opcode::Or(Source::Const(ByteInWord::Hi, 0x33)),
        Opcode::OutLo,
        Opcode::OutHi,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Trap,
        Opcode::Nop,
        Opcode::Load(Source::Const(ByteInWord::Lo, 0)),
        Opcode::Test,
        Opcode::If(Condition::NotZero),
        Opcode::Load(Source::Const(ByteInWord::Lo, 0xBD)),
        Opcode::If(Condition::Else),
        Opcode::Load(Source::Const(ByteInWord::Lo, 0xA4)),
        Opcode::OutLo,
        Opcode::Load(Source::Const(ByteInWord::Lo, 0)),
        Opcode::Test,
        Opcode::If(Condition::Zero),
        Opcode::Load(Source::Const(ByteInWord::Lo, 0xBD)),
        Opcode::If(Condition::NotElse),
        Opcode::Load(Source::Const(ByteInWord::Lo, 0xA5)),
        Opcode::OutLo,
        Opcode::Load(Source::Const(ByteInWord::Lo, 2)),
        Opcode::Store(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, 0x1E)),
        Opcode::Load(Source::Const(ByteInWord::Lo, 1)),
        Opcode::OutLo,
        Opcode::Shift(Direction::Left, ShiftSource::Const(1)),
        Opcode::OutLo,
        Opcode::Shift(Direction::Left, ShiftSource::Const(1)),
        Opcode::OutLo,
        Opcode::Shift(Direction::Left, ShiftSource::Const(1)),
        Opcode::OutLo,
        Opcode::Shift(Direction::Left, ShiftSource::Const(1)),
        Opcode::OutLo,
        Opcode::Shift(Direction::Left, ShiftSource::Const(1)),
        Opcode::OutLo,
        Opcode::Shift(Direction::Left, ShiftSource::Const(1)),
        Opcode::OutLo,
        Opcode::Shift(Direction::Left, ShiftSource::Const(1)),
        Opcode::OutLo,
        Opcode::Shift(Direction::Right, ShiftSource::Ram(RelativeTo::DataPointer, AddressingMode::Direct, 0x1E)),
        Opcode::OutLo,
        Opcode::Shift(Direction::Right, ShiftSource::Ram(RelativeTo::DataPointer, AddressingMode::Direct, 0x1E)),
        Opcode::OutLo,
        Opcode::Shift(Direction::Right, ShiftSource::Ram(RelativeTo::DataPointer, AddressingMode::Direct, 0x1E)),
        Opcode::OutLo,
        Opcode::Shift(Direction::Right, ShiftSource::Const(1)),
        Opcode::OutLo,
        Opcode::Shift(Direction::Right, ShiftSource::Const(1)),
        Opcode::OutLo,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Load(Source::Const(ByteInWord::Lo, 2)),
        Opcode::BranchIndirect,
        Opcode::Load(Source::Const(ByteInWord::Lo, 3)),
        Opcode::OutLo,
        Opcode::Load(Source::Const(ByteInWord::Lo, 0x98)),
        Opcode::CallIndirect,
        Opcode::OutLo,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::LoadImmediateWord(0xABCD),
        Opcode::OutHi,
        Opcode::OutLo,
        Opcode::CallWord(0x0098),
        Opcode::OutLo,
        Opcode::LoadImmediateWord(0xFFFF),
        Opcode::Test,
        Opcode::If(Condition::Negative),
        Opcode::Load(Source::Const(ByteInWord::Lo, 0x72)),
        Opcode::OutLo,
        Opcode::LoadImmediateWord(0xFFFF),
        Opcode::Test,
        Opcode::If(Condition::NotNegative),
        Opcode::Load(Source::Const(ByteInWord::Lo, 0x72)),
        Opcode::OutLo,
    ];

    let target = 0x50;
    let current = 0x52;
    let cursor = 0x54;
    let cache = 0x58;

    let br0 = 0x13;
    let br1 = 0x19;
    let loop_label = 0x1D;
    let br2 = 0x3D;
    let br3 = 0x45;
    let done = 0x45;

    let fib_memo_insts = [
        Opcode::Load(Source::Data(ByteInWord::Lo)),
        Opcode::Store(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, target)),
        Opcode::Load(Source::Const(ByteInWord::Lo, 1)),
        Opcode::Store(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, cache)),
        Opcode::Load(Source::Const(ByteInWord::Lo, 1)),
        Opcode::Store(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, cache + 2)),
        Opcode::Load(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, target)),
        Opcode::Test,
        Opcode::If(Condition::Zero),
        Opcode::Branch(Target::I11(done - br0)),
        Opcode::Sub(Source::Const(ByteInWord::Lo, 1)),
        Opcode::If(Condition::Zero),
        Opcode::Branch(Target::I11(done - br1)),
        Opcode::Load(Source::Const(ByteInWord::Lo, 2)),
        Opcode::Store(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, current)),
        // loop
        Opcode::Load(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, current)),
        Opcode::Add(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, current)),
        Opcode::Add(Source::Const(ByteInWord::Lo, cache)),
        Opcode::Store(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, cursor)),
        Opcode::Sub(Source::Const(ByteInWord::Lo, 2)),
        Opcode::LoadIndirect,
        Opcode::Store(Source::Ram(RelativeTo::DataPointer, AddressingMode::Indirect, cursor)),
        Opcode::Load(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, cursor)),
        Opcode::Sub(Source::Const(ByteInWord::Lo, 4)),
        Opcode::LoadIndirect,
        Opcode::Add(Source::Ram(RelativeTo::DataPointer, AddressingMode::Indirect, cursor)),
        Opcode::Store(Source::Ram(RelativeTo::DataPointer, AddressingMode::Indirect, cursor)),
        Opcode::OutLo,
        Opcode::Nop,
        Opcode::Load(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, target)),
        Opcode::Sub(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, current)),
        Opcode::If(Condition::Zero),
        Opcode::Branch(Target::I11(done - br2)),
        Opcode::Load(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, current)),
        Opcode::Add(Source::Const(ByteInWord::Lo, 1)),
        Opcode::Store(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, current)),
        Opcode::Branch(Target::I11(loop_label - br3)),
        // done
        Opcode::Load(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, target)),
        Opcode::Add(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, target)),
        Opcode::Add(Source::Const(ByteInWord::Lo, cache)),
        Opcode::LoadIndirect,
        Opcode::OutLo,
        Opcode::Halt,
        // target
        Opcode::Nop,
        Opcode::Nop,
        // current
        Opcode::Nop,
        Opcode::Nop,
        // cursor
        Opcode::Nop,
        Opcode::Nop,
        // cache
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
    ];

    let target_abs = 0x60;
    let target = 0x00;
    let current = 0x02;
    let cursor = 0x04;
    let pointer = 0x06;
    let cache = 0x08;

    let br0 = 0x17;
    let br1 = 0x1D;
    let loop_label = 0x21;
    let br2 = 0x47;
    let br3 = 0x4F;
    let done = 0x4F;

    let fib_framed_insts = [
        Opcode::Load(Source::Data(ByteInWord::Lo)),
        Opcode::Store(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, target_abs)),
        Opcode::Load(Source::Const(ByteInWord::Lo, target_abs)),
        Opcode::SetDataPointer,
        Opcode::Nop,
        Opcode::Load(Source::Const(ByteInWord::Lo, 1)),
        Opcode::Store(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, cache)),
        Opcode::Load(Source::Const(ByteInWord::Lo, 1)),
        Opcode::Store(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, cache + 2)),
        Opcode::Load(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, target)),
        Opcode::Test,
        Opcode::If(Condition::Zero),
        Opcode::Branch(Target::I11(done - br0)),
        Opcode::Sub(Source::Const(ByteInWord::Lo, 1)),
        Opcode::If(Condition::Zero),
        Opcode::Branch(Target::I11(done - br1)),
        Opcode::Load(Source::Const(ByteInWord::Lo, 2)),
        Opcode::Store(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, current)),
        // loop
        Opcode::Load(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, current)),
        Opcode::Add(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, current)),
        Opcode::Add(Source::Const(ByteInWord::Lo, cache)),
        Opcode::Store(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, cursor)),
        Opcode::Add(Source::Const(ByteInWord::Lo, target_abs)),
        Opcode::Store(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, pointer)),
        Opcode::Load(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, cursor)),
        Opcode::Sub(Source::Const(ByteInWord::Lo, 2)),
        Opcode::LoadIndirect,
        Opcode::Store(Source::Ram(RelativeTo::DataPointer, AddressingMode::Indirect, pointer)),
        Opcode::Load(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, cursor)),
        Opcode::Sub(Source::Const(ByteInWord::Lo, 4)),
        Opcode::LoadIndirect,
        Opcode::Add(Source::Ram(RelativeTo::DataPointer, AddressingMode::Indirect, pointer)),
        Opcode::Store(Source::Ram(RelativeTo::DataPointer, AddressingMode::Indirect, pointer)),
        Opcode::OutLo,
        Opcode::Nop,
        Opcode::Load(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, target)),
        Opcode::Sub(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, current)),
        Opcode::If(Condition::Zero),
        Opcode::Branch(Target::I11(done - br2)),
        Opcode::Load(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, current)),
        Opcode::Add(Source::Const(ByteInWord::Lo, 1)),
        Opcode::Store(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, current)),
        Opcode::Branch(Target::I11(loop_label - br3)),
        // done
        Opcode::Load(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, target)),
        Opcode::Add(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, target)),
        Opcode::Add(Source::Const(ByteInWord::Lo, cache)),
        Opcode::LoadIndirect,
        Opcode::OutLo,
        Opcode::Halt,
        // target
        Opcode::Nop,
        Opcode::Nop,
        // current
        Opcode::Nop,
        Opcode::Nop,
        // cursor
        Opcode::Nop,
        Opcode::Nop,
        // cache
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
    ];

    let fib_fn = 8;
    let br1 = 15;
    let br2 = 21;
    let just_one = 38;

    let fib_recursive_insts = [
        Opcode::Load(Source::Data(ByteInWord::Lo)),
        Opcode::Push,
        Opcode::Nop,
        Opcode::Call(Target::U11(fib_fn)),
        Opcode::OutLo,
        Opcode::Halt,
        // fib_fn
        Opcode::Load(Source::Ram(RelativeTo::StackPointer, AddressingMode::Direct, 2)),
        Opcode::Test,
        Opcode::If(Condition::Zero),
        Opcode::Branch(Target::U11(just_one - br1)),
        Opcode::Sub(Source::Const(ByteInWord::Lo, 1)),
        Opcode::If(Condition::Zero),
        Opcode::Branch(Target::U11(just_one - br2)),
        Opcode::Push,
        Opcode::Call(Target::U11(fib_fn)),
        Opcode::Drop,
        Opcode::Push,
        Opcode::Load(Source::Ram(RelativeTo::StackPointer, AddressingMode::Direct, 4)),
        Opcode::Sub(Source::Const(ByteInWord::Lo, 2)),
        Opcode::Push,
        Opcode::Call(Target::U11(fib_fn)),
        Opcode::Drop,
        Opcode::Add(Source::Ram(RelativeTo::StackPointer, AddressingMode::Direct, 0)),
        Opcode::Drop,
        Opcode::Return,
        // just_one
        Opcode::Load(Source::Const(ByteInWord::Lo, 1)),
        Opcode::Return,
        Opcode::Nop,
    ];

    run("ops.mem", &ops_insts).unwrap();
    run("fib_memo.mem", &fib_memo_insts).unwrap();
    run("fib_framed.mem", &fib_framed_insts).unwrap();
    run("fib_recursive.mem", &fib_recursive_insts).unwrap();

    run("op_halt.mem", &[
        Opcode::Load(Source::Const(ByteInWord::Lo, 0)),
        Opcode::Test,
        Opcode::If(Condition::NotZero),
        Opcode::Halt,
        Opcode::Load(Source::Const(ByteInWord::Lo, 0)),
        Opcode::Test,
        Opcode::If(Condition::NotZero),
        Opcode::Nop,
        Opcode::If(Condition::NotElse),
        Opcode::Halt,
        Opcode::Load(Source::Const(ByteInWord::Lo, 0)),
        Opcode::Test,
        Opcode::If(Condition::Zero),
        Opcode::Nop,
        Opcode::If(Condition::Else),
        Opcode::Halt,
        Opcode::Load(Source::Const(ByteInWord::Lo, 1)),
        Opcode::OutLo,
        Opcode::Halt,
    ]).unwrap();

    run("op_trap.mem", &[
        Opcode::Load(Source::Const(ByteInWord::Lo, 0)),
        Opcode::Test,
        Opcode::If(Condition::NotZero),
        Opcode::Trap,
        Opcode::Load(Source::Const(ByteInWord::Lo, 0)),
        Opcode::Test,
        Opcode::If(Condition::NotZero),
        Opcode::Nop,
        Opcode::If(Condition::NotElse),
        Opcode::Trap,
        Opcode::Load(Source::Const(ByteInWord::Lo, 0)),
        Opcode::Test,
        Opcode::If(Condition::Zero),
        Opcode::Nop,
        Opcode::If(Condition::Else),
        Opcode::Trap,
        Opcode::Load(Source::Const(ByteInWord::Lo, 1)),
        Opcode::OutLo,
        Opcode::Trap,
        Opcode::Load(Source::Const(ByteInWord::Lo, 2)),
        Opcode::OutLo,
    ]).unwrap();

    run("op_push.mem", &[
        Opcode::Load(Source::Const(ByteInWord::Lo, 0x42)),
        Opcode::Push,
        Opcode::Load(Source::Const(ByteInWord::Lo, 1)),
        Opcode::Test,
        Opcode::If(Condition::Zero),
        Opcode::Push,
        Opcode::Load(Source::Const(ByteInWord::Lo, 2)),
        Opcode::Test,
        Opcode::If(Condition::Zero),
        Opcode::Nop,
        Opcode::If(Condition::NotElse),
        Opcode::Push,
        Opcode::Load(Source::Const(ByteInWord::Lo, 3)),
        Opcode::Test,
        Opcode::If(Condition::NotZero),
        Opcode::Nop,
        Opcode::If(Condition::Else),
        Opcode::Push,
        Opcode::Load(Source::Const(ByteInWord::Lo, 4)),
        Opcode::Test,
        Opcode::If(Condition::NotZero),
        Opcode::Push,
        Opcode::Load(Source::Const(ByteInWord::Lo, 0)),
        Opcode::Pop,
        Opcode::OutLo,
        Opcode::Pop,
        Opcode::OutLo,
    ]).unwrap();

    run("op_pop.mem", &[
        Opcode::Load(Source::Const(ByteInWord::Lo, 5)),
        Opcode::Push,
        Opcode::Load(Source::Const(ByteInWord::Lo, 4)),
        Opcode::Push,
        Opcode::Load(Source::Const(ByteInWord::Lo, 3)),
        Opcode::Push,
        Opcode::Load(Source::Const(ByteInWord::Lo, 2)),
        Opcode::Push,
        Opcode::Load(Source::Const(ByteInWord::Lo, 1)),
        Opcode::Push,
        Opcode::Load(Source::Const(ByteInWord::Lo, 9)),
        Opcode::If(Condition::Zero),
        Opcode::Pop,
        Opcode::Load(Source::Const(ByteInWord::Lo, 8)),
        Opcode::Test,
        Opcode::If(Condition::Zero),
        Opcode::Nop,
        Opcode::If(Condition::NotElse),
        Opcode::Pop,
        Opcode::Load(Source::Const(ByteInWord::Lo, 7)),
        Opcode::Test,
        Opcode::If(Condition::NotZero),
        Opcode::Nop,
        Opcode::If(Condition::Else),
        Opcode::Pop,
        Opcode::Pop,
        Opcode::OutLo,
        Opcode::Pop,
        Opcode::OutLo,
        Opcode::Pop,
        Opcode::OutLo,
        Opcode::Pop,
        Opcode::OutLo,
        Opcode::Pop,
        Opcode::OutLo,
    ]).unwrap();

    run("op_drop.mem", &[
        Opcode::Load(Source::Const(ByteInWord::Lo, 5)),
        Opcode::Push,
        Opcode::Load(Source::Const(ByteInWord::Lo, 4)),
        Opcode::Push,
        Opcode::Load(Source::Const(ByteInWord::Lo, 3)),
        Opcode::Push,
        Opcode::Load(Source::Const(ByteInWord::Lo, 2)),
        Opcode::Push,
        Opcode::Load(Source::Const(ByteInWord::Lo, 1)),
        Opcode::Push,
        Opcode::Load(Source::Const(ByteInWord::Lo, 9)),
        Opcode::Test,
        Opcode::If(Condition::Zero),
        Opcode::Drop,
        Opcode::Load(Source::Const(ByteInWord::Lo, 8)),
        Opcode::Test,
        Opcode::If(Condition::Zero),
        Opcode::Nop,
        Opcode::If(Condition::NotElse),
        Opcode::Drop,
        Opcode::Load(Source::Const(ByteInWord::Lo, 7)),
        Opcode::Test,
        Opcode::If(Condition::NotZero),
        Opcode::Nop,
        Opcode::If(Condition::Else),
        Opcode::Drop,
        Opcode::Pop,
        Opcode::OutLo,
        Opcode::Drop,
        Opcode::OutLo,
        Opcode::Pop,
        Opcode::OutLo,
        Opcode::Drop,
        Opcode::OutLo,
        Opcode::Pop,
        Opcode::OutLo,
    ]).unwrap();

    run("op_test.mem", &[
        Opcode::Load(Source::Const(ByteInWord::Lo, 0xFF)),
        Opcode::OutLo,
        Opcode::LoadImmediateWord(0x0000),
        Opcode::Test,
        Opcode::If(Condition::Zero),
        Opcode::OutLo,
        Opcode::LoadImmediateWord(0x0001),
        Opcode::Test,
        Opcode::If(Condition::Zero),
        Opcode::OutLo,
        Opcode::LoadImmediateWord(0x0001),
        Opcode::Test,
        Opcode::If(Condition::NotZero),
        Opcode::OutLo,
        Opcode::LoadImmediateWord(0x0000),
        Opcode::Test,
        Opcode::If(Condition::NotZero),
        Opcode::OutLo,
    ]).unwrap();

    run("fault.mem", &[
        Opcode::Store(Source::Const(ByteInWord::Lo, 0)),
    ]).unwrap();

    run("op_status.mem", &[
        Opcode::Load(Source::Const(ByteInWord::Lo, 0)),
        Opcode::Test,
        Opcode::Status,
        Opcode::Sub(Source::Const(ByteInWord::Lo, 0x01)),
        Opcode::If(Condition::NotZero),
        Opcode::Trap,
        Opcode::Load(Source::Const(ByteInWord::Lo, 1)),
        Opcode::Test,
        Opcode::Status,
        Opcode::Sub(Source::Const(ByteInWord::Lo, 0x00)),
        Opcode::If(Condition::NotZero),
        Opcode::Trap,
        Opcode::LoadImmediateWord(0xFFFF),
        Opcode::Test,
        Opcode::Status,
        Opcode::Sub(Source::Const(ByteInWord::Lo, 0x02)),
        Opcode::If(Condition::NotZero),
        Opcode::Trap,
        Opcode::Status,
        Opcode::Sub(Source::Const(ByteInWord::Lo, 0x21)),
        Opcode::If(Condition::NotZero),
        Opcode::Trap,
        Opcode::Load(Source::Const(ByteInWord::Lo, 0)),
        Opcode::Test,
        Opcode::If(Condition::Zero),
        Opcode::Nop,
        Opcode::Status,
        Opcode::Sub(Source::Const(ByteInWord::Lo, 0x01)),
        Opcode::If(Condition::NotZero),
        Opcode::Trap,
        Opcode::Load(Source::Const(ByteInWord::Lo, 1)),
        Opcode::OutLo,
    ]).unwrap();

    run("op_add_carry.mem", &[
        // FFFE + 1 => no carry
        Opcode::LoadImmediateWord(0xFFFE),
        Opcode::Add(Source::Const(ByteInWord::Lo, 1)),
        // assert no carry
        Opcode::Status,
        Opcode::And(Source::Const(ByteInWord::Lo, 0x04)),
        Opcode::If(Condition::NotZero),
        Opcode::Trap,
        // FFFF + 1 => carry
        Opcode::LoadImmediateWord(0xFFFF),
        Opcode::Add(Source::Const(ByteInWord::Lo, 1)),
        // assert carry
        Opcode::Status,
        Opcode::And(Source::Const(ByteInWord::Lo, 0x04)),
        Opcode::If(Condition::Zero),
        Opcode::Trap,
        // 1 + FFFF => carry
        Opcode::LoadImmediateWord(0xFFFF),
        Opcode::Store(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, 0xF0)),
        Opcode::Load(Source::Const(ByteInWord::Lo, 1)),
        Opcode::Add(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, 0xF0)),
        // assert carry
        Opcode::Status,
        Opcode::And(Source::Const(ByteInWord::Lo, 0x04)),
        Opcode::If(Condition::Zero),
        Opcode::Trap,
        // FFFF + FF00 => carry
        Opcode::LoadImmediateWord(0xFFFE),
        Opcode::Add(Source::Const(ByteInWord::Hi, 0xFF)),
        // assert carry
        Opcode::Status,
        Opcode::And(Source::Const(ByteInWord::Lo, 0x04)),
        Opcode::If(Condition::Zero),
        Opcode::Trap,
        // done
        Opcode::Load(Source::Const(ByteInWord::Lo, 1)),
        Opcode::OutLo,
    ]).unwrap();

    run("op_sub_carry.mem", &[
        // 1 - 1 => no carry
        Opcode::Load(Source::Const(ByteInWord::Lo, 1)),
        Opcode::Sub(Source::Const(ByteInWord::Lo, 1)),
        // assert no carry
        Opcode::Status,
        Opcode::And(Source::Const(ByteInWord::Lo, 0x04)),
        Opcode::If(Condition::NotZero),
        Opcode::Trap,
        // 0 - 1 => carry
        Opcode::Load(Source::Const(ByteInWord::Lo, 0)),
        Opcode::Sub(Source::Const(ByteInWord::Lo, 1)),
        // assert carry
        Opcode::Status,
        Opcode::And(Source::Const(ByteInWord::Lo, 0x04)),
        Opcode::If(Condition::Zero),
        Opcode::Trap,
        // 7FFF - 8000 => carry
        Opcode::LoadImmediateWord(0x8000),
        Opcode::Store(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, 0xF0)),
        Opcode::LoadImmediateWord(0x7FFF),
        Opcode::Sub(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, 0xF0)),
        // assert carry
        Opcode::Status,
        Opcode::And(Source::Const(ByteInWord::Lo, 0x04)),
        Opcode::If(Condition::Zero),
        Opcode::Trap,
        // 8000 - 8001 => carry
        Opcode::LoadImmediateWord(0x8001),
        Opcode::Store(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, 0xF0)),
        Opcode::LoadImmediateWord(0x8000),
        Opcode::Sub(Source::Ram(RelativeTo::DataPointer, AddressingMode::Direct, 0xF0)),
        // assert carry
        Opcode::Status,
        Opcode::And(Source::Const(ByteInWord::Lo, 0x04)),
        Opcode::If(Condition::Zero),
        Opcode::Trap,
        // done
        Opcode::Load(Source::Const(ByteInWord::Lo, 1)),
        Opcode::OutLo,
    ]).unwrap();

    run("op_not_carry.mem", &[
        Opcode::Load(Source::Const(ByteInWord::Lo, 0)),
        Opcode::Not,
        // assert carry
        Opcode::Status,
        Opcode::And(Source::Const(ByteInWord::Lo, 0x04)),
        Opcode::If(Condition::Zero),
        Opcode::Trap,
        // value does not matter
        Opcode::LoadImmediateWord(0xFFFF),
        Opcode::Not,
        // assert carry
        Opcode::Status,
        Opcode::And(Source::Const(ByteInWord::Lo, 0x04)),
        Opcode::If(Condition::Zero),
        Opcode::Trap,
        // done
        Opcode::Load(Source::Const(ByteInWord::Lo, 1)),
        Opcode::OutLo,
    ]).unwrap();

    run("op_shift_carry.mem", &[
        // 1 >> 1 => carry
        Opcode::Load(Source::Const(ByteInWord::Lo, 1)),
        Opcode::Shift(Direction::Right, ShiftSource::Const(1)),
        // assert carry
        Opcode::Status,
        Opcode::And(Source::Const(ByteInWord::Lo, 0x04)),
        Opcode::If(Condition::Zero),
        Opcode::Trap,
        // 0x8000 << 1 => carry
        Opcode::LoadImmediateWord(0x8000),
        Opcode::Shift(Direction::Left, ShiftSource::Const(1)),
        // assert carry
        Opcode::Status,
        Opcode::And(Source::Const(ByteInWord::Lo, 0x04)),
        Opcode::If(Condition::Zero),
        Opcode::Trap,
        // done
        Opcode::Load(Source::Const(ByteInWord::Lo, 1)),
        Opcode::OutLo,
    ]).unwrap();

    fn run(filename: &str, insts: &[Opcode]) -> std::io::Result<()> {
        let encoded = insts.iter().map(|i| i.encode()).collect::<Vec<_>>();

        let bytes = {
            let mut bytes = vec![];
            for e in encoded {
                match e {
                    Encoded::U8(b) => bytes.push(b),
                    Encoded::U16(w) => {
                        let bs = w.to_le_bytes();
                        bytes.push(bs[1]);
                        bytes.push(bs[0]);
                    }
                    Encoded::U8U16(b, w) => {
                        bytes.push(b);
                        let bs = w.to_le_bytes();
                        bytes.push(bs[1]);
                        bytes.push(bs[0]);
                    }
                }
            }
            while bytes.len() < 65536 {
                bytes.push(0);
            }
            bytes
        };

        use std::io::Write;
        let mut f = std::fs::File::create(format!("../test/mem/{filename}"))?;

        for g in bytes.chunks(4) {
            writeln!(f, "{:02X}{:02X}{:02X}{:02X}", g[3], g[2], g[1], g[0])?;
        }

        Ok(())
    }
}
