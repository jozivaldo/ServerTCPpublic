import hashlib
import sys

def Sha256(message):
    sha256 = hashlib.sha256()
    sha256.update(message.encode('utf-8'))
    return sha256.hexdigest()

if __name__ == "__main__":
    message = sys.argv[1]
    print(Sha256(message))
