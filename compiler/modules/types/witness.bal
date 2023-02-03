import wso2/nballerina.comm.lib;

// FIXME: remove cell
public type WitnessableSubtype MappingAtomicType|ListSubtypeWitness|StringSubtype|DecimalSubtype|FloatSubtype|IntSubtype|BooleanSubtype;

public type ListWitnessValue readonly & record {|
    WitnessValue[] memberValues;
    int[] indices;
    int fixedLen;
|};

public type WitnessValue WrappedSingleValue|string|map<WitnessValue>|ListWitnessValue?;

final readonly & [BasicTypeBitSet, WrappedSingleValue|string][] basicTypeSample = [
// FIXME: NEVER is 0 for bit checks here wont work
    [NEVER, "never"],
    [NIL, "()"],
    [BOOLEAN, { value: true }],
    [INT, { value: 42 }],
    [FLOAT, { value: 2.5f }],
    [DECIMAL, { value: 3.5d }],
    [STRING, { value: "non empty string" }],
    [ERROR, "error"],
    [LIST, "list"],
    [MAPPING, "map"],
    [TABLE, "table"],
    [FUNCTION, "function"],
    [TYPEDESC, "typedesc"],
    [HANDLE, "handle"],
    [XML, "xml"],
    [CELL, "cell"]
];

public class WitnessCollector {
    private WitnessValue witness;
    private Context cx;

    public function init(Context cx) {
        // io:println("creating witness collector");
        self.cx = cx;
        self.witness = ();
    }

    public function remainingSubType(WitnessableSubtype|error subtypeData) {
        // lock {
            if self.witness == () && subtypeData !is error {
                self.witness = subtypeToWitnessValue(self.cx, subtypeData);
            }
        // }
    }

    public function allOfTypes(BasicTypeBitSet all) {
        // lock {
            self.witness = basicTypesToWitnessValue(all);
        // }
    }

    public function get() returns WitnessValue {
        // lock {
            return self.witness;
        // }
    } 

    public function set(WitnessValue witness) {
        // lock {
            self.witness = witness;
        // }
    }
}

function basicTypesToWitnessValue(BasicTypeBitSet bitset) returns WrappedSingleValue|string? {
    foreach var [bt, sample] in basicTypeSample {
        if (bt & bitset) != 0 {
            return sample;
        }
    }
    return ();
}

function semTypeToWitnessValue(Context cx, SemType t) returns WitnessValue {
    if t is BasicTypeBitSet {
        return basicTypesToWitnessValue(t);
    }
    // else if t is CellSemType {
    //     return cellSemTypeToWitness(cx, t);
    // }
    else {
        if t.all != 0 {
            return basicTypesToWitnessValue(t.all);
        }
        foreach var [code, _] in basicTypeSample {
            if (code & t.some) != 0 {
                BasicTypeCode? btCode = basicTypeCode(widenToBasicTypes(code));
                if btCode == () {
                    continue;
                }
                SubtypeData subtypeData = getComplexSubtypeData(t, btCode);
                if subtypeData is WitnessableSubtype {
                    return subtypeToWitnessValue(cx, subtypeData);
                }
                else if subtypeData is BddNode {
                    return bddToWitness(cx, btCode, subtypeData);
                }
                else {
                    return "[Unsupported witness shape]";
                }
            }
        }
        return ();
    }
}

// function cellSemTypeToWitness(Context cx, CellSemType t) returns WitnessValue {
//     if cellAtomicType(t) != () {
//         return semTypeToWitnessValue(cx, cellInner(t));
//     }
//     WitnessCollector tmpWitness = new(cx);
//     var _ = isEmptyWitness(cx, t, tmpWitness);
//     return tmpWitness.get();
//     // FIXME: this is wrong (but good enough for passing tests)
//     // var bdd = t.subtypeDataList[0]; 
//     // if bdd !is BddNode {
//     //     return "[Cell unexpected subtype: " + bdd.toString() + "]";
//     // }
//     // var typeAtom = (<BddNode>bdd.right).atom;
//     // if typeAtom !is TypeAtom {
//     //     return "[Cell unexpected recAtom: " + typeAtom.toString() + "]";
//     // }
//     // var atomicType = typeAtom.atomicType;
//     // if atomicType is ListAtomicType {
//     //     if cx.listMemo.hasKey(bdd) {
//     //         return cx.listMemo.get(bdd).witness;
//     //     }
//     //     return "[Cell unknown list Atom: " + bdd.toString() + "]";
//     // }
//     // else if atomicType is MappingAtomicType {
//     //     if cx.mappingMemo.hasKey(bdd) {
//     //         return cx.mappingMemo.get(bdd).witness;
//     //     }
//     //     return "[Cell unknown mapping Atom: " + bdd.toString() + "]";
//     // }
//     // return semTypeToWitnessValue(cx, (<CellAtomicType>atomicType).ty);
// }

