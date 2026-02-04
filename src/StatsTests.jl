

"""
    apply

apply tests

"""


(t::TestSpecList)(data) = apply(t, data)
(t::TestSpec)(data) = apply(t, data)

function apply(tl::TestSpecList, data)

    [
        ts(data) for ts in tl.tests
    ]
end


function apply(t::TestSpec, data)

    spec = t.spec
    test = t.test

    if length(spec.colnames) > 0
        cols = [
            getcolumn(data, col) for col in spec.colnames
        ]
    else 

        a, b = modelcols(spec.formula, data)

        ub = unique(b)
        if length(b) > 10
            @error "Too many groups: likely wrong formula!"
        else
            cols = [
                getindex(a, findall(==(el), b)) for el in ub
            ]
        end
    end

    if _iscallable(test.name)
        res = test.name(cols..., test.args...)
    end

    res
end

