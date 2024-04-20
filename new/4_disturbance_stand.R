# 0. setup ----------------------------------------------------------------

# R 4.2.3 (2023-03-15) "Shortstop Beagle"

# data.table 1.15.2
library(pool) # 1.0.3
library(tidyverse) # 2.0.0 (dplyr 1.1.4, forcats 1.0.0, ggplot2 3.5.0, lubridate 1.9.3, purrr 1.0.2, readr 2.1.5, stringr 1.5.1, tibble 3.2.1, tidyr 1.3.1)
library(pracma) # 2.4.4
library(RPostgreSQL) # 0.7-6 (DBI 1.2.2)
library(sf) # 1.0-15 (GEOS 3.9.3, GDAL 3.5.2, PROJ 8.2.1)
library(sp) # 2.1-3
library(zoo) # 1.8-12

source("new/pw.R")

source("new/0_disturbance_functions.R")

# 4. STAND-LEVEL ----------------------------------------------------------

# 4. 1. data --------------------------------------------------------------

dist.events <- tbl(KELuser, "dist_event") %>%
  inner_join(., tbl(KELuser, "dist_chrono"), by = c("dist_chrono_id" = "id")) %>%
  right_join(., tbl(KELuser, "dist_plot") %>% filter(type %in% "full"), by = c("dist_plot_id" = "id")) %>%
  inner_join(., tbl(KELuser, "plot") %>% select(plot_id = id, plotid), by = "plot_id") %>%
  inner_join(., tbl(KELuser, "dist_polygons") %>% 
               group_by(stand) %>%
               mutate(nplots = n()) %>%
               ungroup(),
             by = "plotid") %>%
  select(stand, nplots, plotid, plot_id, year, year_min, year_max) %>%
  collect()
  
# 4. 2. bootstrapping -----------------------------------------------------

set.seed(1)

dist.boot <- dist.events %>%
  distinct(., stand, plotid) %>%
  slice(rep(1:nrow(.), each = 1000)) %>%
  mutate(rep = rep(1:1000, times = nrow(.) / 1000)) %>%
  group_by(stand, rep) %>%
  slice_sample(., n = 10, replace = TRUE) %>%
  ungroup() %>%
  left_join(., dist.events, by = c("stand", "plotid"))

# 4. 3. peak detection ----------------------------------------------------

dist.peaks <- tibble()  
  
for (s in unique(dist.boot$stand)) {
  
  x <- dist.boot %>% filter(stand %in% s)

  out <- inner_join(
    x %>% 
      filter(!is.na(year)) %>%
      group_by(stand, rep, year) %>%
      summarise(freq = n() / first(nplots)) %>%
      ungroup(),
    x %>% 
      group_by(stand, rep, plotid) %>% 
      filter(year %in% first(year)) %>% 
      group_by(stand, rep) %>% 
      summarise(year_min = max(year_min),
                year_max = min(year_max)) %>%
      group_by(stand) %>%
      summarise(year_min = round(mean(year_min), 0),
                year_max = round(mean(year_max), 0)),
    by = "stand") %>%
    filter(year >= year_min, year <= year_max) %>%
    group_by(stand, rep) %>%
    complete(year = (min(year_min)-30):(max(year_max)+30), fill = list(freq = 0)) %>%
    mutate(density_pre = kdeFun(freq, k = 30, bw = 5, st = 7),
           density = rollapply(density_pre, width = 5, FUN = mean, fill = 0)) %>%
    filter(year %in% c((min(year)+15):(max(year)-15))) %>%
    group_by(stand) %>%
    mutate(year_min = first(year_min[!is.na(year_min)]), 
           year_max = first(year_max[!is.na(year_max)])) %>%
    group_by(stand, rep) %>%
    filter(row_number() %in% peakDetection(x = density, threshold = 0.00001, nups = 5, mindist = 10),
           year %in% c((min(year_min)+1):(max(year_max)-1))) %>%
    group_by(stand, year_min, year_max, year) %>%
    summarise(freq = n() / 100) %>%
    group_by(stand) %>%
    complete(year = (min(year_min)-10):(max(year_max)+10), fill = list(freq = 0)) %>%
    mutate(freqsmooth = kdeFun(freq, k = 11, bw = 1, st = 7)/10) %>%
    filter(row_number() %in% peakDetection(x = freqsmooth, threshold = 0.00001, nups = 0, mindist = 10)) %>%
    ungroup() %>%
    select(stand, year_min, year_max, peakyear = year)
  
    dist.peaks <- bind_rows(dist.peaks, out)
    
    print(paste(s, Sys.time()))
    
    remove(s, x, out)
}

# write.table(dist.peaks, "dist_peaks.csv", sep = ",", row.names = F, na = "")
# dist.peaks <- read.table("dist_peaks.csv", sep = ",", header = T, stringsAsFactors = F)
  
# 4. 4. join plot-level events to stand-level peaks -----------------------

