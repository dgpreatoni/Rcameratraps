###############################################################################
# UAGRA R Scripts - camera_trap                               base_functions.R
###############################################################################
# Convenience functions for cameratrap [ackage]
# Note: <notes here>
#
# version 0.1
# created fra 20160826
# updated prea 20160829
# updated prea 20161106
# updated prea 20180119
###############################################################################

#### create a package environment to store globals
.pkgOptions <- new.env(FALSE, globalenv())
assign("EXIFTOOL", NULL, envir=.pkgOptions)
assign("metadataFileName", 'metadata.txt', envir=.pkgOptions)
assign("repositoryPath", NULL, envir=.pkgOptions)

#### tasks to be performed at package load
.onLoad <- function(lib, pkg) {
  cat("This is package cameratrap\n")
  #### check for exiftool existence
  # exiftool path can be accessed using get(EXIFTOOL, envir=.pkgOptions)
  #@TODO this uses UNIX 'which', and should be ported to Win and Mac
  exiftool <- system2('which', args='exiftool', stdout=TRUE)
  if('status' %in% names(attributes(exiftool))) { # if system2 returns an error code different than 0 (normal completion), then EXIFTOOL has a 'status' attribute.
    stop("Error: exiftool not found. Please check and install it.")
  } else {
    assign("EXIFTOOL", exiftool, envir=.pkgOptions)
    cat("\tEXIFtool found in", exiftool, '\n')
  }
}

#### create an empty dataframe for catalog data (column names as per Rovero and Zimmermann 2016)
.createCatalog <- function() {
  catalogData <- data.frame(Organization.Name=character(), Project.Name=character(), Sampling.Unit.Name=character(), Latitude=numeric(), Longitude=numeric(), Sampling.Event=character(), Photo.Type=character(), Photo.Date=character(), Photo.Time=character(), Raw.Names=character(), Raw.Path=character(), Genus=character(), Species=character(), Number.of.Animals=numeric(), Person.Identifying.the.Photo=character(), Camera.Serial.Number=numeric(), Camera.Start.Date.and.Time=character(), Camera.End.Date.and.Time=character(), Person.setting.up.the.Camera=character(), Person.picking.up.the.Camera=character(), Camera.Manufacturer=character(), Camera.Model=character(), Camera.Name=character(), Sequence.Info=numeric())
  assign("catalogData", catalogData, envir=.pkgOptions)
}


#### returns path to image/video filesystem repository
getRepository <- function() {
  get("repositoryPath", envir=.pkgOptions)
}

#### sets path to image/video filesystem repository
setRepository <- function(path=getwd()) {
  #@TODO add code to check for repository existance
  assign("repositoryPath", normalizePath(path), envir=.pkgOptions)
}

#### pull out EXIF data for all AVI and JPEG files inside a directory
getEXIFData <- function(EXIFDir=getwd()) {
  oldwd <- getwd()
  setwd(EXIFDir)
  tmpCsvFile <- tempfile(pattern=paste("EXIF", gsub('/', '-', EXIFDir), sep=''), fileext=".csv")
  # fix csv file names containing spaces
  tmpCsvFile <- gsub(' ', '_', tmpCsvFile)
  # ask exiftool to pull out just the tags we need, some files can hide _binary_ tags that are difflcult to process...
  res <- system2(EXIFTOOL, args=paste('-FileModifyDate -Filetype -CHARSET UTF8 -extension AVI -ext JPG -ext avi -ext jpg -ext M4V -csv ',  ' * > ', tmpCsvFile, sep=''))
  if(res==0){
    EXIFData <- read.csv(tmpCsvFile)
    unlink(tmpCsvFile)
    # the following row is not needed anymore, since we ask exiftool what we actually need instead of asking 'just all' and cleaning up after
    # EXIFData <- EXIFData[c(3,6,10)] # get just the data we actually need
    names(EXIFData) <- c('Raw.Names','Photo.Time','Photo.Type')
    #@TODO check for date and time format to be compliant to Rovero and Zimmermann
    EXIFData$Photo.Time <- as.character(EXIFData$Photo.Time)
    EXIFData$Photo.Date <- substr(EXIFData$Photo.Time, 1, 10) ## fixed as requested by Rovero and Zimmermann
    EXIFData$Photo.Date <- gsub(':','-',EXIFData$Photo.Date) ## fixed as requested by Rovero and Zimmermann
    EXIFData$Photo.Time <- substr(EXIFData$Photo.Time, 12, 19) ## fixed as requested by Rovero and Zimmermann
    EXIFData$Sampling.Event <- EXIFDir
  } else {
    EXIFData <- data.frame(Raw.Names=character(), Photo.Time=character(),Photo.Type=character(), Sampling.Event=character())
  }
  setwd(oldwd)
  invisible(EXIFData)
}

#### parse a medata file, returns a named array
.parseMetadata <- function(file) {
  stopifnot(file.exists(file))
  #@FIXME handle 'lines with embedded nulls', i.e. skip in some way any blank line
  # using read.table, but gives warning for non properly terminated files
  md.frame <- suppressWarnings(read.table(file=file, header=FALSE, sep=':', col.names=c('Key', 'Value'), stringsAsFactors=FALSE))
  #md.frame[6,]$Value <- paste(md.frame[6,]$Value,md.frame[7,]$Key,md.frame[7,]$Value, sep=':')
  #md.frame[8,]$Value <- paste(md.frame[8,]$Value,md.frame[9,]$Key,md.frame[9,]$Value, sep=':')
  #md.frame <- md.frame[-c(7,9),]
  #substr(md.frame[6,]$Value, 12,12) <- ' '
  #substr(md.frame[6,]$Value, 21,21) <- ' '
  #substr(md.frame[7,]$Value, 12,12) <- ' '
  #substr(md.frame[7,]$Value, 21,21) <- ' '

  md.frame$Key <- trimws(md.frame$Key)
  md.frame$Value <- trimws(md.frame$Value)
  md.table <- md.frame$Value
  names(md.table) <- md.frame$Key
  #@TODO do any specialized parsing/conditioning based on keys here
  #invisible(md.table)
  return(md.table)
}