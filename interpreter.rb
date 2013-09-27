# Simple lambda calculus interpreter to evaluate arithmetic expressions 
# in the form of abstract syntax trees. Has support for anonymous 
# functions, closures, and let expressions. 
#
# Implemented in functional way, using multi_dispatch gem.

require 'sxp'
require 'multi_dispatch'

# helpers
module Camelizer
  def camelize
    return self.to_s if self !~ /_/ && self =~ /[A-Z]+.*/
    to_s.split('_').map { |e| e.capitalize }.join
  end
end

Symbol.send(:include, Camelizer)

# Lambda Calculus Interpreter
class LCI
  include MultiDispatch

  attr_accessor :env

  def initialize
    @env = {}
    @lang = {
      Numeric => lambda { |e| e },
      :true   => lambda { |e| true },
      :false  => lambda { |e| false },
      :+      => lambda { |e| e.shift
        Plus.new(parse(e.first), parse(e.last))
      },
      Symbol  => lambda { |e| 
        Var.new(e)
      },
      :-      => lambda { |e| e.shift
        Minus.new(parse(e.first), parse(e.last))
      },
      :lambda => lambda { |e| e.shift
        Func.new(e.first, parse(e.last))
      },
      :call   => lambda { |e| e.shift
        Call.new(parse(e.first), parse(e.last))
      },
      :if     => lambda { |e| e.shift
        If.new(parse(e.shift), parse(e.first), parse(e.last))
      },
      :let    => lambda { |e| e.shift
        LetDirect.new(e.shift, parse(e.first), parse(e.last))
      },
      :letf   => lambda { |e| e.shift
        LetByFunc.new(e.shift, parse(e.first), parse(e.last))
      }
    }
    class << @lang
      def [](key)
        return super(Numeric) if key.is_a? Numeric
        return super(Symbol)  if key.is_a?(Symbol) && !self.values_at(key).first
        super(key)
      end
    end
  end

  def self.def_expr(name, *args)
    klass = Object.const_set(name.camelize, Class.new)
    klass.class_eval do
      attr_accessor *args
      define_method :initialize do |*values|
        args.zip(values).each do |var, value|
          instance_variable_set("@#{var}", value)
        end
      end
    end
  end

  def_expr(:var, :name)
  def_expr(:plus, :left, :right)
  def_expr(:minus, :left, :right)
  def_expr(:func, :var_name, :body)
  def_expr(:closure, :var_name, :body)
  def_expr(:call, :func, :param)
  def_expr(:let_direct, :var, :expr, :body)
  def_expr(:let_by_func, :var, :expr, :body)
  def_expr(:if, :cond, :if_true, :if_false)
  
  def_multi :evaluate, Numeric do |num| ; num end
  def_multi :evaluate, true  do ; true  end
  def_multi :evaluate, false do ; false end

  def_multi :evaluate, Plus do |plus|
    evaluate(plus.left) + evaluate(plus.right)
  end

  def_multi :evaluate, Minus do |minus|
    evaluate(minus.left) - evaluate(minus.right)
  end

  def_multi :evaluate, Var do |var|
    @env[var.name]
  end

  def_multi :evaluate, Func do |func|
    Closure.new(func.var_name, func.body)
  end

  def_multi :evaluate, Call do |call|
    closure = evaluate(call.func)
    @env[closure.var_name] = evaluate(call.param)
    evaluate(closure.body)
  end

  def_multi :evaluate, If do |stat|
    evaluate(stat.cond) ? evaluate(stat.if_true) : evaluate(stat.if_false)
  end

  def_multi :evaluate, LetDirect do |let_dir| 
    @env[let_dir.var] = evaluate(let_dir.expr)
    ret = evaluate(let_dir.body) ; @env.delete(let_dir.var) ; ret
  end  
  
  def_multi :evaluate, LetByFunc do |let_func|
    evaluate(Call.new(Func.new(let_func.var, let_func.body), let_func.expr))
  end

  def parse(expr)
    p expr
    # if s-expr
    if expr.is_a? Array
      @lang[expr.first].call(expr)
    else # if atom
      @lang[expr].call(expr)
    end
  end

  class << self ; undef :def_expr end

end
