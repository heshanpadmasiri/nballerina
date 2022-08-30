import ballerina/io;
import ballerina/file;
import wso2/nballerina.front.syntax as s;

public function main(string filePath) returns error? {
    s:SourceFile file = check createSourceFile(filePath);
    s:ModulePart module = check compileBalFile(file);
    string filename = check file:basename(filePath);
    string outputName = filename.substring(0, filename.length() - 4) + ".cd";
    string[] outputBody = check transpileModulePart(module, file);
    return io:fileWriteLines(outputName, outputBody);
}

function createSourceFile(string filePath) returns s:SourceFile|error {
    string[] lines = check io:fileReadLines(filePath);
    return s:createSourceFile(lines, { filename: filePath });
}

function compileBalFile(s:SourceFile file) returns s:ModulePart|error {
    return s:parseModulePart(check s:scanModulePart(file, 0));
}
