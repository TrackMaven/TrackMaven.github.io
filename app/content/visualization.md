Title: Monthly Challenge: Visualization
Date: 2015-01-08
Category: Monthly Challenge
Tags: charting, d3
Slug: using-cartodb-and-threejs-for-mapping
Author: Fletcher Heisler
Avatar: fletcher-heisler

## Using CartoDB and Three.js for mapping

Our next monthly challenge is **visualization**! Although you could visualize data on just about anything in just about any way, for this post we're going to focus on **mapping** data geographically using two different tools:

- CartoDB: a great drag-and-drop solution for super quick and simple map creation - also a paid product that limits its free plan to 50MB of data!
- Three.js and WebGL Globe: for fancy 3D visualizations and an interactive globe onto which we can plot geographic data.


A few other possible frameworks for mapping that we *won't* be covering in this post include:

- [Highcharts](http://www.highcharts.com/) is a library for creating quick interactive charts and has a separate product specifically for [creating maps](http://www.highcharts.com/products/highmaps).

- At TrackMaven, we use [D3.js](http://d3js.org/) to create interactive visualizations. Although we won't be covering D3 in this post, Square has a great [intro to D3](http://square.github.io/intro-to-d3/), which you should follow up with a tutorial on [mapping in D3](http://bost.ocks.org/mike/map/) written by the creator of D3 himself!

- [Leaflet](http://leafletjs.com/) is a great JS library specifically for creating maps and works well with [Mapbox](https://www.mapbox.com/) for some very pretty built-in styling. Check out Chris Given's [Bikeshare Odds](https://github.com/cmgiven/bikeshare-odds) project for a great demo of creating an interactive map viewable over time.

### Mapping airport data

We're going to analyze flight data, eventually creating a 3D rendering of flight patterns by volume projected onto an interactive globe. To get started, though, let's set up the quickest and simplest map possible using [CartoDB](https://cartodb.com) to get an idea of our available data.

Make an account at [CartoDB](https://cartodb.com/signup) and browse around the platform. You'll discover that CartoDB actually already has all the [US airports](https://fheisler.cartodb.com/dashboard/common_data/Cultural%20datasets) as well as some other common datasets available for immediate use.

We'll eventually want international data, however, so from [openflights.org](http://openflights.org/data.html), download the CSV file [airports.dat](https://sourceforge.net/p/openflights/code/HEAD/tree/openflights/data/airports.dat?format=raw) to get the locations, names and codes of airports around the world.

Rename the extension to a proper .CSV, then upload this `airports.csv` file as a new table in CartoDB.

Take a look at the table in CartoDB; you can double-click and rename `field_7` to `lat` and `field_8` to `lon`. Click on the orange "GEO" button next to the column named `the_geom`, then specify your longitude and latitude. Rename `field_5` to `code`; we'll be merging in data based on the airport code later.

And... voilà! You can already toggle over to `MAP VIEW` at the top and see a map of all your airport data. Click on the wizard button on the right side and switch to a choropleth map to get a quick idea of the density of airports around the world:

<center>![map1](/images/map1.png)</center>

Now let's add some actual flight data, available from BTS.

The [description](http://www.transtats.bts.gov/DatabaseInfo.asp?DB_ID=120&DB_Short_Name=On-Time&DB_Name=Airline%20On-Time%20Performance%20Data&Link=0&DB_URL=Subject_ID=3&Subject_Desc=Passenger%20Travel&Mode_ID2=0) doesn't really make it clear *which* 1%+ of non-stop domestic flights were covered, but we'll assume the file [available here](http://www.transtats.bts.gov/DL_SelectFields.asp?Table_ID=236&DB_Short_Name=On-Time) is a representative sample of US air carrier flights. We'll need the `Origin`, `Destination`, and (number of total) `Flights`.

You now have a couple options; you *could* load this dataset in as a new CartoDB table and collapse + export it using their SQL editor:

```sql
SELECT dest, origin, count (*)
FROM flights
GROUP BY dest, origin
```
However, this will take you over your allotted 50MB, so you wouldn't be able to export this created set without signing up for a paid plan. Plus, it's SQL, so in this case I collapsed the file with a quick Python script instead:

```python
from collections import Counter
import csv

flight_counts = Counter()
with open('flights.csv', 'r') as infile:
    csvreader = csv.reader(infile)
    csvreader.next() # skip header row
    for row in csvreader:
        orig_dest = (row[0], row[1])
        flight_counts.update(orig_dest)

with open('flight_counts.csv', 'w') as outfile:
    csvwriter = csv.writer(outfile)
    csvwriter.writerow(["code", "count"])
    for code, count in flight_counts.items():
        csvwriter.writerow([code, count])
```

You can load this CSV file of total flight counts by airport code into CartoDB, then choose "options" in the top right and merge the airports table onto the `code` in the flight data.

Click on the "infowindow" button on the right (below the wizard) and enable the airport code as a mouse hover interaction, then take a look:

<center>![map2](/images/map2.png)</center>

We can see that we're missing a *lot* of smaller airports, but we do have coverage and counts that are roughly as expected for the major US airports.

This dataset includes some other interesting data points that could be interesting and simple enough to analyze; for instance, you could look at weather delays over geographic location and time using a [torque map](http://docs.cartodb.com/tutorials/introduction_torque.html)!

### Visualizing airline data on a globe

Let's turn this up a notch with [Three.js](http://threejs.org/) and the [WebGL Globe](http://www.chromeexperiments.com/globe) to visualize flight data on a 3D globe.

We're going to create a page `map.html` available [here](/demos/globe/map.html), based on the WebGL Globe [basic example](https://github.com/dataarts/webgl-globe/#basic-usage) (with a few tweaks and a bugfix for how options are actually passed):

```html
<html>
  <head>
    <meta charset="utf-8">
    <title>Flight data visualization</title>
    <script src="helpers/three.min.js"></script>
    <script src="globe/globe.js"></script>
  </head>
  <body>
    <div id='container' />

    <script>
      // Where to put the globe?
      var container = document.getElementById( 'container' );

      // Make the globe
      var globe = new DAT.Globe( container );

      // We're going to ask a file for the JSON data.
      var xhr = new XMLHttpRequest();

      // Where do we get the data?
      xhr.open( 'GET', 'flight_data.json', true );

      // What do we do when we have it?
      xhr.onreadystatechange = function() {

        // If we've received the data
        if ( xhr.readyState === 4 && xhr.status === 200 ) {

          // Parse the JSON
          var data = JSON.parse( xhr.responseText );

          // Tell the globe about your JSON data
          for ( var i = 0; i < data.length; i ++ ) {
            // Incorrect version in current example:
            // globe.addData( data[i][1], 'magnitude', data[i][0] );

            globe.addData(data[i][1], {'format': 'magnitude'});
          }

          // Create the geometry
          globe.createPoints();

          // Begin animation
          globe.animate();

        }
      };

      // Begin request
      xhr.send( null );
    </script>
  </body>
</html>
```

We'll need to prepare some JSON data to be loaded in from the file `flight_data.json`. For `globe.js` to read properly, this should be of the format:

```python
[["name", [lat1, lon1, mag1, lat2, lon2, mag2, . . . ]]]
```

Above, the `mag` values are just each total count normalized by the maximum count in the data. We can prepare this file from the previous dataset using a slightly modified preprocessing script:

```python
import csv

data_dict = {}
with open('flight_pos_counts.csv', 'rU') as infile:
    csvreader = csv.reader(infile)
    csvreader.next() # skip header row
    for row in csvreader:
        count = int(row[2])
        lat, lon = row[13], row[14]
        data_dict[lat, lon] = count

data = []
max_count = float(max(data_dict.values()))
for lat_lon, count in data_dict.items():
    data += lat_lon[0], lat_lon[1], str(count/max_count)

with open('flight_data.json', 'w') as outfile:
    outfile.write('[["counts",[{}]]]'.format(",".join(data)))
```

You can download this prepared dataset directly [here](/demos/globe/flight_data.json).

Finally, we'll need to be able to point to [globe.js](https://github.com/dataarts/webgl-globe/blob/master/globe/globe.js) and, from within that script, a [world map](https://github.com/dataarts/webgl-globe/blob/master/globe/world.jpg) to overlay on the globe.

Cross origin requests will(/should) be disabled by your browser, meaning that you won't be able to load static files from disk into the page, so you'll need to run everything from a local host; just `cd` into your project directory and run a server with:

```
python -m SimpleHTTPServer
```

With everything properly connected, you should now be able to visit the fully functional page with an interactive globe at:

```
http://localhost:8000/map.html
```

<center>![map3](/images/map3.png)</center>

### Visualizing flight paths in 3D

As a warning, this section is still a work in progress! We're going to visualize flights *between* airports (specifically non-stop flights with at least one airport in the US) using the BTS dataset [T-100 International Segment (All Carriers)](http://www.transtats.bts.gov/DL_SelectFields.asp?Table_ID=261), which they describe as follows:

`This table contains international non-stop segment data reported by both U.S. and foreign air carriers, including carrier, origin, destination, aircraft type and service class for transported passengers, freight and mail, available capacity, scheduled departures, departures performed, aircraft hours, and load factor when at least one point of service is in the United States or one of its territories. International flight data is released 3 months after domestic data. Flights with both origin and destination in a foreign country are not included.`

We'll grab `DepPerformed`, `Origin` and `Destination` from this table, join with the `airports.dat` file from above, and (again, after some preprocessing) prepare a file `flight_traffic.json` along the following format, where the magnitude `mag1` of each lat/lon origin and destination pair is the count of flights divided by the maximum count for any pair:

```python
[orig_lat1, orig_lon1, dest_lat1, dest_lon1, mag1, orig_lat2, orig_lon2, dest_lat2, dest_lon2, mag2, . . .]
```

This final table is available [here](/demos/globe/flight_traffic.json).

Now for the tricky part: displaying arcs between airports as "flight" patterns... I created a modified `globe2.js` available [here](/demos/globe/globe2.js), which in addition to an `addPoint()` function includes an `addPath()` function to draw 3D splines connection two points on the globe.

My trigonometry is a little rusty, so I'm still working out the details of how to interpolate spherical coordinates properly. For now, I used a *very* hacky system of finding a "midpoint" between the two points, which mostly only works for flights around the US depending on the signs of the coordinate pairs; you'll notice for instance that all the flights to Europe currently dip into the earth before reaching their destinations! I then generate a smooth spline using those three points.

You can see the results, which I limit to only the busiest airport pairs to cut down somewhat on clutter, [here as a live demo](/demos/globe/map2.html):

<center>![map4](/images/map4.png)</center>

I will update this post when/if I properly rework the flight paths; for now, all of the paths calculated in spherical coordinates seem to stray *slightly* off course... One day, it might even look half as cool as this [absolutely crazy visualization](http://nisatapps.prio.org/armsglobe/) of global firearms trade built on work from the crazy Google Ideas. Something to aspire to, but maybe a bit complex for a monthly challenge!
