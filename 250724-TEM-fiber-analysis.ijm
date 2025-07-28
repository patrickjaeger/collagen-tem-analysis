#@ File (label="Select file", style = "file") file
#@ File (label="Select classifier", style = "file") classifier
#@ File (label="Select output directory", style = "directory") output

// open file
open(file);
run("8-bit");
setMinAndMax(150, 220);
img_name_w_ext = getTitle();
img_name = File.nameWithoutExtension;
run("Duplicate...", "title=og");
run("RGB Color");
n_crop = 6;
n_crop2 = n_crop*2;
getDimensions(width, height, channels, slices, frames);
width1 = width;
height1 = height;
makeRectangle(n_crop, n_crop, (width1-n_crop2), (height1-n_crop2));
run("Crop");


// segmentation -----------------------------------------------------------------------
selectWindow(img_name_w_ext);
run("Bandpass Filter...", "filter_large=200 filter_small=20 " +
    "suppress=None tolerance=5 autoscale saturate");

// WEKA
run("Trainable Weka Segmentation");
wait(3000);
selectWindow("Trainable Weka Segmentation v3.3.4");

call("trainableSegmentation.Weka_Segmentation.loadClassifier", classifier);
//call("trainableSegmentation.Weka_Segmentation.loadClassifier", 
//     "C:\\Users\\jaege\\OneDrive - ETH Zurich\\PhD\\R projects\\250724-greta-TEM\\classifier2.model");

call("trainableSegmentation.Weka_Segmentation.getResult");

selectWindow("Classified image");
setAutoThreshold("Default dark");
run("Convert to Mask");
run("Dilate");
run("Erode");
run("Watershed Irregular Features", "erosion=50 convexity_threshold=0 separator_size=0-Infinity");
run("Erode");
run("Erode");

makeRectangle(n_crop, n_crop, (width1-n_crop2), (height1-n_crop2));
run("Crop");


// measure total fiber area vs. inter-fiber area -----------------------------------------
run("Create Selection");
  
  // draw all outlines on og
  selectWindow("og");
  run("Restore Selection");
  setForegroundColor(255, 0, 0);  // red
  //setLineWidth(width);
  run("Draw", "slice");

selectWindow("Classified image");
run("Set Measurements...", "area display redirect=None decimal=3");
run("Measure");
setResult("Label", 0, "fibers");
run("Make Inverse");
run("Measure");
setResult("Label", 1, "background");
saveAs("Results", output + File.separator + img_name +"-areas.csv");
run("Select None");
run("Clear Results");


// clear edges ------------------------------------------------------------------------------
run("Analyze Particles...", "size=100-Infinity exclude add");
newImage("cleared-mask", "8-bit black", width1, height1, 1);
setForegroundColor(255, 255, 255);
roiManager("fill");

  // draw core outlines on og
  selectWindow("og");
  setForegroundColor(255, 255, 0);  // yellow
  //setLineWidth(width);
  roiManager("draw");

roiManager("reset");


// get particles -----------------------------------------------------------------------------
selectWindow("cleared-mask");
run("Set Measurements...", "area center feret's display redirect=None decimal=0");
run("Analyze Particles...", "add");
roiManager("Measure");
saveAs("Results", output + File.separator + img_name +"-COM.csv");

// draw min feret
selectWindow("og");
setForegroundColor(0, 198, 255);  // light blue
n = nResults;
for (i = 0; i < n; i++) {
  r = round(getResult("MinFeret", i)/2);
  x = round(getResult("XM", i)-r);
  y = round(getResult("YM", i)-r);
  drawOval(x, y, 2*r, 2*r);
}


// get center-center distances ---------------------------------------------------------------
selectWindow("cleared-mask");
run("Delaunay Voronoi", "mode=Delaunay inferselectionfromparticles export");
saveAs("Results", output + File.separator + img_name +"-delaunay.csv");

// draw delaunay lines
selectWindow("og");
setForegroundColor(255, 0, 255);  // magenta
n = nResults;
for (i = 0; i < n; i++) {
    x1 = getResult("x1", i);
    y1 = getResult("y1", i);
    x2 = getResult("x2", i);
    y2 = getResult("y2", i);

    drawLine(x1, y1, x2, y2);
}

saveAs("Jpeg", output + File.separator + img_name +"-overlay.jpg");


// clean up -----------------------------------------------------------------------------------
run("Clear Results");
roiManager("reset");
close("*");