#!/bin/bash

#https://gist.github.com/outofcoffee/8f40732aefacfded14cce8a45f6e5eb1

if [[ $# -lt 2 ]]; then
    echo "Usage: $( basename $0 ) <repository-name> <image-tag>"
    exit 1
fi

IMAGE_META="$( aws ecr describe-images --repository-name=$1 --image-ids=imageTag=$2 2> /dev/null )"

if [[ $? == 0 ]]; then
    IMAGE_TAGS="$( echo ${IMAGE_META} | jq '.imageDetails[0].imageTags[0]' -r )"
    echo "$1:$2 found"
else
    echo "$1:$2 not found"
    docker build -t $1 $2 .
	docker images
	docker tag  $1:$2 $4.dkr.ecr.$3.amazonaws.com/$1:$2
	docker push $4.dkr.ecr.$3.amazonaws.com/$1:$2
    exit 1
fi


# docker build -t $1 $2 .
# docker images
# docker tag  $1:$2 $4.dkr.ecr.$3.amazonaws.com/$1:$2
# docker push $4.dkr.ecr.$3.amazonaws.com/$1:$2
# aws lambda update-function-code --region ''' +aws_region+''' --function-name ''' +lambda_name+''' --image-uri ''' +aws_account_id+'''.dkr.ecr.''' +aws_region+'''.amazonaws.com/''' +ecr_repo+''':''' +docker_image_name+'''
# docker image prune -af