# ---------------------------------------------------------------------------- #
# Pre-Process texts
# Christopher Gandrud and CJ Yetman
# MIT License
# ---------------------------------------------------------------------------- #

# Load packages
library(lubridate)
library(dplyr)
library(stringr)
library(countrycode)
library(quanteda)
library(readtext)

# Create date-country labels
date_country <-
  list.files(path = "data/eiu_extracted/") %>%
  gsub('\\.txt', '', .) %>%
  str_split_fixed('_', n = 2) %>%
  as.data.frame(stringsAsFactors = F)

date_country[, 2] <- gsub('-', ' ', date_country[, 2])
names(date_country) <- c('date', 'country')
date_country$date <- ymd(date_country$date)
date_country$iso3c <- countrycode(date_country$country,
                                  origin = 'country.name',
                                  destination = 'iso3c',
                                  warn = TRUE)

# Load corpus and preprocess
texts_df <- readtext(file = list.files(path = "data/eiu_extracted/", full.names = T))

# Apply clean row names
texts_df <- cbind(texts_df, date_country)

# Remove non-countries
texts_df <- subset(texts_df, !is.na(iso3c))

# Remove texts from before 2003 due to inconsistent format
texts_df_2003 <- subset(texts_df, date >= '2003-01-01')

# Create corpus
eiu_corpus <- corpus(texts_df_2003, text_field = "text")

# Add document metadata
docvars(eiu_corpus, 'date') <- texts_df_2003$date
docvars(eiu_corpus, 'country') <- texts_df_2003$country

# Preprocess and convert to document-feature matrix
eiu_token <- tokens(eiu_corpus, remove_numbers = TRUE,
               remove_punct = TRUE, remove_separators = TRUE,
               remove_symbols = TRUE, remove_hyphens = TRUE,
               remove_twitter = TRUE, remove_url = TRUE,
               verbose = TRUE)
eiu_token <- tokens_tolower(eiu_token)
eiu_token <- tokens_remove(eiu_token, stopwords(source = "smart"))
eiu_token <- tokens_wordstem(eiu_token)

# Find documents with fewer than 5 tokens
length_spec <- 5 # Assigns token length
keep_vec <- which(unname(sapply(eiu_token, function(x) length(x) > length_spec)))

# Collapse into a list of character vectors for each document
eiu_list <- lapply(eiu_token, paste, collapse = ' ')

# Remove documents with fewer than 5 tokens
eiu_list <- eiu_list[keep_vec]
eiu_ids <- texts_df_2003[keep_vec, c('date', 'iso3c')]
names(eiu_list) <- paste(eiu_ids[, 'iso3c'], eiu_ids[, 'date'], sep = '_')

# Save preprocessed corpus in the git repository. Change as needed.
save(eiu_list, file = 'source/pca_kpca/preprocessed_data/eiu_texts_from_2003.rda')
