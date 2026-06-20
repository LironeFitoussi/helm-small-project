# Step 06 - MongoDB Helm dependency

- removed local Mongo templates
- added Bitnami MongoDB dependency
- moved Mongo settings under mongodb values
- updated secret.mongoUri to use Bitnami MongoDB service
