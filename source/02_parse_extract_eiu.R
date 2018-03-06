# ---------------------------------------------------------------------------- #
# Parse EIU texts and conduct keyword searches
# Christopher Gandrud & CJ Yetman
# MIT License
# ---------------------------------------------------------------------------- #

# Load required packages
library(xml2)
library(rvest)
library(dplyr)
library(stringr)
library(lubridate)

# Set working directory of parsed texts. Change as needed.
eiu_html <- "data/eiu_html"

#### Clean file names ##########################################################
# List files
raw_files <- list.files(eiu_html)

# Convert HTML file names to standardised txt file names
files_clean <- gsub("\\.html| Main report| Updater| of America", "", raw_files,
                    ignore.case = T)

year <- str_extract(files_clean, "[0-9]{4}")

month <- sub(" [0-9]{4}$", "", sub(".* - ", "", files_clean))
month[month == "1st Quarter"] <- "January"
month[month == "2nd Quarter"] <- "April"
month[month == "3rd Quarter"] <- "July"
month[month == "4th Quarter"] <- "October"

country <- sub(" - .*$", "", files_clean)

dates <- sprintf('01_%s_%s', month, year) %>% dmy()

file_txt <- sprintf('%s_%s.txt', dates, country)


#### Parse/Extract #############################################################
# Keywords to seach/extract for. Modified from Romer and Romer (2015):
# http://eml.berkeley.edu/~cromer/RomerandRomerFinancialCrisesAppendixA.pdf
# NEED TO ADD TO/THINK ABOUT
keywords <- c("bail-out", "bailout", "balance sheet", "balance-sheet", "bank",
              "banks", "banking", "credit", "crunch", "debt", "default",
              "finance", "financial", "lend", "loan", "squeeze")

for (i in 1:length(file_txt)) {
    # Read in file
    message(raw_files[i])
    full <- read_html(file.path(eiu_html, raw_files[i]))

    if (!is.null(full)) {
        # Extract headlines and body text
        extracted <-
          full %>% html_nodes(xpath = "//div[@class='headline'] | //body//p")
    }
    if (!is.null(extracted)) {
        text <- extracted %>% html_text()

        # Find/extract nodes containing keywords
        contains <- sapply(keywords,
                           function(x) grep(x, text, ignore.case = T)) %>%
                    unlist %>% as.vector
        text_out <- text[unique(contains)] %>% paste(collapse = '')

        # Write to file
        writeLines(text_out, sprintf('data/eiu_extracted/%s', file_txt[i]))
    }
}
