class Cpu
  attr_accessor :memory, :pc, :x, :y, :a, :flags

  RESET_VECTOR = 0xFFFC

  # FIXME tables generated from CPU simuulator, may be inaccurate. See:
  #       http://visual6502.org/wiki/index.php?title=6502_all_256_Opcodes

  INSTRUCTION_SIZE = [
    0, 2, 0, 2, 2, 2, 2, 2, 1, 2, 1, 2, 3, 3, 3, 3,
    2, 2, 0, 2, 2, 2, 2, 2, 1, 3, 1, 3, 3, 3, 3, 3,
    3, 2, 0, 2, 2, 2, 2, 2, 1, 2, 1, 2, 3, 3, 3, 3,
    2, 2, 0, 2, 2, 2, 2, 2, 1, 3, 1, 3, 3, 3, 3, 3,
    0, 2, 0, 2, 2, 2, 2, 2, 1, 2, 1, 2, 0, 3, 3, 3,
    2, 2, 0, 2, 2, 2, 2, 2, 1, 3, 1, 3, 3, 3, 3, 3,
    0, 2, 0, 2, 2, 2, 2, 2, 1, 2, 1, 2, 0, 3, 3, 3,
    2, 2, 0, 2, 2, 2, 2, 2, 1, 3, 1, 3, 3, 3, 3, 3,
    2, 2, 2, 2, 2, 2, 2, 2, 1, 2, 1, 2, 3, 3, 3, 3,
    2, 2, 0, 2, 2, 2, 2, 2, 1, 3, 0, 0, 3, 3, 3, 3,
    2, 2, 2, 2, 2, 2, 2, 2, 1, 2, 1, 2, 3, 3, 3, 3,
    2, 2, 0, 2, 2, 2, 2, 2, 1, 3, 1, 3, 3, 3, 3, 3,
    2, 2, 2, 2, 2, 2, 2, 2, 1, 2, 1, 2, 3, 3, 3, 3,
    2, 2, 0, 2, 2, 2, 2, 2, 1, 3, 1, 3, 3, 3, 3, 3,
    2, 2, 2, 2, 2, 2, 2, 2, 1, 2, 1, 2, 3, 3, 3, 3,
    2, 2, 0, 2, 2, 2, 2, 2, 1, 3, 1, 3, 3, 3, 3, 3
  ]

  CYCLE_COUNT = [
    0, 6, 0, 8, 3, 3, 5, 5, 3, 2, 2, 2, 4, 4, 6, 6,
    3, 5, 0, 8, 4, 4, 6, 6, 2, 4, 2, 7, 4, 4, 7, 7,
    6, 6, 0, 8, 3, 3, 5, 5, 4, 2, 2, 2, 4, 4, 6, 6,
    2, 5, 0, 8, 4, 4, 6, 6, 2, 4, 2, 7, 4, 4, 7, 7,
    6, 6, 0, 8, 3, 3, 5, 5, 3, 2, 2, 2, 3, 4, 6, 6,
    3, 5, 0, 8, 4, 4, 6, 6, 2, 4, 2, 7, 4, 4, 7, 7,
    6, 6, 0, 8, 3, 3, 5, 5, 4, 2, 2, 2, 5, 4, 6, 6,
    2, 5, 0, 8, 4, 4, 6, 6, 2, 4, 2, 7, 4, 4, 7, 7,
    2, 6, 2, 6, 3, 3, 3, 3, 2, 2, 2, 2, 4, 4, 4, 4,
    3, 6, 0, 6, 4, 4, 4, 4, 2, 5, 2, 5, 5, 5, 5, 5,
    2, 6, 2, 6, 3, 3, 3, 3, 2, 2, 2, 2, 4, 4, 4, 4,
    2, 5, 0, 5, 4, 4, 4, 4, 2, 4, 2, 4, 4, 4, 4, 4,
    2, 6, 2, 8, 3, 3, 5, 5, 2, 2, 2, 2, 4, 4, 6, 6,
    3, 5, 0, 8, 4, 4, 6, 6, 2, 4, 2, 7, 4, 4, 7, 7,
    2, 6, 2, 8, 3, 3, 5, 5, 2, 2, 2, 2, 4, 4, 6, 6,
    2, 5, 0, 8, 4, 4, 6, 6, 2, 4, 2, 7, 4, 4, 7, 7
  ]

  # Opcodes are in form aaaabbbcc, where cc = group, bb = mode for group
  # (see: http://www.llx.com/~nparker/a2/opcodes.html)

  ADDRESSING_MODE = [
    # group 0b00: BIT, JMP, STY, LDY, CPY, CPX
    [
      :immediate,
      :zero_page,
      :accumulator,
      :absolute,
      nil,
      :zero_page_indexed_x,
      nil,
      :absolute_indexed_x
    ],
    # group 0b01: ORA, AND, EOR, ADC, STA, LDA, CMP, SBC
    [
      :indexed_indirect_x,
      :zero_page,
      :immediate,
      :absolute,
      :indirect_indexed_y,
      :zero_page_indexed_x,
      :absolute_indexed_y,
      :absolute_indexed_x,
    ],
    # group 0b10: ASL, ROL, LSR, ROR, STX, LDX, DEC, INC
    [
      :immediate,
      :zero_page,
      :accumulator,
      :absolute,
      nil,
      :zero_page_indexed_y, # LDX only
      nil,
      :absolute_indexed_y # LDX only
    ]
  ]

  def initialize
    @flags = {}
    @x = @y = @a = 0
  end

  def reset
    @pc = memory[RESET_VECTOR] + 0x100 * memory[RESET_VECTOR + 1]
  end

  def step
    fetch
    execute
  end

  private

  def fetch
    @opcode = memory[@pc]

    group = (@opcode & 0b00000011)
    mode  = (@opcode & 0b00011100) >> 2
    @addressing_mode = ADDRESSING_MODE[group][mode]

    @param_lo = memory[@pc + 1]
    @param_hi = memory[@pc + 2]

    @pc += INSTRUCTION_SIZE[@opcode]
  end

  def execute
    case @opcode
    when 0xA9, 0xA5, 0xB5, 0xAD, 0xBD, 0xB9, 0xB1, 0xA1 # LDA
      @a = load
      update_zn_flags(@a)
    when 0xA2, 0xA6, 0xB6, 0xAE, 0xBE # LDX
      @x = load
      update_zn_flags(@x)
    when 0xA0, 0xA4, 0xB4, 0xAC, 0xBC # LDY
      @y = load
      update_zn_flags(@y)
    when 0x85, 0x95, 0x8D, 0x9D, 0x99, 0x81, 0x91 # STA
      store @a
    when 0x86, 0x96, 0x8E # STX
      store @x
    when 0x84, 0x94, 0x8C # STY
      store @y
    when 0xCA # DEX
      @x = @x == 0 ? 0xFF : @x - 1
      update_zn_flags(@x)
    when 0x88 # DEY
      @y = @y == 0 ? 0xFF : @y - 1
      update_zn_flags(@y)
    end
    time_in_cycles
  end

  def load
    case @addressing_mode
    when :immediate   then @param_lo
    when :accumulator then @a
    else              memory[self.send(@addressing_mode)]
    end
  end

  def store(value)
    case @addressing_mode
    when :immediate   then memory[@param_lo] = value
    when :accumulator then @a = value
    else              memory[self.send(@addressing_mode)] = value
    end
  end

  # Timing

  def time_in_cycles
    cycles = CYCLE_COUNT[@opcode]
    cycles += 1 if page_boundary_crossed?
    cycles
  end

  def page_boundary_crossed?
    (@opcode == 0xBE && @param_lo + @y > 0xFF) ||  # LDX; Absolute Y
    (@opcode == 0xB9 && @param_lo + @y > 0xFF) ||  # LDA; Absolute Y
    (@opcode == 0xB1 && memory[memory[@pc - 1]] + @y > 0xFF) || # LDA; indirect indexed y
    (@opcode == 0xBD && @param_lo + @x > 0xFF) ||  # LDA; Absolute X
    (@opcode == 0xBC && @param_lo + @x > 0xFF)     # LDY; Absolute X
  end

  # Address calculation for memory addressing modes

  def zero_page
    @param_lo
  end

  def zero_page_indexed_x
    (@param_lo + @x) % 0x100
  end

  def zero_page_indexed_y
    (@param_lo + @y) % 0x100
  end

  def absolute
    @param_hi * 0x100 + @param_lo
  end

  def absolute_indexed_x
    (@param_hi * 0x100 + @param_lo + @x) % 0x10000
  end

  def absolute_indexed_y
    (@param_hi * 0x100 + @param_lo + @y) % 0x10000
  end

  def indirect_indexed_y
    (memory[@param_lo + 1] * 0x100 + memory[@param_lo] + @y) % 0x10000
  end

  def indexed_indirect_x
    indexed_param = (@param_lo + @x) % 0x100
    memory[indexed_param + 1] * 0x100 + memory[indexed_param]
  end

  # Flag management

  def update_zn_flags(value)
    @flags[:z] = (value == 0)
    @flags[:n] = (value & 0b10000000 != 0)
  end

end
