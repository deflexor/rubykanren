require 'rspec'
require_relative '../lib/kanren'

describe Kanren do
  subject(:mod) { Class.new.extend(described_class) }
  let(:f1) { ->(x) { [x+1] } }
  let(:f2) { ->(x) { [x*2] } }
  let(:f3) { ->(x) { [x-1] } }
  
  
  it 'creates logic var' do
    mod::LVARC = 1
    expect(mod.lvar).to eq :lvar1
    expect(mod.lvar).to eq :lvar2
    expect(mod.lvar "x").to eq :x3
  end
  
  it 'creates logic var and checks for it' do
    mod::LVARC = 1
    lv = mod.lvar
    expect(mod.is_lvar? lv).to be true
  end
  
  
  it 'unifies' do
    expect( mod.unify(1, 1, {}) ).to eq( {} )
    expect( mod.unify(1, 2, {}) ).to eq( false )
    
    expect( mod.unify(:x, 1, {}) ).to eq( { x: 1 } )
    expect( mod.unify(1, :x, {}) ).to eq( { x: 1 } )
    expect( mod.unify(1, :x, { x: 1 }) ).to eq( { x: 1 }  )
    
    expect(mod.unify(:x, :y, {})).to eq( { x: :y } )
    expect( mod.unify(:y, :x, {}) ).to eq( { y: :x } )
    
    expect( mod.unify(:y, [1], {}) ).to eq( { y: [1] } )
    expect( mod.unify([1], :y, {}) ).to eq( { y: [1] } )
    
    
    expect(mod.unify(:y, [], {})).to eq( { y: [] } )
    
    expect( mod.unify([:x], [1], {}) ).to eq( { x: 1 } )
    expect( mod.unify([1], [:x], {}) ).to eq( { x: 1 } )
    
    expect( mod.unify([:x], [1, 2], {}) ).to eq( false )
    
    expect( mod.unify(mod.pair(:x, :y), [:z], { z: 3 }) ).to eq( { x: 3, z: 3, y: [] } )
    expect( mod.unify(mod.pair(:x, :y), [1, 2, 3], {}) ).to eq( {:x=>1, :y=>[2, 3]} )
    
  end
  
  it 'disjoins' do
    expect(mod.disj(f1, f2, f3).(3)).to eq( [4, 6, 2] )
    f = mod.disj(
      mod.disj(mod.method(:fail), mod.method(:succeed)),
      mod.conj( 
        mod.disj(
        ->(x) { mod.succeed(x + 1) },
        ->(x) { mod.succeed(x + 10) }
        ),
        mod.disj(mod.method(:succeed), mod.method(:succeed))
      )
    )
    expect( f.(100) ).to eq ( [100,101,101,110,110] )
    expect( mod.disj2(f1, f2).(2) ).to eq( [3,4] )
    expect( mod.disj(f1, f2).(2) ).to eq( [3,4] )
    expect( mod.disj(f1, f2, f3).(2) ).to eq( [3,4,1] )
    expect( mod.disj(f1).(2) ).to eq( [3] )
    expect( mod.disj().(2) ).to eq( [] )
  end
  
  it 'binds' do
    expect( mod.bind([1], f1) ).to eq( [2] )
    expect( mod.bind([], f1) ).to eq( [] )
  end
  
  it 'conjoins' do
    expect( mod.conj(f1, f2, f3).(3) ).to eq( [7] )
    expect( mod.conj(f1).(2) ).to eq( [3] )
    expect( mod.conj2(f1, f2).(2) ).to eq( [6] )
    expect( mod.conj(f1, f2).(2) ).to eq( [6] )
  end
  
  #
  # Logic
  #
  
  it "should eqo" do
    expect( mod.eqo(:x, 1).({}) ).to eq( [{ :x => 1  }] )
  end
  
  it "should existo" do
    expect( mod.existo(2, [1, 2, 3]).({}) ).to eq( [{}] );
    expect( mod.existo(:x, [1, 2, 3]).({}) ).to eq( [{:x => 1}, {:x => 2}, {:x => 3}] )
  end
  
  it "should commono" do
    expect( mod.run( :q, mod.commono(:q, [1, 2, 4, 5], [1, 2, 3]) ) ).to eq( [1,2])
    expect( mod.run( :q, mod.commono(:q,  [4, 5], [2, 3]) ) ).to eq( [] );
  end
  
  it "should conso" do
    expect( mod.run( :q, mod.conso( 1, [2, 3], :q)) ).to eq( [[1,2,3]] )
    expect( mod.run( :q,
      mod.eqo( :q, [ :x, :y ]),
      mod.conso( :x, :y, [1, 2, 3]) 
    )).to eq( [[ 1,2,3 ]] )
  end 
  
  
  it "should appendo" do
   expect( mod.run( :q, mod.appendo([1, 2, 3], :q,  [1, 2, 3, 4, 5]) ) ).to eq( [[4,5]] )
  end
  
  it "should membero" do
    expect( mod.run( :q, mod.membero(1, [1, 2, 3]) ) ).to eq( [:q] )
    expect( mod.run( :q, mod.membero(4, [1, 2, 3]) ) ).to eq( [] )
  end
  
  
end
