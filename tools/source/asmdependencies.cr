# Get all the dependencies of RGBDS assembly files recursively,
# and output them using Make dependency syntax.

require "option_parser"

def dependencies_in(asm_file_paths, source_dir = "", build_dir = "")
    asm_file_paths = asm_file_paths.clone
    asm_file_paths.map! { |p| File.join(source_dir, p) } if !source_dir.empty?
    build_dir += File::SEPARATOR if !build_dir.empty? && !build_dir.ends_with?(File::SEPARATOR)
    dependencies = {} of String => Set(String)

    asm_file_paths.each do |asm_file_path|
        if !dependencies.has_key? asm_file_path
            asm_dependencies, bin_dependencies =
                shallow_dependencies_of asm_file_path, source_dir, build_dir
            dependencies[asm_file_path] = asm_dependencies | bin_dependencies
            asm_file_paths.concat asm_dependencies.to_a
        end
    end

    return dependencies
end

def shallow_dependencies_of(asm_file_path, source_dir = "", build_dir = "")
    asm_dependencies = Set(String).new
    bin_dependencies = Set(String).new

    File.each_line asm_file_path do |line|
        keyword_match = line.match /^\s*(INC(?:LUDE|BIN))/i
        next if !keyword_match

        keyword = keyword_match[1].upcase
        line = line.split(';', 1)[0]
        path = line[line.index('"').not_nil! + 1...line.rindex('"').not_nil!]
        if !source_dir.empty? && !(!build_dir.empty? && path.starts_with?(build_dir))
            path = File.join(source_dir, path)
        end
        if keyword == "INCLUDE"
            asm_dependencies << path
        else
            bin_dependencies << path
        end
    end

    return asm_dependencies, bin_dependencies
end

ACTUAL_PROGRAM_NAME = "#{PROGRAM_NAME.split('/')[-1]}"
USAGE = "Usage: #{ACTUAL_PROGRAM_NAME} <paths to assembly files...>"

if ARGV.size == 0
    puts USAGE
    puts %(Run "#{ACTUAL_PROGRAM_NAME} --help" for more info!)
    exit 1
end

source_dir = ""
build_dir = ""

OptionParser.parse! do |parser|
    parser.banner = "#{USAGE}\n\nArguments:"
    parser.on("-h", "--help", "Show this help and exit.") { puts parser; exit 0 }
    parser.on("-s PATH",
              "Prepend a source directory to arguments and includes.") { |s| source_dir = s }
    parser.on(
        "-b PATH",
        "Build directory - when includes begin with this, -s won't be prepended."
    ) { |b| build_dir = b }
    parser.missing_option { |o| STDERR.puts %(Missing argument to "#{o}".); exit 1 }
    parser.invalid_option { |o| STDERR.puts %(Invalid option: "#{o}".); exit 1 }
end

dependencies_in(ARGV, source_dir, build_dir).each do |file, dependencies|
    # It seems that if A depends on B which depends on C, and
    # C is modified, Make needs you to change the modification
    # time of B too. That's the reason for the "@touch $@".
    puts "#{file}: #{dependencies.join(' ')}\n\t@touch $@" if !dependencies.empty?
end
