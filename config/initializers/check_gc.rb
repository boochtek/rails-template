if File.basename($0) != 'rake' && ENV['RUBY_GC_MALLOC_LIMIT'].nil?
  puts 'WARNING: Ruby GC not tuned! See http://stackoverflow.com/questions/4985310/.'
end