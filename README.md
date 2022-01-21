# GWELLS Docker Image (Rstudio, Python, geospatial libraries)

## Description 

This is a python/R/geospatial docker image that builds upon rocker/geospatial:4.1.2.    The rocker/geospatial:4.1.2 image contains R, a lot of pre-installed R spatial libraries and the associated system dependencies.  The dockerfile starts from that image, installs miniconda python and creates an environment is defined by the `environment.yml` file in Simon Norris's [GWELLS_LocationQA](https://github.com/bcgov/GWELLS_LocationQA) repository.

The objective of this docker image is to allow the github actions defined on [GWELLS-QAQC_Geocode_ArchiveData]((https://github.com/bcgov/GWELLS-QAQC_Geocode_ArchiveData)) to download gwells.csv, reverse-geocode the lat-long, create data quality variables and save the results to CSVs in the data/ folder of that repo.  These CSVs will then be read by the GWELLS QAQC Shiny ([github](https://github.com/bcgov/GWELLS-QAQC-RShiny-Dashboard), [deployed app on BCGOV Shinyapps.io account](https://bcgov-env.shinyapps.io/gwells-qaqc-rshiny-dashboard/)).


## Deployment

Here is the lines of codes I use to build the image and upload it to dockerhub (my username is "lespelleteux", replace it with the BCGOV docker account.):

    docker build -t docker_for_gwells .
    docker tag docker_for_gwells lespelleteux/docker_for_gwells  
    docker push lespelleteux/docker_for_gwells

Once this is done, visit please edit the following 3 github actions so that they now refer to the docker image hosted under BCGOV's docker account.
You will need to replace the "image: lespelleteux/docker_for_gwells" line with whatever username and tag you used when you pushed the docker image.  

[archive_new_wells_csv.yaml](https://github.com/bcgov/GWELLS-QAQC_Geocode_ArchiveData/blob/main/.github/workflows/archive_new_wells_csv.yaml)
[geocode_csv.yaml](https://github.com/bcgov/GWELLS-QAQC_Geocode_ArchiveData/blob/main/.github/workflows/geocode_csv.yaml)  
[qa_csv.yaml](https://github.com/bcgov/GWELLS-QAQC_Geocode_ArchiveData/blob/main/.github/workflows/qa_csv.yaml)

## Credits / Blame

This repo was created by Simon Coulombe during a "Code With Us" opportunity in January 2022.  Lots of the code in the Dockerfile comes from [this image by Thomas Schaffer](https://github.com/tschaffter/rstudio), and there is more useful stuff there.



## Extra info   

Here is a line of code to start the server with "yourpasswordhere".  The rstudio server will be available at 127.0.0.1:8787

    docker run   -d --rm -p 8787:8787 -e PASSWORD=yourpasswordhere  --name docker_for_gwells -v ~/git/montest:/tmp/workingdir -w /tmp/workingdir docker_for_gwells  


The -d  (detached)  starts the server but allows us to keep working in the terminal.   
The -v (volume) allows us to work on code that is available locally.
The -w (working dir) sets the current work directory to /tmp/workingdir


This is how to SSH into the docker after starting it :  
     
     docker exec -it docker_for_gwells bash


Once in Rstudio,  one can use `reticulate` to set the conda environment to gwells_locationqa using this code:

    library(reticulate)  
    use_condaenv(condaenv = "gwells_locationqa", required= TRUE)  


We do not use reticulate in this project, because reticulate converts functions to R. The geocoding and qa scripts are closer to shell commands.  They  do not take a table in memory as input and do not return a table in memory as output.  Instead, they read a CSV file and write to a different CSV file.

The easiest way I found to run the python scripts from the `gwells_locationqa` environment is to create a shell script that activates the environment and calls the .py file, like so:

### geocode.sh:

    #!/bin/bash  
    #set -euxo pipefail  
    eval "$(conda shell.bash hook)"  
    conda activate gwells_locationqa  
    cp   /GWELLS_LocationQA/gwells_locationqa.py  /tmp/workingdir/gwells_locationqa.py  
    python gwells_locationqa.py geocode  not_an_api_key  



