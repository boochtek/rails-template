# From http://blog.davidchelimsky.net/2009/01/13/rspec-1-1-12-is-released/#comment-344
def self.its(attribute, &block)
  describe(attribute) do
    define_method(:subject) { super.send(attribute) }
    it(&block)
  end
end

