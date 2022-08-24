import ballerina/io;
import wso2/nballerina.front.syntax as s;

public function main() {
    // TODO: take the input file path as arg
	io:println("Helloe");
}

function compileBalFile(string filePath) returns s:ModulePart|error {
    string[] lines = check io:fileReadLines(filePath);
    s:SourceFile sourceFile = s:createSourceFile(lines, { filename: filePath });
    return s:parseModulePart(check s:scanModulePart(sourceFile, 0));
}

// TODO: turn panics to warnings
function transpileModulePart(s:ModulePart modulePart) returns string[] {
    if modulePart.importDecls.length() != 0 {
        panic error("imports");
    }
    string[] body = [];
    foreach s:ModuleLevelDefn defn in modulePart.defns {
        if defn !is s:TypeDefn {
            panic error("non-type defns");
        }
        body.push(typeDefnToCDuce(defn));
    }
    return body;
}

function typeDefnToCDuce(s:TypeDefn defn) returns string {
    string definition = typeDescToCDuce(defn.td);
    return string `type ${defn.name} = ${definition};;`;
}

function typeDescToCDuce(s:TypeDesc td) returns string {
    if td is s:BuiltinTypeDesc {
        return builtinTypeDescToCDuce(td);
    }
    panic error("not implemented");
}

public type SubsetBuiltinTypeName "any"|"anydata"|"boolean"|"byte"|"int"|"decimal"|"float"|"string"|"error";
function builtinTypeDescToCDuce(s:BuiltinTypeDesc td) returns string {
    match td.builtinTypeName {
        // TODO: this should be a a warning (CDuce any includes error)
        "any"|"anydata" => { return "Any"; }
        "boolean" => { return "Bool"; }
        "byte" => { return "0--255"; }
        "int" => { return "Int"; }
        // TODO: this should result in warning
        "decimal" => { return "Float"; }
        "float" => { return "Float"; }
        "string" => { return "String"; }
    }
    panic error("not implemented");
}
