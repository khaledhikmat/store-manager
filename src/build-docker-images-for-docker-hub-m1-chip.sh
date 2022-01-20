docker buildx build --platform=linux/amd64 -t khaledhikmat/store-manager-actors:1.0 . -f Dockerfile-actors
docker buildx build --platform=linux/amd64 -t khaledhikmat/store-manager-orders:1.0 . -f Dockerfile-orders
docker buildx build --platform=linux/amd64 -t khaledhikmat/store-manager-entities:1.0 . -f Dockerfile-entities