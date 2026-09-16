# Rails template

- rails new with postgres, tailwind, no rubocop

tools
- standardrb
- lefthook

code
- app.yml configuration
- docker compose
- bin/dev and bin/setup
- bin/ci 
- rails auth generation

steps
- add gemfile
- add bin/ scripts
- run bin/lint
- setup app.yml
- setup docker compose
- route namespaces
  - public, dashboard, admin
- run rails auth generation (standard multi-tenant accounts, memberships, users)
- setup mise
- mailers in `/mailer/` path
- monoform css
- lograge 
- factorybot
- test helpers
  - auth, rate limting, 
- studio claude plugin right in local .claude settings
- env specific rails credentials, 1password as backend for non local master.key
- setup  solid jobs, cache, cable

studio gems
- enum gem
- monitoring
- timezone detection
