module MRerun

  def m_rerun
    out = StringIO.new
    failed = tests.reject {|t| t.passed? || t.skipped? }

    if failed.size > 0
      out.puts "\nRe-run with m:"
      failed.each do |test|
        file = test.source_location.join(":")
        shorter_path = file.sub(Dir.pwd, '').sub(/^\//, '').sub(/^RAILS_APP\//, '')
        out.puts "m #{shorter_path}"
      end
    end

    out.string
  end

  def on_report
    super
    puts yellow(m_rerun)
  end

end
