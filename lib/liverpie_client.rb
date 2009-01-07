require 'net/http'

class LiverpieClient

  def initialize
    @http = Net::HTTP.new(Liverpie.config['webapp_ip'], Liverpie.config['webapp_port'])
  end
  
  # Send a regular event triggered by the webapp. This is the state machine call.
  def send(params, cookie)
    hdrs = {}
    hdrs['Cookie'] = cookie if cookie
    
    Liverpie.log "Calling webapp... (with cookie: #{hdrs['Cookie'].inspect})"

    partxt = params.keys.map { |k| "#{k}=#{params[k]}"}*'&'
    
    begin
      resp = @http.post(Liverpie.config['webapp_uri'], partxt, hdrs)
    rescue Exception => e
      Liverpie.log "Error - could not reach the webapp: #{e.message}"
      return [nil, nil]
    end
    
    case resp.code.to_i
    when 200, 302
      received_cookie = resp['Set-Cookie']
      Liverpie.log "Got webapp response for runner method, with cookie: #{received_cookie}"
    else
      Liverpie.log "Error - code(#{resp.code}) - #{resp.msg}"
    end
    
    return [(resp.code.to_i == 200 ? resp.body : nil), received_cookie]
  end
  
  # Asynchronously notify the webapp of all the inbound DTMF codes.
  def send_dtmf(code, cookie)
    dtmf_uri = Liverpie.config['webapp_dtmf_uri']
    return nil, cookie if dtmf_uri.to_s.empty?
    
    Liverpie.log "Sending DTMF #{code} to webapp..."
    
    hdrs = {}
    hdrs['Cookie'] = cookie if cookie
    
    begin
      resp = @http.post(dtmf_uri, "dtmf_code=#{code}", hdrs)
    rescue Exception => e
      Liverpie.log "Error - could not reach the webapp: #{e.message}"
      return [nil, nil]
    end
    
    case resp.code.to_i
    when 200, 302
      received_cookie = resp['Set-Cookie']
      Liverpie.log "Got webapp response for dtmf method, with cookie: #{received_cookie}"
    else
      Liverpie.log "Error - code(#{resp.code}) - #{resp.msg}"
    end
    
    return [(resp.code.to_i == 200 ? resp.body : nil), received_cookie]
  end
  
  # Reset the webapp state machine
  def reset
    Liverpie.log "Resetting webapp state machine..."

    begin
      resp = @http.get(Liverpie.config['webapp_reset_uri'])    
    rescue Exception => e
      Liverpie.log "Error - could not reach the webapp: #{e.message}"
      return nil
    end
    
    case resp.code.to_i
    when 200, 302
      received_cookie = resp['Set-Cookie']
      Liverpie.log "Got webapp response for reset method, with cookie: #{received_cookie}"
    else
      Liverpie.log "Error - code(#{resp.code}) - #{resp.msg}"
    end
    return received_cookie
  end
  
end