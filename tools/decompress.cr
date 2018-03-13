# Decompress data encoded with the method used in Hamtaro: Ham-Hams Unite!

def decompress_section(file)
    data = [] of UInt8

    chunk_start = file.read_byte.not_nil!
    until chunk_start == 0
        if chunk_start <= 127
            cur_bytes = Bytes.new(chunk_start)
            file.read(cur_bytes)
            data += cur_bytes.to_a
        elsif 0xFC <= chunk_start <= 0xFE
            data += decompress_reference_chunk(file, chunk_start, data)
        else
            data += decompress_rle_chunk(file, chunk_start)
        end
        chunk_start = file.read_byte.not_nil!
    end

    return data
end

def decompress_rle_chunk(file, chunk_start)
    num_bytes = (chunk_start & 0b01111100) >> 1
    num_bytes = 1 if num_bytes == 0
    run_length = ((chunk_start & 0b11) << 8) | file.read_byte.not_nil!

    bytes_to_repeat = Bytes.new(num_bytes)
    file.read(bytes_to_repeat)

    return bytes_to_repeat.to_a * run_length
end

def decompress_reference_chunk(file, chunk_start, data)
    num_bytes = ((chunk_start & 0b11) << 8) | file.read_byte.not_nil!
    num_bytes += 0x100 if num_bytes & 0xFF == 0
    start_index = file.read_bytes(UInt16, IO::ByteFormat::LittleEndian)

    return data[start_index, num_bytes]
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
    File.write out_path, Bytes.new(data.to_unsafe, data.size * sizeof(UInt8))
else
    STDOUT.write Bytes.new(data.to_unsafe, data.size * sizeof(UInt8))
end
