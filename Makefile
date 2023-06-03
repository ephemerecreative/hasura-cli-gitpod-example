#
# Configuration & Defaults
#

endpoint?=http://localhost:8080
passwd?=hasura
project?=fake-hasura-state
db?=default
dbName=postgres
schema?=public
from?=default
steps?=1
name?=new-migration
q?=select now();

# -- Optional --
# overrides of the variables using a gitignored file
-include ./Makefile.env

# Compose the docker-compose file chain based on an environmental variable.
# On GitPod and Codespaces the $DOCKER_COMPOSE_TARGET is set at workspace boot time.
# It is ignored for local development as the console runs with the Hasura CLI installed natively.
ifdef DOCKER_COMPOSE_TARGET
    DOCKER_COMPOSE_CHAIN := -f docker-compose.yml -f docker-compose.${DOCKER_COMPOSE_TARGET}.yml
else
    DOCKER_COMPOSE_CHAIN := -f docker-compose.yml
endif


#
# Default Action
#

help:
	@clear
	@echo ""
	@echo "---------------------"
	@echo "Hasura 2023 Make APIs"
	@echo "---------------------"
	@echo ""
	@echo " 1) make boot"
	@echo " 2) make start"
	@echo " 3) make stop"
	@echo " 4) make logs"
	@echo ""
	@echo " 5) make init"
	@echo " 6) make exports"
	@echo ""
	@echo "20) make migrate"
	@echo "21) make migrate-status"
	@echo "22) make migrate-up"
	@echo "23) make migrate-down"
	@echo "24) make migrate-redo"
	@echo "25) make migrate-rebuild"
	@echo "26) make migrate-destroy"
	@echo "27) make migrate-create"
	@echo "28) make migrate-export"
	@echo ""
	@echo "30) make seed"
	@echo ""
	@echo "40) make apply"
	@echo "41) make metadata-export"
	@echo ""
	@echo "60) make psql"
	@echo "61) make psql-exec"
	@echo ""
	@echo "70) make pagila-init"
	@echo "71) make pagila-destroy"
	@echo "72) make pagila-reset"
	@echo ""
	@echo "80) make pgtap"
	@echo "81) make pgtap-run"
	@echo "82) make pgtap-schema"
	@echo "83) make pgtap-build"
	@echo ""
	@echo "90) make hasura-install"
	@echo "91) make hasura-console"
	@echo "91) make py"
	@echo ""
	@echo "98) make clean"
	@echo "99) make reset"
	@echo ""


#
# High Level APIs
#

_boot:
	@docker compose $(DOCKER_COMPOSE_CHAIN) up -d
	@sleep 5
	@$(MAKE) -f Makefile _init
	@docker compose $(DOCKER_COMPOSE_CHAIN) logs -f
boot:
	@clear
	@echo "\n# Starting Docker Project with Hasura State from:\n> $(DOCKER_COMPOSE_CHAIN)\n> project=$(project); db=$(db) seed=$(from).sql\n"
	@$(MAKE) -f Makefile _boot

start:
	@clear
	@echo "\n# Starting Docker Project:\n> $(DOCKER_COMPOSE_CHAIN)\n"
	@docker compose $(DOCKER_COMPOSE_CHAIN) up -d
	@docker compose $(DOCKER_COMPOSE_CHAIN) logs -f

stop:
	@clear
	@echo "\n# Stopping Docker Project:\n> $(DOCKER_COMPOSE_CHAIN)\n"
	@docker compose $(DOCKER_COMPOSE_CHAIN) down

logs:
	@clear
	@echo "\n# Attaching to Docker Project logs:\n> $(DOCKER_COMPOSE_CHAIN)\n"
	@docker compose $(DOCKER_COMPOSE_CHAIN) logs -f

_init:
	@$(MAKE) -f Makefile _migrate
	@$(MAKE) -f Makefile _apply
	@$(MAKE) -f Makefile _seed
init:
	@clear
	@echo "\n# Initializing Hasura State from:\n> project=$(project); db=$(db) seed=$(from).sql\n"
	@$(MAKE) -f Makefile _init

exports: 
	@clear
	@echo "\n# Exporting Hasura State to:\n> project=$(project); db=$(db) schema=$(schema)\n"
	@$(MAKE) -f Makefile _migrate-export
	@$(MAKE) -f Makefile _metadata-export





#
# Hasura Migrations Utilities
#

_migrate:
	@hasura migrate apply \
		--endpoint $(endpoint) \
		--admin-secret $(passwd) \
		--project $(project) \
		--database-name $(db)
migrate:
	@clear
	@echo "\n# Running migrations from:\n> $(project)/migrations/$(db)/*\n"
	@$(MAKE) -f Makefile _migrate

_migrate-status:
	@hasura migrate status \
		--endpoint $(endpoint) \
		--admin-secret $(passwd) \
		--project $(project) \
		--database-name $(db)
migrate-status:
	@clear
	@echo "\n# Checking migrations status on:\n> project=$(project); db=$(db)"
	@$(MAKE) -f Makefile _migrate-status

