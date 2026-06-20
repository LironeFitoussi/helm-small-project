# Step 06 - MongoDB Helm dependency

- removed local Mongo templates
- added Bitnami MongoDB dependency
- moved Mongo settings under mongodb values
- updated secret.mongoUri to use Bitnami MongoDB service

- installed chart with Bitnami MongoDB dependency
- waited for demo-mongodb StatefulSet
- waited for demo-movie-chart Deployment
- checked pods services pvc and app logs

- tested upgrade with dependency
- checked Helm history
- rolled back release
- uninstalled demo release
- Step 06 completed
