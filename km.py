import urllib
import socket
from datetime import datetime

class KM:
  _id   = None
  _key  = None
  _host = None

  @classmethod
  def init(cls,key,host='trk.kissmetrics.com:80'):
    cls._key  = key
    cls._host = host

  @classmethod
  def identify(cls,id):
    cls._id = id

  @classmethod
  def record(cls,action,props={}):
    cls.check_id_key()
    if isinstance(action,dict):
      return cls.set(action)

    props.update({'_n': action})
    cls.request('e',props)



  @classmethod
  def set(cls,data):
    cls.check_id_key()
    cls.request('s',data)

  @classmethod
  def alias(cls,name,alias_to):
    cls.check_init()
    cls.request('a', {'_n': alias_to, '_p': name}, False)

  @classmethod
  def log_file(cls):
    return '/tmp/kissmetrics_error.log'

  @classmethod
  def reset(cls):
    cls._id = None
    cls._key = None

  @classmethod
  def check_identify(cls):
    if cls._id == None:
      raise Exception, "Need to identify first (KM.identify <user>)"

  @classmethod
  def check_init(cls):
    if cls._key == None:
      raise Exception, "Need to initialize first (KM.init <your_key>)"

  @classmethod
  def now(cls):
    return datetime.now()

  @classmethod
  def check_id_key(cls):
    cls.check_init()
    cls.check_identify()

  @classmethod
  def logm(cls,msg):
    msg = cls.now().strftime('<%c> ') + msg
    try:
      fh = open(cls.log_file(), 'a')
      fh.write(msg)
      fh.close()
    except IOError:
      pass #just discard at this point

  @classmethod
  def request(cls,type,data,update=True):
    query = []

    # if user has defined their own _t, then include necessary _d
    if '_t' in data:
      data['_d'] = 1
    else:
      data['_t'] = cls.now().strftime('%s')

    # add customer key to data sent
    data['_k'] = cls._key

    if update:
      data['_p'] = cls._id

    for key,val in data.items():
      query.append( urllib.quote(str(key)) + '=' + urllib.quote(str(val)) )

    try:
      sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
      host,port = cls._host.split(':')
      sock.connect((host, int(port)))
      sock.setblocking(0) # 0 is non-blocking

      get = 'GET /' + type + '?' + '&'.join(query) + " HTTP/1.1\r\n"
      out = get
      out += "Host: " + socket.gethostname() + "\r\n"
      out += "Connection: Close\r\n\r\n";
      sock.send(out)
      sock.close()
    except:
      cls.logm("Could not transmit to " + cls._host)
