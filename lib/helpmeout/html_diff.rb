#https://github.com/defunkt/diff-lcs/blob/master/bin/htmldiff
#
require 'diff/lcs'
require 'diff/lcs/hunk'
class HTMLDiff #:nodoc:

  def initialize(before, after)
    @before = before
    @after = after
    @output = ""
  end

  def output(context_lines=3, format = :unified)
    diffs = Diff::LCS.diff(@after, @before)
    return @output if diffs.empty?
    old_hunk = hunk = nil
    file_length_difference = 0
    diffs.each do |piece|
      begin
        hunk = Diff::LCS::Hunk.new(@after, @before, piece, context_lines, file_length_difference)
        file_length_difference = hunk.file_length_difference
        next unless old_hunk

        if (context_lines > 0) and hunk.overlaps?(old_hunk)
          hunk.unshift(old_hunk)
        else
          @output < old_hunk.diff(format)
        end
      ensure
        old_hunk = hunk
        @output << "\n"
      end
    end

    @output << old_hunk.diff(format) << "\n"
  end
end
