require "socket" unless defined?(Socket)
require "ipaddr" unless defined?(IPAddr)

def resolve_fqdn

    hostname = %x{hostname}.chomp
    addrinfo = Socket.getaddrinfo(hostname, nil).first
    iaddr = IPAddr.new(addrinfo[3])
    Socket.gethostbyaddr(iaddr.hton)[0]
rescue
    nil
end

def canonicalize_hostname(hostname)
    Addrinfo.getaddrinfo(hostname, nil, nil, nil, nil, Socket::AI_CANONNAME).first.canonname
end

def canonicalize_hostname_with_retries(hostname)
    retries = 3
    begin
        canonicalize_hostname(hostname)
    rescue
        retries -= 1
        retry if retries > 0
        nil
    end
end

def resolve_fqdn_without_deprecated_call(hostname)
    Addrinfo.ip(hostname).getnameinfo&.[](0)
end

puts "old code: #{resolve_fqdn}"
puts "new code: #{canonicalize_hostname_with_retries(%x{hostname}.chomp)}"
puts "proposed code: #{resolve_fqdn_without_deprecated_call(%x{hostname}.chomp)}"