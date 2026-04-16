**\# Sample MERN with Microservices**

For \`helloService\`, create \`.env\` file with the content:  
\`\`\`bash  
PORT\=3001  
\`\`\`

For \`profileService\`, create \`.env\` file with the content:  
\`\`\`bash  
PORT\=3002  
MONGO\_URL\="specifyYourMongoURLHereWithDatabaseNameInTheEnd"  
\`\`\`

Finally install packages in both the services by running the command \`npm install\`.

\<br/\>  
For frontend, you have to install and start the frontend server:

\`\`\`bash  
cd frontend  
npm install  
npm start  
\`\`\`

Note: This will run the frontend in the development server. To run in production, build the application by running the command \`npm run build

![][image1]

**Install and upate the apt package** 

sudo apt update  
sudo apt upgrade \-y   
sudo apt install git \-y   
git clone [https://github.com/Adish786/SampleMERNwithMicroservices.git](https://github.com/Adish786/SampleMERNwithMicroservices.git)  
cd SampleMERNwithMicroservices  
sudo mkdir k8s-manifests

Install Docker  
In simple ways only run the single command   
sudo apt install [docker.io](http://docker.io) \-y 

Or If you want to install with certificate and add the repository then follow the next step 

*`# Add Docker's official GPG key`*  
`curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg`

*`# Add the Docker repository`*  
`echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null`

*`# Install Docker Engine`*  
`sudo apt update`  
`sudo apt install -y docker-ce docker-ce-cli containerd.io`

*`# Add your user to the 'docker' group to run Docker commands without 'sudo'`*  
`sudo usermod -aG docker $USER`

\#Check the systemctl status 

sudo systemctl status containerd

systemctl enable \--now containerd

systemctl restart docker

![][image2]

#### **Install kubectl**

\# Download the latest release  
curl \-LO "https://dl.k8s.io/release/$(curl \-L \-s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

\# Install the binary  
sudo install \-o root \-g root \-m 0755 kubectl /usr/local/bin/kubectl

\# Verify the installation  
kubectl version \--client

![][image3]

#### 

####  **Install Minikube**

\# Download the latest Minikube binary  
curl \-LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

\# Install it  
sudo install minikube-linux-amd64 /usr/local/bin/minikube

\# Verify the installation  
minikube version

![][image4]

minikube start \--driver=docker

![][image5]

### **Install Google Cloud SDK**

\# Download and install gcloud CLI  
curl \-O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86\_64.tar.gz  
tar \-xf google-cloud-cli-linux-x86\_64.tar.gz  
./google-cloud-sdk/install.sh  
\# Restart your shell or run:  
source \~/.bashrc

### **Authenticate and Set Project**

gcloud auth login  
gcloud config set project YOUR\_PROJECT\_ID   \# replace with your GCP project ID

![][image6]

Create a Docker file for each service 

helloservice 

\# Build stage  
FROM node:18-alpine AS builder  
WORKDIR */app*  
COPY *package\*.json* *./*  
RUN *npm* *ci* *\--only=production*

\# Runtime stage  
FROM node:18-alpine  
RUN *addgroup* *\-g* *1001* *\-S* *nodejs* *&&* *adduser* *\-S* *nodejs* *\-u* *1001*  
WORKDIR */app*  
COPY *\--from*\=builder *\--chown*\=nodejs:nodejs */app/node\_modules* *./node\_modules*  
COPY *.* *.*  
USER *nodejs*  
EXPOSE *3001*  
CMD *\[*"node"*,* "index.js"*\]*

profileservice 

\# Build stage  
FROM node:18-alpine AS builder  
WORKDIR */app*  
COPY *package\*.json* *./*  
RUN *npm* *ci* *\--only=production*

\# Runtime stage  
FROM node:18-alpine  
RUN *addgroup* *\-g* *1001* *\-S* *nodejs* *&&* *adduser* *\-S* *nodejs* *\-u* *1001*  
WORKDIR */app*  
COPY *\--from*\=builder *\--chown*\=nodejs:nodejs */app/node\_modules* *./node\_modules*  
COPY *.* *.*  
USER *nodejs*  
EXPOSE *3002*  
CMD *\[*"node"*,* "index.js"*\]*

frontendservice 

