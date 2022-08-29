type M1 record {|
    int l1;
    string l2;
|};

type M2 record {||};

type M3 record {|
    [int, string] l1;
|};

type L1 int[];

type M4 record {|
    L1 l1;
    M1 m1;
|};

type M5 record {
    int l1;
    string l2;
    int[] l3;
};

type M6 record {|
    int l1;
    string l2;
    int[] l3;
|};

type M7 record {
    int l1;
    string l2;
    any[] l3;
};

type M8 record {|
    int l1;
    string l2;
    any[] l3;
|};
