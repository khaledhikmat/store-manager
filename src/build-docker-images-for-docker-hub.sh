docker image build -t khaledhikmat/store-manager-actors:1.0 . -f Dockerfile-actors
docker image build -t khaledhikmat/store-manager-orders:1.0 . -f Dockerfile-orders
docker image build -t khaledhikmat/store-manager-entities:1.0 . -f Dockerfile-entities