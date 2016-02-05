# Adapted from Miki Tebeka's: http://pythonwise.blogspot.com/2015/04/docker-miniconda-perfect-match.html

FROM ubuntu:14.04

# System packages 
RUN apt-get update && apt-get install -y curl

# Install miniconda to /miniconda
RUN curl -LO https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
RUN bash Miniconda3-latest-Linux-x86_64.sh -p /miniconda3 -b
RUN rm Miniconda3-latest-Linux-x86_64.sh
ENV PATH=/miniconda3/bin:${PATH}
RUN conda update -y conda

# Python packages from conda
RUN conda install -y flask flask-login

# Setup application
COPY flask-server.py /
ENTRYPOINT ["/miniconda3/bin/python", "/flask-server.py"]
EXPOSE 5000