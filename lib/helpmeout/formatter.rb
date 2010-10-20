require 'dm-core'
require 'dm-migrations'
require 'rspec/core/formatters/base_text_formatter'
require 'helpmeout/failed_test'
require 'helpmeout/failed_test_file'
require 'differ'

  module Helpmeout
    class Formatter < RSpec::Core::Formatters::BaseTextFormatter

      def start(example_count)
        project_root = Rails.root
        DataMapper.setup(:default, 'sqlite://' + File.join (project_root, '/helpmeout.db'))
        DataMapper.finalize
        DataMapper.auto_upgrade!
        output.puts(html_header)
      end
      
      def example_failed(example)
        exception = example.execution_result[:exception_encountered]
        backtrace = exception.backtrace.join("\n")

        delete_failed_test(example)
        inserted_test = create_failed_test exception.message, backtrace, example.full_description

        project_files = get_project_files(exception.backtrace)
        project_files.each do |file_path|
          create_failed_test_file(file_path, inserted_test.id)
        end

        output.puts "<div class='failed-example'>"
        output.puts "<h1>Example: #{example.full_description} failed. </h1>"
        output.puts "<dl>"
        output.puts "<dt>Message:</dt>"
        output.puts "<dd>#{exception.message}</dd>"
        output.puts "</dl>"
        fixes = service.query_fix(exception.backtrace)
        if fixes['fixes']
          fixes['fixes'].each do |fix|
            output.puts "<div class='fix'>"
            output.puts "<h2>Suggested fix:</h2>"
            fix['fix_files'].each do |fix_file|
              unless fix_file['content_before'] == fix_file['content_after']
                diff = Differ.diff(fix_file['content_after'], fix_file['content_before'])
                output.puts "<pre>"
                output.puts(diff.format_as(:html))
                output.puts "</pre>"
              end
            end
          end
        end
        output.puts "</div>"
        output.flush
    end

    def example_passed(example)
      if failed_test = matching_failed_test(example)
        service.add_fix(failed_test)
        failed_test.destroy!
      end
    end


    def dump_summary(duration, example_count, failure_count, pending_count)
      output.puts '</body>'
      output.puts '</html>'
      output.flush
    end


    private

    def delete_failed_test(example)
      failed_test = matching_failed_test(example)
      if failed_test
        failed_test.destroy
      end
    end

    def create_failed_test_file(path, failed_test_id)
      file_content = File.read(path)
      FailedTestFile.create( :path => path, :content => file_content,
                            :failed_test_id => failed_test_id)
    end

    def create_failed_test(exception_message, backtrace, example_description)
      FailedTest.create(:exception_message => exception_message,
                        :backtrace => backtrace,
                        :example_description => example_description
                       )
    end

    def matching_failed_test(example)
      FailedTest.first(:example_description => example.full_description)
    end

    def get_project_files(backtrace)
      backtrace.collect {|line| line.starts_with?(Rails.root) ? line.split(':')[0] : nil }.uniq.compact
    end

    def service
      @service ||= Service.new
    end


    def html_header #stolen from rspec htmlformatter
       <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html
  PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
  <title>RSpec results</title>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <meta http-equiv="Expires" content="-1" />
  <meta http-equiv="Pragma" content="no-cache" />
  <style type="text/css">
  body {
    margin: 0;
    padding: 0;
    background: #fff;
    font-size: 80%;
  }
  </style>
  <script type="text/javascript">
    // <![CDATA[
    // ]]>
  </script>
  <style type="text/css">
#{global_styles}
  </style>
</head>
<body>
EOF
    end

    def global_styles #stolen from rspecs html formatter
      <<-EOF
      #rspec-header {
  background: #65C400; color: #fff; height: 4em;
}

.rspec-report h1 {
  margin: 0px 10px 0px 10px;
  padding: 10px;
  font-family: "Lucida Grande", Helvetica, sans-serif;
  font-size: 1.8em;
  position: absolute;
}

#summary {
  margin: 0; padding: 5px 10px;
  font-family: "Lucida Grande", Helvetica, sans-serif;
  text-align: right;
  top: 0px;
  right: 0px;
  float:right;
}

#summary p {
  margin: 0 0 0 2px;
}

#summary #totals {
  font-size: 1.2em;
}

.example_group {
  margin: 0 10px 5px;
  background: #fff;
}

dl {
  margin: 0; padding: 0 0 5px;
  font: normal 11px "Lucida Grande", Helvetica, sans-serif;
}

dt {
  padding: 3px;
  background: #65C400;
  color: #fff;
  font-weight: bold;
}

dd {
  margin: 5px 0 5px 5px;
  padding: 3px 3px 3px 18px;
}

dd.spec.passed {
  border-left: 5px solid #65C400;
  border-bottom: 1px solid #65C400;
  background: #DBFFB4; color: #3D7700;
}

dd.spec.failed {
  border-left: 5px solid #C20000;
  border-bottom: 1px solid #C20000;
  color: #C20000; background: #FFFBD3;
}

dd.spec.not_implemented {
  border-left: 5px solid #FAF834;
  border-bottom: 1px solid #FAF834;
  background: #FCFB98; color: #131313;
}

dd.spec.pending_fixed {
  border-left: 5px solid #0000C2;
  border-bottom: 1px solid #0000C2;
  color: #0000C2; background: #D3FBFF;
}

.backtrace {
  color: #000;
  font-size: 12px;
}

a {
  color: #BE5C00;
}

/* Ruby code, style similar to vibrant ink */
.ruby {
  font-size: 12px;
  font-family: monospace;
  color: white;
  background-color: black;
  padding: 0.1em 0 0.2em 0;
}

.ruby .keyword { color: #FF6600; }
.ruby .constant { color: #339999; }
.ruby .attribute { color: white; }
.ruby .global { color: white; }
.ruby .module { color: white; }
.ruby .class { color: white; }
.ruby .string { color: #66FF00; }
.ruby .ident { color: white; }
.ruby .method { color: #FFCC00; }
.ruby .number { color: white; }
.ruby .char { color: white; }
.ruby .comment { color: #9933CC; }
.ruby .symbol { color: white; }
.ruby .regex { color: #44B4CC; }
.ruby .punct { color: white; }
.ruby .escape { color: white; }
.ruby .interp { color: white; }
.ruby .expr { color: white; }

.ruby .offending { background-color: gray; }
.ruby .linenum {
  width: 75px;
  padding: 0.1em 1em 0.2em 0;
  color: #000000;
  background-color: #FFFBD3;
}
EOF
    end

  end
end
