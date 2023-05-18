import ballerina/io;
type F1 function(int) returns 1|2;
type F2 function(string) returns 2|3;

type Fx F1&F2;

public function main() {
    Fx fx = foo;
    2 r1 = fx(1);
    io:println(r1); // @output 2
}

function foo(any a) returns 2 {
    return 2;
}
