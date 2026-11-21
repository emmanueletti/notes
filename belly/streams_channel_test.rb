# frozen_string_literal: true

require "test_helper"

class StreamsChannelTest < ActionCable::Channel::TestCase
  setup do
    @user = create(:user)
    stub_connection current_session: @user.sessions.create!
  end

  test "#subscribe lets a member watch their workspace's grocery list" do
    subscribe signed_stream_name: signed([@user.default_workspace, :grocery_list])

    assert_predicate subscription, :confirmed?
  end

  test "#subscribe refuses another workspace's grocery list, even with a valid signature" do
    subscribe signed_stream_name: signed([create(:workspace), :grocery_list])

    assert_predicate subscription, :rejected?
  end

  test "#subscribe refuses a workspace someone has left" do
    workspace = create(:workspace)
    membership = create(:workspace_membership, user: @user, workspace: workspace)
    name = signed([workspace, :recipes])
    membership.destroy!

    subscribe signed_stream_name: name

    assert_predicate subscription, :rejected?
  end

  test "#subscribe lets a member watch a recipe in their workspace" do
    subscribe signed_stream_name: signed([create(:recipe, workspace: @user.default_workspace)])

    assert_predicate subscription, :confirmed?
  end

  test "#subscribe refuses a recipe in another workspace" do
    subscribe signed_stream_name: signed([create(:recipe)])

    assert_predicate subscription, :rejected?
  end

  test "#subscribe lets only the host watch their party" do
    subscribe signed_stream_name: signed([create(:party, host: @user), :bella])
    assert_predicate subscription, :confirmed?

    subscribe signed_stream_name: signed([create(:party), :bella])
    assert_predicate subscription, :rejected?
  end

  private

  def signed(streamables)
    Turbo::StreamsChannel.signed_stream_name(streamables)
  end
end
