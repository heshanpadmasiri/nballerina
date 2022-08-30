import wso2/nballerina.front.syntax as s;
import ballerina/io;

type TypeRef string;
type BaseType s:BuiltinTypeName|"list"|"top";

type Range record {|
    int startPos;
    int endPos;
|};

function transpileModulePart(s:ModulePart modulePart, s:SourceFile file) returns string[]|error {
    TranspileContext cx = new(file);
    foreach s:ModuleLevelDefn defn in modulePart.defns {
        if defn !is s:TypeDefn {
            warning(cx, "module level definitions that are not type definitions will be ignored", { startPos: defn.startPos, endPos: defn.endPos });
            continue;
        }
        var [name, definition] = check typeDefnToCDuce(cx, defn);
        cx.addTypeDefn(name, definition);
    }
    return cx.finalize();
}

// Used to genrate BuiltinTypeDesc avoiding duplicates
class TranspileContext {
    private final map<TypeRef> definedTypes = {};
    private final string[] lines = [];
    private final string[] baseTypeDefns = [];
    s:SourceFile file;

    function init(s:SourceFile file) {
        self.file = file;	
    }

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
                definition = "(`error, Any)";
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

function typeDefnToCDuce(TranspileContext cx, s:TypeDefn defn) returns [string, string]|error {
    string definition = check typeDescToCDuce(cx, defn.td);
    return [defn.name, definition];
}

function typeDescToCDuce(TranspileContext cx, s:TypeDesc td) returns string|error {
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

function binaryTypeToCDuce(TranspileContext cx, s:BinaryTypeDesc td) returns string|error {
    string seperator = " " + td.op + " ";
    return seperator.'join(...from var operand in td.tds select check typeDescToCDuce(cx, operand));
}

function constructorTypeDescToCDuce(TranspileContext cx, s:ConstructorTypeDesc td) returns string|error {
    if td is s:TupleTypeDesc {
        return tupleTypeDescToCDuce(cx, td);
    }
    else if td is s:ArrayTypeDesc {
        return arrayTypeDescToCDuce(cx, td);
    }
    else if td is s:MappingTypeDesc {
        return mappingTypeDescToCDuce(cx, td);
    }
    else if td is s:ErrorTypeDesc {
        return errorTypeDescToCDuce(cx, td);
    }
    else if td is s:FunctionTypeDesc|s:XmlSequenceTypeDesc|s:TableTypeDesc {
        panic error(td.toString() + "not implemented");
    }
}

function errorTypeDescToCDuce(TranspileContext cx, s:ErrorTypeDesc td) returns string|error {
    string[] body = ["(", "`error", ", ", check typeDescToCDuce(cx, td.detail), ")"];
    return "".'join(...body);
}

function mappingTypeDescToCDuce(TranspileContext cx, s:MappingTypeDesc td) returns string|error {
    string[] body = ["{"];
    // TODO: turn this in to a query expression
    foreach s:FieldDesc fd in td.fields {
        body.push(fd.name, "=", (checkpanic typeDescToCDuce(cx, fd.typeDesc))+ ";");
    }
    var rest = td.rest;
    if rest !is () {
        if rest !is s:INCLUSIVE_RECORD_TYPE_DESC {
            warning(cx, "approximating record type open record type", { startPos: rest.startPos, endPos: rest.endPos });
        }
        body.push("..");
    }
    body.push("}");
    return " ".'join(...body);
}

function tupleTypeDescToCDuce(TranspileContext cx, s:TupleTypeDesc td) returns string|error {
    return listTypeDescToCDuceInner(cx, td.members, td.rest);
}

function arrayTypeDescToCDuce(TranspileContext cx, s:ArrayTypeDesc td) returns string|error {
    string[] body = [];
    foreach var dimension in td.dimensions {
        if dimension is () {
            body.push(check listTypeDescToCDuceInner(cx, [], td.member));
        }
        else if dimension is s:IntLiteralExpr {
            int size = dimension.base is 10 ? check int:fromString(dimension.digits) : check int:fromHexString(dimension.digits);
            body.push(check listTypeDescToCDuceInner(cx, from var _ in 0..<size select td.member, ()));
        }
        else {
            panic error("non integer dimensions not implemented");
        }
    }
    string defn = " ".'join(...body);
    if body.length() > 1 {
        defn = "[" + defn + "]";
    }
    return defn;
}

function listTypeDescToCDuceInner(TranspileContext cx, s:TypeDesc[] members, s:TypeDesc? rest) returns string|error {
    string[] body = ["["];
    foreach int i in 0 ..< members.length() {
        if i > 0 {
            body.push(" ");
        }
        body.push(check typeDescToCDuce(cx, members[i]));
    }
    if rest != () {
        if body.length() != 1 {
            body.push(" ");
        }
        body.push(check typeDescToCDuce(cx, rest) + "*");
    }
    body.push("]");
    return "".'join(...body);
}

function warning(TranspileContext cx, string body, Range range) {
    s:SourceFile file = cx.file;
    string fileName = file.filename();
    var [startLine, startColumn] = file.lineColumn(range.startPos);
    var [endLine, endColumn] = file.lineColumn(range.endPos);
    (string|int)[] positionBody = ["[",fileName,":", "(", startLine, ":", startColumn, ",", endLine, ":", endColumn, ")","]", " "];
    string positionPart = "".'join(...from var each in positionBody select each.toString());
    io:println("WARNING: ", positionPart, body);
}
