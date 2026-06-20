# Step 01 - run app

- started existing mongo container
- verified mongo container is running
- next: install app deps and run api

- fixed mongo container port mapping
- old container saved as mongo-old-before-step01
- new mongo exposes localhost:27017

- created python virtualenv under movie-api
- installed app requirements

- first venv used python 3.7 and failed on fastapi 0.115.0
- recreated venv with python 3.12
- installed requirements from movie-api/requirements.txt

- ran api with MONGO_URI=mongodb://localhost:27017/movies
- verified /health endpoint

- created one movie through POST /movies
- verified movie appears in GET /movies
