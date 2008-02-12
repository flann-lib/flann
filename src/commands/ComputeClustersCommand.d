module commands.ComputeClustersCommand;

import tango.text.convert.Sprint;

import commands.GenericCommand;
import commands.IndexCommand;
import nn.Testing;
import dataset.Dataset;
import algo.NNIndex;
import output.Console;
import util.Logger;
import util.Utils;
import util.Profile;


static this() {
 	register_command!(ComputeClustersCommand);
}

class ComputeClustersCommand : IndexCommand
{
	public static string NAME = "compute_clusters";
	
	string clustersFile;
	uint clusters;

	this(string name) 
	{
		super(name);
		register(clustersFile,"f","clusters-file", "","File to save the cluster centers to.");
		register(clusters,"k","clusters", 100u,"Number of cluster centers to save.");
 			
 		description = super.description~" Save the cluster centers to a file.";
	}
	
	void execute() 
	{
		super.execute();
		
		if (clustersFile != "") {
			float[][] centers = index.getClusterCenters(clusters);
			
			showOperation((new Sprint!(char)).format("Writing {} cluster centers to file {}... ",centers.length, clustersFile),{
				Dataset!(float).handler.write(clustersFile,centers,"dat");
				//writeToFile(centers, clustersFile);
			});
		}
		
		delete index;
	}
	

	
}