_migrate-up:
	@hasura migrate apply \
		--endpoint $(endpoint) \
		--admin-secret $(passwd) \
		--project $(project) \
		--database-name $(db) \
		--up $(steps)
migrate-up:
	@clear
	@echo "\n# Migrate $(steps) UP from:\n> $(project)/migrations/$(db)/*\n"
	@$(MAKE) -f Makefile _migrate-up

_migrate-down:
	@hasura migrate apply \
		--endpoint $(endpoint) \
		--admin-secret $(passwd) \
		--project $(project) \
		--database-name $(db) \
		--down $(steps)
migrate-down:
	@clear
	@echo "\n# Migrate $(steps) DOWN from:\n> $(project)/migrations/$(db)/*\n"
	@$(MAKE) -f Makefile _migrate-down

_migrate-destroy:
	@hasura migrate apply \
		--endpoint $(endpoint) \
		--admin-secret $(passwd) \
		--project $(project) \
		--database-name $(db) \
		--down all
migrate-destroy:
	@clear
	@echo "\n# Destroy migrations on:\n> project=$(project); db=$(db)\n"
	@$(MAKE) -f Makefile _migrate-destroy

migrate-redo: 
	@clear
	@echo "\n# Replaying last $(steps) migrations on:\n> project=$(project); db=$(db)\n"
	@$(MAKE) -f Makefile _migrate-down
	@$(MAKE) -f Makefile _migrate-up

migrate-rebuild: 
	@clear
	@echo "\n# Rebuilding migrations on:\n> project=$(project); db=$(db)\n"
	@$(MAKE) -f Makefile _migrate-destroy
	@$(MAKE) -f Makefile _migrate

migrate-create:
	@clear
	@echo "\n# Scaffolding a new migration on:\n> project=$(project); db=$(db); name=$(name)\n"
	@hasura migrate create \
		"$(name)" \
		--endpoint $(endpoint) \
		--admin-secret $(passwd) \
		--project $(project) \
		--database-name $(db) \
		--up-sql "SELECT NOW();" \
		--down-sql "SELECT NOW();"
	@hasura migrate apply \
		--admin-secret $(passwd) \
		--project $(project) \
		--database-name $(db)

_migrate-export:
	@hasura migrate create \
		"__full-export___" \
		--endpoint $(endpoint) \
  	--admin-secret $(passwd) \
		--project $(project) \
		--database-name $(db) \
  	--schema $(schema) \
  	--from-server \
		--down-sql "SELECT NOW();"
migrate-export:
	@clear
	@echo "\n# Dumping database to a migration:\n> project=$(project); db=$(db); schema=$(schema)\n"
	@$(MAKE) -f Makefile _migrate-export




#
# Hasura seeding utilities
#

_seed:
	@hasura seed apply \
		--endpoint $(endpoint) \
		--admin-secret $(passwd) \
		--project $(project) \
		--database-name $(db) \
		--file $(from).sql
seed:
	@clear
	@echo "\n# Seeding on:\n> project=$(project); db=$(db)\n"
	@$(MAKE) -f Makefile _seed





#
# Hasura Metadata Utilities
#

_apply:
	@hasura metadata apply \
		--endpoint $(endpoint) \
		--admin-secret $(passwd) \
		--project $(project)
apply:
	@clear
	@echo "\n# Apply Hasura Metadata on:\n> project=$(project)\n"
	@$(MAKE) -f Makefile _apply

_metadata-export:
	@hasura metadata export \
		--endpoint $(endpoint) \
		--admin-secret $(passwd) \
		--project $(project)
metadata-export:
	@clear
	@echo "\n# Exporting Hasura metadata to:\n> project=$(project)\n"
	@$(MAKE) -f Makefile _metadata-export




#
# Postgres Utilities
#

psql:
	@clear
	@echo "\n# Attaching SQL Client to:\n> db=$(dbName)\n"
	@docker compose $(DOCKER_COMPOSE_CHAIN) exec postgres psql -U postgres $(dbName)

query:
	@clear
	@echo "\n# Running a SQL script to DB \"$(dbName)\":\n>$(project)/sql/$(db)/$(from).sql\n"
	@docker compose $(DOCKER_COMPOSE_CHAIN) exec -T postgres psql -U postgres $(dbName) < $(project)/sql/$(db)/$(from).sql



#
# Pagila Demo DB
# https://github.com/devrimgunduz/pagila
#

_pagila-init:
	@curl -vs https://raw.githubusercontent.com/devrimgunduz/pagila/master/pagila-schema.sql | docker compose exec -T postgres psql -U postgres $(dbName)
	@curl -vs https://raw.githubusercontent.com/devrimgunduz/pagila/master/pagila-data.sql | docker compose exec -T postgres psql -U postgres $(dbName)
	@curl -vs https://raw.githubusercontent.com/devrimgunduz/pagila/master/pagila-schema-jsonb.sql | docker compose exec -T postgres psql -U postgres $(dbName)
	@curl -k -L -s --compressed https://github.com/devrimgunduz/pagila/raw/master/pagila-data-yum-jsonb.sql | docker compose exec -T postgres pg_restore -U postgres -d $(dbName)
	@curl -k -L -s --compressed https://github.com/devrimgunduz/pagila/raw/master/pagila-data-apt-jsonb.sql | docker compose exec -T postgres pg_restore -U postgres -d $(dbName)
