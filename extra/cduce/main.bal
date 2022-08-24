import ballerina/io;
import wso2/nballerina.front.syntax as s;

public function main() {
	io:println("Helloe");
}

function compileBalFile(string filePath) returns s:ModulePart|error {
    string[] lines = check io:fileReadLines(filePath);
    s:SourceFile sourceFile = s:createSourceFile(lines, { filename: filePath });
    return s:parseModulePart(check s:scanModulePart(sourceFile, 0));
}
