#@ File (label="Select file", style = "file") file
#@ File (label="Select output directory", style = "directory") output

// open file
BFopen(file);
img_name_w_ext = getTitle();
img_name = File.nameWithoutExtension;


// segmentation
run("Bandpass Filter...", "filter_large=200 filter_small=20 suppress=None tolerance=5 autoscale saturate");
// WEKA
setAutoThreshold("Default dark");
run("Convert to Mask");
run("Dilate");
run("Erode");
run("Watershed Irregular Features", "erosion=30 convexity_threshold=0 separator_size=0-Infinity");
run("Erode");
run("Auto Crop");

// measure total fiber area vs. inter-fiber area

// get particles
run("Set Measurements...", "area center feret's display redirect=None decimal=3");
run("Analyze Particles...", "add");
roiManager("Measure");
saveAs("Results", output + File.separator + img_name +"-COM.csv");


// get center-center distances
run("Delaunay Voronoi", "mode=Delaunay inferselectionfromparticles export");
saveAs("Results", output + File.separator + img_name +"-delaunay.csv");

// draw fiber outlines

// draw delaunay lines
n = nResults;

for (i = 0; i < n; i++) {
    x1 = getResult("x1", i);
    y1 = getResult("y1", i);
    x2 = getResult("x2", i);
    y2 = getResult("y2", i);

    // Draw the line
//    makeLine(x1, y1, x2, y2);
    drawLine(x1, y1, x2, y2);

}


// clean up
run("Clear Results");
roiManager("reset");
close("*");

