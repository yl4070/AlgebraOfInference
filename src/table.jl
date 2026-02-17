using SummaryTables: simple_table
using IOCapture

"""
specs | name of test | p_value | 

"""

function get_labels(t::TestRes)

    t.spec.label
end


function table(test_outs::Vector{TestRes})

    pvals = pvalue.(test_outs)
    specs = get_labels.(test_outs)

    
    baretest = map(test_outs) do t
        t.res
    end

    c = IOCapture.capture() do 
        baretest 
    end

    testnames = c.value .|>  typeof

    data = (
        testname = testnames,
        specs = specs,
        pvals = pvals
    )


    simple_table(
        data, [:testname => "Test Name", :specs => "Specification", :pvals => "P-values"]
    )
end

