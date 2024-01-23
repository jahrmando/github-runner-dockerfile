FROM ubuntu:20.04 as base

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y
RUN apt-get install -y --no-install-recommends \
    curl jq build-essential libssl-dev libffi-dev python3 python3-venv python3-dev python3-pip \
    ca-certificates gnupg lsb-release libuser unzip

# Setup Docker
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update -y \
	&& apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

ARG DOCKERGID="995"
RUN groupmod -g $DOCKERGID docker

# Setup NodeJS
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && apt-get install -y nodejs
RUN npm install --global yarn

# Setup AWSCLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" && unzip -d /tmp/ /tmp/awscliv2.zip 
RUN /tmp/aws/install -i /usr/local/aws-cli -b /usr/local/bin

# Setup action-runner
ARG RUNNER_VERSION="2.294.0"

RUN useradd -m runner -G docker
WORKDIR /home/runner

RUN mkdir -p actions-runner/_work .cache && cd actions-runner \
    && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
RUN chown -R runner:runner ~runner && ./actions-runner/bin/installdependencies.sh

COPY start.sh start.sh
RUN chmod +x start.sh

RUN apt-get clean && \
  rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man /tmp/*

USER runner

# Extra configurations
RUN yarn config set network-timeout 300000

ENTRYPOINT ["./start.sh"]
