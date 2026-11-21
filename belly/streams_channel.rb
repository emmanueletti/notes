# frozen_string_literal: true

class StreamsChannel < Turbo::StreamsChannel
  include Studio::Auth::ForCableChannel

  private

  def authorized?
    streamables.all? do |streamable|
      case streamable
      when String then true
      when Workspace then workspace_ids.include?(streamable.id)
      when Party then streamable.host_id == current_user.id
      else streamable.respond_to?(:workspace_id) && workspace_ids.include?(streamable.workspace_id)
      end
    end
  end

  def workspace_ids
    current_user.workspace_memberships.pluck(:workspace_id)
  end
end
