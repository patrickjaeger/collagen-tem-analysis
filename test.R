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


# filter out the really long distances (on the edges)


# transfer feret
delaunay <- delaunay %>%
  mutate(
    feret_p1 = com$feret[p1],
    feret_p2 = com$feret[p2]
  )


# calculate inter-fiber distance
distances <- delaunay %>% 
  rename(cc_dist = dist_p) %>% 
  mutate(min_dist = cc_dist - feret_p1/2 - feret_p2/2)
distances
ggplot(distances, aes(min_dist)) +
  geom_freqpoly(bins = 200)
distances %>% arrange(x1)

ggplot(distances, aes(x1, -y1)) +
  geom_segment(aes(x = x1, y = -y1, xend = x2, yend = -y2), color = "blue") +
  geom_circle(aes(x0 = x1, y0 = -y1, r = feret_p1/2*0.9), color = "darkgray") +
  geom_point() 

# just declare min_dist < 0 as 0, i.e. touching
