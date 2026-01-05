class IpService
  class << self
    # Get your local IP address so your phone can reach your laptop (localhost won't work from a phone!)
    def local_ip_v4
      Socket.ip_address_list.detect(&:ipv4_private?)&.ip_address
    end
  end
end
