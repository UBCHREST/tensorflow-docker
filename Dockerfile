# from the latest chrest base image
FROM ghcr.io/ubchrest/chrest-base-image/chrest-base-image:latest as build

# Download and install tensorflow pip packages
RUN pip install --user pip numpy wheel
RUN pip install --user keras_preprocessing --no-deps

# Install bazel
RUN npm install -g @bazel/bazelisk

# Get the commit hash
ARG COMMIT_HASH=master

# Download the tensorlofw source code
RUN git clone https://github.com/tensorflow/tensorflow.git /tensorflow-build
WORKDIR /tensorflow-build
run git checkout $COMMIT_HASH
RUN yes '' | ./configure

# Build the c library
RUN bazel build --jobs 10 -c fastbuild --config=nogcp --config=nonccl  //tensorflow/tools/lib_package:libtensorflow

# start a clean image
FROM ghcr.io/ubchrest/chrest-base-image/chrest-base-image:latest 

# copy the build result
COPY --from=build /tensorflow-build/bazel-bin/tensorflow/tools/lib_package/libtensorflow.tar.gz libtensorflow.tar.gz

# Extract the result
RUN mkdir /tensorflow
RUN tar -C /tensorflow -xzf libtensorflow.tar.gz
ENV TENSORFLOW_DIR=/tensorflow

