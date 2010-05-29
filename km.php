<?

class KM
{
  static $epoch      = null; // used for testing only atm.
  static $host       = 'trk.kissmetrics.com:80';
  static $id         = null;
  static $key        = null;
  static $logs       = array();
  static $log_dir    = '/tmp';
  static $to_stderr  = true;
  static $use_cron   = false;
  static $query_line = null;
  static $hostname   = null;
  static $VERSION    = '1.0.5';

  static function init($key, $options=array())
  {
    self::$epoch     = self::array_get($options,'epoch',self::$epoch);
    self::$host      = self::array_get($options,'host',self::$host);
    self::$key       = $key;
    self::$log_dir   = self::array_get($options,'log_dir',self::$log_dir);
    self::$to_stderr = self::array_get($options,'to_stderr',self::$to_stderr);
    self::$use_cron  = self::array_get($options,'use_cron',self::$use_cron);
    self::is_log_dir_writable();
  }

  static function identify($id) { self::$id = $id; }

  static function record($action, $props = array())
  {
    set_error_handler(array('self','error_handler'));
    try
    {
      if (!self::is_initialized_and_identified())
      {
        restore_error_handler();
        return;
      }
      if (is_array($action))
      {
        restore_error_handler();
        return self::set($action);
      }

      $array = array_merge($props, array(
        '_n' => $action,
      ));
      self::generate_query('e', $array);
      restore_error_handler();
    }
    catch(Exception $e)
    {
      restore_error_handler();
      self::log_error($e->getMessage());
    }
  }

  static function set($array)
  {
    set_error_handler(array('self','error_handler'));
    try
    {
      if (!self::is_initialized_and_identified())
      {
        restore_error_handler();
        return;
      }
      self::generate_query('s', $array);
      restore_error_handler();
    }
    catch(Exception $e)
    {
      restore_error_handler();
      self::log_error($e->getMessage());
    }
  }

  static function alias($name,$alias_to)
  {
    set_error_handler(array('self','error_handler'));
    try
    {
      if (!self::is_initialized())
      {
        restore_error_handler();
        return;
      }
      $array = array(
        '_p' => $name,
        '_n' => $alias_to
      );
      self::generate_query('a', $array, false);
      restore_error_handler();
    }
    catch(Exception $e)
    {
      restore_error_handler();
      self::log_error($e->getMessage());
    }
  }

  static function send_logged_queries()
  {
    set_error_handler(array('self','error_handler'));
    try
    {
      self::$query_line = null;
      if (!is_file(self::log_name('query')))
      {
        restore_error_handler();
        return;
      }

      // Fixed: If the processing takes more than one second the self::log_name returns a different filename due to time() being used
      $query_log = self::log_name('query');
      $send_log = self::log_name('send');

      rename($query_log, $send_log);
      $fh_send = fopen($send_log, "r");
      if ($fh_send) {
        while (!feof($fh_send)) {
          self::$query_line = fgets($fh_send);
          if (self::$query_line == false) continue;
          self::send_query(self::$query_line);
        }
        fclose($fh_send);
      }
      unlink($send_log);
      self::$query_line = null;
      restore_error_handler();
    }
    catch(Exception $e)
    {
      restore_error_handler();
      self::log_error($e->getMessage());
    }
  }

  static function error_handler($errno, $errstr, $errfile, $errline)
  {
    self::log_error("[$errno] $errstr on line $errline in file $errfile");
  }

  static function array_get($array, $key, $default=null)
  {
    if ( !is_array($array) )
      return $default;
    if (array_key_exists($key, $array))
      return $array[$key];
    else
      return $default;
  }


  ############################################################################
  #### PROTECTED #############################################################

  static protected function is_log_dir_writable()
  {
    if (!is_writable(self::$log_dir))
      if (self::$to_stderr)
        error_log("Could't open " . self::$log_dir . " for writing. Does " . self::$log_dir . " exist? Permissions?");
  }

  static protected function reset() {
    self::$epoch     = null;
    self::$id        = null;
    self::$key       = null;
    self::$logs      = array();
    self::$log_dir   = '/tmp';
    self::$to_stderr = true;
    self::$use_cron  = false;
  }

