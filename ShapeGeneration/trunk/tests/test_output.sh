#!/bin/bash
for foo in par dat
do
    diff test.${foo} tests/GoodResults/test.${foo}
done
