import ballerina/io;
type F1 function(1|2) returns 3|4;
type F2 function(2|3) returns 4|5;

type F F1|F2;

public function main() {
    F f = foo; // @error
    3|4|5 res = f(2);
    io:println(res);
}

function foo(1 a) returns 4 {
    return 4;
}