dist.events.dt <- data.table::data.table(
  dist.events %>% 
    select(-year_min, -year_max) %>%
    inner_join(., dist.peaks %>% distinct(., stand, year_min, year_max), by = "stand") %>%
    filter(year >= year_min, year <= year_max),
  key = c("stand", "year"))

dist.peaks.dt <- data.table::data.table(dist.peaks %>% mutate(year = peakyear), key = c("stand", "year"))

dist.events.joined <-  data.frame(
  dist.peaks.dt[dist.events.dt,
                list(stand, nplots, year_min, year_max, peakyear, year, plot_id, plotid),
                roll = "nearest"])

# 4. 5. patch area & stand size -------------------------------------------

polygons <- st_as_sf(tbl(KELuser, "dist_polygons") %>% collect(), wkt = "geometry") %>%
  left_join(., dist.events.joined %>% distinct(., plotid, plot_id, peakyear), by = "plotid")
  
polygons$area <- as.numeric(st_area(polygons) / 10000)
  
patches <- tibble()

for (s in unique(polygons$stand)) {
  
  data.in <- polygons %>% filter(stand %in% s & !is.na(peakyear)) %>% group_by(peakyear) %>% summarise()
  
  data.out <- tibble()
  
  for (p in data.in$peakyear) {
    
    x <- data.in %>% filter(peakyear %in% p)
    
    l <- list()
    
    for (i in 1:length(x[[2]][[1]])) {
      
      if((length(x[[2]][[1]]) != 1) & (length(x[[2]][[1]][[i]])) > 1){
        
        a <- Polygon(x[[2]][[1]][[i]][[1]])
        b <- Polygon(x[[2]][[1]][[i]][[2]])

        if(a@hole == T){

          print(paste(s, p, i, 1, "hole", sep = "_"))

          y <- b

        } else {

          print(paste(s, p, i, 2, "hole", sep = "_"))

          y <- a

        }

        y <- Polygons(list(y), i); y <- SpatialPolygons(list(y))

        l[[i]] <- y
        
        remove(a, b)

        } else {
        
        y <- Polygon(x[[2]][[1]][[i]])
        
        if(y@hole == T) {
          
          print(paste(s, p, i, "hole", sep = "_"))
          
        } else {
          
          y <- Polygons(list(y), i); y <- SpatialPolygons(list(y))
          
          l[[i]] <- y
          
        }  
        
      }
      
    }
    
    sp <- SpatialPolygons(lapply(l, function(x){x@polygons[[1]]}))
    
    sf <- st_set_crs(st_as_sf(sp), 3035) %>% rownames_to_column("npatch") %>% mutate(stand = s, peakyear = p)
    sf$patch_area <- as.numeric(st_area(sf) / 10000)
    
    sf <- st_join(sf, polygons %>% filter(stand %in% s & peakyear %in% p) %>% group_by(plot_id) %>% summarise())
    
    sf <- as.data.frame(sf) %>% select(-geometry)
    
    data.out <- bind_rows(data.out, sf)
    
  }
  
  patches <- bind_rows(patches, data.out)
  
  remove(s, data.in, data.out, p, x, l, i, y, sp, sf)
  
}

# # plot can contribute only once within one peakyear!
# patches %>% group_by(peakyear, plot_id) %>% filter(n() > 1)

dist.patches <- patches %>%
  group_by(stand, peakyear, npatch) %>% 
  mutate(nplots_dist = n()) %>%
  ungroup() %>%
  inner_join(., as.data.frame(polygons) %>% 
              distinct(., stand, plotid, area) %>% 
              group_by(stand) %>% 
              summarise(stand_size = sum(area)),
            by = "stand") %>%
  select(stand, stand_size, peakyear, npatch, patch_area, nplots_dist, plot_id)

# 4. 6. proportion of plots disturbed & finalisation ----------------------

dist.stand <- tbl(KELuser, "dist_event") %>%
  inner_join(., tbl(KELuser, "dist_chrono"), by = c("dist_chrono_id" = "id")) %>%
  inner_join(., tbl(KELuser, "dist_plot") %>% filter(type %in% "full"), by = c("dist_plot_id" = "id")) %>%
  select(dist_event_id = id, year, plot_id) %>%
  collect() %>%
  inner_join(., dist.events.joined, by = c("plot_id", "year")) %>%
  inner_join(., dist.patches, by = c("stand", "peakyear", "plot_id")) %>%
  inner_join(., dist.events.joined %>%
               distinct(., stand, nplots, peakyear, plotid) %>%
               group_by(stand, peakyear) %>%
               summarise(plotsprop_dist = n() / first(nplots)) %>%
               ungroup(),
             by = c("stand", "peakyear")) %>%
  select(stand, stand_size, nplots, year_min, year_max, peakyear, npatch, 
         patch_area, plotsprop_dist, nplots_dist, plot_id, dist_event_id) %>%
  arrange(stand, peakyear, npatch) %>%
  mutate(stand_size = round(stand_size, 3),
         patch_area = round(patch_area, 3),
         plotsprop_dist = round(plotsprop_dist, 2))

# ! close database connection ---------------------------------------------

poolClose(KELuser)
