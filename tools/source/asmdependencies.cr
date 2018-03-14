# Get all the dependencies of RGBDS assembly files recursively,
# and output them using Make dependency syntax.

def dependencies_in(asm_file_paths)
    asm_file_paths = asm_file_paths.clone
    dependencies = {} of String => Set(String)

    asm_file_paths.each do |asm_file_path|
        if !dependencies.has_key? asm_file_path
            asm_dependencies, bin_dependencies = shallow_dependencies_of asm_file_path
            dependencies[asm_file_path] = asm_dependencies | bin_dependencies
            asm_file_paths.concat asm_dependencies.to_a
        end
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
        line = line.split(';', 1)[0]
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
    # It seems that if A depends on B which depends on C, and
    # C is modified, Make needs you to change the modification
    # time of B too. That's the reason for the "@touch $@".
    puts "#{file}: #{dependencies.join(' ')}\n\t@touch $@" if !dependencies.empty?
end
