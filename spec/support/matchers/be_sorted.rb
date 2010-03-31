# From Josh Susser (http://blog.hasmanythrough.com/2008/6/1/the-great-test-framework-dance-off)
def be_sorted
 return simple_matcher("a sorted list") do |actual|
    actual.sort == actual
 end
end
