# Execution Flow Diagrams

This document provides visual execution flow and sequence diagrams for Sprint 4 operations.

## 0. Primary Visual Execution Map

```mermaid
flowchart LR
    trigger([Commit or Manual Trigger]) --> jenkins

    subgraph CI[CI Orchestration - Jenkins]
        direction TB
        jenkins[Jenkins Controller]
        tfJob[Jenkinsfile.terraform]
        ansJob[Jenkinsfile.ansible]
        appJob[Jenkinsfile.sprint4]
        jenkins --> tfJob --> ansJob --> appJob
    end

    subgraph Infra[AWS Infrastructure Layer]
        direction TB
        s3[(S3 Terraform State)]
        ddb[(DynamoDB Lock)]
        ec2[(EC2 Management Host)]
        ecr[(Amazon ECR)]
        eks[(Amazon EKS)]
    end

    subgraph IaC[Terraform Actions]
        direction TB
        tfInit[terraform init]
        tfPlan[terraform plan]
        tfApply[terraform apply]
        tfInit --> tfPlan --> tfApply
    end

    subgraph Config[Ansible Actions]
        direction TB
        inv[Generate Inventory]
        cfg[Configure Management Host]
        val[Validate Management Host]
        inv --> cfg --> val
    end

    subgraph Delivery[App Delivery Actions]
        direction TB
        test[npm ci and npm test]
        build[Build Docker Image]
        push[Push Image to ECR]
        deploy[Apply k8s Manifests]
        verify[Rollout and Health Verification]
        test --> build --> push --> deploy --> verify
    end

    tfJob --> tfInit
    tfApply --> s3
    tfApply --> ddb
    tfApply --> ec2
    tfApply --> eks

    ansJob --> inv
    inv --> ec2
    val --> ec2

    appJob --> test
    push --> ecr
    deploy --> eks
    verify --> eks

    verify --> success{Verification Passed?}
    success -- Yes --> done([Release Successful])
    success -- No --> rollback([Rollback + Incident Runbook])

    classDef ci fill:#dbeafe,stroke:#1d4ed8,stroke-width:1px,color:#0f172a;
    classDef infra fill:#ede9fe,stroke:#6d28d9,stroke-width:1px,color:#0f172a;
    classDef action fill:#e0f2fe,stroke:#0369a1,stroke-width:1px,color:#0f172a;
    classDef decision fill:#fef3c7,stroke:#b45309,stroke-width:1px,color:#0f172a;
    classDef good fill:#dcfce7,stroke:#15803d,stroke-width:1px,color:#0f172a;
    classDef bad fill:#fee2e2,stroke:#b91c1c,stroke-width:1px,color:#0f172a;

    class jenkins,tfJob,ansJob,appJob ci;
    class s3,ddb,ec2,ecr,eks infra;
    class tfInit,tfPlan,tfApply,inv,cfg,val,test,build,push,deploy,verify action;
    class success decision;
    class done good;
    class rollback bad;
```

## 1. End-to-End Execution Flow

```mermaid
flowchart TD
    start([Code Commit or Manual Trigger]) --> t1[Run Jenkinsfile.terraform]
    t1 --> d1{Terraform apply successful?}
    d1 -- No --> f1[Stop pipeline\nRaise infra incident]
    d1 -- Yes --> a1[Run Jenkinsfile.ansible]
    a1 --> d2{Ansible configure and validate successful?}
    d2 -- No --> f2[Stop pipeline\nRaise host/config incident]
    d2 -- Yes --> s1[Run Jenkinsfile.sprint4]

    s1 --> s2[npm ci and npm test]
    s2 --> d3{Tests passed?}
    d3 -- No --> f3[Fail build\nNotify owner]
    d3 -- Yes --> s3[Build Docker image]
    s3 --> s4[Push image to ECR]
    s4 --> d4{RUN_DEPLOYMENT is true?}
    d4 -- No --> ok1[Publish build metadata only]
    d4 -- Yes --> s5[Deploy to EKS\nnamespace, deployment, service, hpa]
    s5 --> s6[Verify rollout and pod health]
    s6 --> d5{Verification passed?}
    d5 -- No --> f4[Fail deploy\nStart rollback runbook]
    d5 -- Yes --> ok2[Publish IMAGE_URI\nMark deployment success]

    classDef good fill:#d9f7e8,stroke:#15803d,stroke-width:1px,color:#0f172a;
    classDef bad fill:#fee2e2,stroke:#b91c1c,stroke-width:1px,color:#0f172a;
    classDef action fill:#dbeafe,stroke:#1d4ed8,stroke-width:1px,color:#0f172a;
    classDef decision fill:#fef3c7,stroke:#b45309,stroke-width:1px,color:#0f172a;

    class start,t1,a1,s1,s2,s3,s4,s5,s6 action;
    class d1,d2,d3,d4,d5 decision;
    class ok1,ok2 good;
    class f1,f2,f3,f4 bad;
```

## 2. Execution Sequence (Cross-System)

```mermaid
sequenceDiagram
    autonumber
    actor Dev as Developer
    participant J as Jenkins
    participant TF as Terraform
    participant AWS as AWS APIs
    participant A as Ansible
    participant ECR as Amazon ECR
    participant EKS as Amazon EKS
    participant K8S as Kubernetes API

    Dev->>J: Trigger delivery flow

    rect rgb(235, 245, 255)
    J->>TF: terraform init, validate, plan, apply
    TF->>AWS: Create or update infrastructure
    AWS-->>TF: Resource state and outputs
    TF-->>J: Terraform outputs for downstream steps
    end

    rect rgb(236, 253, 245)
    J->>A: configure-management.yml and validate-management.yml
    A->>AWS: Fetch host metadata if needed
    A-->>J: Management host configured and verified
    end

    rect rgb(255, 247, 237)
    J->>J: npm ci and npm test
    J->>J: docker build
    J->>ECR: Authenticate and push image
    ECR-->>J: Return IMAGE_URI
    end

    rect rgb(243, 232, 255)
    J->>EKS: update-kubeconfig
    J->>K8S: Apply manifests from k8s directory
    J->>K8S: rollout status and health checks
    K8S-->>J: Deployment result
    end

    alt Verification passed
        J-->>Dev: Success with IMAGE_URI and deployment status
    else Verification failed
        J-->>Dev: Failure summary and rollback guidance
    end
```

## 3. Sprint 4 Pipeline Stage Map

```mermaid
flowchart LR
    i1[Initialize Context] --> i2[Install Dependencies]
    i2 --> i3[Test]
    i3 --> i4[Build Docker Image]
    i4 --> i5[Push to ECR]
    i5 --> c1{RUN_DEPLOYMENT}
    c1 -- true --> i6[Deploy to EKS]
    i6 --> i7[Verify Deployment]
    c1 -- false --> i8[Skip Deploy Stage]
    i7 --> i9[Post Actions]
    i8 --> i9

    classDef stage fill:#e0f2fe,stroke:#0369a1,stroke-width:1px,color:#0f172a;
    classDef gate fill:#fef3c7,stroke:#b45309,stroke-width:1px,color:#0f172a;

    class i1,i2,i3,i4,i5,i6,i7,i8,i9 stage;
    class c1 gate;
```

## 4. Recommended Execution Sequence

1. Run Jenkinsfile.terraform
2. Run Jenkinsfile.ansible
3. Run Jenkinsfile.sprint4

If rollout verification fails, follow the rollback and incident flow in the support runbook.
