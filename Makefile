ECR-REPO ?= maithrinet-adserverx-unified-repo

help :
	@echo "";
	@echo "Example command to build and push connectivity API image to ECR repo::"
	@echo "$$ make build_push NAME=connectivity"
	@echo "The above command cleans(API images locally), builds(API images locally), push specific API images to ECR repo, deploys to lambda"
	@echo "";
	@echo "**API-NAMES** 		:	**DESCRIPTION**"
	@echo "connectivity 		: 	connectivity api"
	@echo "ip-exclusion 		: 	ip exclusion api"
	@echo "campaign-credits 	:	campaign credits api"
	@echo "phov 			: 	predictive hov api"
	@echo "media-info 		: 	media info api"
	@echo "ads 			:	retrieve ads api"
	@echo "processS3File		:	process S3 file api"
	@echo "processSQSS3FileEvent	:	process SQS event for S3 file api"
	@echo "writeEventToSQS		:	write file event to SQS"


git_pull:
	git config credential.helper cache
	git pull origin dev-06012021

install:
	npm install

clean_images:
	docker image prune -af;

build_push: git_pull
	$(MAKE) clean_images
	$(MAKE) handler_update
	docker build -t $(ECR-REPO):$(NAME)-latest .
	$(MAKE) push
	$(MAKE) update
	$(MAKE) clean_images

handler_update:
	sed -i '$$d' Dockerfile;
	if test "$(NAME)" = "connectivity"; then \
		echo 'CMD ["dist/src/handler.handleConnectivity"]' >> Dockerfile;    \
	elif test "$(NAME)" = "ip-exclusion"; then \
		echo 'CMD ["dist/src/handler.handleIpExclusions"]' >> Dockerfile;    \
	elif test "$(NAME)" = "campaign-credits"; then \
		echo 'CMD ["dist/src/handler.handleCredits"]' >> Dockerfile;    \
	elif test "$(NAME)" = "phov"; then \
		echo 'CMD ["dist/src/handler.handlePhov"]' >> Dockerfile;    \
	elif test "$(NAME)" = "media-info"; then \
		echo 'CMD ["dist/src/handler.handleAdMediaInfo"]' >> Dockerfile;    \
	elif test "$(NAME)" = "ads"; then \
		echo 'CMD ["dist/src/handler.handleAds"]' >> Dockerfile;    \
	elif test "$(NAME)" = "processS3File"; then \
		echo 'CMD ["dist/src/handler.processS3File"]' >> Dockerfile;    \
	elif test "$(NAME)" = "processSQSS3FileEvent"; then \
		echo 'CMD ["dist/src/handler.processSQSS3FileEvent"]' >> Dockerfile;    \
	elif test "$(NAME)" = "writeEventToSQS"; then \
		echo 'CMD ["dist/src/handler.writeEventToSQS"]' >> Dockerfile;    \
	else \
		echo 'ELSE TEST';    \
		#echo 'CMD ["dist/src/handler.retrieveAds"]' >> Dockerfile;    \
	fi; \

run: build
	docker run -i -t -p 8180:8180 -d $(NAME)

test:
	curl localhost:8180

clean:
	rm -rf node_modules

push:
	{ \
	aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 709097557611.dkr.ecr.us-east-1.amazonaws.com ;\
	docker tag  $(ECR-REPO):$(NAME)-latest 709097557611.dkr.ecr.us-east-1.amazonaws.com/$(ECR-REPO):$(NAME)-latest ;\
	docker push 709097557611.dkr.ecr.us-east-1.amazonaws.com/$(ECR-REPO):$(NAME)-latest ;\
	}

update:
	$(shell /usr/local/bin/aws lambda update-function-code --region us-east-1 --function-name $(NAME) --image-uri 709097557611.dkr.ecr.us-east-1.amazonaws.com/$(ECR-REPO):$(NAME)-latest)

.PHONY: help install build run test clean update
