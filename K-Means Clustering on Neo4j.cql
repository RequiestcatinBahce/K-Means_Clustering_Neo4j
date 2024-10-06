//I Created 50 points of dataset in 2D for clustering with K-Means.
CREATE 
(:Point {location:point({x:1, y:2})}),
(:Point {location:point({x:4, y:3})}),
(:Point {location:point({x:10, y:8})}),
(:Point {location:point({x:7, y:15})}),
(:Point {location:point({x:20, y:12})}),
(:Point {location:point({x:14, y:18})}),
(:Point {location:point({x:25, y:9})}),
(:Point {location:point({x:8, y:22})}),
(:Point {location:point({x:30, y:5})}),
(:Point {location:point({x:12, y:7})}),
(:Point {location:point({x:16, y:6})}),
(:Point {location:point({x:18, y:11})}),
(:Point {location:point({x:22, y:25})}),
(:Point {location:point({x:35, y:8})}),
(:Point {location:point({x:28, y:30})}),
(:Point {location:point({x:33, y:17})}),
(:Point {location:point({x:40, y:12})}),
(:Point {location:point({x:38, y:24})}),
(:Point {location:point({x:27, y:15})}),
(:Point {location:point({x:45, y:20})}),
(:Point {location:point({x:50, y:28})}),
(:Point {location:point({x:12, y:40})}),
(:Point {location:point({x:30, y:35})}),
(:Point {location:point({x:55, y:33})}),
(:Point {location:point({x:48, y:45})}),
(:Point {location:point({x:60, y:20})}),
(:Point {location:point({x:65, y:15})}),
(:Point {location:point({x:70, y:10})}),
(:Point {location:point({x:35, y:50})}),
(:Point {location:point({x:42, y:60})}),
(:Point {location:point({x:57, y:70})}),
(:Point {location:point({x:75, y:40})}),
(:Point {location:point({x:80, y:30})}),
(:Point {location:point({x:62, y:58})}),
(:Point {location:point({x:95, y:45})}),
(:Point {location:point({x:100, y:20})}),
(:Point {location:point({x:90, y:15})}),
(:Point {location:point({x:78, y:65})}),
(:Point {location:point({x:85, y:50})}),
(:Point {location:point({x:60, y:90})}),
(:Point {location:point({x:48, y:82})}),
(:Point {location:point({x:120, y:100})}),
(:Point {location:point({x:115, y:85})}),
(:Point {location:point({x:105, y:70})}),
(:Point {location:point({x:98, y:55})}),
(:Point {location:point({x:125, y:35})}),
(:Point {location:point({x:130, y:25})}),
(:Point {location:point({x:150, y:40})}),
(:Point {location:point({x:145, y:55})}),
(:Point {location:point({x:135, y:75})});

//Selecting 2 random points from our dataset as centroids of 2 clusters. For further process i created centroid iterations.
MATCH (p:Point)  
WITH p, rand() AS sortOrder
ORDER BY sortOrder
LIMIT 2  
CREATE (c:Centroid)  
SET c.location_x = p.location.x,   
    c.location_y = p.location.y,
    c.iterations = 0
RETURN p.location.x, p.location.y, c.location_x, c.location_y

//I gave numbers to each cluster. 
MATCH (c:Centroid)
WITH collect(c) AS centroids
UNWIND range(0, 1) AS num
SET (centroids[num]).clusterNumber = num + 1
RETURN centroids[num]

//For further distance calculations between pointns and centroids, we need every x and y values of our dataset.
MATCH (p:Point) 
RETURN labels(p)[0] AS nodeType, 
p.location.x AS x,
p.location.y AS y

//Calculating distance between every points and centroids then we are appointing them to the nearest cluster.
MATCH (p:Point), (c:Centroid)
WITH p, c, sqrt((p.location_x - c.location_x)^2 + (p.location_y - c.location_y)^2) AS distance
ORDER BY distance
WITH p, collect(c) AS centroids
SET p.clusterNumber = centroids[0].clusterNumber
RETURN p, p.clusterNumber

//After clustering every point in our dataset, now we are calculating average x and y values and taking them as new centroids.
MATCH (p:Point), (c:Centroid)
WHERE p.clusterNumber = c.clusterNumber
WITH c, avg(p.location.x) AS newX, avg(p.location.y) AS newY
SET c.location = point({x:newX, y:newY}), 
c.iterations = c.iterations + 1

//If new centroids are different, we recluster every points in our dataset. As i mentioned before about centroid iterations, we are recording every iteraions and the changes.
MATCH (p:Point), (c:Centroid)
WITH p, c, sqrt((p.location_x - c.location_x)^2 + (p.location_y - c.location_y)^2) AS distance
ORDER BY distance
WITH p, p.clusterNumber AS oldClusterNumber, collect(c) AS centroids
SET p.clusterNumber = centroids[0].clusterNumber
WITH p, oldClusterNumber
WHERE p.clusterNumber <> oldClusterNumber
WITH count(*) AS changedCount
MATCH (p:Point), (c:Centroid)
WHERE p.clusterNumber = c.clusterNumber
WITH changedCount, c, avg(p.location.x) AS newX, avg(p.location.y) AS newY
SET c.location = point({x:newX, y:newY}),
c.iterations = c.iterations + 1
RETURN changedCount, c.iterations AS iterations
