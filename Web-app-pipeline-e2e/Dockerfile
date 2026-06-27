FROM jenkins/jenkins:lts

USER root

# Install dependencies (no software-properties-common needed)
RUN apt-get update && apt-get install -y wget unzip curl gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install Terraform
ENV TERRAFORM_VERSION=1.9.0
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform /usr/local/bin/terraform \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip aws

USER jenkins
