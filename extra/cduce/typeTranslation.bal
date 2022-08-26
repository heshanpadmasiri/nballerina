import wso2/nballerina.front.syntax as s;

type TypeRef string;
type BaseType s:BuiltinTypeName|"list"|"top";

// TODO: turn panics to warnings
function transpileModulePart(s:ModulePart modulePart) returns string[] {
    if modulePart.importDecls.length() != 0 {
        panic error("imports");
    }
    TranspileContext cx = new();
    foreach s:ModuleLevelDefn defn in modulePart.defns {
        if defn !is s:TypeDefn {
            panic error("non-type defns");
        }
        var [name, definition] = typeDefnToCDuce(cx, defn);
        cx.addTypeDefn(name, definition);
    }
    return cx.finalize();
}

// Used to genrate BuiltinTypeDesc avoiding duplicates
class TranspileContext {
    private final map<TypeRef> definedTypes = {};
    private final string[] lines = [];
    private final string[] baseTypeDefns = [];

    function basetypeToCDuce(BaseType typeName) returns TypeRef {
        if self.definedTypes.hasKey(typeName) {
            return self.definedTypes.get(typeName);
        }
        return self.createBaseType(typeName);
    }

    function createBaseType(BaseType typeName) returns TypeRef {
        string name = self.baseTypeName(typeName);
        self.definedTypes[typeName] = name;
        string? definition = ();
        match typeName {
            "any" => {
                BaseType[] members = ["null", "string", "int", "boolean", "list"];
                definition = self.createUnion(from var member in members select self.basetypeToCDuce(member));
            }
            "boolean" => {
                definition = "Bool";
            }
            "byte" => {
                definition = "0--255";
            }
            "decimal" => {
                definition = "(`decimal, (Int, Int))";
            }
            "error" => {
                definition = "`error";
            }
            "float" => {
                definition = "Float";
            }
            "int" => {
                definition = "Int";
            }
            "list" => {
                definition = string `[${self.basetypeToCDuce("top")}*]`;
            }
            "null" => {
                definition = "`null";
            }
            "string" => {
                definition = "String";
            }
            "top" => {
                BaseType[] members = ["any", "error"];
                definition = self.createUnion(from var member in members select self.basetypeToCDuce(member));
            }
        }
        if definition !is string {
            panic error("Unimplemented type construction for " + typeName);
        }
        self.addTypeDefn(name, definition, self.baseTypeDefns);
        return name;
    }

    function finalize() returns string[] {
        string[] output = from var line in self.baseTypeDefns select line;
        output.push("");
        output.push(...(from var line in self.lines select line));
        return output;
    }

    function addTypeDefn(string name, string definition, string[]? buffer=()) {
        string[] targetBuffer = buffer ?: self.lines; 
        targetBuffer.push(string `type ${name} = ${definition}`);
    }

    private function baseTypeName(string typeName) returns string {
        string firstChar = typeName[0].toUpperAscii();
        return "B" + firstChar + typeName.substring(1);
    }


    private function createUnion(TypeRef[] refs) returns string {
        string seperator = " | ";
        return seperator.'join(...refs);
    }

}

function typeDefnToCDuce(TranspileContext cx, s:TypeDefn defn) returns [string, string] {
    string definition = typeDescToCDuce(cx, defn.td);
    return [defn.name, definition];
}

function typeDescToCDuce(TranspileContext cx, s:TypeDesc td) returns string {
    if td is s:BuiltinTypeDesc {
        return cx.basetypeToCDuce(td.builtinTypeName);
    }
    else if td is s:BinaryTypeDesc {
        return binaryTypeToCDuce(cx, td);
    }
    else if td is s:TypeDescRef {
        return td.typeName;
    }
    else if td is s:ConstructorTypeDesc {
        return constructorTypeDescToCDuce(cx, td);
    }
    panic error(td.toString() + "not implemented");
}

function binaryTypeToCDuce(TranspileContext cx, s:BinaryTypeDesc td) returns string {
    string seperator = " " + td.op + " ";
    return seperator.'join(...from var operand in td.tds select typeDescToCDuce(cx, operand));
}

function constructorTypeDescToCDuce(TranspileContext cx, s:ConstructorTypeDesc td) returns string {
    if td is s:TupleTypeDesc {
        return tupleTypeDescToCDuce(cx, td);
    }
    panic error(td.toString() + "not implemented");
}

function tupleTypeDescToCDuce(TranspileContext cx, s:TupleTypeDesc td) returns string {
    string[] body = ["["];
    foreach int i in 0 ..< td.members.length() {
        if i > 0 {
            body.push(" ");
        }
        body.push(typeDescToCDuce(cx, td.members[i]));
    }
    s:TypeDesc? rest = td.rest;
    if rest != () {
        if body.length() != 1 {
            body.push(" ");
        }
        body.push(typeDescToCDuce(cx, rest) + "*");
    }
    body.push("]");
    return "".'join(...body);
}
