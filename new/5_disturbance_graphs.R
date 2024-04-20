# 0. setup ----------------------------------------------------------------

# R 4.2.3 (2023-03-15) "Shortstop Beagle"

library(ggrepel) # 0.9.5
library(pool) # 1.0.3
library(tidyverse) # 2.0.0 (dplyr 1.1.4, forcats 1.0.0, ggplot2 3.5.0, lubridate 1.9.3, purrr 1.0.2, readr 2.1.5, stringr 1.5.1, tibble 3.2.1, tidyr 1.3.1)
library(RPostgreSQL) # 0.7-6 (DBI 1.2.2)

source("new/pw.R")

# 5. GRAPHS ---------------------------------------------------------------

# 5. 1. data --------------------------------------------------------------

data.all <- tbl(KELuser, "dist_event") %>% mutate(peak = "yes") %>%
  right_join(., tbl(KELuser, "dist_chrono"), by = c("dist_chrono_id" = "id")) %>%
  inner_join(., tbl(KELuser, "dist_plot"), by = c("dist_plot_id" = "id")) %>%
  inner_join(., tbl(KELuser, "plot"), by = c("plot_id" = "id")) %>%
  select(plotid, ncores, type, year, ca_pct, kde, peak) %>%
  collect()

# 5. 2. plotting ----------------------------------------------------------

pdf("new/plots.pdf", width = 18, height = 10, pointsize = 12, onefile = T)

for (p in unique(data.all$plotid)) {

  n <- data.all %>% filter(plotid %in% p) %>% distinct(., ncores) %>% pull()
  
  data.gg <- data.all %>% filter(plotid %in% p)
  
  print(
    ggplot(data.gg) +
      geom_histogram(aes(year, weight = ca_pct), breaks = seq(1590, 2010, 10), fill = "grey80") +
      geom_histogram(aes(year, weight = ca_pct), binwidth = 1, fill = "grey20") +
      geom_line(aes(year, kde), linewidth = 1, colour = "grey20") +
      geom_point(data = data.gg %>% filter(peak %in% "yes"), aes(year, kde), shape = 21, colour = "grey20", fill = "#78c2ef", size = 3) +
      geom_text_repel(data = data.gg %>% filter(peak %in% "yes"), aes(year, kde, label = year), colour = "#78c2ef", size = 3) +
      geom_hline(aes(yintercept = 10), linetype = 2, colour = "grey80") +
      coord_cartesian(xlim = c(1590, 2010)) + coord_cartesian(ylim = c(0, 100)) +
      xlab("Year") + ylab("Canopy area (%)") + 
      ggtitle(paste(p, "(number of cores:", n, ")", sep = " ")) +
      theme_bw() +
      facet_wrap(~type)
    )
  
  cat(p)
  
  remove(n, data.gg, p)
}

dev.off()

# ! close database connection ---------------------------------------------

poolClose(KELuser)
