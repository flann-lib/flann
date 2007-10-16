module commands.ComputeClustersCommand;

import std.string;

import commands.GenericCommand;
import commands.IndexCommand;
import util.logger;
import util.registry;
import util.utils;
import util.profiler;
import nn.testing;
import dataset.features;
import algo.nnindex;
import algo.kmeans;
import output.console;


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
			
			showOperation("Writing %d cluster centers to file %s... ".format(centers.length, clustersFile),{
				writeToFile(centers, clustersFile);
			});
		}
	}
	

	
}