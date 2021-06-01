//Preprocess Images
//Ioritz Sorzabal 09-12-20
//Admitted Format: .tif
//Works only for 3 level folder distribution e.g:
//inputDir_i\Date\AgNP@SiO2



run("Close All");

inputDir_i = getDirectory("Choose Directory");
fileList_i = getFileList(inputDir_i);
fileList_i = Array.deleteValue(fileList_i, "desktop.ini");

setBatchMode(false);
setOption("ExpandableArrays", true);
run("Set Measurements...", "area centroid feret's redirect=None decimal=3");




for (i = 0; i < fileList_i.length; i++) {

	inputDir_ii = inputDir_i + File.separator +fileList_i[i];
	fileList_ii = getFileList(inputDir_ii);
	fileList_ii = Array.deleteValue(fileList_ii, "desktop.ini");
	

	for (ii = 0; ii < fileList_ii.length; ii++) {
		
		inputDir_iii = inputDir_ii + File.separator + fileList_ii[ii] + "Segmentation";
		fileList_iii = getFileList(inputDir_iii);
		fileList_iii = Array.deleteValue(fileList_iii, "desktop.ini");
		outputDir = inputDir_ii + File.separator + fileList_ii[ii] + File.separator + "Results" + File.separator;
		File.makeDirectory(outputDir);

		m = 0;
		image_name = newArray;
		diameter_ag = newArray;
		l_short_silica = newArray;
		l_long_silica = newArray;


		for (iii = 0; iii < fileList_iii.length; iii++) {

	
			if (endsWith(fileList_iii[iii], ".tif")){

				
				file = inputDir_iii + File.separator + fileList_iii[iii];
				open(file);
				
				///// IMAGE PREPROCESSING//////
				//--Remove .tif from name
				name_full = split(getTitle(), File.separator);
				name_full = name_full[1]; //1 if Windows 0 if Mac
				dotIndex = indexOf(name_full, ".");
				name = substring(name_full, 0, dotIndex);
				rename(name);

				
				//--Get Ag mask
				name_ag = name +"_ag";
				selectWindow(name);
				run("Duplicate...", name_ag);
				setThreshold(2, 2);
				setOption("BlackBackground", true);
				run("Convert to Mask");
				run("Median...", "radius=4");
				rename(name_ag);

				//--Get Silica mask
				name_silica = name +"_silica";
				selectWindow(name);
				run("Duplicate...", "temp_image");
				rename("temp_image");
				setThreshold(1, 2);
				setOption("BlackBackground", true);
				run("Convert to Mask");
				run("Median...", "radius=4");
				run("Analyze Particles...", "size=100-Infinity show=Masks exclude");
				rename(name_silica);

				//--Run ellipse fitting
				run("Clear Results"); 
				roiManager("reset");
				run("Ellipse Split", "binary=[Use standard watershed] add_to_manager add_to_results_table remove merge_when_relativ_overlap_larger_than_threshold overlap=95 major=0-Infinity minor=0-Infinity aspect=1-1.2");
				wait(10);

				//--Store data in temporary arrays
				long_temp = newArray;
				short_temp = newArray;
				n = nResults;

				//--Save and Close results
				for (i_temp = 0; i_temp < nResults(); i_temp++) {

					long_temp[i_temp] = getResult("Length long axis", i_temp);
					short_temp[i_temp] = getResult("Length short axis", i_temp);
					print(long_temp[i_temp]);
				
				}
				run("Clear Results");
				selectWindow("Results");
				run("Close");
				
				

				//--Store results
				nROI = roiManager("count");

				for (j = 0; j < nROI; j++) {

					selectWindow(name_ag);
					roiManager("Select", j);
					run("Clear Results");
					run("Analyze Particles...", "size=10-Infinity display");
					selectWindow("Results");
					n = nResults;

					if (n>0) {
						
						image_name[m] = name;
						diameter_ag[m] = getResult("Feret", 0);
						l_short_silica[m] = short_temp[j];
						l_long_silica[m] = long_temp[j];
						m++;
											
						
					}
	
				}




			

			} 	
		}
		
		run("Clear Results");
		selectWindow("Results");
		run("Close");
		
		for (jj = 0; jj < m; jj++) {
			
			setResult("Filename", jj, image_name[jj] );
			setResult("Ag_Diameter", jj, diameter_ag[jj] );
			setResult("SiO2_short_diameter", jj, l_short_silica[jj] );
			setResult("SiO2_long_diameter", jj, l_long_silica[jj] );
			
		}
		updateResults();
		saveAs("Results", outputDir + File.separator + "Summary.tsv");
		run("Clear Results");
		selectWindow("Results");
		run("Close");
		run("Close All");

	
	}
}