\# Stage 1: Build the React application  
FROM node:18-alpine AS builder  
WORKDIR */app*  
COPY *package\*.json* *./*  
RUN *npm* *ci*  
COPY *.* *.*  
RUN *npm* *run* *build*

\# Stage 2: Serve with Nginx  
FROM nginx:stable-alpine  
\# Copy custom nginx config (optional \- see note below)  
COPY *nginx.conf* */etc/nginx/conf.d/default.conf*  
\# Copy built static files  
COPY *\--from*\=builder */app/build* */usr/share/nginx/html*  
EXPOSE *3000*  
CMD *\[*"nginx"*,* "-g"*,* "daemon off;"*\]*

In frontendservice 

`nginx.conf`

`cat > nginx.conf << 'EOF'`  
`server {`  
    `listen 3000;`  
    `server_name localhost;`  
    `root /usr/share/nginx/html;`  
    `index index.html;`

    `location / {`  
        `try_files $uri $uri/ /index.html;`  
    `}`

    `location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {`  
        `expires 1y;`  
        `add_header Cache-Control "public, immutable";`  
    `}`  
`}`  
`EOF`

## **Build & Push Images Using Cloud Build**

### **Enable Cloud Build API**

gcloud services enable [cloudbuild.googleapis.com](http://cloudbuild.googleapis.com)  
gcloud builds submit \--tag gcr.io/heroviredacademics/hello-service ./backend/helloService  
gcloud builds submit \--tag gcr.io/heroviredacademics/profile-service ./backend/profileService  
gcloud builds submit \--tag gcr.io/heroviredacademics/frontend ./frontend

![][image7]  
![][image8]  
![][image9]  
![][image10]

gcloud container images list \--repository=[gcr.io/heroviredacademics](http://gcr.io/heroviredacademics)

![][image11]

## **Install the GKE Auth Plugin**

![][image12]

![][image13]  
![][image14]  
\# Install the plugin using apt (Ubuntu)  
sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin //if apt are not found the plugin then run the second command 

gcloud components install gke-gcloud-auth-plugin

\# Verify installation  
gke-gcloud-auth-plugin \--version

### **Create a GKE Cluster**

gcloud container clusters create mern-cluster \--zone us-central1-b \--num-nodes 2  \--machine-type e2-medium

## **Add a Third Node**

gcloud container clusters resize mern-cluster \--node-pool default-pool \--num-nodes=3 \--zone us-central1-b

### **Get Credentials for kubectl**

gcloud container clusters get-credentials mern-cluster \--zone us-central1-b

![][image15]  
![][image16]  
![][image17]

###  **Verify kubectl Works**

kubectl apply \-f k8s-manifests/

kubectl get nodes  
kubectl get all  
kubectl get pods  
kubectl get pods \-w  
kubectl get svc  
kubectl get ingress  
kubectl get ingress mern-ingress   //name of the cluster 

![][image18]

![][image19]  
![][image20]

![][image21]

![][image22]

![][image23]

![][image24]

\# Frontend (should return the React HTML)  
curl http://34.111.2.96/  
\# Hello service (should return a greeting JSON)  
curl http://34.111.2.96/api/  
\# Profile service (should return profile data or a message)  
curl http://34.111.2.96/profile/

[image1]: ./docs/readme-images/image1.png

[image2]: ./docs/readme-images/image2.png

[image3]: ./docs/readme-images/image3.png

[image4]: ./docs/readme-images/image4.png

[image5]: ./docs/readme-images/image5.png

[image6]: ./docs/readme-images/image6.png

[image7]: ./docs/readme-images/image7.png

[image8]: ./docs/readme-images/image8.png

[image9]: ./docs/readme-images/image9.png

[image10]: ./docs/readme-images/image10.png

[image11]: ./docs/readme-images/image11.png

[image12]: ./docs/readme-images/image12.png

[image13]: ./docs/readme-images/image13.png

[image14]: ./docs/readme-images/image14.png

[image15]: ./docs/readme-images/image15.png

[image16]: ./docs/readme-images/image16.png

[image17]: ./docs/readme-images/image17.png

[image18]: ./docs/readme-images/image18.png

[image19]: ./docs/readme-images/image19.png

[image20]: ./docs/readme-images/image20.png

[image21]: ./docs/readme-images/image21.png

[image22]: ./docs/readme-images/image22.png

[image23]: ./docs/readme-images/image23.png

[image24]: ./docs/readme-images/image24.png