require 'tailor'
require 'tailor/file_line'

require 'cane/style_violation'

# This monkey-patch is required since `print_problem` is marked private in the
# 3rd party library.
module Tailor
  class FileLine
    def print_problem(message)
      message = message.gsub(/\[.+\]\s+/, '')
      @problems << StyleViolation.new(@file_path, @line_number, message)
    end

    def problems
      @problems = []
      find_problems
      @problems
    end

    def find_problems
      # This is weird. These methods actually have side-effects! We capture
      # the effects my monkey-patching FileLine above.
      spacing_problems
      method_line? && camel_case_method?
      class_line?  && snake_case_class?
      too_long?
    end
  end
end

module Cane
  class StyleCheck < Struct.new(:opts)
    def violations
      Dir[opts.fetch(:files)].map do |file_name|
        find_violations_in_file(file_name)
      end.flatten
    end

    def find_violations_in_file(file_name)
      source    = File.open(file_name, 'r')
      file_path = Pathname.new(file_name)

      source.each_line.map.with_index do |source_line, line_number|
        Tailor::FileLine.new(source_line, file_path, line_number + 1).problems
      end
    end
  end
end
