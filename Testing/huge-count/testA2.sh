#!/bin/csh

echo "Test A2 for huge-count.pl"
echo "Running huge-count.pl --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A2.output test-A2.data"

huge-count.pl --newLine --token token.regex --nontoken nontoken.regex --stop stoplist test-A2.output test-A2.data

# testing count

foreach i (1 2 3 4)
	sort test-A2.output/test-A2.data$i.bigrams > t0
	sort test-A2.reqd/test-A2.data$i.bigrams > t1
	diff t0 t1 > var$i
end

if(-z var1 && -z var2 && -z var3 && -z var4) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A2.reqd/test-A2.data1.bigrams";
        cat var1;
        echo "When tested against test-A2.reqd/test-A2.data2.bigrams";
        cat var2;
        echo "When tested against test-A2.reqd/test-A2.data3.bigrams";
        cat var3;
        echo "When tested against test-A2.reqd/test-A2.data4.bigrams";
        cat var4;
endif

/bin/rm -f var1 var2 var3 var4 t0 t1

# testing final output

sort test-A2.output/huge-count.output > t0
sort test-A2.reqd/huge-count.output > t1

diff -w t0 t1 > var1

if(-z var1) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A2.reqd/huge-count.output";
        cat var1;
endif

/bin/rm -f -r var1 t0 t1 test-A2.output
