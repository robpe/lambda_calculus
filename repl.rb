require_relative './interpreter.rb'

class LC

  def initialize
    @lci = LCI.new    
  end

  def repl(prompt)
    loop do
      print prompt
      tokens = SXP.read gets.chomp!
      puts(" => %s" % @lci.evaluate(@lci.parse(tokens)))
    end
  end

end

if __FILE__ == $0
  LC.new.repl(">> ")
end

# >> (call (lambda y (+ y 100)) 100)
#  => 200
# >> (call (lambda f (call f 10)) (lambda x (- 100 x)))
#  => 90
