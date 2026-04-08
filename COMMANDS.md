rails new skycom --database=postgresql --css=tailwind

rails generate authentication --omniauthable --passwordless --invitable

docker compose up -d RAILS_MASTER_KEY=$(cat config/master.key) docker compose up -d

RAILS_MASTER_KEY=$(cat config/master.key) docker compose -f docker-compose.seed-test.yml up --abort-on-container-exit --exit-code-from web --attach web

RAILS_MASTER_KEY=$(cat config/master.key) docker compose -f docker-compose.rspec-test.yml up --abort-on-container-exit --exit-code-from web --attach web

Seed::ApplicationService.run Seed::ApplicationService.put_count

bin/rubocop --autocorrect-all EDITOR="code --wait" bin/rails credentials:edit EDITOR="code --wait" bin/rails credentials:edit -e production