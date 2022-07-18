import ballerina/io;
type R1 record {
    int l1;
};

type R2 record {|
    1|2 l1;
    int...;
|};

type T R1 & R2;

public function main() {
    T a = { l1: 1, "l2": 5 };
    int l2 = a["l2"]; // @error
    io:println(l2);
}
