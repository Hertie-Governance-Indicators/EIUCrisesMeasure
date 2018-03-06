library("webdriver")
library("secret")
library("rvest")


cache_dir <- "data/eiu_html/"


pjs <- run_phantomjs()
ses <- Session$new(port = pjs$port)
ses$setTimeout(pageLoad = 5000)


login_url <- "https://login.proxy.library.emory.edu/login?auth=shibboleth&url=^U"
ses$go(login_url)

username <- ses$findElement("#username")
username$setValue(get_secret("username", vault = "vault"))

password <- ses$findElement("#password")
password$setValue(get_secret("password", vault = "vault"))

loginbutton <- ses$findElement("#loginbutton")
loginbutton$click()

url <- "http://portal.eiu.com.proxy.library.emory.edu/index.asp?layout=displayPublication&publication_type_id=50000205&eiu_publication_id=2000001000"
ses$go(url)
# ses$takeScreenshot(file = NULL)

cntry_links <-
  ses$getSource() %>%
  read_html() %>%
  html_nodes("table") %>%
  `[[`(9) %>%
  html_nodes("a") %>%
  html_attr("href") %>%
  url_absolute(base = ses$getUrl())

cntry_names <-
  ses$getSource() %>%
  read_html() %>%
  html_nodes("table") %>%
  `[[`(9) %>%
  html_nodes("a") %>%
  html_text(trim = T)

cntry_links <- setNames(cntry_links, cntry_names)

all_html_links <- character()

for (i in seq_along(cntry_links)) {
# for (i in 1:length(cntry_links)) {
  ses$go(cntry_links[i])

  html_links <-
    ses$getSource() %>%
    read_html() %>%
    html_nodes(xpath = "//a[text()='html']") %>%
    html_attr("href") %>%
    url_absolute(base = ses$getUrl())

  html_names <-
    ses$getSource() %>%
    read_html() %>%
    html_nodes("table") %>%
    `[[`(10) %>%
    html_nodes("tr td:nth-of-type(2)") %>%
    html_text(trim = T)

  html_links <- setNames(html_links, paste(names(cntry_links[i]), "-", html_names))

  all_html_links <- c(all_html_links, html_links)
}


# all_html_links <- readRDS("data/all_html_links.rds")

tries <- 5

for (i in seq_along(all_html_links)) {
# for (i in 10855:length(all_html_links)) {
  attempt <- 0

  while (attempt <= tries & attempt != -1) {
    try_result <- try(ses$go(all_html_links[i]), silent = T)

    if ("try-error" %in% class(try_result)) {
      attempt <- attempt + 1
      if (attempt > tries) {
        cat(paste0("--- skipped ", names(all_html_links[i]), " (i = ", i, ") after ", tries, " attempts\n"))
      }
    } else {
      attempt <- -1

      download_url <-
        ses$getSource() %>%
        read_html() %>%
        html_node(xpath = "//a[text()='html']") %>%
        html_attr("href") %>%
        url_absolute(base = ses$getUrl())

      try_result <- try(ses$go(download_url), silent = T)

      if ("try-error" %in% class(try_result)) {
        attempt <- attempt + 1
        if (attempt > tries) {
          cat(paste0("--- skipped ", names(all_html_links[i]), " (i = ", i, ") after ", tries, " attempts\n"))
        }
      } else {
        attempt <- -1

        file_path <- file.path(cache_dir, paste0(names(all_html_links[i]), ".html"))
        write(ses$getSource(), file_path)
        cat(paste0("downloaded ", names(all_html_links[i]), " (i = ", i, ")\n"))
      }
    }
  }
}

ses$delete()
pjs$process$kill()
