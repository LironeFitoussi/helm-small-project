# Step 03 - Kubernetes manual manifests

- added ConfigMap for PORT
- added Secret for MONGO_URI
- added Deployment with 2 replicas and probes
- added ClusterIP Service
- image: idf775/movie-api:1.0

- applied k8s manifests
- checked rollout status
- checked pods and deployment logs

- opened port-forward to svc/movie-api on localhost:8080
- verified /health through Kubernetes Service
- created and listed movie through Kubernetes Service
- Step 03 completed
