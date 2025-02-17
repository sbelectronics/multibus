words=open("hang.txt","r").readlines()
words = [word.strip() for word in words]

print("char *wordlist[]={")
for word in words:
  print("  \"%s\"," % word.upper())

print("  NULL")
print("};")

print("")
print("#define NUMWORDS %d" % len(words));
