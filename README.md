# Web-app Test deployment using Jenkins

We are building test web-application image using this Dockerfile and deploying it to the Kubernetes cluster with Jenkins.

Whole idea is to automate image building and deploy custom web-application to the Kubernetes cluster.

![Test web-app](images/test-web-app.png)


#### 1. Commit custom code to the GitHub/Bitbucket repo

Develop and check-in/commit your code to the repo: https://github.com/poyaskov/test-web-app.git


#### 2. Build Docker image based on gitHub repo

Configure webhook in the DockerHub to auto build web-server custom image once code is commited to the GitHub repo.

Here is DockerHub image location: [poyaskov/test-web-app](https://hub.docker.com/repository/docker/poyaskov/test-web-app)


#### 3. Create k8s deployment


Once new custom image has been built and pushed to the Image repo ( DockerHub), we need to deploy it to the Runtime ( Kubernetes Cluster).

Here is deployment-file which we need to run wit kubectl command: 

```
---
apiVersion: v1
kind: Service
metadata:
  name: test-web-app-svc
  labels:
    app: test-web-app
spec:
  type: NodePort
  ports:
   - port: 80
  selector:
   app: test-web-app

---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
   name: px-test-web-app
   annotations:
     volume.beta.kubernetes.io/storage-class: px-db-repl3-sc
spec:
   accessModes:
     - ReadWriteOnce
   resources:
     requests:
       storage: 1Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-web-app
  labels:
    app: test-web-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-web-app
  template:
    metadata:
      labels:
        app: test-web-app
    spec:
      initContainers:
        - name: www-html-vol
          image: busybox
          command:
            - sh
            - '-c'
            - 'chown -R 33:33 /var/www'
          volumeMounts:
            - name: apachehome
              mountPath: /var/www/html
          imagePullPolicy: IfNotPresent
      imagePullSecrets:
        - name: regcred
      containers:
      - name: test-web-app
        image: poyaskov/test-web-app:latest
        imagePullPolicy: "Always"
        ports:
        - containerPort: 80
        volumeMounts: 
#        - name: apachehome
#          mountPath: /var/www/html
      volumes:
      - name: apachehome
        persistentVolumeClaim:
          claimName: px-test-web-app
```


#### 4. Jenkins pipeline for K8s deployment

Here is Jenkins URL: https://jenkins.crdsmart.city


```
pipeline {

    agent { label 'docker-rg' }

    options {
      timestamps()
    }

    environment {
      //Use Pipeline Utility Steps plugin to read information from pom.xml into env variables
        IMAGE = 'test-web-app'
        LIMAGE = 'registry.crdsmart.city/test-web-app'
        VERSION = "0.5"
        TAG = "0.5"
        NAMESPACE = 'test-web-app'
        INC="0.1"
    }
    
    stages { 
        
        stage('Clone source code from GitHub') {
            steps {
                git url: 'https://github.com/poyaskov/test-web-app.git'
            }
        }
 
        stage('Build and push web-app image to the local registry') {
            steps {
                sh """
                    ls -l
                    docker pull ubuntu:18.04
                    docker build -t ${IMAGE} .
                    docker tag ${IMAGE} ${LIMAGE}:${VERSION}
                    docker push ${LIMAGE}:${VERSION}
                """
            }
        }

        stage('Deploy kubectl and apply kubectl-config to the agent') {
            steps {
                sh """
                    sudo apt-get update && sudo apt-get install -y kubectl
                    mkdir -p ~/.kube/
                    scp user@xx.xx.xx.xx:~/.kube/config ~/.kube/
                    kubectl get nodes
                """
            }
        }

        stage('Deploy new image to k8s cluster') {
            steps {
                sh """
                    sed '/image/ s/latest/${VERSION}/' files/test-webapp-deploy.yaml
                    kubectl -n ${NAMESPACE} apply -f files/test-webapp-deploy.yaml
                    kubectl -n ${NAMESPACE} get pod |grep -v NAME | awk '{ print \$1 }'| xargs -i kubectl -n ${NAMESPACE} delete pod {}
                """
            }
        }

        stage('Test k8s web-app pod status') {
            steps {
                sh """
                    kubectl -n ${NAMESPACE} get pod 
                """
            }
        }

        stage('Test k8s web-app URI health') {
            steps {
                sh """
                    curl -s -I https://web-app.poyaskov.ca 
                """
            }
        }

    }

    post {
        failure {
            mail to: 'vadim@poyaskov.ca',
                subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
                body: "Something is wrong with ${env.BUILD_URL}"
        }
        success {
            mail to: 'vadim@poyaskov.ca',
                subject: "Deployment finisged Successfully . Pipeline: ${currentBuild.fullDisplayName}",
                body: "Deployment finished Successfullt there ${env.BUILD_URL}"
        }
    }    

}

```

#### 5. Deployed app

Deployed application is available here:  https://web-app.poyaskov.ca
