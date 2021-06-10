import ballerina/test;

function exprBinaryDiv() returns Module {
    Module m = new ();
    FunctionDefn abort = m.addFunctionDefn("abort", {returnType:"void", paramTypes:[]});
    FunctionDefn foo = m.addFunctionDefn("foo", {returnType: "i64", paramTypes: ["i64", "i64"]});
    BasicBlock initBlock = foo.appendBasicBlock();
    Builder builder = new ();
    builder.positionAtEnd(initBlock);
    Value R0 = foo.getParam(0);
    Value R1 = foo.getParam(1);
    PointerValue R3 = builder.alloca("i64", 8);
    PointerValue R4 = builder.alloca("i64", 8);
    builder.store(R0, R3);
    builder.store(R1, R4);
    Value R5 = builder.load(R4);
    Value R6 = builder.iCmp("eq", R5, constInt("i64", 0));

    BasicBlock bb7 = foo.appendBasicBlock();
    BasicBlock bb10 = foo.appendBasicBlock();
    BasicBlock bb13 = foo.appendBasicBlock();
    BasicBlock bb14 = foo.appendBasicBlock();

    builder.condBr(R6, bb13, bb7);

    builder.positionAtEnd(bb7);
    Value R8 = builder.load(R3);
    Value R9 = builder.iCmp("eq", R8, constInt("i64",-9223372036854775808));
    builder.condBr(R9, bb10, bb14);

    builder.positionAtEnd(bb10);
    Value R11 = builder.load(R4);
    Value R12 = builder.iCmp("eq", R11, constInt("i64", -1));
    builder.condBr(R12, bb13, bb14);

    builder.positionAtEnd(bb13);
    _ = builder.call(abort,[]);

    builder.positionAtEnd(bb14);
    Value R15 = builder.load(R3);
    Value R16 = builder.load(R4);
    Value R17 = builder.binaryInt("sdiv", R15, R16);
    builder.ret(R17);
    return m;
}

@test:Config {}
function testExprBinaryDiv() returns error? {
    return runTest(exprBinaryDiv, "expr_binary_div.ll");
}
