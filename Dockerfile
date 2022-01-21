FROM rocker/geospatial:4.1.2

LABEL maintainer="simoncoulombe@protonmail.com"
LABEL description="Image with Rstudio, Conda and geospatial dependencies"

ENV miniconda3_version="py39_4.9.2"
ENV miniconda_bin_dir="/opt/miniconda/bin"
ENV PATH="${PATH}:${miniconda_bin_dir}"

# Safer bash scripts with 'set -euxo pipefail'
SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

RUN apt-get update -yqq

# install nano
RUN apt-get install -yqq nano

# install a bunch of dependencies
RUN apt-get update -qq -y \
    && apt-get install --no-install-recommends -qq -y \
        bash-completion \
        curl \
        gosu \
        libxml2-dev \
        zlib1g-dev \
        # Fix https://github.com/tschaffter/rstudio/issues/11 (1/2)
        libxtst6 \
        libxt6 \
        # Lato font is required by the R library `sagethemes`
        fonts-lato \
    && apt-get -y autoclean \
    && apt-get -y autoremove \
    && rm -rf /var/lib/apt/lists/* \
    # Fix https://github.com/tschaffter/rstudio/issues/11 (2/2)
    && ln -s /usr/local/lib/R/lib/libR.so /lib/x86_64-linux-gnu/libR.so    
    
# install miniconda  
RUN  curl -fsSLO https://repo.anaconda.com/miniconda/Miniconda3-${miniconda3_version}-Linux-x86_64.sh \
    && bash Miniconda3-${miniconda3_version}-Linux-x86_64.sh \
        -b \
        -p /opt/miniconda \
    && rm -f Miniconda3-${miniconda3_version}-Linux-x86_64.sh \
    && useradd -u 1500 -s /bin/bash miniconda \
    && chown -R miniconda:miniconda /opt/miniconda \
    && chmod -R go-w /opt/miniconda \
    && conda --version

#  clone GWELLS_LocationQA github  (to get environment file)
RUN git clone https://github.com/simoncoulombe/GWELLS_LocationQA.git

# create environment defined in github
RUN conda env create -f /GWELLS_LocationQA/environment.yml

# install aws cli to download tif from s3
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" &&\
 unzip /tmp/awscliv2.zip -d /tmp &&\
 sudo /tmp/aws/install &&\
 rm -rf /tmp/*

# download  world cover
RUN ./GWELLS_LocationQA/get_esa_worldcover_bc.sh  &&\
 rm /data/ESA_WorldCover_10m* &&\
 mv /data /GWELLS_LocationQA &&\
 mv /esa_bc.tif /GWELLS_LocationQA/data/


# install R libraries that will be used in the github actions
RUN install2.r --error --skipinstalled --ncpus -1 \
    janitor \
    sessioninfo \
    kableExtra \
    mapview \
    reticulate \
    DBI \
    RPostgreSQL


#Run the download.sh script to have the pmbc_parcel_fabric_poly_svw.gdb available for github actions
COPY download.sh /
RUN ./download.sh &&\
  mv /data/pmbc_parcel_fabric_poly_svw.gdb /GWELLS_LocationQA/data/ &&\
  rm -rf data
