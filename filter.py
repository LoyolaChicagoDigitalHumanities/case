"""
   filter.py is a work in progress to rewrite input files containing 
   hyphenation and dashes into a form that PC-Case can handle without
   generating false positives. This is documented by Peter Shillingsburg
   in a Google Drive document that I will turn into Markdown.

   This script is not at all ready for primetime and will probably be
   replaced in the future with a regex-based solution.
"""

import sys

def preserved_eol_hyphen(line):
   if line[-1] == '=':
      return line[0:-1] + '-'
   else:
      return line

def ordinary_eol_hyphen(line1, line2):

   if len(line1) < 2:
      return (line1, line2)

   # Line ends with hyphen but NOT two hyphens (dash)
   if line1[-1] != '-' or line1[-2] == '-':
      return (line1, line2)

   line1words = line1.split()
   line2words = line2.split()
   (line2hd, line2rest) = (line2words[0], line2words[1:])
   line1lastword = line1words.pop()
   line1words.append(line1lastword[0:-1] + line2hd)
   newline1 = ' '.join(line1words)
   newline2 = ' '.join(line2rest)
   return (newline1, newline2)

def ordinary_eol_dash(line1, line2):

   if len(line1) < 3:   # -- + at least one character before the --
      return (line1, line2)

   # Line ends with hyphen but NOT two hyphens (dash)
   if line1[-2:] != '--':
      return (line1, line2)

   line1words = line1.split()
   line2words = line2.split()
   (line2hd, line2rest) = (line2words[0], line2words[1:])
   line1lastword = line1words.pop()
   line1words.append(line1lastword + line2hd)
   newline1 = ' '.join(line1words)
   newline2 = ' '.join(line2rest)
   return (newline1, newline2)

def ordinary_bol_dash(line1, line2):

   if len(line2) < 3:   # -- + at least one character before the --
      return (line1, line2)

   # Line ends with hyphen but NOT two hyphens (dash)
   if line2[0:2] != '--':
      return (line1, line2)

   line1words = line1.split()
   line2words = line2.split()
   (line1head, line1tail) = (line1words[0:-1], line1words[-1])
   line2firstword = line2words[0]
   newline1 = ' '.join(line1head)
   newline2 = line1tail + ' '.join(line2words)
   return (newline1, newline2)


filename = sys.argv[1]
newfilename = sys.argv[2]
if filename == newfilename:
   print "In and out filename must be different."
   sys.exit(1)

with open(filename) as file:
   doc = file.readlines()

for i in range(0, len(doc)):
   doc[i] = doc[i].rstrip()

# Transformations that involve pairs of lines
for i in range(0, len(doc)-1):
   (doc[i], doc[i+1]) = ordinary_eol_hyphen(doc[i], doc[i+1])

for i in range(0, len(doc)-1):
   (doc[i], doc[i+1]) = ordinary_eol_dash(doc[i], doc[i+1])
   (doc[i], doc[i+1]) = ordinary_bol_dash(doc[i], doc[i+1])

# Transformations that are contained within a line
for i in range(0, len(doc)-1):
   doc[i] = preserved_eol_hyphen(doc[i])

with open(newfilename, "w") as out:
   out.write('\n'.join(doc))

