# Notes

## problem

how do we get recorded meetings summarized and available for all studio team
members cost effectively.

## requirements

- meetings can be recorded and summarized by any provider that supports webhooks
  or a way for agency tooling to plug into the providers event lifecycle
- meeting recording provider needs an api for studio tooling to request data
- preferably, studio tooling should not use api access to llm providers but
  instead a plan pricing

## flow

- team member records a meeting
- once meeting is complete, recorder tool emits a webhook to little-brother
  with:
  - meeting identifier
  - meeting owner identifier (brother email address)
- little-brother web server records a row in a pending_mettings table
- little-brother web server then sends private slack message to the team member
  asking if they want that meeting archived
- if the team member ignores, then pending row is deleted after 24hrs by a
  scheduled sweeper job
  - sweeper job targets any row that has been there for at least 24hrs
- if the user response with a check emoji the little-brother slack app sends a
  request to little-brother web server
- web server uses saved info to request the summarized meeting notes and
  attendent information then sends payload to llm provider (validate that we can
  use a running oauth connection vs api for cost effective billing)
- job to be done by the llm:
  - turn into a structure meeting log (schema to be decided)
  - make the summary even more consise
  - use github credentials to save this information into a knowledge repo
    organized by clients
    - skip PR creation and approval process - unecesary complexity at this
      moment
  - read the current rollup summary and see if this meeting adds anything to
    that (preferable to re-reading every meeting and trying to generate a new
    rollup each time)

## access

- using context saved in a global AGENT.md file, every team member can use their
  codex to ask a little-brother skill any information about client meetings
- the skill knows about the knowledge-repo and its structure organization
- team members can do the same using a slack bot "@lilbro catch me up on the
  last 3 meetings we've had with this client"
- slackbot sends a request to the web server which can pass that request
  directly to the llm service

## how to make changes

### meeting recording service

- as long as the service can send webhooks and reference summarized meetings,
  any paid service can be swapped in and out

### agent context

- held in a repo with a sync command that updates all team members context
  - global AGENT.md files
  - global skills
  - project skills
- knowledge-repo holding meeting notes and text based context for humans and
  agents
- text based so changes are very easy to make

### web server and extension services (slackbot, chrome extension, etc)

- source code saved in github
- configuration based on 12factor methodology (each to change without
  deployments or runtime changes)
- text based schema so changes are diff-able (as opposed to db stored config)

## questions

- using oauth connection programmatically and shared among multiple people is a
  violation of openai and anthropic tos, i have a friend who is currently banned
  from anthropic for breaking their tos and it sucks
- could it be cheap to use batch api + prompt caching? will need a way to track
  and control costs

## explicit descopes

- access control: for mvp all team members can query all notes
