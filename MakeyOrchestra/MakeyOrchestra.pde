//Global variables
HubManager hubManager;
OutputManager outputManager;
OscP5 osc; 

//global variables
int totalTracks;

//play settings
boolean useVolume = true; // if false, volume pin will have no effect

//display settings
boolean hubDebug = false;
int maxHubConnections = 24;
// relative to min(width,height)
float flowerRadius_r = 1.0f/7;
float flowerSize_r = 1.0f/18;
float globalRadius_r = 1.0f/2 - flowerRadius_r- flowerSize_r*1.2/2; 



int globalRadius = 180;//width*flowerRadius_r;
int flowerRadius = 80;//width*flowerRadius_r;
int flowerSize = 30;//width*flowerRadius_r;

boolean fullscreen = false;
boolean gridMode = true;



void setup()
{
  //fullScreen(2); //force on second display
   size(600,600,P2D);
  surface.setResizable(true);
  //frame.setSize(width,height);
  
  
  frameRate(40);
  background(0);
  
  osc = new OscP5(this,12000);
  
  println("Makey Orchestra, connected ports :");
  println(Serial.list());
  
  initHubs();
  initOutputs();  
  
  
  hubManager.reset();
}

void draw()
{
  background(0);
  float mdim = min(width,height);
  globalRadius = int(mdim*globalRadius_r);
  flowerRadius = int(mdim*flowerRadius_r);
  flowerSize = int(mdim*flowerSize_r);
  
  hubManager.draw();
}

void initHubs()
{
  if(hubManager!=null){
    hubManager.disconnect();
  }
  hubManager = new HubManager(this);
  
  String[] hubLines = loadStrings("hubs.txt");
  
  int startTrack = 0;
  
  for(int i=0;i<hubLines.length;i++)
  {
    if(hubLines[i].charAt(0) == '#') continue;
    String[] hubSplit = hubLines[i].split(",");
    String type = hubDebug?"switch":hubSplit[2];
    int numTracks = hubDebug?maxHubConnections:parseInt(hubSplit[1]);
    String portName = hubSplit[0];
    int []  portMap = new int[maxHubConnections];
    for(int k= 0 ; k < maxHubConnections ; k++){
      portMap[k] = k;
    }
    boolean isTrack = hubSplit[2].equals("track");
    println(hubSplit[2]);
    if(!hubDebug){
      
    for(int k = 2 ; k < hubSplit.length ; k++){
      int makeyNum = parseInt(hubSplit[k])*(isTrack?3:1); 
      portMap[makeyNum] = k-2;
      if(isTrack){
        portMap[makeyNum+1] = portMap[makeyNum]+1;
        portMap[makeyNum+2] = portMap[makeyNum]+2;
      }
    }
    }
    else if (isTrack){
      numTracks = maxHubConnections/3;
     for(int k= 0 ; k < maxHubConnections ; k++){
      portMap[k] = k/3;
    }
    }
    
    int targetStart = hubDebug?0:startTrack;
    //if(type.equals("trigger")) targetStart = 0;
    
    hubManager.addHub(portName,targetStart,numTracks,type,portMap);
    
    //if(type.equals("track")) 
    startTrack += numTracks;
    
  }
  
  if(hubManager.hubs.size() == 1)
  {
    flowerRadius = globalRadius;
    globalRadius = 0;
  }
  
  totalTracks = startTrack;
  
   
}

void toggleHubDebug(){
 hubDebug = !hubDebug;
 initHubs();
 
 
}

void initOutputs()
{
  outputManager = new OutputManager();
  
  String[] outputLines = loadStrings("outputs.txt");
  
  for(int i=0;i<outputLines.length;i++)
  {
    if(outputLines[i].charAt(0) == '#') continue;
    String[] outputSplit = outputLines[i].split(",");
    String type = outputSplit[0];
    String remoteIP = outputSplit[1];
    int remotePort = parseInt(outputSplit[2]);
    String midiPortName = "";
    if(outputSplit.length >= 4) midiPortName = outputSplit[3];
    
    outputManager.addOutput(type,totalTracks,remoteIP,remotePort,midiPortName);
  }
}


//Methods called from hubs
void trackMuteCallback(int track, boolean mute)
{
  outputManager.sendTrackMute(track,mute);
}

void trackVolumeCallback(int track, float volume)
{
  outputManager.sendTrackVolume(track,volume);
}

void triggerCallback(int trigger)
{
  outputManager.sendTrigger(trigger);
}


//test
void keyPressed()
{
  switch(key)
  {
    case ' ':
    hubManager.reset();
    break;
    
    case '1':
    hubManager.hubs.get(0).toggleTrackActive(0);
    break;
    
    case '2':
    hubManager.hubs.get(0).toggleTrackActive(1);
    break;
    
    case '+':
    hubManager.hubs.get(1).setTrackVolume(0,hubManager.hubs.get(1).trackVolumes[0]+.1f);
    break;
    
     case '-':
    hubManager.hubs.get(1).setTrackVolume(0,hubManager.hubs.get(1).trackVolumes[0]-.1f);
    break;
    
    case 't':
    hubManager.hubs.get(3).triggerTrack(0);
    break;
    
    case 'v':
    for(int i=0;i<hubManager.hubs.size();i++) hubManager.hubs.get(i).showText = !hubManager.hubs.get(i).showText;
    break;
    
    case 'f':
    if(fullscreen==false){surface.setSize(displayWidth,displayHeight);}
    else{surface.setSize(600,600);}
    fullscreen=!fullscreen;
    break;
    
    case 'd':
    toggleHubDebug();
    break;
    
    case 'g':
    gridMode = !gridMode;
    break;
    
    case 'm':
    hubManager.toggleAutoMap();
    break;
  }
}

void oscEvent(OscMessage theOscMessage) {
  outputManager.processFB(theOscMessage);
  
}
