docker image build -t store-manager/actors:1.0 . -f Dockerfile-actors
docker image build -t store-manager/orders:1.0 . -f Dockerfile-orders
docker image build -t store-manager/entities:1.0 . -f Dockerfile-entities