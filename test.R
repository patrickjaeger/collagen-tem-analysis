library(tidyverse)

com <- read_csv("COM-2.csv", show_col_types = FALSE) %>%
  select(-1) %>%
  rename_with(tolower)

delaunay <- read_csv("delaunay-2.csv", show_col_types = FALSE) %>%
  select(-1) %>%
  rename_with(tolower)

# helper: index of closest value in a vector
which_closest <- function(x, val) {
  which.min(abs(x - val))
}

# return a single INTEGER index if x and y match the same row in `com`, else NA_integer_
match_point <- function(.x, .y) {
  closest_x <- which_closest(com$xm, .x)
  closest_y <- which_closest(com$ym, .y)
  if (closest_x == closest_y) {
    as.integer(closest_y)
  } else {
    as.integer(NA)
  }
}

# compute p1 using pmap_int over x1,y1
delaunay <- delaunay %>%
  mutate(p1 = pmap_int(list(x1, y1), ~ match_point(..1, ..2)))

# look at result
delaunay
sum(is.na(delaunay$p1))
