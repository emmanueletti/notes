# Belly: StreamsChannel for studio-auth cable checks

studio-auth ad35adc makes turbo_stream_from go through the app's StreamsChannel and
refuses Turbo::StreamsChannel. Belly needs these files in the same toolshed bump,
or every live update stops (the security test fails CI first).

Belly is pinned to toolshed 770c83e (2026-11-17), 23 commits behind, so the bump
also takes the studio-auth sign-up, email change and config changes (mail_address
was removed). Do that bump as its own piece of work, then add:

- streams_channel.rb -> server/app/channels/streams_channel.rb
- application_cable_channel.rb -> server/app/channels/application_cable/channel.rb
- streams_channel_test.rb -> server/test/channels/streams_channel_test.rb

Access rules: workspace streams for members, recipes and bulk imports by their
workspace, parties for the host only (matches current_user.hosted_parties).
Not yet run against Belly.
