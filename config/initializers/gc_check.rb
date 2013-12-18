unless ENV['RUBY_GC_MALLOC_LIMIT']
  puts 'WARNING: Ruby GC not tuned!'
  puts '   See http://stackoverflow.com/questions/4985310/garbage-collector-tuning-in-ruby-1-9'
end
