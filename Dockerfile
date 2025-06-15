FROM node:lts-buster-slim 
ARG NODE_ENV=productions
ENV NODE_ENV=${NODE_ENV}

WORKDIR /usr/src/app

COPY package.json yarn.lock ./

RUN yarn install --frozen-lockfile --network-timeout 600000 || yarn install --network-timeout 600000

COPY . . 

CMD ["yarn", "start"]
