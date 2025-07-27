#' 1. fiber area vs. empty area
#' 2. number of fibers per area
#' 3. distribution of fiber diameters
#'    - fraction of e.g. 0-30, 31-100, 100+; stacked bar plot
#' 4. inter-fiber distance
#' 5. 


library(tidyverse)
library(RANN)
library(ggforce)

com <- read_csv("COM-2.csv", show_col_types = FALSE) %>%
  select(-1) %>%
  rename_with(tolower)

delaunay <- read_csv("delaunay-2.csv", show_col_types = FALSE) %>%
  select(-1) %>%
  rename_with(tolower)

# match points in com to delauny
ref   <- as.matrix(select(com, xm, ym))
q_p1  <- as.matrix(select(delaunay, x1, y1))
q_p2  <- as.matrix(select(delaunay, x2, y2))

idx_p1 <- nn2(ref, q_p1, k = 1)$nn.idx[, 1]
idx_p2 <- nn2(ref, q_p2, k = 1)$nn.idx[, 1]

delaunay <- delaunay %>%
  mutate(p1 = idx_p1,
         p2 = idx_p2)

com
delaunay

# add euclidean distance between p1 and p2
delaunay <- delaunay %>%
  mutate(
    dist_p = sqrt( (com$xm[p1] - com$xm[p2])^2 +
                     (com$ym[p1] - com$ym[p2])^2 )
  )
ggplot(delaunay, aes(dist_p)) +
  geom_freqpoly(bins = 200)


# transfer feret
delaunay <- delaunay %>%
  mutate(
    feret_p1 = com$minferet[p1],
    feret_p2 = com$minferet[p2]
  )


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


# just declare min_dist < 0 as 0, i.e. touching


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
