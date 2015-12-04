import sqlite3
import codecs
import json
import csv
import cStringIO
import xlsxwriter
import os

extStKey = 'EXTERNAL_STORAGE'
if os.environ.has_key(extStKey):
  rootPath = os.environ[extSdKey]
else:
  rootPath = '.'
  
workPath = rootPath + '/work/'

#colPath = "/sdcard/collection.anki2"
colPath = workPath + "collection.anki2"
#outdir = '/sdcard/work/'
outPath = workPath

class UnicodeWriter:
  """ A CSV writer which will write rows to CSV file "f", which is encoded in the given encoding. """
  def __init__(self, f, dialect=csv.excel, encoding="utf-8", **kwds):
    # Redirect output to a queue
    self.queue = cStringIO.StringIO()
    self.writer = csv.writer(self.queue, dialect=dialect, **kwds)
    self.stream = f
    self.encoder = codecs. getincrementalencoder(encoding)()

  def writerow(self, row):
    self.writer.writerow([s.encode("utf-8") for s in row])
    # Fetch UTF-8 output from the queue ...
    data = self.queue.getvalue()
    data = data.decode("utf-8")
    # ... and reencode it into the target encoding
    data = self.encoder.encode(data)
    # write to the target stream
    self.stream.write(data)
    # empty queue
    self.queue.truncate(0)

  def writerows(self, rows):
    for row in rows:
      self.writerow(row)
      
fmodel = codecs.open(outPath + 'models.txt', 'w', 'utf-8')
conn = sqlite3.connect(colPath)
c=conn.cursor()
c.execute("select models from col")
rw=c.fetchone()
x=json.loads(rw[0])
print x.keys()
workbook = xlsxwriter.Workbook(outPath + 'cards.xlsx')
for mid,v in x.iteritems():
  print mid
  fmodel.write(str(v) + "\n")
  r=c.execute("select flds from notes where mid = ?", (mid, ))
  worksheet = workbook.add_worksheet()
  flds=v['flds']
  
  #w = csv.writer(f2, delimiter = ',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
  outfname = outPath + v['name'] + ".txt"
  f2 = open(outPath + v['name'] + ".csv", 'w')
  w = UnicodeWriter(f2)
  f = codecs.open(outfname, 'w', 'utf-8')
  firstf = True
  row = 0
  col = 0
  for fld in flds:
    if firstf == False:
      f.write("\t")
    firstf = False
    f.write(fld['name'])
    worksheet.write(row, col, fld['name'])
    col += 1
  f.write("\n")
  row += 1
  col = 0
  for orow in r:
    rf=orow[0].split("\x1f")
    for rff in rf:
#      print rff
#      if isinstance(rff,str):
#        print "string"
      x12 = codecs.encode(rff, 'utf-8')
      worksheet.write(row, col, rff)
      col += 1

    row += 1
    col = 0
    w.writerow(rf)
    p=orow[0].replace("\x1f","\t")
    f.write(p)
    f.write("\n")
  f.close()
  
  f2.close()
fmodel.close()
workbook.close()


