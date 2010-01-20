require 'cgi'
require 'socket'
require 'fileutils'

# changelog:
# 1.0.1
# - '@' are now escaped properly in properties.

class KM
  VERSION    = '1.0.1'
  @id        = nil
  @host      = 'trk.kissmetrics.com:80'
  @log_dir   = '/tmp'
  @key       = nil
  @logs      = {}
  @to_stderr = true

  class << self
    def init(key, options={})
      begin
        @key       = key
        @host      = options[:host]      || @host
        @log_dir   = options[:log_dir]   || @log_dir
        @use_cron  = options[:use_cron]  if defined? options[:use_cron]
        @to_stderr = options[:to_stderr] if defined? options[:to_stderr]
        log_dir_writable?
      rescue Exception => e
        log_error(e)
      end
    end

    def identify(id)
      @id = id
    end

    def record(action,props={})
      begin
        return unless is_initialized_and_identified?
        return set(action) if action.class == Hash

        props.update('_n' => action)
        generate_query('e', props)
      rescue Exception => e
        log_error(e)
      end
    end

    def alias(name, alias_to)
      begin
        return unless is_initialized?
        generate_query('a', { '_n' => alias_to, '_p' => name }, false)
      rescue Exception => e
        log_error(e)
      end
    end

    def set(data)
      begin
        return unless is_initialized_and_identified?
        generate_query('s', data)
      rescue Exception => e
        log_error(e)
      end
    end

    def send_logged_queries
      line = nil
      begin
        return unless File.exists?(log_name(:query))
        FileUtils.move(log_name(:query), log_name(:send))
        File.open(log_name(:send)) do |fh|
          while not fh.eof?
            begin
              line = fh.readline.chomp
              send_query(line)
            rescue Exception => e
              log_query(line) if line
              log_error(e)
            end
          end
        end
        FileUtils.rm(log_name(:send))
      rescue Exception => e
        log_error(e)
      end
    end

    def log_dir
      @log_dir
    end
    def host
      @host
    end

    protected
    def reset
      @id   = nil
      @key  = nil
      @logs = {}
    end

    def log_name(type)
      return @logs[type] if @logs[type]
      fname = ''
      case type
      when :error
        fname = 'kissmetrics_error.log'
      when :query
        fname = 'kissmetrics_query.log'
      when :send
        fname = Time.now.to_i.to_s + 'kissmetrics_sending.log'
      end
      @logs[type] = File.join(@log_dir,fname)
    end

    def log_query(msg)
      log(:query,msg)
    end

    def log_send(msg)
      log(:send,msg)
    end

    def log_error(msg)
      msg = Time.now.strftime("<%c> ") + msg
      $stderr.puts msg if @to_stderr
      log(:error, msg)
    end

    def log(type,msg)
      begin
        File.open(log_name(type), 'a') do |fh|
          fh.puts(msg)
        end
      rescue Exception => e
        # just discard at this point
      end
    end

    def generate_query(type, data, update=true)
      query_arr = []
      query     = ''
      data.update('_p' => @id) unless update == false
      data.update('_k' => @key, '_t' => Time.now.to_i)
      data.inject(query) do |query,key_val|
        query_arr <<  key_val.collect { |i| CGI.escape i.to_s }.join('=')
      end
      query = '/' + type + '?' + query_arr.join('&')
      if @use_cron
        log_query(query)
      else
        begin
          send_query(query)
        rescue Exception => e
          log_query(query)
          log_error(e)
        end
      end
    end

    def send_query(line)
      host,port = @host.split(':')
      begin
        sock = TCPSocket.open(host,port)
        request = 'GET ' +  line + " HTTP/1.1\r\n"
        request += "Host: " + Socket.gethostname + "\r\n"
        request += "Connection: Close\r\n\r\n";
        sock.print(request)
        sock.close
      rescue Exception => e
        raise "#{e} for host #{@host}"
      end
    end

    def log_dir_writable?
      if not FileTest.writable? @log_dir
        $stderr.puts("Could't open #{log_name(:query)} for writing. Does #{@log_dir} exist? Permissions?") if @to_stderr
      end
    end

    def is_identified?
      if @id == nil
        log_error("Need to identify first (KM::identify <user>)")
        return false
      end
      return true
    end

    def is_initialized_and_identified?
      return false unless is_initialized?
      return is_identified?
    end

    def is_initialized?
      if @key == nil
        log_error("Need to initialize first (KM::init <your_key>)")
        return false
      end
      return true
    end
  end
end

if __FILE__ == $0
  $stderr.puts "At least one argument required. #{$0} <km_key> [<log_dir>]" unless ARGV[0]
  KM.init(ARGV[0], :log_dir => ARGV[1] || KM.log_dir, :host => ARGV[2] || KM.host)
  KM.send_logged_queries
end
