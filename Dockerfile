FROM public.ecr.aws/lambda/nodejs:14

ARG arg1

# Copy function code
COPY . ${LAMBDA_TASK_ROOT}

RUN npm ci
RUN npm i vast-builder --save
RUN npm run build

CMD ["dist/src/handler.handleCampaigns"]
