library(tidyverse)

com <- read_csv("COM-2.csv") %>% select(-1) %>% rename_with(tolower)
delaunay <- read_csv("delaunay-2.csv") %>% select(-1) %>% rename_with(tolower)

com
delaunay



which_closest <- function(x, val) {
  which.min(abs(x - val))
}

match_point <- function(.x, .y) {
  closest_x <- which_closest(.x, com$xm)
  closest_y <- which_closest(.y, com$ym)
  
  if (closest_x == closest_y) closest_y else NA
}


mutate(delaunay, p1 = pmap())
delaunay$p1 <- pmap_int(.l = list(delaunay$x1, delaunay$y1), .f = match_point)
  delaunay
sum(is.na(delaunay))
