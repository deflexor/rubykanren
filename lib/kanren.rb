require 'pp'
# RubyVM::InstructionSequence.compile_option = { :tailcall_optimization => true,  :trace_instruction => false }

module Kanren

  @@LVARC = 0

  def deep_copy(o)
    Marshal.load(Marshal.dump(o))
  end

  def lvar(v = "lvar")
    @@LVARC += 1
    "#{v}#{@@LVARC}".to_sym
  end

  def is_lvar?(v)
    v.is_a? Symbol
  end

  def pair(a,b)
    return { :first => a, :second => b }
  end

  def lookup(v, s)
    if(!is_lvar?(v))
      v
    else
      (s.keys.include? v) ? lookup(s[v], s) : v
    end
  end

  def deep_lookup(v, s)
    v = lookup(v, s)
    if(is_pair_or_list? v)
        [ deep_lookup( first(v), s ), deep_lookup( rest(v), s ) ].flatten 1
    else
        v
    end
  end

  def is_pair?(obj)
    obj.respond_to?(:keys) && obj.keys.include?(:first) && obj.keys.include?(:second)
  end

  def is_list?(l)
    l.is_a?(Array)
  end

  def is_empty_list?(l)
    l.is_a?(Array) && l.size == 0
  end

  def non_empty_list?(l)
    l.is_a?(Array) && l.size > 0
  end

  def is_pair_or_list?(obj)
    return is_pair?(obj) || non_empty_list?(obj)
  end

  def first(obj)
    is_pair?(obj) ? obj[:first] : obj[0]
  end

  def rest(obj)
    is_pair?(obj) ? obj[:second] : obj[1..-1]
  end

  def unify(t1, t2, s)
    r = unify2(t1, t2, s)
    #puts("unify(%s,%s,%s) => %s", JSON.stringify(t1), JSON.stringify(t2), JSON.stringify(s), JSON.stringify(r))
    r
  end

  def unify2(t1, t2, s)
    if(!s)
      return false
    end
    t1 = lookup(t1, s)
    t2 = lookup(t2, s)
    if(is_empty_list?(t1) && is_empty_list?(t2))
      return s
    end
    if(t1 === t2)
      return s
    end
    if(is_lvar?(t1))
        new_s = deep_copy(s)
        new_s[t1] = t2
        return new_s
    end
    if(is_lvar?(t2))
        new_s = deep_copy(s)
        new_s[t2] = t1
        return new_s
    end
    if(is_pair_or_list?(t1) && is_pair_or_list?(t2))
        s_head = unify(first(t1), first(t2),s)
        return s_head ? unify(rest(t1), rest(t2),s_head) : s_head
    end
    #if(t1 == t2) return s;
    # case when none of vars is list or lvar
    false
  end

  def succeed(x)
    [x]
  end

  def fail(x = nil)
    []
  end

  def disj2(f1, f2)
    ->(x) {
      v1 = f1.respond_to?(:call) ? f1.call(x) : []
      v2 = f2.respond_to?(:call) ? f2.call(x) : []
      v1 + v2
      #f1.call(x) + f2.call(x)
    }
  end

  def disj(*args0)
    args = args0.flatten()
    if(args.length > 0)
      args.reduce { |a, v| disj2(a, v) }
    else
      ->(x) { [] }
    end
  end

  def bind(mv, f)
    mv.map { |x| f.(x) }.flatten(1)
  end

  def conj2(f1, f2)
    ->(x) {
        bind( f1.(x), f2 );
    }
  end

  def conj(*args0)
    args = args0.flatten()
    if(args.length > 0)
      args.reduce { |a, v| conj2(a, v) }
    else
      ->(x) { [] }
    end
  end

  def run(*args)
    lv = first(args)
    conj( rest(args) ).({}).map { |s| deep_lookup(lv, s) }
  end

#  Logic system 

  def eqo(t1, t2)
    ->(s) {
        s1 = unify(t1, t2, s);
        s1 ? succeed(s1) : fail(s)
    }
    end

  #  existo(x, l) succeeds if x is member of l  
  def existo(v, lst)
      if(non_empty_list?(lst))
        disj( eqo(v, first(lst)), existo(v, rest(lst)) )
      else
        fail
      end
  end

  def commono(x, lst1, lst2)
      conj(existo(x,lst1), existo(x, lst2))
  end

  #  conso(a, b, lst) is a goal that succeeds if in the current state
  # of the world, pair(a, b) is the same as l  
  def conso(a, b, lst)
      #puts("conso(%o,%o,%o)", a, b, lst);
      return eqo( pair(a, b), lst );
  end

  #   appendo(l1, l2, l3) holds if the list l3 is the
  #   concatenation of lists l1 and l2.  
  def appendo(l1, l2, l3)
      #puts("appendo(%o,%o,%o)", l1, l2, l3);
      h = lvar("h")
      t = lvar("t")
      p = lvar("p")
      disj(
          conj( eqo(l1, []), eqo(l2, l3) ),
          conj( conso(h, t, l1),
                conso(h, p, l3),
                ->(s) { appendo(t, l2, p).(s) }
          )
      )
  end

  #  membero(x, l) succeeds if x is member of l  
  def  membero(x, l)
      #puts("membero(%o,%o)", x, l);
      h = lvar("h");
      t = lvar("t");
      disj(
          conso(x, t, l),
          conj( conso(h, t, l),
                ->(s) { membero(x, t).(s) }
          )
      );
  end

  #  firsto(l, a) succeeds if l is a first element of a  
  def firsto(l, a)
      conso(a, lvar(), l)
  end

end
