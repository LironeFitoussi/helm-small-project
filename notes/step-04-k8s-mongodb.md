# Step 04 - MongoDB on Kubernetes

- added headless Service for MongoDB
- added MongoDB StatefulSet with PVC
- changed MONGO_URI to mongodb://mongo:27017/movies

- applied MongoDB headless Service and StatefulSet
- waited for MongoDB rollout
- reapplied app manifests with in-cluster Mongo URI
- restarted movie-api deployment
