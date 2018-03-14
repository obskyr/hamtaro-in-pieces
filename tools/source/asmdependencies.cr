# Get all the dependencies of RGBDS assembly files recursively,
# and output them using Makefile dependency syntax.

def dependencies_in(asm_file_paths)
    asm_file_paths = asm_file_paths.clone
    dependencies = {} of String => Set(String)

    i = 0
    while i < asm_file_paths.size
        asm_file_path = asm_file_paths[i]
        if !dependencies.has_key? asm_file_path
            asm_dependencies, bin_dependencies = shallow_dependencies_of asm_file_path
            dependencies[asm_file_path] = asm_dependencies | bin_dependencies
            asm_file_paths += asm_dependencies.to_a
        end
        i += 1
    end

    return dependencies
end

def shallow_dependencies_of(asm_file_path)
    asm_dependencies = Set(String).new
    bin_dependencies = Set(String).new

    File.each_line asm_file_path do |line|
        keyword_match = line.match /^\s*(INC(?:LUDE|BIN))/i
        next if !keyword_match

        keyword = keyword_match[1].upcase
        path = line[line.index('"').not_nil! + 1...line.rindex('"').not_nil!]
        if keyword == "INCLUDE"
            asm_dependencies << path
        else
            bin_dependencies << path
        end
    end

    return asm_dependencies, bin_dependencies
end

if ARGV.size == 0
    puts "Usage: #{PROGRAM_NAME.split('/')[-1]} <paths to assembly files...>"
    exit 1
end

dependencies_in(ARGV).each do |file, dependencies|
    puts "#{file}: #{dependencies.join(' ')}" if !dependencies.empty?
end
