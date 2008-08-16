module console.commands.SaveTreeCommand;

import tango.text.Util : split;
import tango.util.Convert;
import tango.time.WallClock;

import console.commands.GenericCommand;
import console.commands.IndexCommand;
import nn.Testing;
import dataset.Dataset;
import algo.NNIndex;
import algo.KMeansTree;
import console.report.Report;
import util.Logger;
import util.Utils;
import util.Profile;


static this() {
 	register_command!(SaveTreeCommand);
}

class SaveTreeCommand : IndexCommand
{
	public static string NAME = "save_tree";
	
	string outFile;
	
	this(string name) 
	{
		super(name);
		register(outFile,"o","out-file", "","File in which to save the tree.");
 			
 		description = super.description~" Save kmeans tree into a file.";
	}
	
	private void executeWithType(T)() 
	{   
    
        logger.info("Saving tree");
    
        KMeansTree!(T) tree = cast(KMeansTree!(T)) index;
           
        if (index is null) {
            throw new FLANNException("Index is not a kmeans index");
        }
        
        alias KMeansTree!(T).KMeansNode Node;
        
        Node root = tree.root;
        
        T[][] vecs = tree.vecs;
        
        withOpenFile(outFile, (FormatOutput write) {
            void saveNode(Node node) 
            {
                if (node.childs.length==0) {
                    write.format("{} {} {} 1\n",node.indices.length, tree.veclen, node.level);
                    foreach (ind; node.indices) {
                        foreach (i,elem; vecs[ind]) {
                            if (i!=0) write(" ");
                            if (is (T==float)) {
                                write.format("{:g}",elem);
                            } else {
                                write.format("{}",elem);
                            }
                        }
                        write.newline;
                    }
                }
                else {
                    write.format("{} {} {} 0\n",node.childs.length, tree.veclen, node.level);
                    foreach(child; node.childs) {
                        foreach (i,elem; child.pivot) {
                            if (i!=0) write(" ");
                            if (is (T==float)) {
                                write.format("{:g}",elem);
                            } else {
                                write.format("{}",elem);
                            }
                        }
                        write.newline;
                    }
                    
                    foreach(child; node.childs) {
                        saveNode(child);
                    }
                    
                }            
            }  
            saveNode(root);
        });        
                
	}
	

	void execute() 
	{
		super.execute();

		if (byteFeatures) {
			executeWithType!(ubyte)();
		} else {
			executeWithType!(float)();
		}
	}
	
}