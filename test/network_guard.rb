# frozen_string_literal: true

require "socket"

class NetworkAccessDenied < StandardError; end unless defined?(NetworkAccessDenied)

module DenyOutboundSockets
  def tcp(*)
    raise NetworkAccessDenied, "outbound TCP is disabled during tests"
  end

  def getaddrinfo(*)
    raise NetworkAccessDenied, "outbound address resolution is disabled during tests"
  end
end

module DenyOutboundSocketConstruction
  def new(*)
    raise NetworkAccessDenied, "outbound sockets are disabled during tests"
  end

  def open(*)
    raise NetworkAccessDenied, "outbound sockets are disabled during tests"
  end
end

Socket.singleton_class.prepend(DenyOutboundSockets) unless Socket.singleton_class < DenyOutboundSockets
TCPSocket.singleton_class.prepend(DenyOutboundSocketConstruction) unless TCPSocket.singleton_class < DenyOutboundSocketConstruction
UDPSocket.singleton_class.prepend(DenyOutboundSocketConstruction) unless UDPSocket.singleton_class < DenyOutboundSocketConstruction
