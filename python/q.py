import sqlite3
import codecs
import json
import csv
import cStringIO

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
      
outdir = '/sdcard/work/'
fmodel = codecs.open(outdir + 'models.txt', 'w', 'utf-8')
conn = sqlite3.connect("/sdcard/collection.anki2")
c=conn.cursor()
c.execute("select models from col")
rw=c.fetchone()
x=json.loads(rw[0])
print x.keys()
for mid,v in x.iteritems():
  print mid
  fmodel.write(str(v) + "\n")
  r=c.execute("select flds from notes where mid = ?", (mid, ))
  flds=v['flds']
  
  #w = csv.writer(f2, delimiter = ',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
  outfname = "/sdcard/work/" + v['name'] + ".txt"
  f2 = open("/sdcard/work/" + v['name'] + ".csv", 'w')
  w = UnicodeWriter(f2)
  f = codecs.open(outfname, 'w', 'utf-8')
  firstf = True
  for fld in flds:
    if firstf == False:
      f.write("\t")
    firstf = False
    f.write(fld['name'])
  f.write("\n")
  for row in r:
    rf=row[0].split("\x1f")
    w.writerow(rf)
    p=row[0].replace("\x1f","\t")
    f.write(p)
    f.write("\n")
  f.close()
  
  f2.close()
fmodel.close()

