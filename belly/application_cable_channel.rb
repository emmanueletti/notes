module ApplicationCable
  class Channel < ActionCable::Channel::Base
    include Studio::Auth::ForCableChannel
  end
end
