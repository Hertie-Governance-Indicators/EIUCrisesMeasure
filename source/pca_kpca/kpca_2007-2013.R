# ---------------------------------------------------------------------------- #
# Set up for PCA and KPCA runs
# Christopher Gandrud
# MIT License
# ---------------------------------------------------------------------------- #

# !! Must set working directory to the location of the EIUCrisesMeasure repository

# which file to use
rda_file <- "source/pca_kpca/preprocessed_data/eiu_texts_from_2003.rda"
years <- 2007:2013

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

eiu_list <- eiu_list[as.integer(str_extract(names(eiu_list), '20[0-9][0-9]')) %in% years]

# Source the function for conducting KPCA/refining/saving the results
source('source/pca_kpca/setup/kpca_eiu_function.R')

all_out_dir <- 'source/pca_kpca/output'
if (!dir.exists(all_out_dir)) { dir.create(all_out_dir) }

# Extract identifying country names and document dates
country_date <- names(eiu_list)
country_date <- stringr::str_split(country_date, pattern = '_', n = 2,
                                   simplify = TRUE) %>% as.data.frame
names(country_date) <- c('iso3c', 'date')
country_date$country <- countrycode(country_date$iso3c, origin = 'iso3c',
                                    destination = 'country.name')
country_date <- country_date[, c('country', 'iso3c', 'date')]

out_dir <- file.path('source/pca_kpca/output', paste0(min(years), "-", max(years)))
if (!dir.exists(out_dir)) { dir.create(out_dir) }

save(eiu_list, country_date, file = file.path(out_dir, 'env_sav.Rds'))

# Run KPCA
gc()
cat(paste0('\n\nrunning sample: ', min(years), "-", max(years), "\n"))
Sys.time()
print(system.time(
  kpca_eiu(eiu_list, country_date, length_spec = 5, n_period = 2,
           out_dir = out_dir)
))
