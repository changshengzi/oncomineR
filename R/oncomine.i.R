oncomine.i <- function(x){
    # library(rvest)
    x = readLines(x) %>%
        do::Replace0(c("\t",'3D'))
    x[do::right(x,1)=='=']=knife_right(x[do::right(x,1)=='='],1)
    area = x %>%
        paste0(collapse = '') %>%
        read_html() %>%
        html_nodes(xpath = '//map//area') %>%
        grepl_not_or(c('name="geneIn',
                       'name="reporterInfo"',
                       'name="summaryText"',
                       'name="summaryCell"',
                       'name="restrictedSummaryMouseOver"',
                       'om4:rightcontent="-\\|\\|-'))
    viztitle=x %>%
        paste0(collapse = '') %>%
        read_html() %>%
        html_nodes(xpath = '//span[@id="pVisualizationName"]') %>%
        html_text()
    allnames = area %>%
        html_attr('om4:leftcontent') %>%
        grepl_and('\\|\\|') %>%
        strsplit('\\|\\|')
    if (viztitle=='Gene Summary'){
        df.header = area %>%
            html_attr('om4:headercontent') %>%
            strsplit('\\|\\|') %>%
            as.data.frame() %>%
            t() %>%
            as.data.frame(row.names = NA)
        dim(df.header)
    }
    names.length = sapply(allnames, function(i) length(i))
    tbn=table(names.length)
    maxname=as.numeric(names(tbn)[which.max(tbn)])
    if (length(tbn) > 1){
        df = area %>%
            html_attr('om4:rightcontent') %>%
            strsplit('\\|\\|')
        for (i in 1:length(df)) {
            if (length(df[[i]]) < maxname){
                df[[i]]=c(df[[i]][-length(df[[i]])],
                          rep(NA,maxname-length(df[[i]])),
                          df[[i]][length(df[[i]])])
            }
        }
        df = df %>%
            as.data.frame() %>%
            t() %>%
            as.data.frame(row.names = NA)
    }else{
        df = area %>%
            html_attr('om4:rightcontent') %>%
            strsplit('\\|\\|') %>%
            as.data.frame() %>%
            t() %>%
            as.data.frame(row.names = NA)
    }


    name = allnames[names.length==maxname][[1]]
    # check the first name
    firstname <- allnames %>%
        sapply(function(i) i[1])
    firstname.check=identical(firstname[1],firstname[length(firstname)])
    # Differential Analysis for heat map
    if (!firstname.check){
        x[grepl('Gene Summary',x)]
        Gene = area %>%
            html_attr('om4:leftcontent') %>%
            grepl_and('\\|\\|') %>%
            do::Replace0(c(' {0,}expression:.*',
                           ' {0,}Rank:.*'))
        RE = ifelse(grepl('Rank',firstname[1]),'Rank','Expression')
        names(df) = c(RE,gsub(":",'',name)[-1])
        df$Gene=Gene
        df[c('Gene',RE,gsub(":",'',name)[-1])]
    }else{
        names(df) = gsub(":",'',name)
        if (viztitle=='Gene Summary') df=cbind(df,df.header)
        df
    }
}

