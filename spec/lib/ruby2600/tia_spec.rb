require 'spec_helper'
include Ruby2600::Constants

describe Ruby2600::TIA do

  subject(:tia) do
    tia = Ruby2600::TIA.new
    tia.cpu = mock('cpu', :step => 2)
    tia
  end

  describe '#initialize' do
    it 'should initialize with random values on registers' do
      registers1 = Ruby2600::TIA.new.instance_variable_get(:@reg)
      registers2 = tia.instance_variable_get(:@reg)

      registers1.should_not == registers2
    end

    it "should initialize with valid (byte-size) values on registers" do
      tia.instance_variable_get(:@reg).each do |register_value|
        (0..255).should cover register_value
      end
    end
  end

  describe '#scanline' do
    context 'CPU-TIA integration' do
      it 'should spend 76 CPU cycles generating a scanline' do
        tia.cpu.stub(:step).and_return(2)
        tia.cpu.should_receive(:step).exactly(76 / 2).times

        tia.scanline
      end

      it 'should account for variable instruction lenghts' do
        # The 11 stubbed values below add up to 48 cycles. To make 76, TIA should
        # call it 7 more times (since it will return the last one, 4).
        tia.cpu.stub(:step).and_return(2, 3, 4, 5, 6, 7, 6, 5, 4, 2, 4)
        tia.cpu.should_receive(:step).exactly(11 + 7).times

        tia.scanline
      end

      it "should account for multiple lines with unmatching instruction size" do
        # 76 / 3 will be a "split" instruction (25 1/3), but they should add up
        # back to 76 in the course of three lines
        tia.cpu.stub(:step).and_return(3)
        tia.cpu.should_receive(:step).exactly(76).times

        tia.scanline
        tia.scanline
        tia.scanline
      end
    end

    context 'PF0, PF1, PF2' do
      before do
        tia[COLUBK] = 0xBB
        tia[COLUPF] = 0xFF
        tia[VBLANK] = 0x00
      end

      context 'all-zeros playfield' do
        before { tia[PF0] = tia[PF1] = tia[PF2] = 0x00 }

        it 'should generate a fullscanline with background color' do
          tia.scanline.should == Array.new(160, 0xBB)
        end
      end

      context 'all-ones playfield' do
        before { tia[PF0] = tia[PF1] = tia[PF2] = 0xFF }

        it 'should generate a fullscanline with foreground color' do
          tia.scanline.should == Array.new(160, 0xFF)
        end
      end

      context 'pattern playfield' do
        before do
          tia[PF0] = 0b01000101
          tia[PF1] = 0b01001011
          tia[PF2] = 0b01001011
        end

        it 'should generate matching pattern' do
          tia.scanline.should == [0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xFF, 0xFF, 0xFF, 0xFF, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xFF, 0xFF, 0xFF, 0xFF, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xFF, 0xFF, 0xFF, 0xFF, 0xBB, 0xBB, 0xBB, 0xBB, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xBB, 0xBB, 0xBB, 0xBB, 0xFF, 0xFF, 0xFF, 0xFF, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xFF, 0xFF, 0xFF, 0xFF, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xFF, 0xFF, 0xFF, 0xFF, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xFF, 0xFF, 0xFF, 0xFF, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xFF, 0xFF, 0xFF, 0xFF, 0xBB, 0xBB, 0xBB, 0xBB, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xBB, 0xBB, 0xBB, 0xBB, 0xFF, 0xFF, 0xFF, 0xFF, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xFF, 0xFF, 0xFF, 0xFF, 0xBB, 0xBB, 0xBB, 0xBB]
        end
      end
    end

    context 'CTRLPF' do
      it 'should reflect if bit 0 is set'

      it 'should use player colors if bit 1 is set (score mode)'

      it 'should get its color ahead of players/missiles if bit 2 is set (priority'

      it 'should contorl ball size (bits 4 and 5)'
    end

    context 'WSYNC' do
      def write_to_wsync_on_6th_call
        @step_counter ||= 0
        @step_counter += 1
        tia[WSYNC] = rand(256) if @step_counter == 6
        2
      end

      it 'should stop calling the CPU if WSYNC is written to' do
        tia.cpu.stub(:step) { write_to_wsync_on_6th_call }
        tia.cpu.should_receive(:step).exactly(6).times

        tia.scanline
      end
    end

    context 'VBLANK' do
      before do
        tia[COLUBK] = 0xBB
        tia[COLUPF] = 0xFF
        tia[PF0]    = 0xF0
        tia[PF1]    = 0xFF
        tia[PF2]    = 0xFF
      end

      it 'should generate a black scanline when "blanking" bit is set' do
        tia[VBLANK] = rand_with_bit(1, :set)

        tia.scanline.should == Array.new(160, 0x00)
      end

      it 'should generate a normal scanline when "blanking" bit is clear' do
        tia[VBLANK] = rand_with_bit(1, :clear)

        tia.scanline.should == Array.new(160, 0xFF)
      end

      pending "Latches: INPT4-INPT5 bit (6) and INPT6-INPT7 bit(7)"
    end
  end

  # The "ideal" NTSC frame has 259 scanlines (+3 of vsync, which we don't return),
  # but we should allow some leeway (we won't emulate "screen roll" that TVs do
  # with irregular frames)

  describe '#frame' do
    def build_frame(lines)
      @counter ||= -10 # Start on the "previous" frame
      @counter += 1
      case @counter
      when 0, lines + 3 then tia[VSYNC] = rand_with_bit(1, :set)   # Begin frame
      when 3            then tia[VSYNC] = rand_with_bit(1, :clear) # End frame
      end
      tia[WSYNC] = 255 # Finish scanline
      2
    end

    258.upto(260).each do |lines|
      it "should generate a frame with #{lines} scanlines" do
      tia.cpu.stub(:step) { build_frame(lines) }

      tia[VSYNC] = rand_with_bit 1, :clear
      tia.frame
      tia.frame.size.should == lines
      end
    end
  end
end