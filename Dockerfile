FROM 954976316440.dkr.ecr.ap-south-1.amazonaws.com/mf-test:1.0.10

ENV CUDA_DEVICE_ORDER="PCI_BUS_ID"
ENV CUDA_VISIBLE_DEVICES="0"
COPY config/config.yaml .
COPY functions.py .
SHELL ["/bin/bash", "-c"]