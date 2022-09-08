import argparse
import random
import string

random.seed(0);
MAX_CHUNK_LEN = 10;

def main(nSets, nTests, outputFile=None):
    output = ["["];
    for i in range(nSets):
        for j, each in enumerate(generateTests(testGenerator1, nTests)):
            if i == nSets - 1 and j == nTests -1:
                # last test
                output.append(each)
            else:
                output.append(each + ",")
        if i != nSets -1 :
            output.append("");
    output.append("]")
    if outputFile == None:
        stdOuput(output)
    else:
        fileOutput(output, outputFile)

def stdOuput(lines):
    for line in lines:
        print(line)

def fileOutput(lines, fileName):
    with open(fileName, "w") as file:
        file.writelines(map(lambda line: line + "\n", lines))

def generateTests(testGenerator, n):
    tests = testGenerator(n)
    lines = []
    for i in range(len(tests)-1):
        lhs = tests[i]
        rhs = tests[i+1]
        lines.append(f'    ["<", "{lhs}", "{rhs}"]') 
    return lines

def testGenerator1(count):
    chunks = [genRandomString(random.randint(1, MAX_CHUNK_LEN)) for _ in range(count + 1)]
    currentRegex = chunks.pop();
    results = [currentRegex];
    insertRange = (0, len(currentRegex)-1)
    while len(chunks) > 0:
        insertPoint = random.randint(*insertRange)
        randomStringLen = random.randint(1, MAX_CHUNK_LEN)
        insertRange = (insertPoint+1 , insertPoint + randomStringLen)
        newRegex = currentRegex[:insertPoint] + f'({chunks.pop()})*' +currentRegex[insertPoint:]
        results.append(newRegex)
        currentRegex = newRegex
    return results;

def genRandomString(length):
    return ''.join(random.choices(string.ascii_letters, k=length))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Generate random regex tests')
    parser.add_argument('NSets', type=int, help='Number of unique test sets')
    parser.add_argument('NTests', type=int, help='For each test set generate this many tests')
    parser.add_argument('--o', type=str, help='Output file path')
    args = parser.parse_args()
    main(args.NSets, args.NTests, args.o)
