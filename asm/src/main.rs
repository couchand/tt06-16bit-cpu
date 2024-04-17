enum Opcode {
    Text(u8),
    Nop,
    OutLo,
    Load(Source),
    Store(Source),
    Add(Source),
    Sub(Source),
    And(Source),
    Or(Source),
    Xor(Source),
    Branch(Target),
    If(Condition),
}

impl Opcode {
    fn encode(&self) -> Encoded {
        match self {
            Opcode::Text(v) => Encoded::U8(*v),
            Opcode::Nop => Encoded::U8(0),
            Opcode::OutLo => Encoded::U8(8),
            Opcode::Load(s) => s.encode(0x80),
            Opcode::Store(s) => s.encode(0x90),
            Opcode::Add(s) => s.encode(0x88),
            Opcode::Sub(s) => s.encode(0x98),
            Opcode::And(s) => s.encode(0xA0),
            Opcode::Or(s) => s.encode(0xA8),
            Opcode::Xor(s) => s.encode(0xB0),
            Opcode::Branch(t) => t.encode(0xC0),
            Opcode::If(c) => c.encode(0xF0),
        }
    }
}

enum Source {
    Const(ByteInWord, u8),
    Data(ByteInWord),
    Ram(u8),
}

impl Source {
    fn encode(&self, op: u8) -> Encoded {
        let mut res = u16::from(op) << 8;
        res |= match self {
            Source::Const(b, c) => b.encode() | u16::from(*c),
            Source::Data(b) => 0x0200 | b.encode(),
            Source::Ram(a) => 0x0400 | u16::from(*a),
        };
        Encoded::U16(res)
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
}

impl Target {
    fn encode(&self, op: u8) -> Encoded {
        let mut res = u16::from(op) << 8;
        res |= match self {
            Target::I11(v) => *v as u16,
        };
        Encoded::U16(res)
    }
}

enum Condition {
    Zero,
    NotZero,
    Else,
    NotElse,
}

impl Condition {
    fn encode(&self, op: u8) -> Encoded {
        let mut res = u16::from(op) << 8;
        res |= match self {
            Condition::Zero     => 0x0000,
            Condition::NotZero  => 0x0001,
            Condition::Else     => 0x0002,
            Condition::NotElse  => 0x0003,
        };
        Encoded::U16(res)
    }
}

enum Encoded {
    U16(u16),
    U8(u8),
}

fn main() {
    let insts = [
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
        Opcode::Load(Source::Ram(0x20)),
        Opcode::Add(Source::Ram(0x22)),
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
        Opcode::If(Condition::NotZero),
        Opcode::Branch(Target::I11(0x07F8)),
        Opcode::Load(Source::Const(ByteInWord::Lo, 0x09)),
        Opcode::Store(Source::Ram(0x20)),
        Opcode::Load(Source::Const(ByteInWord::Lo, 0x33)),
        Opcode::Load(Source::Ram(0x20)),
        Opcode::Add(Source::Ram(0x22)),
        Opcode::OutLo,
        Opcode::Nop,
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
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
    ];

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
            }
        }
        bytes
    };

    for g in bytes.chunks(4) {
        println!("{:02X}{:02X}{:02X}{:02X}", g[3], g[2], g[1], g[0]);
    }
}
