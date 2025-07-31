#' 1. fiber area vs. empty area
#' 2. number of fibers per area
#' 3. distribution of fiber diameters
#'    - fraction of e.g. 0-30, 31-100, 100+; stacked bar plot
#' 4. inter-fiber distance
#' 5. 


library(tidyverse)
library(RANN)
library(ggforce)

path <- "data/t1"
tags <- c("x", "y")
sep <- "_"

areas <- tibble(
  file = list.files(path, pattern = "areas.csv", full.names = TRUE),
  area = map(file, ~data.table::fread(.) %>% 
               select(-1) %>% 
               rename_with(tolower))
) %>% 
  mutate(file = basename(file)) %>% 
  separate(file, tags, sep = sep)

coms <- tibble(
  file = list.files(path, pattern = "COM.csv", full.names = TRUE),
  com = map(file, ~data.table::fread(.) %>% 
               select(-1) %>% 
               rename_with(tolower))
) %>% 
  mutate(file = basename(file)) %>% 
  separate(file, tags, sep = sep)

dely <- tibble(
  file = list.files(path, pattern = "delaunay.csv", full.names = TRUE),
  dely = map(file, ~data.table::fread(.) %>% 
               select(-1) %>% 
               rename_with(tolower))
) %>% 
  mutate(file = basename(file)) %>% 
  separate(file, tags, sep = sep)

dat <- full_join(areas, coms) %>% full_join(., dely)


# calculate distances ----
add_pidx <- function(dely_tbl, com_tbl, max_dist = Inf) {
  # be flexible about input types (data.table, data.frame, tibble)
  dely_tbl <- as_tibble(dely_tbl)
  com_tbl  <- as_tibble(com_tbl)
  
  # ensure numeric columns
  dely_tbl <- dely_tbl %>% mutate(across(c(x1, y1, x2, y2), as.numeric))
  com_tbl  <- com_tbl  %>% mutate(across(c(xm, ym), as.numeric))
  
  if (nrow(dely_tbl) == 0L || nrow(com_tbl) == 0L) {
    return(dely_tbl %>% mutate(p1 = NA_integer_, p2 = NA_integer_))
  }
  
  ref <- as.matrix(select(com_tbl, xm, ym))
  q1  <- as.matrix(select(dely_tbl, x1, y1))
  q2  <- as.matrix(select(dely_tbl, x2, y2))
  
  res1 <- nn2(ref, q1, k = 1)
  res2 <- nn2(ref, q2, k = 1)
  
  p1 <- res1$nn.idx[, 1]
  p2 <- res2$nn.idx[, 1]
  
  # optional: drop matches beyond a threshold
  if (is.finite(max_dist)) {
    p1[res1$nn.dists[, 1] > max_dist] <- NA_integer_
    p2[res2$nn.dists[, 1] > max_dist] <- NA_integer_
  }
  
  dely_tbl <- dely_tbl %>% mutate(p1 = p1, p2 = p2)
  
  # transfer minferet
  d1 <- res1$nn.dists[, 1]
  d2 <- res2$nn.dists[, 1]
  dely_tbl <- dely_tbl %>%
    mutate(p1 = p1,
           p2 = p2,
           # dist_p1 = d1,
           # dist_p2 = d2,
           feret_p1 = com_tbl$feret[p1],
           feret_p2 = com_tbl$feret[p2])
  
  # calculate distance between points 
  dely_tbl %>% 
    mutate(cc_dist = sqrt((com_tbl$xm[p1] - com_tbl$xm[p2])^2 +
                       (com_tbl$ym[p1] - com_tbl$ym[p2])^2)) %>% 
    mutate(min_dist = cc_dist - feret_p1/2 - feret_p2/2)
  
}

dat <- dat %>%
  mutate(
    dely = map2(dely, com, ~ add_pidx(.x, .y))
  )
dat %>% pluck("dely", 1)


ggplot(delaunay, aes(dist_p)) +
  geom_freqpoly(bins = 200)




# inter-fiber distances ----
# calculate inter-fiber distance
distances <- delaunay %>% 
  rename(cc_dist = dist_p) %>% 
  mutate(min_dist = cc_dist - feret_p1/2 - feret_p2/2)
distances

# filter out the really long distances (on the edges)
d2 <- filter(distances, min_dist < quantile(distances$min_dist, 0.90))

# plot
ggplot(distances, aes(x1, -y1)) +
  geom_segment(aes(x = x1, y = -y1, xend = x2, yend = -y2), color = "blue") +
  geom_segment(data = d2, aes(x = x1, y = -y1, xend = x2, yend = -y2), color = "red") +
  geom_circle(aes(x0 = x1, y0 = -y1, r = feret_p1/2), color = "darkgray") +
  geom_point() 

ggplot(d2, aes(min_dist)) +
  geom_freqpoly()

# filter edges by using quantile on x/y and remove the outer layer; should 
# be better solution for images with empty patches inside




# fibril distribution ----
com
d2$p1[!duplicated(d2$p1)]
com[d2$p1[!duplicated(d2$p1)],]

ggplot(com, aes(minferet)) +
  geom_freqpoly() +
  # geom_density() +
  scale_x_continuous(breaks = seq(0, 180, 20),
                     limits = c(0, 200))

sizes <- com %>% 
  mutate(diam = 
           case_when(minferet < 40 ~ "small",
                     between(minferet, 40, 120) ~ "medium",
                     minferet > 120 ~ "large",
                     T~"x")) %>% 
  mutate(sample = "1")
filter(sizes, diam == "x")

# https://r-graph-gallery.com/48-grouped-barplot-with-ggplot2
ggplot(sizes, aes(sample, minferet, fill = diam)) +
  geom_bar(position = "fill", stat="identity")
