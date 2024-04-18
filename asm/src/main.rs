enum Opcode {
    Text(u8),
    Nop,
    Halt,
    OutLo,
    Not,
    LoadIndirect,// TODO: (AddressingMode),
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
            Opcode::Halt => Encoded::U8(1),
            Opcode::OutLo => Encoded::U8(8),
            Opcode::Not => Encoded::U8(7),
            //Opcode::LoadIndirect(m) => Encoded::U8(0x44 | m.encode()),
            Opcode::LoadIndirect => Encoded::U8(0x44),
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
    Ram(AddressingMode, u8),
}

impl Source {
    fn encode(&self, op: u8) -> Encoded {
        let mut res = u16::from(op) << 8;
        res |= match self {
            Source::Const(b, c) => b.encode() | u16::from(*c),
            Source::Data(b) => 0x0200 | b.encode(),
            Source::Ram(m, a) => 0x0400 | (u16::from(m.encode()) << 8) | u16::from(*a),
        };
        Encoded::U16(res)
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
}

impl Target {
    fn encode(&self, op: u8) -> Encoded {
        let mut res = u16::from(op) << 8;
        res |= match self {
            Target::I11(v) => (*v as u16) & 0x07FF,
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
        Opcode::Load(Source::Ram(AddressingMode::Direct, 0x20)),
        Opcode::Add(Source::Ram(AddressingMode::Direct, 0x22)),
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
        Opcode::Store(Source::Ram(AddressingMode::Direct, 0x20)),
        Opcode::Load(Source::Const(ByteInWord::Lo, 0x33)),
        Opcode::Load(Source::Ram(AddressingMode::Direct, 0x20)),
        Opcode::Add(Source::Ram(AddressingMode::Direct, 0x22)),
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
        Opcode::Load(Source::Const(ByteInWord::Lo, 0xA5)),
        Opcode::Not,
        Opcode::OutLo,
        Opcode::Load(Source::Const(ByteInWord::Lo, 0x20)),
        Opcode::LoadIndirect,
        Opcode::OutLo,
        Opcode::Load(Source::Const(ByteInWord::Lo, 0x22)),
        Opcode::Store(Source::Ram(AddressingMode::Direct, 0x1E)),
        Opcode::Load(Source::Const(ByteInWord::Lo, 0)),
        Opcode::Load(Source::Ram(AddressingMode::Indirect, 0x1E)),
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
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
        Opcode::Nop,
    ];

    let target = 0x50;
    let current = 0x52;
    let cursor = 0x54;
    let cache = 0x58;

    let br0 = 0x12;
    let br1 = 0x18;
    let loop_label = 0x1C;
    let br2 = 0x3C;
    let br3 = 0x44;
    let done = 0x44;

    let fib_memo_insts = [
        Opcode::Load(Source::Data(ByteInWord::Lo)),
        Opcode::Store(Source::Ram(AddressingMode::Direct, target)),
        Opcode::Load(Source::Const(ByteInWord::Lo, 1)),
        Opcode::Store(Source::Ram(AddressingMode::Direct, cache)),
        Opcode::Load(Source::Const(ByteInWord::Lo, 1)),
        Opcode::Store(Source::Ram(AddressingMode::Direct, cache + 2)),
        Opcode::Load(Source::Ram(AddressingMode::Direct, target)),
        Opcode::If(Condition::Zero),
        Opcode::Branch(Target::I11(done - br0)),
        Opcode::Sub(Source::Const(ByteInWord::Lo, 1)),
        Opcode::If(Condition::Zero),
        Opcode::Branch(Target::I11(done - br1)),
        Opcode::Load(Source::Const(ByteInWord::Lo, 2)),
        Opcode::Store(Source::Ram(AddressingMode::Direct, current)),
        // loop
        Opcode::Load(Source::Ram(AddressingMode::Direct, current)),
        Opcode::Add(Source::Ram(AddressingMode::Direct, current)),
        Opcode::Add(Source::Const(ByteInWord::Lo, cache)),
        Opcode::Store(Source::Ram(AddressingMode::Direct, cursor)),
        Opcode::Sub(Source::Const(ByteInWord::Lo, 2)),
        Opcode::LoadIndirect,
        Opcode::Store(Source::Ram(AddressingMode::Indirect, cursor)),
        Opcode::Load(Source::Ram(AddressingMode::Direct, cursor)),
        Opcode::Sub(Source::Const(ByteInWord::Lo, 4)),
        Opcode::LoadIndirect,
        Opcode::Add(Source::Ram(AddressingMode::Indirect, cursor)),
        Opcode::Store(Source::Ram(AddressingMode::Indirect, cursor)),
        Opcode::OutLo,
        Opcode::Nop,
        Opcode::Load(Source::Ram(AddressingMode::Direct, target)),
        Opcode::Sub(Source::Ram(AddressingMode::Direct, current)),
        Opcode::If(Condition::Zero),
        Opcode::Branch(Target::I11(done - br2)),
        Opcode::Load(Source::Ram(AddressingMode::Direct, current)),
        Opcode::Add(Source::Const(ByteInWord::Lo, 1)),
        Opcode::Store(Source::Ram(AddressingMode::Direct, current)),
        Opcode::Branch(Target::I11(loop_label - br3)),
        // done
        Opcode::Load(Source::Ram(AddressingMode::Direct, target)),
        Opcode::Add(Source::Ram(AddressingMode::Direct, target)),
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

    run("../test/ops.mem", &ops_insts).unwrap();
    run("../test/fib_memo.mem", &fib_memo_insts).unwrap();

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
                }
            }
            bytes
        };

        use std::io::Write;
        let mut f = std::fs::File::create(filename)?;

        for g in bytes.chunks(4) {
            writeln!(f, "{:02X}{:02X}{:02X}{:02X}", g[3], g[2], g[1], g[0])?;
        }

        Ok(())
    }
}
