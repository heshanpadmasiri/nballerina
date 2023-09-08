import ballerina/io;
type F function(int) returns int;

public function main() {
    int val = 10;
    F a = function(int p) returns int {
        val *= 2;
        return val + p;
    };
    F b = function(int p) returns int {
        val = val + a(p);
        return val;
    };
    io:println(b(3)); // @output 43
    io:println(val); // @output 43
}
