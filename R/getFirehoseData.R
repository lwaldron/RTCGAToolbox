#' Get data from Firehose portal.
#'
#' \code{getFirehoseData} returns \code{FirehoseData} object that stores TCGA data.
#'
#' This is a main client function to download data from Firehose TCGA portal.
#'
#' @param dataset A cohort name. All dataset names can be accessible via \code{\link{getFirehoseDatasets}}
#' @param runDate Standard data run dates. Date list can be accessible via \code{\link{getFirehoseRunningDates}}
#' @param gistic2_Date Analyze running dates for GISTIC processed copy number data. Date list can be accessible via \code{\link{getFirehoseAnalyzeDates}}
#' @param RNAseq_Gene Logical (default FALSE) parameter for RNAseq data.
#' @param Clinic Logical (default TRUE) parameter for clinical data.
#' @param RNAseq2_Gene_Norm Logical (default FALSE) parameter for RNAseq v2 (RSEM processed) data.
#' @param miRNASeq_Gene Logical (default FALSE) parameter for smallRNAseq data.
#' @param CNA_SNP Logical (default FALSE) parameter for somatic copy number alterations data from SNP array.
#' @param CNV_SNP Logical (default FALSE) parameter for germline copy number variants data from SNP array.
#' @param CNA_Seq Logical (default FALSE) parameter for somatic copy number alterations data from sequencing.
#' @param CNA_CGH Logical (default FALSE) parameter for somatic copy number alterations data from CGH.
#' @param Methylation Logical (default FALSE) parameter for methylation data.
#' @param Mutation Logical (default FALSE) parameter for mutation data from sequencing.
#' @param mRNA_Array Logical (default FALSE) parameter for mRNA expression data from microarray.
#' @param miRNA_Array Logical (default FALSE) parameter for miRNA expression data from microarray.
#' @param RPPA Logical (default FALSE) parameter for RPPA data
#' @param RNAseqNorm RNAseq data normalization method. (Default raw_counts)
#' @param RNAseq2Norm RNAseq v2 data normalization method. (Default normalized_count)
#' @param todir The directory path to download files to and from which to read files. It will be created if necessary. Defaults to current working directory. 
#' @param forceDownload A logic (Default FALSE) key to force download files when run. By default, local files in the specified directory will be used if available.
#' @param fileSizeLimit Files that are larger than set value (megabyte) won't be downloaded (Default: 500)  
#' @param getUUIDs Logical key to get UUIDs from barcode (Default: FALSE)
#' @return A \code{FirehoseData} data object that stores data for selected data types.
#' @examples
#'
#' \dontrun{
#' a2 <- getFirehoseData(dataset="BRCA",
#' runDate="20140416",gistic2_Date="20140115",
#' RNAseq_Gene=TRUE,Clinic=TRUE,mRNA_Array=TRUE,Mutation=TRUE)
#' }
#' 
getFirehoseData <- function(dataset, runDate=NULL, gistic2_Date=NULL, RNAseq_Gene=FALSE,Clinic=TRUE,
                            miRNASeq_Gene=FALSE, RNAseq2_Gene_Norm=FALSE,
                            CNA_SNP=FALSE,CNV_SNP=FALSE,
                            CNA_Seq=FALSE,CNA_CGH=FALSE,Methylation=FALSE,Mutation=FALSE,mRNA_Array=FALSE,
                            miRNA_Array=FALSE,RPPA=FALSE,RNAseqNorm="raw_counts",RNAseq2Norm="normalized_count", 
                            todir = NULL, forceDownload=FALSE,fileSizeLimit=500,getUUIDs=FALSE)
{
  #check input parameters
  if(!class(dataset)=="character" || is.null(dataset) || !length(dataset) == 1 || nchar(dataset) < 2)
  {stop('Please set "dataset" parameter! You should specify one dataset name. Ex: dataset="BRCA"...')}
  runDatasets <- getFirehoseDatasets()
  if(!any(runDatasets==dataset)){stop('Please use valid dataset name! "getFirehoseDatasets" function gives you the vector of valid dataset names!')}
  if(!is.null(runDate))
  {
    if(!class(runDate)=="character" || !length(runDate) == 1 || !nchar(runDate) == 8)
    {stop('Please set "runDate" parameter! You should specify one Firehose run date. Ex: runDate="20140416"...')}
    runDateList <- getFirehoseRunningDates()
    if(!any(runDateList==runDate)){stop('Please use valid run date! "getFirehoseRunningDates" function gives you the vector of valid dates!')}
  }
  
  if(!is.null(gistic2_Date))
  {
    if(!class(gistic2_Date)=="character" || !length(gistic2_Date) == 1 || !nchar(gistic2_Date) == 8)
    {stop('Please set "gistic2_Date" parameter! You should specify one Firehose run date. Ex: gistic2_Date="20140115"...')}
    runGisticDate <- getFirehoseAnalyzeDates()
    if(!any(runGisticDate==gistic2_Date)){stop('Please use valid analyze date for GISTIC! "getFirehoseAnalyzeDates" function gives you the vector of valid dates!')}
  }
  if(is.null(gistic2_Date) & is.null(runDate)){stop("Please specify run date or/and gistic date!")}
  
  trim <- function (x) gsub("^\\s+|\\s+$", "", x)
  
  if(!is.null(todir)) {
    if(!class(todir)=="character"){
      stop("Please provide a valid directory path!")
    } else if(!file.exists(todir)) {
      cat("Directory does not exist, creating one ...")
      dir.create(todir, recursive=TRUE)
      message("Files will be located in ", todir,"!")
    } else {
      message("Files will be located in ", todir, "!")
    }
  } else { 
    todir <- getwd()
    message("Using the current directory (", getwd(), ") for downloading and reading files!")
  }
    
  setwd(todir)
  
  makeExprMat <- function(dataset,fileExt,normMethod,dataType,mergeSize=1000,arrayData=FALSE)
  {
    #Get selected type only
    tmpCols = read.delim(paste0(runDate,"-",dataset,fileExt),nrows=1,colClasses="character")
    if(!arrayData)
    {
      colOrder <- 1:ncol(tmpCols)
      colOrder <- colOrder[tmpCols[1,] == normMethod]
    }
    else
    {
      colOrder <- 2:ncol(tmpCols) 
    }
    closeAllConnections()
    message(paste0(dataType,"data will be imported! This may take a while!"))
    message(paste0("Start: ",Sys.time()))
    tmpMat <- fread(paste0(runDate,"-",dataset,fileExt),header=F,colClasses = "character", select=c(1,colOrder), data.table = FALSE)
    message(paste0("Done: " ,Sys.time()))
    closeAllConnections()
    if(!arrayData)
    {
      colnames(tmpMat) <- tmpMat[1,]
    }
    else
    {
      colnames(tmpMat) <- c("Symbol",tmpMat[1,2:ncol(tmpMat)])
    }
    tmpMat <- tmpMat[-c(1:2),]
    removeQM <- grepl("\\?\\|",tmpMat[,1])
    tmpMat <- tmpMat[!removeQM,]
    names1 <- tmpMat[,1]
    names2 <- sapply(names1,function(x){unlist(strsplit(x,"\\|"))[1]})
    names1 <- duplicated(names2)
    tmpMat <- tmpMat[!names1,]
    rownames(tmpMat) <- names2[!names1]
    tmpMat <- tmpMat[,-1]
    cNames <- colnames(tmpMat)
    rNames <- rownames(tmpMat)
    tmpMat <- apply(tmpMat,2,as.numeric)
    colnames(tmpMat) <- cNames
    rownames(tmpMat) <- rNames
    return(tmpMat)
  }
  
  getLinks <- function(keyWord1,keyWord2,datasetLink=NULL)
  {
    keyWord = keyWord1 #paste0(dataset,keyWord1)
    keyWord = paste0("//a[contains(@href, '",keyWord,"')]")
    plinks = xpathSApply(doc, keyWord, xmlAttrs)
    if(is.null(datasetLink))
    {
      plinks = plinks[grepl(keyWord2,plinks)]
    }
    else
    {
      plinks = plinks[grepl(paste0("*.",datasetLink,keyWord2),plinks)]
    }
    message(plinks)
    return(plinks)
  }
  
  exportFiles <- function(fileLink,dataset,fileExt,searchName,subSearch=FALSE,exportName,manifest=FALSE)
  {
    if(forceDownload || !file.exists(paste0(runDate,"-",dataset,exportName)))
    {
      download.file(url=fileLink,destfile=paste0(dataset,fileExt),method="auto",quiet = FALSE, mode = "w")
      fileList <- untar(paste0(dataset,fileExt), list = TRUE)
      if(!subSearch)
      {
        fileList = fileList[grepl(searchName,fileList)]
      }
      else
      {
        if(!manifest)
        {
          grepSearch = paste0("*.",dataset,searchName)
          fileList = fileList[grepl(grepSearch,fileList)]
        }
        else
        {
          fileList = fileList[!grepl("MANIFEST.txt",fileList)]
        }
      }
      untar(paste0(dataset,fileExt),files=fileList)
      file.rename(from=fileList,to=paste0(runDate,"-",dataset,exportName))
      file.remove(paste0(dataset,fileExt))
      delFodler <- strsplit(fileList[1],"/")[[1]][1]
      message(delFodler)
      unlink(delFodler, recursive = TRUE)
    }
  }
  
  checkFileSize <- function(dataURL)
  {
    asd = read.csv(url(paste0("http://www.canevolve.org/fmineRgetSize.php?url=",dataURL)))
    if(as.numeric(asd[1,1])/(1024^2) > fileSizeLimit)
    {
      message(dataURL)
      message(paste("File Size: ~"),format(as.numeric(asd[1,1])/(1024^2), digits=1, decimal.mark="."),"MB")
      message("File above won't be downloaded due to data size, RTCGAToolbox will skip this data!")
      return(FALSE)
    }
    else
    {
      return(TRUE)
    }
    
  }
  
  barcodeUUID <- function(object)
  {
    message("Converting barcodes to UUID")
    barcodes <- NULL
    if(dim(object@RNASeqGene)[1] > 0 & dim(object@RNASeqGene)[2] > 0)
    {
      barcodes <- c(barcodes,colnames(object@RNASeqGene))
    }
    if(dim(object@RNASeq2GeneNorm)[1] > 0 & dim(object@RNASeq2GeneNorm)[2] > 0)
    {
      barcodes <- c(barcodes,colnames(object@RNASeq2GeneNorm))
    }
    if(dim(object@miRNASeqGene)[1] > 0 & dim(object@miRNASeqGene)[2] > 0)
    {
      barcodes <- c(barcodes,colnames(object@miRNASeqGene))
    }
    if(dim(object@CNASNP)[1] > 0 & dim(object@CNASNP)[2] > 0)
    {
      barcodes <- c(barcodes,as.character(object@CNASNP[,1]))
    }
    if(dim(object@CNVSNP)[1] > 0 & dim(object@CNVSNP)[2] > 0)
    {
      barcodes <- c(barcodes,as.character(object@CNVSNP[,1]))
    }
    if(dim(object@CNAseq)[1] > 0 & dim(object@CNAseq)[2] > 0)
    {
      barcodes <- c(barcodes,as.character(object@CNAseq[,1]))
    }
    if(length(object@CNACGH) > 0 )
    {
      barcodes <- c(barcodes,as.character(object@CNACGH[,1]))
    }
    if(length(object@Methylation) > 0 )
    {
      for(i in 1:length(object@Methylation))
      {
        barcodes <- c(barcodes,colnames(object@Methylation[[i]]@DataMatrix))
      }
    }
    if(length(object@mRNAArray) > 0 )
    {
      for(i in 1:length(object@mRNAArray))
      {
        barcodes <- c(barcodes,colnames(object@mRNAArray[[i]]@DataMatrix))
      }
    }
    if(length(object@miRNAArray) > 0 )
    {
      for(i in 1:length(object@miRNAArray))
      {
        barcodes <- c(barcodes,colnames(object@miRNAArray[[i]]@DataMatrix))
      }
    } 
    if(length(object@RPPAArray) > 0 )
    {
      for(i in 1:length(object@RPPAArray))
      {
        barcodes <- c(barcodes,colnames(object@RPPAArray[[i]]@DataMatrix))
      }
    }
    if(length(object@GISTIC@Dataset) > 0)
    {
      barcodes <- c(barcodes,colnames(object@GISTIC@AllByGene)[-c(1:3)])
    }
    if(dim(object@Mutations)[1] > 0 & dim(object@Mutations)[2] > 0)
    {
      barcodes <- c(barcodes,unique(as.character(object@Mutations[,16])))
      barcodes <- c(barcodes,unique(as.character(object@Mutations[,17])))
    }
    barcodes <- unique(barcodes)
    barcodes <- toupper(barcodes)
    barcodes <- gsub(pattern = "\\.",replacement = "-",x = barcodes)
    
    pb <- txtProgressBar(min = 0, max = length(barcodes), style = 3)
    breakPoints <- seq(1,length(barcodes),20)
    for(i in breakPoints)
    {
      setTxtProgressBar(pb, i)
      urlToGo <- "https://tcga-data.nci.nih.gov/uuid/uuidws/mapping/json/barcode/batch"
      endPoint <- (i+19)
      if(endPoint > length(barcodes)){endPoint = length(barcodes)}
      searchBarcode <- paste(barcodes[i:endPoint], collapse=",")
      uuids = fromJSON(getURL(urlToGo, customrequest="POST", 
                              httpheader=c("Content-Type: text/plain"), 
                              postfields=searchBarcode))$uuidMapping
      if(class(uuids)=="character")
      {
        if(exists("convertTable"))
        {
          convertTable <- rbind(convertTable,c(uuids[1],uuids[2]))
        }
        else
        {
          convertTable <- data.frame(Barcode=uuids[1],UUID=uuids[2])
        }
      }
      else
      {
        if(exists("convertTable"))
        {
          convertTable <- rbind(convertTable,
                                data.frame(matrix(unlist(uuids), nrow=length(uuids), byrow=TRUE),stringsAsFactors=FALSE))
        }
        else
        {
          convertTable <- data.frame(matrix(unlist(uuids), nrow=length(uuids), byrow=TRUE),stringsAsFactors=FALSE)
        }    
      }
      
      if ((endPoint %% 400) == 0)
      {
        message("RTCGAToolbox will wait 185 seconds due to TCGA web service limitations")
        Sys.sleep(185)
      }
      
    }
    
    shortNames <- apply(convertTable,1,function(x){
      as.character(paste(strsplit(x[1],split = "-")[[1]][1:3],collapse = "-"))
    })
    convertTable <- cbind(convertTable,shortNames)
    colnames(convertTable) <- c("Barcode","UUID","ShortName")
    setTxtProgressBar(pb, length(barcodes))
    return(convertTable)
  }
  
  resultClass <- new("FirehoseData", Dataset = dataset)
  if(!is.null(runDate)){
    resultClass@runDate <- runDate
  } else { 
    resultClass@runDate <- "N/A"
  }
  if(!is.null(gistic2_Date)){
    resultClass@gistic2Date <- gistic2_Date
  } else {
    resultClass@gistic2Date <- "N/A"
  }
  
  if(!is.null(runDate))
  {
    ##build URL for getting file links
    fh_url <- "http://gdac.broadinstitute.org/runs/stddata__"
    fh_url <- paste0(fh_url,substr(runDate,1,4),"_",substr(runDate,5,6),"_",substr(runDate,7,8),"/data/")
    fh_url <- paste0(fh_url,dataset,"/",runDate,"/")
    doc = htmlTreeParse(fh_url, useInternalNodes = T)

    #Download clinical data
    if(Clinic)
    {
      #Search for links
      plinks <- getLinks(".Clinical_Pick_Tier1.Level_4","*.tar[.]gz$")
      
      for(i in trim(plinks))
      {
        if(checkFileSize(paste0(fh_url,i)))
        {
          exportFiles(paste0(fh_url,i),dataset,"-Clinical.tar.gz","*.clin.merged.picked.txt$",FALSE,"-Clinical.txt")
          
          raw.clin <- read.delim(paste0(runDate,"-",dataset,"-Clinical.txt"),colClasses="character")
          df.clin <- data.frame(do.call(rbind, raw.clin[, -1]))
          colnames(df.clin) <- raw.clin[, 1]
          resultClass@Clinical <- df.clin
          gc() 
        }
      }
    }
    
    #Download RNAseq gene level data
    if(RNAseq_Gene)
    {
      #Search for links
      plinks <- getLinks("Level_3__gene_expression__data.Level_3","*.Merge_rnaseq__.*._rnaseq__.*.tar[.]gz$")
      
      for(i in trim(plinks))
      { 
        if(checkFileSize(paste0(fh_url,i)))
        {
          exportFiles(paste0(fh_url,i),dataset,"-RNAseqGene.tar.gz","[.]rnaseq__.*.__Level_3__gene_expression__data.data.txt$",TRUE,"-RNAseqGene.txt")
          #Get selected type only
          resultClass@RNASeqGene <- makeExprMat(dataset,"-RNAseqGene.txt",RNAseqNorm,"RNAseq")
          gc() 
        }
      }
    }
    
    #Download RNAseq2 gene level data
    if(RNAseq2_Gene_Norm)
    {
      #Search for links
      plinks <- getLinks("Level_3__RSEM_genes_normalized__data.Level_3","*.Merge_rnaseqv2__.*._rnaseqv2__.*.tar[.]gz$")
      
      for(i in trim(plinks))
      {
        if(checkFileSize(paste0(fh_url,i)))
        {
          exportFiles(paste0(fh_url,i),dataset,
                      "-RNAseq2GeneNorm.tar.gz",
                      "[.]rnaseqv2__.*.__Level_3__RSEM_genes_normalized__data.data.txt$",
                      TRUE,
                      "-RNAseq2GeneNorm.txt")
          
          resultClass@RNASeq2GeneNorm <- makeExprMat(dataset,"-RNAseq2GeneNorm.txt",RNAseq2Norm,"RNAseq2")
          gc() 
        }
      }
    }
    
    #Download miRNAseq gene level data
    if(miRNASeq_Gene)
    {
      #Search for links
      plinks <- getLinks("Level_3__miR_gene_expression__data.Level_3","[.]Merge_mirnaseq__.*.hiseq_mirnaseq__.*.tar[.]gz$",dataset)
      
      for(i in trim(plinks))
      {
        if(checkFileSize(paste0(fh_url,i)))
        {
          exportFiles(paste0(fh_url,i),dataset,
                      "-miRNAseqGene.tar.gz",
                      "[.]mirnaseq__.*.__Level_3__miR_gene_expression__data.data.txt$",
                      TRUE,
                      "-miRNAseqGene.txt")
          
          resultClass@miRNASeqGene <- makeExprMat(dataset,"-miRNAseqGene.txt","read_count","miRNAseq",100)
          gc() 
        }
      }
    }
    
    #Download CNA SNP data
    if(CNA_SNP)
    {
      #Search for links
      plinks <- getLinks("Level_3__segmented_scna_hg19__seg.Level_3","[.]Merge_snp__.*.__Level_3__segmented_scna_hg19__seg.Level_3.*.tar[.]gz$",dataset)
      
      for(i in trim(plinks))
      {
        if(checkFileSize(paste0(fh_url,i)))
        {
          exportFiles(paste0(fh_url,i),dataset,
                      "-CNASNPHg19.tar.gz",
                      "[.]snp__.*.__Level_3__segmented_scna_hg19__seg.seg.txt$",
                      TRUE,
                      "-CNASNPHg19.txt")
          #Get selected type only
          tmpMat = fread(paste0(runDate,"-",dataset,"-CNASNPHg19.txt"),header=TRUE,colClasses=c("character","numeric","numeric",
                                                                                                "numeric","numeric","numeric"),data.table = FALSE)
          resultClass@CNASNP <- tmpMat 
        }
      }
    }
    
    #Download CNV SNP data
    if(CNV_SNP)
    {
      #Search for links
      plinks <- getLinks("Level_3__segmented_scna_minus_germline_cnv_hg19__seg.Level_3","[.]Merge_snp__.*.__Level_3__segmented_scna_minus_germline_cnv_hg19__seg.Level_3.*.tar[.]gz$",dataset)
      
      for(i in trim(plinks))
      {
        if(checkFileSize(paste0(fh_url,i)))
        {
          exportFiles(paste0(fh_url,i),dataset,
                      "-CNVSNPHg19.tar.gz",
                      "[.]snp__.*.__Level_3__segmented_scna_minus_germline_cnv_hg19__seg.seg.txt$",
                      TRUE,
                      "-CNVSNPHg19.txt")
          #Get selected type only
          tmpMat = fread(paste0(runDate,"-",dataset,"-CNVSNPHg19.txt"),header=TRUE,colClasses=c("character","numeric","numeric",
                                                                                                "numeric","numeric","numeric"),data.table = FALSE)
          resultClass@CNVSNP <- tmpMat
        }
      }
    }
    
    #Download CNA DNAseq data
    if(CNA_Seq)
    {
      #Search for links
      plinks <- getLinks("__Level_3__segmentation__seg.Level_3","[.]Merge_cna__.*.dnaseq.*.__Level_3__segmentation__seg.Level_3.*.tar[.]gz$",dataset)
      
      for(i in trim(plinks))
      {
        if(checkFileSize(paste0(fh_url,i)))
        {
          exportFiles(paste0(fh_url,i),dataset,
                      "-CNAseq.tar.gz",
                      "[.]cna__.*.__Level_3__segmentation__seg.seg.txt$",
                      TRUE,
                      "-CNAseq.txt")
          #Get selected type only
          tmpMat = fread(paste0(runDate,"-",dataset,"-CNAseq.txt"),
                         header=TRUE,colClasses=c("character","numeric","numeric","numeric","numeric","numeric"), 
                         data.table = FALSE)
          #tmpMat = read.delim(paste0(runDate,"-",dataset,"-CNAseq.txt"),header=TRUE,colClasses=c("character","numeric","numeric",
          #                                                                                 "numeric","numeric"))
          resultClass@CNAseq <- tmpMat 
        }
      }
    }
    
    #Download CNA CGH data
    if(CNA_CGH)
    {
      #Search for links
      plinks <- getLinks("__Level_3__segmentation__seg.Level_3","[.]Merge_cna__.*.cgh.*.__Level_3__segmentation__seg.Level_3.*.tar[.]gz$",dataset)
      
      dataLists <- list()
      listCount = 1
      for(i in trim(plinks))
      {
        if(checkFileSize(paste0(fh_url,i)))
        {
          exportFiles(paste0(fh_url,i),dataset,
                      "-CNACGH.tar.gz",
                      "[.]cna__.*.__Level_3__segmentation__seg.seg.txt$",
                      TRUE,
                      paste0("-CNACGH-",listCount,".txt"))
          #Get selected type only
          tmpMat = fread(paste0(runDate,"-",dataset,"-CNACGH-",listCount,".txt"),
                         header=TRUE,colClasses=c("character","numeric","numeric","numeric","numeric","numeric"), 
                         data.table = FALSE)
          #tmpMat = read.delim(paste0(runDate,"-",dataset,"-CNACGH-",listCount,".txt",sep=""),header=TRUE,colClasses=c("character","numeric","numeric",
          #                                                                                               "numeric","numeric"))
          tmpReturn <- new("FirehoseCGHArray",Filename=i,DataMatrix=tmpMat)
          dataLists[[listCount]] <- tmpReturn
          listCount = listCount + 1 
        }
      }
      resultClass@CNACGH <- dataLists
    }
    
    #Download methylation
    if(Methylation)
    {
      #Search for links
      plinks <- getLinks("__Level_3__within_bioassay_data_set_function__data.Level_3","[.]Merge_methylation__.*.methylation.*.__Level_3__within_bioassay_data_set_function__data.Level_3.*.tar[.]gz$",dataset)
      
      dataLists <- list()
      listCount = 1
      for(ii in trim(plinks))
      {
        if(checkFileSize(paste0(fh_url,ii)))
        {
          exportFiles(paste0(fh_url,ii),dataset,
                      "-Methylation.tar.gz",
                      "[.]methylation__.*.__Level_3__within_bioassay_data_set_function__data.data.txt$",
                      TRUE,
                      paste0("-Methylation-",listCount,".txt"))
          
          #Get selected type only
          tmpCols = read.delim(paste0(runDate,"-",dataset,"-Methylation-",listCount,".txt"),nrows=1,colClasses="character")
          colOrder <- 1:ncol(tmpCols)
          colOrder <- colOrder[tmpCols[1,] == "Beta_value"]
          
          tmpMat <- fread(paste0(runDate,"-",dataset,"-Methylation-",listCount,".txt"),header=F,colClasses = "character", select=c(1,3,4,5,colOrder), data.table = FALSE)
          tmpMat <- tmpMat[,c(1,3,4,5,2,6:ncol(tmpMat))]
          closeAllConnections()
          colnames(tmpMat) <- c("CompositeElementREF","Gene_Symbol","Chromosome","Genomic_Coordinate",tmpMat[1,5:ncol(tmpMat)])
          tmpMat <- tmpMat[-c(1:2),]
          removeQM <- grepl("\\?\\|",tmpMat[,1])
          tmpMat <- tmpMat[!removeQM,]
          names1 <- tmpMat[,1]
          tmpMat <- tmpMat[,-1]
          rownames(tmpMat) <- names1
          tmpReturn <- new("FirehoseMethylationArray",Filename=ii,DataMatrix=tmpMat)
          dataLists[[listCount]] <- tmpReturn
          listCount = listCount + 1 
        }
      }
      resultClass@Methylation <- dataLists
    }
    
    #Download mRNA array
    if(mRNA_Array)
    {
      #Search for links
      plinks1 <- getLinks("Merge_transcriptome__agilentg4502a_07","[.]Merge_transcriptome__agilentg4502a_.*.__Level_3__unc_lowess_normalization_gene_level__data.Level_3.*.tar[.]gz$",dataset)
      plinks2 <- getLinks("Merge_transcriptome__ht_hg_u133a","[.]Merge_transcriptome__ht_hg_u133a__.*.__Level_3__gene_rma__data.Level_3.*.tar[.]gz$",dataset)
      plinks3 <- getLinks("Merge_exon__huex_1_0_st_v2","[.]Merge_exon__huex_1_0_st_v2__.*.__Level_3__quantile_normalization_gene__data.Level_3.*.tar[.]gz$",dataset)
      
      plinks = c(plinks1,plinks2,plinks3)
      plinks = unique(plinks[plinks != ""])
      dataLists <- list()
      listCount = 1
      for(ii in trim(plinks))
      {
        if(checkFileSize(paste0(fh_url,ii)))
        {
          exportFiles(paste0(fh_url,ii),dataset,
                      "-mRNAArray.tar.gz",
                      "",
                      TRUE,
                      paste0("-mRNAArray-",listCount,".txt"),
                      TRUE)
          tmpReturn <- new("FirehosemRNAArray",Filename=ii,
                           DataMatrix=makeExprMat(dataset,paste0("-mRNAArray-",listCount,".txt"),
                                                  "","mRNAArray",1000,TRUE))
          dataLists[[listCount]] <- tmpReturn
          listCount = listCount + 1 
        }
      }
      resultClass@mRNAArray <- dataLists
    }
    
    #Download miRNA array
    if(miRNA_Array)
    {
      #Search for links
      plinks <- getLinks("h_mirna_8x15k","[.]Merge_mirna__h_mirna_8x15k.*.data.Level_3.*.tar[.]gz$",dataset)
      plinks = unique(plinks[plinks != ""])
      
      dataLists <- list()
      listCount = 1
      for(ii in trim(plinks))
      {
        if(checkFileSize(paste0(fh_url,ii)))
        {
          exportFiles(paste0(fh_url,ii),dataset,
                      "-miRNAArray.tar.gz",
                      "",
                      TRUE,
                      paste0("-miRNAArray-",listCount,".txt"),
                      TRUE)
          tmpReturn <- new("FirehosemRNAArray",Filename=ii,
                           DataMatrix=makeExprMat(dataset,paste0("-miRNAArray-",listCount,".txt"),
                                                  "","miRNAArray",100,TRUE))
          dataLists[[listCount]] <- tmpReturn
          listCount = listCount + 1 
        }
      }
      resultClass@miRNAArray <- dataLists
    }
    
    #Download RPPA array
    if(RPPA)
    {
      #Search for links
      plinks <- getLinks("rppa_core","[.]Merge_protein_exp.*.protein_normalization__data.Level_3.*.tar[.]gz$",dataset)
      plinks = unique(plinks[plinks != ""])
      
      dataLists <- list()
      listCount = 1
      for(ii in trim(plinks))
      {
        if(checkFileSize(paste0(fh_url,ii)))
        {
          exportFiles(paste0(fh_url,ii),dataset,
                      "-RPPAArray.tar.gz",
                      "",
                      TRUE,
                      paste0("-RPPAArray-",listCount,".txt"),
                      TRUE)
          tmpReturn <- new("FirehosemRNAArray",Filename=ii,
                           DataMatrix=makeExprMat(dataset,paste0("-RPPAArray-",listCount,".txt"),
                                                  "","RPPAArray",100,TRUE))
          dataLists[[listCount]] <- tmpReturn
          listCount = listCount + 1 
        }
      }
      resultClass@RPPAArray <- dataLists
    }
    
    #Download RPPA array
    if(Mutation)
    {
      #Search for links 
      plinks <- getLinks("Mutation_Packager_Calls","[.]Mutation_Packager_Calls[.]Level_3[.].*.tar[.]gz$",dataset)
      plinks = unique(plinks[plinks != ""])
      
      dataLists <- list()
      listCount = 1
      for(ii in trim(plinks))
      {
        if(checkFileSize(paste0(fh_url,ii)))
        {
          if(forceDownload || !file.exists(paste0(runDate,"-",dataset,"-Mutations-AllSamples.txt")))
          {
          download_link = paste(fh_url,ii,sep="")
          download.file(url=download_link,destfile=paste(dataset,"-Mutation.tar.gz",sep=""),method="auto",quiet = FALSE, mode = "w")
          fileList <- untar(paste0(dataset,"-Mutation.tar.gz"),list=TRUE)
          grepSearch = "MANIFEST.txt"
          fileList = fileList[!grepl(grepSearch,fileList)]
          ###
          untar(paste(dataset,"-Mutation.tar.gz",sep=""),files=fileList)
          retMutations <- do.call("rbind",lapply(fileList,FUN=function(files){
            read.delim(files,header=TRUE,colClasses="character")
          }))
          delFodler <- strsplit(fileList[1],"/")[[1]][1]
          unlink(delFodler, recursive = TRUE)
          file.remove(paste(dataset,"-Mutation.tar.gz",sep=""))
          write.table(retMutations,file=paste0(runDate,"-",dataset,"-Mutations-AllSamples.txt"),sep="\t",row.names=F,quote=F)
        }
        else
        {
          #retMutations <- read.delim(file=paste0(runDate,"-",dataset,"-Mutations-AllSamples.txt"),header = T,sep="\t")
          retMutations <- fread(paste0(runDate,"-",dataset,"-Mutations-AllSamples.txt"),header=TRUE,colClasses="character", data.table = FALSE)
        }
        resultClass@Mutations <- retMutations
        }
      }
    }
  }
  if(!is.null(gistic2_Date))
  {
    ##build URL for getting file links
    fh_url <- "http://gdac.broadinstitute.org/runs/analyses__"
    fh_url <- paste(fh_url,substr(gistic2_Date,1,4),"_",substr(gistic2_Date,5,6),"_",substr(gistic2_Date,7,8),"/data/",sep="")
    fh_url <- paste(fh_url,dataset,"/",gistic2_Date,"/",sep="")
    doc = htmlTreeParse(fh_url, useInternalNodes = T)
    #Search for links
    plinks <- getLinks("CopyNumber_Gistic2.Level_4","-TP[.]CopyNumber_Gistic2[.]Level_4.*.tar[.]gz$",dataset)
    
    for(ii in trim(plinks))
    {
      if(checkFileSize(paste0(fh_url,ii)))
      {
        if(forceDownload || !file.exists(paste0(gistic2_Date,"-",dataset,"-all_thresholded.by_genes.txt")))
        {
        download_link = paste(fh_url,ii,sep="")
        download.file(url=download_link,destfile=paste0(dataset,"-Gistic2.tar.gz"),method="auto",quiet = FALSE, mode = "w")
        fileList <- untar(paste(dataset,"-Gistic2.tar.gz",sep=""),list=TRUE)
        grepSearch = "all_data_by_genes.txt"
        fileList = fileList[grepl(grepSearch,fileList)]
        untar(paste0(dataset,"-Gistic2.tar.gz"),files=fileList)
        tmpCNAll = fread(fileList,header=TRUE,colClasses="character", data.table = FALSE)
        file.rename(from=fileList,to=paste0(gistic2_Date,"-",dataset,"-all_data_by_genes.txt"))
        fileList <- untar(paste(dataset,"-Gistic2.tar.gz",sep=""),list=TRUE)
        grepSearch = "all_thresholded.by_genes.txt"
        fileList = fileList[grepl(grepSearch,fileList)]
        untar(paste0(dataset,"-Gistic2.tar.gz"),files=fileList)
        tmpCNThreshhold = fread(fileList,header=T,colClasses = "character", data.table = FALSE)
        file.rename(from=fileList,to=paste0(gistic2_Date,"-",dataset,"-all_thresholded.by_genes.txt"))
        delFodler <- strsplit(fileList[1],"/")[[1]][1]
        unlink(delFodler, recursive = TRUE)
        file.remove(paste0(dataset,"-Gistic2.tar.gz"))
      }
      else
      {
        tmpCNThreshhold = fread(paste0(gistic2_Date,"-",dataset,"-all_thresholded.by_genes.txt"),header=TRUE,colClasses = "character", data.table = FALSE)
        tmpCNAll = fread(paste0(gistic2_Date,"-",dataset,"-all_data_by_genes.txt"),header=TRUE,colClasses="character", data.table = FALSE)
      }
      tmpReturn <- new("FirehoseGISTIC",Dataset=dataset,AllByGene=data.frame(tmpCNAll),
                       ThresholedByGene=data.frame(tmpCNThreshhold))
      resultClass@GISTIC <- tmpReturn
      }
    }
  }
  
  if(getUUIDs)
  {
    resultClass@BarcodeUUID <- barcodeUUID(resultClass) 
  }
  return(resultClass)
}

