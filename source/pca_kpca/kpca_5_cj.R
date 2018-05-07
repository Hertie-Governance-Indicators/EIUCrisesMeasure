# ---------------------------------------------------------------------------- #
# Set up for PCA and KPCA runs
# Christopher Gandrud
# MIT License
# ---------------------------------------------------------------------------- #

# !! Must set working directory to the location of the EIUCrisesMeasure repository

# which file to use
rda_file <- "source/pca_kpca/preprocessed_data/eiu_texts_from_2003.rda"
sample_cuts <- 10

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
load(rda_file)
# eiu_list <- readRDS(file.path('source/pca_kpca/preprocessed_data', rds_file))

set.seed(1234)
rand_seq <- sample(seq_along(eiu_list))
sample_sets <- split(rand_seq, seq_along(rand_seq) %% sample_cuts)

lapply(sample_sets, range)
lapply(sample_sets, length)

# Source the function for conducting KPCA/refining/saving the results
source('source/pca_kpca/setup/kpca_eiu_function.R')

all_out_dir <- 'source/pca_kpca/output'
if (!dir.exists(all_out_dir)) { dir.create(all_out_dir) }

for (i in seq_along(sample_sets)) {

  cat(paste0('\n\nrunning sample: ', i, ' of ', length(sample_sets), "\n"))
  corpus <- eiu_list[sample_sets[[i]]]

  # Extract identifying country names and document dates
  country_date <- names(corpus)
  country_date <- stringr::str_split(country_date, pattern = '_', n = 2,
                                     simplify = TRUE) %>% as.data.frame
  names(country_date) <- c('iso3c', 'date')
  country_date$country <- countrycode(country_date$iso3c, origin = 'iso3c',
                                      destination = 'country.name')
  country_date <- country_date[, c('country', 'iso3c', 'date')]

  out_dir <- file.path('source/pca_kpca/output', paste0('sample', i))
  if (!dir.exists(out_dir)) { dir.create(out_dir) }
  save(corpus, country_date, sample_sets, i, file = file.path(out_dir, 'env_sav.Rds'))

  # Run KPCA
  gc()
  print(system.time(
    kpca_eiu(corpus, country_date, length_spec = 5, n_period = 2,
             out_dir = out_dir)
  ))
}