pagila-init:
	@clear
	@echo "\n# Initializing Pagila Demo DB to \"$(dbName)\"\n"
	@$(MAKE) -f Makefile _pagila-init

_pagila-destroy:
	@$(MAKE) -f Makefile _migrate-destroy
	@docker compose $(DOCKER_COMPOSE_CHAIN) exec postgres psql -U postgres $(dbName) -c 'drop schema public cascade;'
	@docker compose $(DOCKER_COMPOSE_CHAIN) exec postgres psql -U postgres $(dbName) -c 'create schema public;'
	@$(MAKE) -f Makefile _migrate
pagila-destroy:
	@clear
	@echo "\n# Destroying Pagila Demo DB to \"$(dbName)\"\n"
	@$(MAKE) -f Makefile _pagila-destroy

pagila-reset:
	@clear
	@echo "\n# Resetting Pagila Demo DB to \"$(dbName)\"\n"
	@$(MAKE) -f Makefile _pagila-destroy
	@$(MAKE) -f Makefile _pagila-init





#
# General Utilities
#

hasura-install:
	@curl -L https://github.com/hasura/graphql-engine/raw/stable/cli/get.sh | bash

hasura-console:
	hasura console \
		--endpoint $(endpoint) \
		--admin-secret $(passwd) \
		--project $(project) \

clean:
	@clear
	@echo "\n# Tearing down the Docker Compose Project (with volumes)\n> $(DOCKER_COMPOSE_CHAIN)\n"
	@docker compose $(DOCKER_COMPOSE_CHAIN) down -v

reset:
	@clear
	@echo "\n# Resetting the Docker Compose Project\n> $(DOCKER_COMPOSE_CHAIN)\n> project=$(project); db=$(db) seed=$(from).sql\n"
	@docker compose $(DOCKER_COMPOSE_CHAIN) down -v
	@docker compose $(DOCKER_COMPOSE_CHAIN) pull
	@docker compose $(DOCKER_COMPOSE_CHAIN) build
	@$(MAKE) -f Makefile _boot



#
# Python Utilities
#

# Run a script from the project's scripts folder
env?="F=F"
py:
	@docker images -q hasura-2023-py | grep -q . || docker build -t hasura-2023-py ./docker-images/python
	@docker run --rm \
		-e $(env) \
		-e HASURA_GRAPHQL_ENDPOINT=http://hasura-engine:8080/v1/graphql \
		-e HASURA_GRAPHQL_ADMIN_SECRET=$(passwd) \
		-v $(CURDIR)/$(project)/scripts/$(db):/scripts:ro \
		--network=hasura_2023 \
		hasura-2023-py \
		sh -c "python /scripts/$(from).py"

py-build:
	docker build --no-cache -t hasura-2023-py ./docker-images/python



#
# SQL Testing Utilities
#

case?=*
pgtap-reset:
	@docker exec -i hasura-pg psql -U postgres < $(project)/tests/reset-test-db.sql
	
pgtap-schema: $(CURDIR)/$(project)/migrations/$(db)/*
	@for file in $(shell find $(CURDIR)/$(project)/migrations/$(db) -name 'up.sql' | sort ) ; do \
		echo "---> Apply:" $${file}; \
		docker exec -i hasura-pg psql -U postgres test-db < $${file};	\
	done

pgtap-build:
	docker build --no-cache -t hasura-2023-pgtap ./docker-images/pg-tap

pgtap-run:
	@docker images -q hasura-2023-pgtap | grep -q . || docker build -t hasura-2023-pgtap ./docker-images/pg-tap
	clear
	@echo "Running Unit Tests ..."
	@docker run --rm \
		--name pgtap \
		--network=hasura_2023 \
		--link hasura-pg:db \
		-v $(CURDIR)/$(project)/tests/$(db)/:/tests \
		hasura-2023-pgtap \
    	-h db -u postgres -w postgres -d test-db -t '/tests/$(case).sql'

pgtap: pgtap-reset pgtap-schema pgtap-run

#
# Numeric API
#

1: boot
2: start
3: stop
4: logs
5: init
6: exports
20: migrate
21: migrate-status
22: migrate-up
23: migrate-down
24: migrate-redo
25: migrate-rebuild
26: migrate-destroy
27: migrate-create
28: migrate-export
30: seed
40: metadata
41: metadata-export
60: psql
61: psql-exec
70: pagila-init
71: pagila-destroy
72: pagila-reset
80: pgtap
81: pgtap-run
82: pgtap-schema
83: pgtap-build
90: hasura-install
91: hasura-console
92: py
98: clean
99: reset