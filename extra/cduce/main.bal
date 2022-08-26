import ballerina/io;
import ballerina/file;
import wso2/nballerina.front.syntax as s;

public function main(string filePath) returns error? {
    s:ModulePart module = check compileBalFile(filePath);
    string filename = check file:basename(filePath);
    string outputName = filename.substring(0, filename.length() - 4) + ".cd";
    string[] outputBody = check transpileModulePart(module);
    return io:fileWriteLines(outputName, outputBody);
}

function compileBalFile(string filePath) returns s:ModulePart|error {
    string[] lines = check io:fileReadLines(filePath);
    s:SourceFile sourceFile = s:createSourceFile(lines, { filename: filePath });
    return s:parseModulePart(check s:scanModulePart(sourceFile, 0));
}
