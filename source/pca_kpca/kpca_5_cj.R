# ---------------------------------------------------------------------------- #
# Set up for PCA and KPCA runs
# Christopher Gandrud
# MIT License
# ---------------------------------------------------------------------------- #

# !! Must set working directory to the location of the EIUCrisesMeasure repository

# which file to use
rds_file <- "eiu_texts_2016_2018.rds"

# Load packages
library(simpleSetup)

pkgs <- c('quanteda', 'kernlab', 'repmis', 'tidyverse', 'rio', 'lubridate',
          'countrycode', 'TTR', 'devtools', 'tm', 'pushoverr')
library_install(pkgs)

# Set working directory. Change as needed.
possible_dir <- c('/Users/cjyetman/Documents/github/FinStress-gr18/',
                  '/home/ubuntu/EIUCrisesMeasure-gr18')
simpleSetup::set_valid_wd(possible_dir)

# Load preprocessed data (see source/preprocess_eiu.R)
eiu_list <- readRDS(file.path('source/pca_kpca/preprocessed_data', rds_file))

# Extract identifying country names and document dates
country_date <- names(eiu_list)
country_date <- stringr::str_split(country_date, pattern = '_', n = 2,
                                   simplify = TRUE) %>% as.data.frame
names(country_date) <- c('iso3c', 'date')
country_date$country <- countrycode(country_date$iso3c, origin = 'iso3c',
                                    destination = 'country.name')
country_date <- country_date[, c('country', 'iso3c', 'date')]

# Source the function for conducting KPCA/refining/saving the results
source('source/pca_kpca/setup/kpca_eiu_function.R')

# Run KPCA
system.time(
  kpca_eiu(eiu_list, country_date, length_spec = 5, n_period = 2,
           out_dir = 'source/pca_kpca/raw_data_output/5_strings/')
)

# notify me with a push message
pushover(message = paste(rds_file, "is done"),
         user = "uffbujtdi51jm3kk1vcgcjog699a85",
         app = "adk4twf314vctkfdbe95vb35f4mrsz")
