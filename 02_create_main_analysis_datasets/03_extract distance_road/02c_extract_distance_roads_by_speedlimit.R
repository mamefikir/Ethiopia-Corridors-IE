# Distance to Roads by Speed Limit and Year

# Calculate distance of each point to the closest road for each speed limit in 
# each year.

# Load and Prep Data -----------------------------------------------------------
# Load data and reporject to Ethiopia UTM. UTM better for distance calculations 
# than WGS84.

#### Load points
points <- readRDS(file.path(finaldata_file_path, DATASET_TYPE,"individual_datasets", "points.Rds"))
if(grepl("grid", DATASET_TYPE)){
  coordinates(points) <- ~long+lat
  crs(points) <- CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
}
points <- points %>% spTransform(CRS(UTM_ETH))

#### Load roads
roads_sdf <- readRDS(file.path(project_file_path, "Data", "FinalData", "roads", "RoadNetworkPanelData_1996_2016.Rds"))
roads_sdf$id <- 1 # useful to have a variable the same for all obs when aggreagting roads later
roads_sdf <- roads_sdf %>% spTransform(CRS(UTM_ETH))

# Calculate Distance -----------------------------------------------------------
roads <-roads_sdf
determine_distance_to_points <- function(year, points, roads){
  
  print("* -------------------------")
  print(year)
  
  # Grab roads for relevant year. Select if speed limit above 0 (ie, road exists)
  roads_yyyy <- roads[roads[[paste0("Speed",year)]] > 0,]
  
  # Loop through speeds. Subset road based on that speed. Add that speed to the
  # points dataframe
  for(speed in sort(unique(roads_yyyy[[paste0("Speed", year)]]))){
    print("* -------------------------")
    print(speed)
    
    # Restrict to roads that are speed limit "speed" and aggregate to one row
    roads_subset <- roads_yyyy[roads_yyyy[[paste0("Speed", year)]] %in% speed,] #%>% raster::aggregate(by="id")
    
    roads_subset <- roads_subset %>% st_as_sf() %>% st_combine() %>% as("Spatial")
    roads_subset$id <- 1
    
    points[[paste0("distance_road_speed_", speed)]] <- gDistance_chunks(points, roads_subset, CHUNK_SIZE_DIST_ROADS, MCCORS_DIST_ROADS) 
  }
  
  points$year <- year
  
  return(points@data)
}

points_all <- lapply(1996:2016, determine_distance_to_points, points, roads_sdf) %>% bind_rows

# Export -----------------------------------------------------------------------
saveRDS(points_all, file.path(finaldata_file_path, DATASET_TYPE, "individual_datasets", "points_distance_roads_byspeed.Rds"))