function subtypeToWitnessValue(Context cx, WitnessableSubtype subtype) returns WitnessValue {
    if subtype is MappingAtomicType {
        return createMappingWitness(cx, subtype);
    }
    else if subtype is StringSubtype {
        return createStringWitness(subtype);
    }
    else if subtype is DecimalSubtype {
        return createDecimalWitness(subtype);
    }
    else if subtype is FloatSubtype { 
        return createFloatWitness(subtype);
    }
    else if subtype is BooleanSubtype {
        return createBooleanWitness(subtype);
    }
    else if subtype is ListSubtypeWitness {
        return createListWitness(cx, subtype);
    }
    // else if subtype is CellAtomicType {
    //     return createCellWitness(cx, subtype);
    // }
    else {
        return createIntWitness(subtype);
    }
}

function bddToWitness(Context cx, BasicTypeCode typeCode, BddNode bdd) returns WitnessValue {
    if typeCode == BT_CELL {
        WitnessCollector innerWitness = new(cx);
        _ = cellSubtypeIsEmptyWitness(cx, bdd, innerWitness);
        // return string `[cell bdd ${bdd.toString()} -> ${innerWitness.get().toString()}]`;
        return innerWitness.get();
    }
    BddMemo? m = ();
    if typeCode == BT_LIST {
        m = cx.listMemo[bdd];
    }
    else if typeCode == BT_MAPPING {
        m = cx.mappingMemo[bdd];
    }
    return m != () ? m.witness : ();
}

function createMappingWitness(Context cx, MappingAtomicType subtype) returns WitnessValue {
    map<WitnessValue> witness = {};
    foreach int i in 0 ..< subtype.names.length() {
        // TODO: handle never correctly (we can use cell inner with never)
        witness[subtype.names[i]] = semTypeToWitnessValue(cx, subtype.types[i]);
    }
    if cellInnerVal(subtype.rest) != NEVER {
        witness["..."] = semTypeToWitnessValue(cx, subtype.rest);
    }
    return witness;
}

// FIXME:
function createListWitness(Context cx, ListSubtypeWitness listWitnessType) returns ListWitnessValue {
    var { memberTypes, indices, fixedLen } = listWitnessType;
    foreach var each in memberTypes {
        if each !is CellSemType {
            panic error("unexpected");
        }
    }
    WitnessValue[] memberValues = from var m in memberTypes select semTypeToWitnessValue(cx, m);
    return { memberValues: memberValues.cloneReadOnly(), indices, fixedLen };
}

function createStringWitness(StringSubtype subtype) returns WrappedSingleValue {
    var { char, nonChar } = subtype;
    if nonChar.allowed {
        if nonChar.values.length() > 0 {
            return { value: nonChar.values[0] };
        }
    }
    else {
        return createRandomStringWitness(4, nonChar.values);
    }
    if char.allowed {
        if char.values.length() > 0 {
            return { value: char.values[0] };
        }
    }
    else {
        return createRandomStringWitness(1, char.values);
    }
    panic error("not implemented!");
}

function createRandomStringWitness(int len, string[] exclude) returns WrappedSingleValue {
    lib:Random random = new(11);
    while true {
        string value = random.randomStringValue(len);
        if exclude.indexOf(value) == () {
            return { value };
        }
    }
}

function createDecimalWitness(DecimalSubtype subtype) returns WrappedSingleValue {
    if subtype.allowed {
        return { value: subtype.values[0] };
    }
    else {
        lib:Random random = new(11);
        while true {
            do {
                decimal value = check decimal:fromString(string `${random.next()}.${random.next()}`);
                if subtype.values.indexOf(value) == () {
                    return { value };
                }
            } on fail error e {
                // ignore the error and re iterate the while loop.
                _ = e.message();
            }
        }
    }
}

function createFloatWitness(FloatSubtype subtype) returns WrappedSingleValue {
    if subtype.allowed {
        return { value: subtype.values[0] };
    }
    else {
        lib:Random random = new(11);
        while true {
            do {
                float value = check float:fromString(string `${random.next()}.${random.next()}`);
                if subtype.values.indexOf(value) == () {
                    return { value };
                }
            } on fail error e {
                // ignore the error and re iterate the while loop.
                _ = e.message();
            }
        }
    }
}


function createIntWitness(IntSubtype subtype) returns WrappedSingleValue {
    return { value: subtype[0].min };
}

function createBooleanWitness(BooleanSubtype subtype) returns WrappedSingleValue {
    return { value: subtype.value };
}

