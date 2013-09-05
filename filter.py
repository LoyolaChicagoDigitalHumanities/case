"""
   filter.py is a work in progress to rewrite input files containing 
   hyphenation and dashes into a form that PC-Case can handle without
   generating false positives. This is documented by Peter Shillingsburg
   in a Google Drive document that I will turn into Markdown.

   This script is not at all ready for primetime and will probably be
   replaced in the future with a regex-based solution.
"""

import sys
import re



# Transformations for CASE

# This function handles trailing - or --. Can actually pass any type of dash and 
# indicate whether the hyphen(s) should be deleted when joining with words
# on next line.

def ordinary_eol_dash_or_hyphen(line1, line2, hyphen_type, delete_hyphens=False):

   if not line1[-1].endswith(hyphen_type):
      return (line1, line2)

   l2iter = iter(line2)
   item = l2iter.next()

   if isNonWord(item):
      return (line1, line2)

   if delete_hyphens:
      lastWord = line1[-1]
      lastWord = lastWord[:-len(hyphen_type)]
      line1.pop()
      item = lastWord + item

   line1len = len(line1)
   line1.append(item)
   for item in l2iter:
      if isWord(item): break
      line1.append(item)

   tokensAdded = len(line1) - line1len
   popN(line2, tokensAdded)
   return (line1, line2)

# This function handles the case of a leading dash.
# You can indicate the type of dash. Right now, we support --.


def ordinary_bol_dash(line1, line2, dash_type = '--'):

   if not line2[0].startswith(dash_type):
      return (line1, line2)

   l1lastword = line1[-1]
   if isNonWord(l1lastword):
      return (line1, line2)

   line1.pop()
   line2.insert(0, l1lastword)
   return (line1, line2)

#
# This is to indicate a trailing hyphen that is to be left untouched.
# This rule is applied last.

def preserved_eol_hyphen(line):
   if line[-1] == '=':
      line[-1] = '-'
   return line

def regexWSSplit(item):
   return re.split('(\s+)', item)

def regexWordSplit(line):
   tokens = re.split('(\W+)', line)
   tokenList = []
   for token in tokens:
      wsTokens = regexWSSplit(token)
      tokenList = tokenList + wsTokens
   return [ item for item in tokenList if item != '' ]

def isNonWord(s):
   return re.match("^\W+$", s) != None

def isWord(s):
   return re.match("^\w+$", s) != None

def popN(someList, n):
   for i in range(0, n):
      someList.pop(0)

def main():
   filename = sys.argv[1]
   newfilename = sys.argv[2]
   if filename == newfilename:
      print "In and out filename must be different."
      sys.exit(1)

   with open(filename) as infile:
      doc = infile.readlines()

   for i in range(0, len(doc)):
      doc[i] = regexWordSplit(doc[i].rstrip())

   for i in range(0, len(doc)-1):
      (doc[i], doc[i+1]) = ordinary_eol_dash_or_hyphen(doc[i], doc[i+1], '--', False)
      (doc[i], doc[i+1]) = ordinary_eol_dash_or_hyphen(doc[i], doc[i+1], '-', True)
      (doc[i], doc[i+1]) = ordinary_bol_dash(doc[i], doc[i+1])

   for i in range(0, len(doc)-1):
      doc[i] = preserved_eol_hyphen(doc[i])

   for i in range(0, len(doc)):
      doc[i] = ''.join(doc[i])

   with open(newfilename, "w") as out:
      out.write('\n'.join(doc))

if __name__ == '__main__':
   main()
