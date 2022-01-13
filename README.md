# GWELLS-QAQC_Docker
relates to GWELLS-QAQC-RShiny-Dashboard Github 

## Description 

This Repo defines  a docker image that is used by the github actions schedule on the [bcgov/GWELLS-QAQC_Geocode_ArchiveData](https://github.com/bcgov/GWELLS-QAQC_Geocode_ArchiveData) repo to prepare and archive GWELLS data for GWELLS-QAQC Shiny consumption.  

The docker image is currently hosted on dockerhub as morglum/monrstudio, but should be moved over the BCGOV's dockerhub account.

This is a python/R/geospatial docker image that builds upon rocker/geospatial:4.1.2.   

A second repo, [bcgov/GWELLS-QAQC_Geocode_ArchiveData](https://github.com/bcgov/GWELLS-QAQC_Geocode_ArchiveData) contains scripts that are run daily using Github actions that will download the gwells.csv file , reverse-geocode the lat-long, create data quality variables and save the results to a repo of ever-increasing size.   The python scripts come from [Simon Norris code](https://github.com/bcgov/GWELLS_LocationQA).

A third repo, [bcgov/GWELLS-QAQC-RShiny-Dashboard](https://github.com/bcgov/GWELLS-QAQC-RShiny-Dashboard) defines that will read these csv and display them in an app.  That app is hosted on shnyapps.io as [gwells-qaqc-rshiny-dashboard](https://bcgov-env.shinyapps.io/gwells-qaqc-rshiny-dashboard/).

## Credits  

Lots of code for the Dockerfile was pulled from  from [this image by Thomas Schaffer](https://github.com/tschaffter/rstudio), and there is more useful stuff there.

## Notes   

Here is more info than required:  


Here is the lines of codes I used to build the image and upload it to dockerhub (my username is morglum):

    docker build -t monrstudio .
    docker tag monrstudio  morglum/monrstudio  
    docker push morglum/monrstudio

Here is a line of code to start the server with "yourpasswordhere".  The rstudio server will be available at 127.0.0.1:8787

    docker run   -d --rm -p 8787:8787 -e PASSWORD=yourpasswordhere  --name monrstudio -v ~/git/montest:/tmp/workingdir -w /tmp/workingdir monrstudio  

The -d  (detached)  starts the server but allows us to keep working in the terminal.   
The -v (volume) allows us to work on code that is available locally.
The -w (working dir) sets the current work directory to /tmp/workingdir

This is how to SSH into the docker after starting it :  
     
     docker exec -it monrstudio bash

Once in Rstudio,  one can use `reticulate` to set the conda environment to gwells_locationqa using this code:

    library(reticulate)  
    use_condaenv(condaenv = "gwells_locationqa", required= TRUE)  

e do not use reticulate in this project, because reticulate is used to convert functions to R. The geocoding and qa scripts are meant to called from the shell, so 
the easiest way I found to run the python scripts from the `gwells_locationqa` environment is to create a shell script that activates the environment and calls the .py file, like so:

### geocode.sh:

    #!/bin/bash  
    #set -euxo pipefail  
    eval "$(conda shell.bash hook)"  
    conda activate gwells_locationqa  
    cp   /GWELLS_LocationQA/gwells_locationqa.py  /tmp/workingdir/gwells_locationqa.py  
    python gwells_locationqa.py geocode  not_an_api_key  



