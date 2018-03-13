# Get all the dependencies of an RGBDS assembly file recursively.

def dependencies_of(asm_file_path)
    dependencies = Set(String).new
    File.each_line asm_file_path do |line|
        dependencies |= dependencies_from_line line
    end
    return dependencies
end

def dependencies_from_line(line)
    dependencies = Set(String).new
    line = line.lstrip
    line = line.split(";", 1)[0]
    return dependencies if !line.starts_with? "INC"

    path = line[line.index('"').not_nil! + 1...line.rindex('"').not_nil!]
    dependencies << path
    if line.starts_with? "INCLUDE"
        dependencies |= dependencies_of path
    end

    return dependencies
end

if ARGV.size != 1
    puts "Usage: #{PROGRAM_NAME.split("/")[-1]} <path to assembly file>"
    exit 1
end

dependencies_of(ARGV[0]).each do |dependency|
    puts dependency
end