  static protected function is_initialized_and_identified()
  {
    if (!self::is_initialized())
      return false;
    return self::is_identified();
  }

  static protected function is_initialized()
  {
    if ( self::$key )
      return true;

    self::log_error("Need to initialize first ( KM::init(<your_key>) )");
    return false;
  }

  static protected function is_identified()
  {
    if ( self::$id )
      return true;

    self::log_error("Need to identify first ( KM::identify(<user>) )");
    return false;
  }

  static protected function epoch()
  {
    if ( self::$epoch )
      return self::$epoch;
    return time();
  }

  static protected function log_name($type)
  {
    if ($log_name = self::array_get(self::$logs,$type))
      return $log_name;
    $fname = '';
    switch($type) {
    case 'error':
      $fname = 'kissmetrics_error.log';
      break;
    case 'query':
      $fname = 'kissmetrics_query.log';
      break;
    case 'send':
      $fname = self::epoch() . '.kissmetrics_sending.log';
      break;
    }
    $logs[$type] = self::$log_dir . '/' . $fname;
    return $logs[$type];
  }

  static protected function log_query($msg) { self::log('query',$msg); }

  static protected function log_send($msg) { self::log('send',$msg); }

  static protected function log_error($msg)
  {
    $msg = '[' . self::epoch() . '] ' . $msg;
    if (self::$to_stderr)
      error_log("$msg");
    self::log('error', $msg);
  }

  static protected function log($type, $msg)
  {
    set_error_handler(array('self','error_handler'));
    try
    {
      $fh = fopen(self::log_name($type),'a');
      fputs($fh, $msg . "\n");
      fclose($fh);
      restore_error_handler();
    }
    catch(Exception $e)
    {
      restore_error_handler();
    } // just discard this
  }

  static protected function generate_query($type,$data,$update = true)
  {
    $data = array_merge($data, array( '_k' => self::$key, '_t' => self::epoch() ));
    if ($update)
      $data = array_merge($data, array( '_p' => self::$id,));

    $query = '/' . $type . '?' . http_build_query($data, '', '&');

    if (self::$use_cron)
      self::log_query($query);
    else
    {
      try { self::send_query($query); }
      catch(Exception $e)
      {
        self::log_query($query);
        self::log_error($e->getMessage());
      }
    }
  }

  static protected function get_hostname()
  {
    if (self::$hostname)
      return self::$hostname;

    self::$hostname = php_uname('n');
    if (is_callable('gethostname'))
    {
      if ($hostname = gethostname())
        self::$hostname = $hostname;
    }

    self::$hostname = self::array_get($_SERVER,'HOSTNAME',self::$hostname);
    return self::$hostname;
  }

  static protected function send_query($query)
  {
    $query = chop($query); // make sure we don't get newlines;
    try
    {
      $host_port = explode(':',self::$host);
      $get = 'GET ' . $query . " HTTP/1.1\r\n";
      $fp = fsockopen($host_port[0], $host_port[1], $errno, $errstr, 30);
      if (!$fp) {
        self::log_error("Failed to create socket ". self::$host . " : $errstr ($errno)\n");
        self::log_query($query);
      } else {
        stream_set_blocking($fp,0); // If mode is 0, the given stream will be switched to non-blocking mode, and if 1, it will be switched to blocking mode. 
        $out = $get;
        $out .= "Host:" . self::get_hostname() . "\r\n";
        $out .= "Connection: Close\r\n\r\n";
        $write_success = fwrite($fp, $out);
        if (!$write_success)
        {
          self::log_error("Failed to send query: $query");
          self::log_query($query);
        }
        fclose($fp);
      }
    }
    catch(Exception $e)
    {
      throw new Exception($e->getMessage() . "for host " . self::$host);
    }
  }
}

if ( basename(KM::array_get($_SERVER,'SCRIPT_NAME')) == basename(__FILE__) )
{
  if (!KM::array_get($argv,1))
    error_log("At least one argument required. km.php <km_key> [<log_dir>]");

  KM::init(KM::array_get($argv,1), array('log_dir' => KM::array_get($argv,2,KM::$log_dir), 'host' => KM::array_get($argv,3,KM::$host) ));
  KM::send_logged_queries();
}
?>
