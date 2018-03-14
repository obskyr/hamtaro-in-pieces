# Decompress data encoded with the method used in Hamtaro: Ham-Hams Unite!

def decompress_section(file)
    io = IO::Memory.new

    chunk_start = file.read_byte.not_nil!
    until chunk_start == 0
        if chunk_start <= 127
            IO.copy(file, io, chunk_start)
        elsif 0xFC <= chunk_start <= 0xFE
            decompress_reference_chunk(file, io, chunk_start)
        else
            decompress_rle_chunk(file, io, chunk_start)
        end
        chunk_start = file.read_byte.not_nil!
    end

    return io.to_slice
end

def decompress_rle_chunk(from, to, chunk_start)
    num_bytes = (chunk_start & 0b01111100) >> 1
    num_bytes = 1 if num_bytes == 0
    run_length = ((chunk_start & 0b11) << 8) | from.read_byte.not_nil!

    bytes_to_repeat = Bytes.new(num_bytes)
    from.read_fully bytes_to_repeat
    run_length.times do
        to.write bytes_to_repeat
    end
end

def decompress_reference_chunk(from, to, chunk_start)
    num_bytes = ((chunk_start & 0b11) << 8) | from.read_byte.not_nil!
    # The in-game decoder uses code akin to a do-while loop,
    # so a length of 0x0000 underflows back to 0x100.
    num_bytes = 0x100 if num_bytes == 0 
    start_index = from.read_bytes(UInt16, IO::ByteFormat::LittleEndian)
    
    # This won't work if the reference references bytes it itself writes,
    # but I'm fairly certain the encoder Pax Softnica used wouldn't do that.
    reference_io = IO::Memory.new(to.to_slice)
    reference_io.seek start_index

    IO.copy(reference_io, to, num_bytes)
end

begin
    in_path = ARGV[0]
    address = ARGV[1].to_i(prefix: true)
rescue IndexError | ArgumentError
    puts "Usage: #{PROGRAM_NAME.split("/")[-1]} <input file> <address> [output file]"
    exit 1
end
out_path = ARGV[2]?

file = File.open in_path, "rb"
file.seek address
data = decompress_section file
file.close

if out_path
    puts "Decompressing section at $%06X in #{in_path} to #{out_path}..." % address
    File.write out_path, data
else
    STDOUT.write data
end
