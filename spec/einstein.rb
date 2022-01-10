require 'rspec'
require_relative '../lib/kanren'

module Ein

    include Kanren

    def righto(x, y, l)
        t = lvar("t");
        disj(
            conj(
                conso(x, t, l),
                conso(y, lvar(), t)
            ),
            conj(
                conso(lvar(), t, l),
                ->(s) { righto(x, y, t).(s) }
            )
        )
    end

    def nexto(x, y, l)
        disj(
            righto(x, y, l),
            righto(y, x, l)
        )
    end

    def zebrao(houses)
        return conj(
            eqo([lvar(), lvar(), lvar(), lvar(), lvar()], houses),
            membero(["Englishman",lvar(),lvar(),lvar(),"red"], houses),
            membero(["Swede",lvar(),lvar(),"dog",lvar()], houses),
            membero(["Dane",lvar(),"tea",lvar(),lvar()], houses),
            righto([lvar(),lvar(),lvar(),lvar(),"white"], [lvar(),lvar(),lvar(),lvar(),"green"], houses),
            membero([lvar(), lvar(), 'coffee', lvar(), 'green'], houses),
            membero([lvar(), 'Pall Mall', lvar(), 'birds', lvar()], houses),
            membero([lvar(), 'Dunhill', lvar(), lvar(), 'yellow'], houses),
            eqo([lvar(), lvar(), [lvar(), lvar(), 'milk', lvar(), lvar()], lvar(), lvar()], houses),
            eqo([['Norwegian', lvar(), lvar(), lvar(), lvar()], lvar(), lvar(), lvar(), lvar()], houses),
            nexto([lvar(), 'Blend', lvar(), lvar(), lvar()],[lvar(), lvar(), lvar(), 'cats', lvar()], houses),
            nexto([lvar(), 'Dunhill', lvar(), lvar(), lvar()],[lvar(), lvar(), lvar(), 'horse', lvar()], houses),
            membero([lvar(), 'Blue Master', 'beer', lvar(), lvar()], houses),
            membero(['German', 'Prince', lvar(), lvar(), lvar()], houses),
            nexto(['Norwegian', lvar(), lvar(), lvar(), lvar()],[lvar(), lvar(), lvar(), lvar(), 'blue'], houses),
            nexto([lvar(), 'Blend', lvar(), lvar(), lvar()],[lvar(), lvar(), 'water', lvar(), lvar()], houses),
            membero([lvar(), lvar(), lvar(), 'zebra', lvar()], houses)
        )
    end

end

describe Ein do
    subject(:mod) { Class.new.extend(described_class) }

    it 'solves' do
        q = mod.lvar("q")
        sols = mod.run(q,  mod.zebrao(q))

        sol = []
        sols[0].each_slice(5) do |a|
            if(a[3] == 'zebra')
                sol = a
            end
        end

        expect( sol.length ).to eq( 5 )
        # German owns Zebra
        expect( sol[0] ).to eq( "German" )
    end
   
end