import ballerina/test;
import ballerina/io;
import ballerina/file;
import wso2/nballerina.front.syntax as s;

type TranspileTestCase [string, string[]];

@test:Config {
    dataProvider: transpileTestCaseProvider
}
function testTranspile(string balFilePath, string[] expected) returns error? {
    s:SourceFile sourceFile = check createSourceFile(balFilePath);
    s:ModulePart modulePart = check compileBalFile(sourceFile);
    string[] actual = check transpileModulePart(modulePart, sourceFile);
    test:assertEquals("\n".'join(...actual), "\n".'join(...expected));
}


function transpileTestCaseProvider() returns map<TranspileTestCase>|error {
    map<TranspileTestCase> tests = {};

    foreach var balFile in check file:readDir("tests/balFiles") {
        string fileName = check file:basename(balFile.absPath);
        string testName = fileName.substring(0, fileName.length()-4);
        string cDuceFilePath = check file:joinPath(".", "tests", "cDuceFiles", testName + ".cd");
        string[] cDuceFileBody = check io:fileReadLines(cDuceFilePath);
        tests[testName] = [balFile.absPath, cDuceFileBody];
    }
    return tests;
}
