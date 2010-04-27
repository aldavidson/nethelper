module NetHelper
  
  def do_get(url, time_out=5, retries_on_timeout=5, max_redirects = 3)
    retrycount = 0
    resp = nil
    begin
      get_with_timeout( url, time_out )
      
      handle_response( resp, retries_on_timeout,  max_redirects )
    
    rescue TimeoutError      
      if(retrycount < retries_on_timeout)
        retrycount+=1
        retry
      else
        raise IOError.new( "HTTP request timed out #{retrycount} times" )
      end
    end
    
  end
  
  def get_with_timeout( url, time_out )
    timeout(time_out) do
      resp = Net::HTTP.get_response(URI.parse(url))    
    end
  end
  
  
  def handle_response( url, resp, retries_on_timeout=5, max_redirects = 3 )
    if resp.is_a? Net::HTTPSuccess then resp.body
    elsif resp.is_a? Net::HTTPRedirection
        if max_redirects > 0
          do_get( url, retries_on_timeout, max_redirects - 1 )
        else
          raise IOError.new("too many redirects!")
        end
    else
      resp.error!
    end
  end
  
  
  module_function :do_get, :get_with_timeout, :handle_response
end
