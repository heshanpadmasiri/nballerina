import random
import string

random.seed(0);
MAX_CHUNK_LEN = 10;
# a((xy)*bd)*d

def genRandomString(length:int)->str:
    return ''.join(random.choices(string.ascii_letters, k=length))

def insertRandom(base:str)->str:
    insertPoint = random.randint(0, len(base)-1)
    randomStringLen = random.randint(1, MAX_CHUNK_LEN)
    return base[:insertPoint] + f'({genRandomString(randomStringLen)})*' + base[insertPoint:]

def generateTest(base:str, depth:int):
    insertPoint = random.randint(0, len(base)-1)
    randomStringLen = random.randint(1, MAX_CHUNK_LEN)
    prefix = base[:insertPoint]
    suffix = base[insertPoint:]
    if depth == 0:
        body = genRandomString(randomStringLen)
    else:
        body = generateTest(genRandomString(randomStringLen), depth-1)
    return prefix + f'({body})*' + suffix

if __name__ == "__main__":
    print(generateTest("abd", 3))
