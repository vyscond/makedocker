
.ONSHELL:
.PHONY: help
.DEFAULT_GOAL := help

company=company_name
project=project_name

# Environment based variables

ifeq ($(env),local)
	git_branch=develop
	tag=$(env)
endif

ifeq ($(env),develop)
	git_branch=develop
	tag=$(env)
endif

ifeq ($(env),stage)
	git_branch=stage
endif

ifeq ($(env),production)
	git_branch=master
endif

ifeq ($(tag),git_commit)
	$(eval tag := $(shell git log --merges -n 1 | grep -m 1 -Eo '[release|hotfix]/[^ ]*' | sed 's#^.*/##g' | tr -d "'"))
endif

ifeq ($(tag),git_tag)
	$(eval tag := $(shell git tag -l --points-at HEAD))
endif

git_skip_checkout=1

docker_registry_login=login
docker_registry_password=password
docker_build_image_tag=$(tag)
docker_build_image_path=.
docker_build_image_name=$(company)/$(project):$(docker_build_image_tag)
docker_container=$(company)_$(project)_1

# Docker/Container routines

docker_build_image:
ifeq ($(git_skip_checkout),0)
	git checkout $(git_branch)
endif
	docker build $(docker_build_image_path) \
		-t $(docker_build_image_name)

docker_registry_signin:
	docker login --username=$(docker_registry_login) --password=$(docker_registry_password)

docker_registry_signout:
	docker logout

docker_push_image:
	docker push $(docker_registry)/$(docker_build_image_name)

docker_push: docker_build_image docker_registry_signin docker_push_image docker_registry_signout

docker_stop:
	-docker-compose -p $(company) stop
	-docker-compose -p $(company) down

docker_start:
	-docker-compose -p $(company) up -d --force-recreate
	-docker-compose -p $(company) start

docker_shell:
	docker exec -ti $(docker_container) bash

docker_logs:
	docker logs -f $(docker_container)

run: docker_stop docker_build_image docker_start docker_logs

help:
	@echo "help - make help"
