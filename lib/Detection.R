
Truth_Extract = function(filenames){
  
  #filenames = ground_truth[1:5]  # for debugging
  
  text = ""
  for (file in filenames){
    #file = filenames[1]
    text_lines = readLines(file)
    text = paste(text, 
                 paste(text_lines, collapse = " ")
    )
  }
  
  #text = "applied data science is challenging.!sfsfas 09073 \\W"
  text<-gsub("[[:punct:]]", " ", text)
  text = iconv(text, from = 'UTF-8', to = 'ASCII//TRANSLIT')
  word = strsplit(text," ")[[1]]
  words = word[word!=""]
  
  corpus = VCorpus(VectorSource(words))%>%
    tm_map(stripWhitespace)%>%
    tm_map(content_transformer(tolower))%>%
    tm_map(removeWords, character(0))%>%
    tm_map(removeNumbers)%>%
    tm_map(removePunctuation)
  
  truth_words = tidy(corpus) %>%
    select(text) %>%
    unnest_tokens(dictionary, text)
  
  
  truth_words = unique(truth_words)
  truth_words = as.matrix(truth_words)
  truth_words = truth_words[nchar(truth_words) > 1] # no single character words
  #truth_words = truth_words[truth_words!=""]
  
  #check_punct = grep("[[:punct:]]", truth_words)
  #check_num = grep("[0-9]", truth_words)
  #check_punct
  #check_num
  
  
  return(truth_words)
}


Digrams = function(dictionary){
  
  dic = dictionary  # character vector
  
  N = max(nchar(dic))
  digrams = list()
  #numberletters = c(0:9, letters)
  
  for (i in 2:N){     # empty dictionary digrams
    
    digrams[[i]] = list()   # word length
    n = i*(i-1)/2      # number of distinct pairs in word with length i
    
    for (j in 1:n){
      #dic[[i]][[j]] = matrix(0, nrow = 36, ncol = 36)
      digrams[[i]][[j]] = matrix(0, nrow = 26, ncol = 26)
      
    }
  }
  digrams[[1]] = "No single-character words"
  #length(digrams) == N
  
  #for (word in string){
  for (word in dic){
    
    n = nchar(word)
    count_pair = 1
    
    for (i in 1:(n-1)){
      
      for (j in 2:n){
        
        if (i<j){
          
          #row_index = match(substr(word, i, i),numberletters)
          #col_index = match(substr(word, j, j),numberletters)
          row_index = match(substr(word, i, i),letters)
          col_index = match(substr(word, j, j),letters)
          digrams[[n]][[count_pair]][row_index,col_index] = 1
          count_pair = count_pair + 1
          
        }
      }
    }
  }
  
  # apply(digrams[[24]][[270]],2,sum)
  # length(digrams[[24]])
  
  
  return(digrams)
}


OCR_Extract <- function(filename){   # for extract single ocr .txt only 
  
  #filename = ocrTrain[1]  # for debugging
  #text = ""
  #for (file in filenames){
  #file = filenames[1]
  #text_lines = readLines(file)
  # text = paste(text, 
  #              paste(text_lines, collapse = " ")
  #             )
  #}
  
  text = paste(readLines(filename), collapse = " ")
  text<-gsub("[[:punct:]]", " ", text)
  text = iconv(text, from = 'UTF-8', to = 'ASCII//TRANSLIT')
  word = strsplit(text," ")[[1]]
  words = word[word!=""]
  
  corpus = VCorpus(VectorSource(words))%>%
    tm_map(stripWhitespace)%>%
    tm_map(content_transformer(tolower))%>%
    tm_map(removeWords, character(0))%>%
    tm_map(removeNumbers)%>%
    tm_map(removePunctuation)
  
  ocr_words = tidy(corpus) %>%
    select(text) %>%
    unnest_tokens(dictionary, text)
  
  
  ocr_words = as.matrix(ocr_words)
  ocr_words = ocr_words[nchar(ocr_words) > 1] # no single character words
  ocr_words = ocr_words[nchar(ocr_words) <= 24] # no words longer than the longest word in ground truth
  
  
  return(ocr_words)
}


Detection = function(filenames, digrams){
  
  Detection_list = list()
  #filenames = ocrTrain[1:5]   # for debugging
  #filenames = ocrTrain  # for debugging
  #digrams = dic_digrams  # for debugging
  
  
  for (f in 1:length(filenames)){
    
    #f = 25  # for debugging
    words = OCR_Extract(filename = filenames[f])
    N = length(words)
    
    error_det = matrix(NA, nrow = N, ncol = 2)
    error_det[,1] = words
    error_det[,2] = 0   # Initial values, character mode! 
    
    #######  Start detection  ######
    for (w in 1:N){
      # w = 3498  # for debugging
      
      count_pair = 1
      word = error_det[w,1]
      n = nchar(word)
      
      for (i in 1:(n-1)){
        
        for(j in 2:n){
          
          if (i<j){
            
            row_index = match(substr(word, i, i),letters)
            col_index = match(substr(word, j, j),letters)
            
            if(dic_digrams[[n]][[count_pair]][row_index,col_index] == 0){
              error_det[w,2] = 1
              break
            }
            
            count_pair = count_pair + 1
            
          }
          
        }
        
        
      }
      
      
    }
    
    cat("OCR",f,"Done! \n")
    Detection_list[[f]] = error_det
    
    
  }
  
  return(Detection_list)
  
}
