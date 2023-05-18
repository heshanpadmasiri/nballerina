import ballerina/io;
type F1 function(int) returns int;
type F2 function(string) returns int;

type Fx F1&F2;

public function main() {
    Fx fx = foo;
    int r1 = fx(1);
    io:println(r1); // @output 1
}

function foo(any a) returns int {
    return 1;
}
